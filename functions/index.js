/**
 * MeroKotha Cloud Functions — chat push notifications.
 *
 * Firestore rules deliberately do NOT grant clients any ability to send
 * notifications. Push is only triggered here, by the database, so a malicious
 * client cannot use it to spam another user or to read their conversations.
 *
 * Data keys must stay in sync with
 * `lib/features/notification/messaging_service.dart` (`PushKeys`).
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

const PUSH_TYPE = "chat_message";
const MAX_BODY_LENGTH = 120;

/** Trims a Firestore user doc down to the tokens this function may use. */
function tokensOf(userDoc) {
  if (!userDoc.exists) return [];
  const data = userDoc.data() || {};
  const list = Array.isArray(data.fcmTokens) ? data.fcmTokens.filter((t) => typeof t === "string") : [];
  // Backwards compatibility: chats created before multi-device support may
  // only have the single-token field populated.
  if (typeof data.fcmToken === "string" && !list.includes(data.fcmToken)) {
    list.push(data.fcmToken);
  }
  return [...new Set(list)];
}

/**
 * Drops tokens Firebase reports as permanently invalid so a dead device stops
 * costing a send on every message. [deadTokens] comes straight from the
 * send results below — only tokens FCM confirmed unregistered are removed.
 */
async function pruneDeadTokens(uid, deadTokens) {
  const invalid = [...new Set(deadTokens.filter((t) => typeof t === "string" && t.length > 0))];
  if (invalid.length === 0) return;
  try {
    const ref = db.doc(`users/${uid}`);
    await ref.update({
      fcmTokens: FieldValue.arrayRemove(...invalid),
    });
    // The legacy single-token field is not covered by arrayRemove. If it
    // holds a dead token, clear it too — otherwise tokensOf() re-adds it
    // on every send and the dead device keeps costing a fan-out.
    const snap = await ref.get();
    if (snap.exists && invalid.includes(snap.data()?.fcmToken)) {
      await ref.update({ fcmToken: FieldValue.delete() });
    }
  } catch (e) {
    logger.warn(`Failed to prune tokens for ${uid}: ${e.message}`);
  }
}

/**
 * Fired when a message is written to `chats/{chatId}/messages/{messageId}`.
 *
 * Fan-out rules:
 *   - never notify the author of the message;
 *   - notify the other participant only;
 *   - `android.priority: high` and the `chat_messages` channel make the
 *     notification heads-up rather than a silent tray entry;
 *   - the `notification` block is what the OS renders when the app is
 *     backgrounded or terminated, so those two contexts need no extra work.
 */
exports.onMessageCreated = onDocumentCreated(
  {
    document: "chats/{chatId}/messages/{messageId}",
    region: "asia-south1",
    memory: "256MiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const senderId = message.senderId;

    if (!senderId) {
      logger.warn(`Message ${messageId} has no senderId; skipping push.`);
      return;
    }

    const chatSnap = await db.doc(`chats/${chatId}`).get();
    if (!chatSnap.exists) {
      logger.warn(`Chat ${chatId} missing for message ${messageId}; skipping.`);
      return;
    }

    const chat = chatSnap.data();
    const recipientId =
      chat.ownerId === senderId ? chat.customerId : chat.ownerId;

    if (!recipientId || recipientId === senderId) {
      logger.warn(`No distinct recipient for chat ${chatId}; skipping push.`);
      return;
    }

    const recipient = await db.doc(`users/${recipientId}`).get();
    if ((recipient.data() || {}).isBanned === true) {
      logger.info(`Recipient ${recipientId} is banned; skipping push.`);
      return;
    }

    const tokens = tokensOf(recipient);
    if (tokens.length === 0) {
      logger.info(`Recipient ${recipientId} has no registered device tokens.`);
      return;
    }

    const senderName =
      senderId === chat.ownerId ? chat.ownerName : chat.customerName;
    const hasImage = typeof message.imageUrl === "string" && message.imageUrl.length > 0;
    const body = hasImage
      ? "📷 Photo"
      : String(message.text || "").slice(0, MAX_BODY_LENGTH);

    const payload = {
      tokens: tokens,
      notification: {
        title: senderName || "New message",
        body: body || "New message",
      },
      data: {
        type: PUSH_TYPE,
        chatId: String(chatId),
        messageId: String(messageId),
        senderId: String(senderId),
        senderName: String(senderName || "New message"),
        listingTitle: String(chat.listingTitle || ""),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_messages",
          tag: `chat_${chatId}`,
          // Replace the previous alert from the same conversation rather than
          // stacking one per message.
          notificationCount: 1,
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            alert: {
              title: senderName || "New message",
              body: body || "New message",
            },
            sound: "default",
            threadId: chatId,
          },
        },
      },
    };

    try {
      const result = await getMessaging().sendEachForMulticast(payload);
      logger.info(
        `Pushed message ${messageId} to ${recipientId}: ` +
          `${result.successCount} ok, ${result.failureCount} failed.`
      );

      // Permanent failure codes: the token will never become valid again,
      // so it is pruned from the recipient's list. Any other failure is
      // transient and the token is kept.
      const deadCodes = new Set([
        "messaging/registration-token-not-registered",
        "messaging/invalid-registration-token",
        "messaging/invalid-argument",
      ]);
      const dead = [];
      result.responses.forEach((r, i) => {
        if (!r.success && r.error && deadCodes.has(r.error.code)) {
          dead.push(tokens[i]);
        }
      });
      await pruneDeadTokens(recipientId, dead);
    } catch (e) {
      // sendEachForMulticast only throws on infrastructure errors (auth,
      // network), in which case nothing was delivered — rethrowing retries
      // the whole batch. Per-token failures never reach here; they are
      // reported in the response above without retry, so a delivered
      // notification is never duplicated by this path. At-least-once
      // delivery is deliberate: a lost chat alert is worse than a repeat.
      logger.error(`Push failed for message ${messageId}: ${e.message}`);
      throw e; // let FCM retry
    }
  }
);
