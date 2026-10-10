/**
 * One-time backfill: move legacy top-level `ownerPhone` on agent-posted
 * listings into the restricted `listings/{id}/ownerContact/info` document,
 * then remove the top-level field.
 *
 * WHY: public listing reads (`status == 'active'`) expose every top-level
 * field, so legacy agent listings leak the real owner's phone number to
 * anyone, including logged-out scrapers. New clients already write the phone
 * only to `ownerContact` (see `AgentRepository.saveOwnerContact`); this
 * script migrates rows written before that change. Listing documents
 * themselves are never deleted — only the phone field is cleared, and only
 * after its contact document has been verified.
 *
 * SAFETY:
 *  - Dry-run is the default. Nothing is written without `--apply`.
 *  - Requires admin credentials (service account with Firestore access).
 *    Never run against the emulator with production data; never point this
 *    at production without a backup (Firestore export) first.
 *  - Per-document order is write-contact → re-read → clear field. A document
 *    is skipped (never half-migrated) if any step fails.
 *  - Idempotent: already-migrated documents (contact exists, no top-level
 *    phone) are skipped; re-running is safe.
 *
 * SETUP (one-off, outside the repo — no project files are touched):
 *   mkdir backfill-run && cd backfill-run
 *   npm init -y && npm install firebase-admin
 *   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
 *
 * USAGE:
 *   node <repo>/scripts/backfill-owner-contact.mjs --project=mero-kotha-1f4f3 [--limit 50]
 *   node <repo>/scripts/backfill-owner-contact.mjs --project=mero-kotha-1f4f3 --apply [--limit 50]
 *
 * LIMIT batches the run; re-run until "Found 0" (idempotent). Take a
 * Firestore export before the first --apply.
 *
 * ALTERNATIVE (no script): in the Firebase Console, query
 * `listings` where `ownerPhone != null`, and for each agent-posted
 * document manually create `ownerContact/info` {name, phone} and delete
 * the top-level `ownerPhone` field.
 */
import { readFileSync } from "node:fs";
import { initializeApp, cert, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const args = new Set(process.argv.slice(2));
const APPLY = args.has("--apply");
const limitArg = process.argv.find((a) => a.startsWith("--limit="));
const projectArg = process.argv.find((a) => a.startsWith("--project="));
const LIMIT = limitArg ? Number(limitArg.split("=")[1]) : 500;
const PROJECT = projectArg ? projectArg.split("=")[1] : null;

if (!Number.isInteger(LIMIT) || LIMIT <= 0) {
  console.error(`Invalid --limit value: ${limitArg}. Must be a positive integer.`);
  process.exit(2);
}

// Explicit project gate: this script touches real user data, so the
// target project must be stated on every invocation — never inferred.
// Example: --project=mero-kotha-1f4f3
if (!PROJECT) {
  console.error("Missing required --project=<project-id>. Refusing to run.");
  process.exit(2);
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.FIREBASE_CONFIG) {
  console.error(
    "Missing credentials: set GOOGLE_APPLICATION_CREDENTIALS to a service " +
      "account key with Firestore admin access. Refusing to run.",
  );
  process.exit(2);
}

// Service-account key when provided; otherwise Application Default Credentials.
try {
  const key = JSON.parse(
    readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, "utf8"),
  );
  initializeApp({ credential: cert(key), projectId: PROJECT });
} catch {
  initializeApp({ credential: applicationDefault(), projectId: PROJECT });
}

const db = getFirestore();
const mode = APPLY ? "APPLY" : "DRY-RUN";
console.log(`Mode: ${mode} (default is dry-run; pass --apply to write)`);

const snap = await db
  .collection("listings")
  .where("ownerPhone", "!=", null)
  .limit(LIMIT)
  .get();

console.log(`Found ${snap.size} listing(s) with a top-level ownerPhone.`);

let moved = 0;
let skipped = 0;
let failed = 0;

for (const listingDoc of snap.docs) {
  const id = listingDoc.id;
  const data = listingDoc.data();
  const phone = data.ownerPhone;
  const name = data.ownerName ?? "";
  const isAgentListing = (data.agentId ?? null) === data.ownerId;

  if (typeof phone !== "string" || phone.length === 0) {
    console.log(`- ${id}: empty phone value, skipping`);
    skipped++;
    continue;
  }

  const contactRef = listingDoc.ref.collection("ownerContact").doc("info");
  const existing = await contactRef.get();

  if (existing.exists) {
    const kept = existing.data()?.phone;
    if (kept === phone) {
      console.log(`- ${id}: contact already migrated; clearing top-level field`);
      if (APPLY) {
        await listingDoc.ref.update({ ownerPhone: FieldValue.delete() });
      }
      moved++;
      continue;
    }
    console.log(
      `- ${id}: contact exists with a DIFFERENT phone; ` +
        `leaving both in place for manual review` +
        (isAgentListing ? "" : " (not an agent listing — unexpected)"),
    );
    skipped++;
    continue;
  }

  if (!isAgentListing) {
    console.log(
      `- ${id}: non-agent listing carries a top-level phone; ` +
        `leaving in place for manual review (owner listings never set this field)`,
    );
    skipped++;
    continue;
  }

  console.log(`- ${id}: move phone to ownerContact/info, clear top-level`);
  if (APPLY) {
    try {
      await contactRef.set({ name, phone });
      const verify = await contactRef.get();
      if (!verify.exists || verify.data()?.phone !== phone) {
        throw new Error("contact verification read failed");
      }
      await listingDoc.ref.update({ ownerPhone: FieldValue.delete() });
      moved++;
    } catch (e) {
      console.error(`  ! ${id} failed, left untouched: ${e.message}`);
      failed++;
    }
  } else {
    moved++; // would-move count for dry-run reporting
  }
}

console.log(
  `\nDone (${mode}): ${moved} to migrate, ${skipped} skipped, ${failed} failed.`,
);
if (!APPLY) {
  console.log("Re-run with --apply to perform the migration.");
}
if (failed > 0) process.exit(1);
