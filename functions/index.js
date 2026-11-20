const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { shouldNotifyApproval } = require("./src/approval_notification");

initializeApp();

exports.notifyEventApproved = onDocumentUpdated(
  { document: "events/{eventId}", retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after || !shouldNotifyApproval(before, after)) {
      return;
    }

    const eventId = event.params.eventId;
    const name =
      typeof after.name === "string" && after.name.trim()
        ? after.name.trim().slice(0, 100)
        : "Event baru";

    const messageId = await getMessaging().send({
      topic: "all_users",
      notification: {
        title: "Event baru disetujui",
        body: `${name} sudah disetujui dan dapat dilihat di Eventify Campus.`,
      },
      data: {
        type: "event_approved",
        eventId,
      },
      android: {
        notification: {
          tag: `event-approved-${eventId}`,
        },
      },
      apns: {
        headers: {
          "apns-collapse-id": `event-approved-${eventId}`,
        },
      },
    });

    logger.info("Approval notification sent", { eventId, messageId });
  },
);
