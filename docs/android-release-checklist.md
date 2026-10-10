# Android Release Checklist — MeroKotha

Manual, ordered checklist for the release manager. Nothing here runs
automatically; every Firebase Console step must be done by a human with
project access. **No fingerprints or secrets are recorded in this repo —
obtain the values with the commands below and paste them into the
console directly.**

Project: `mero-kotha-1f4f3` · package: `com.merokotha.app`

## 1. Signing material (local machine only — never commit)

Verified untracked and git-ignored: `android/key.properties`,
`android/app/upload-keystore.jks`, `android/app/google-services.json`,
`lib/firebase_options.dart`. Only the public
`android/app/upload_certificate.pem` is tracked — that is expected.

- [ ] Offline backup of `upload-keystore.jks` + `android/key.properties`
      exists outside this machine. Loss = cannot update the Play listing.

## 2. SHA fingerprints (obtain — do not invent)

Google Sign-In and Play Integrity fail with `ApiException: 10 /
DEVELOPER_ERROR` unless **all three** SHAs are registered. Obtain each
with the matching command (replace the alias/store paths with yours):

```powershell
# 1. Debug key (local development)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android

# 2. Upload key (this release)
keytool -list -v -keystore android/app/upload-keystore.jks -alias <keyAlias>

# 3. Play App Signing certificate — Firebase Console > Project Settings >
#    Android app > App signing key certificate (Play Console > Setup >
#    App integrity > App signing). Copy SHA-1 and SHA-256 from there.
```

- [ ] Debug SHA-1/SHA-256 added under the Android app in Firebase Console.
- [ ] Upload SHA-1/SHA-256 added under the same app.
- [ ] Play App Signing SHA-1/SHA-256 added under the same app.

## 3. OAuth + Firebase config refresh

- [ ] Firebase Console shows an OAuth client for **each** registered SHA
      (Web client is used with `google-services.json`; mismatches surface
      as sign-in error 10 — see `auth_provider.dart` mapping).
- [ ] Re-downloaded `android/app/google-services.json` **after** adding the
      SHAs and replaced the local file (it is git-ignored by design).
- [ ] `package_name` entries in that file read `com.merokotha.app`.

## 4. Firestore indexes

- [ ] `firebase deploy --only firestore:indexes --project mero-kotha-1f4f3`
      (review only — do not run until approved).
- [ ] Every entry in `firestore.indexes.json` shows `READY` in
      Firebase Console > Firestore > Indexes before release. Required
      composites cover: listings search permutations
      (`status` + `roomType`/`furnishing` + `rentPerMonth`), inquiries
      (`ownerId+status`, `customerId+listingId`), chats
      (`ownerId/customerId` + `lastMessageAt`), legacy chat lookup
      (`ownerId+customerId+listingId`). Message threads intentionally use
      automatic single-field indexes (no `messages` composite is needed).
- [ ] Optional cleanup (Console > Firestore > Indexes > delete; code
      queries never use these fields): `listings categoryL1Id+createdAt`,
      `categoryL2Id+createdAt`, `status+categoryL1Id+rentPerMonth`
      (client filters map `categoryL1Id` state onto the `roomType`
      field), and `chats ownerId/customerId+createdAt` (queries order by
      `lastMessageAt`). Harmless if left; do not delete anything else.

## 5. Rules + functions deploy (review exact commands first)

```powershell
firebase deploy --only firestore:rules --project mero-kotha-1f4f3
firebase deploy --only storage --project mero-kotha-1f4f3
firebase deploy --only functions --project mero-kotha-1f4f3
```

The rules under review additionally contain, all emulator-verified
(16/16): `usersPublic` name/photo projection (public reads) with
`users/{uid}` reads restricted to owner + admin; banned-user write
blocks (unchanged) plus a client-side suspension screen; agent
application lifecycle (`pending` → admin `approved`/`rejected`,
`agentStatus` immutable self-side). No new composite indexes are
needed for these paths (direct document reads/writes only).

- [ ] `functions/package-lock.json` is committed so Cloud Build resolves
      `firebase-admin@13` / `firebase-functions@6` deterministically
      (runtime `nodejs20`, region `asia-south1`).
- [ ] After deploy: `onMessageCreated` shows HEALTHY; send a test chat
      message and confirm a push arrives.

## 6. Data migration (before or with rules deploy)

- [ ] Firestore export taken (Console > Firestore > Import/Export).
- [ ] `scripts/backfill-owner-contact.mjs --project=mero-kotha-1f4f3`
      dry-run reviewed, then `--apply`; re-run until it reports nothing
      left to migrate. This clears legacy top-level `ownerPhone` fields
      that public listing reads would otherwise expose.
- [ ] Console spot-check: `listings where ownerPhone != null` returns empty.
- [ ] `usersPublic` (optional): legacy accounts lack the projection until
      their next profile save; displays fall back to denormalized
      listing/chat names, so no action is required. If desired, create
      `usersPublic/{uid}` = `{name, photoUrl}` per user from a Firestore
      export (admin SDK, same precautions as above).

## 7. App Check

The app activates Play Integrity / App Attest but never crashes without
it. Enforcement is a console toggle, not code:

- [ ] Firebase Console > App Check: apps registered with the SHAs above.
- [ ] Monitor metrics for a rollout window, then **Enforce** on
      Firestore, Storage, and FCM. Until enforced, the `viewCount`
      increment and public reads are bot-accessible by design.

## 8. Real-device verification (Android 13+ and 14)

- [ ] Google Sign-In on a release build (catches error 10 early).
- [ ] Gallery uploads work (listings, agent listings, chat photos).
- [ ] Location permission prompt → map centers on device, not Kathmandu.
- [ ] Get Directions opens the maps app with the room pinned.
- [ ] Chat push in foreground / background / terminated states; tap opens
      the right thread; no pushes arrive after sign-out on the same device.
- [ ] Banned test account sees the suspension screen and cannot write.
- [ ] Deep link `/customer/inquire/<id>` with no cached state loads the form.
