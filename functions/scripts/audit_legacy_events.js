const { applicationDefault, initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const expectedProjectId = "eventify-campus-15122";
const projectArgument = process.argv.find((arg) =>
  arg.startsWith("--projectId="),
);
const projectId = projectArgument?.slice("--projectId=".length);

if (projectId !== expectedProjectId) {
  throw new Error(
    `Pass --projectId=${expectedProjectId} to audit the configured project.`,
  );
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const requiredFields = [
  "id",
  "name",
  "pic",
  "date",
  "location",
  "description",
  "status",
  "category",
  "createdAt",
  "createdBy",
  "isPublished",
  "reminderDaysBefore",
];
const validApprovalStatuses = new Set(["pending", "approved", "rejected"]);
const selectedFields = [
  ...requiredFields,
  "approvalStatus",
  "reviewedBy",
  "reviewedAt",
  "rejectionReason",
];

async function main() {
  const snapshot = await getFirestore()
    .collection("events")
    .select(...selectedFields)
    .get();

  const records = snapshot.docs.map((document) => {
    const data = document.data();
    const hasApprovalStatus = Object.hasOwn(data, "approvalStatus");
    const hasReviewedStatus = ["approved", "rejected"].includes(
      data.approvalStatus,
    );
    const missingFields = requiredFields.filter(
      (field) => !Object.hasOwn(data, field),
    );
    const missingReviewFields = hasReviewedStatus
      ? ["reviewedBy", "reviewedAt"].filter(
          (field) => !Object.hasOwn(data, field),
        )
      : [];
    if (
      data.approvalStatus === "rejected" &&
      typeof data.rejectionReason !== "string"
    ) {
      missingReviewFields.push("rejectionReason");
    }

    return {
      id: document.id,
      name: typeof data.name === "string" ? data.name : "",
      approvalStatus: hasApprovalStatus ? data.approvalStatus : null,
      isPublished: typeof data.isPublished === "boolean"
        ? data.isPublished
        : null,
      missingFields,
      missingReviewFields,
      needsStatusReview:
        !hasApprovalStatus || !validApprovalStatuses.has(data.approvalStatus),
    };
  });

  const needsStatusReview = records.filter((record) => record.needsStatusReview);
  const publishedWithoutApproval = records.filter(
    (record) => record.isPublished === true
      && record.approvalStatus !== "approved",
  );

  console.log(
    JSON.stringify(
      {
        projectId,
        totalEvents: records.length,
        eventsNeedingStatusReview: needsStatusReview,
        publishedWithoutApproval,
        eventsMissingRequiredFields: records.filter(
          (record) => record.missingFields.length > 0,
        ),
        eventsMissingReviewFields: records.filter(
          (record) => record.missingReviewFields.length > 0,
        ),
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error("Legacy event audit failed:", error);
  process.exitCode = 1;
});
