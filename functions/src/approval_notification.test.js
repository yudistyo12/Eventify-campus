const assert = require("node:assert/strict");
const test = require("node:test");
const { shouldNotifyApproval } = require("./approval_notification");

test("notifies only when a pending event is approved and published", () => {
  assert.equal(
    shouldNotifyApproval(
      { approvalStatus: "pending", isPublished: false },
      { approvalStatus: "approved", isPublished: true },
    ),
    true,
  );
});

test("does not notify for rejected, unpublished, or reactivated events", () => {
  assert.equal(
    shouldNotifyApproval(
      { approvalStatus: "pending", isPublished: false },
      { approvalStatus: "approved", isPublished: false },
    ),
    false,
  );
  assert.equal(
    shouldNotifyApproval(
      { approvalStatus: "approved", isPublished: false },
      { approvalStatus: "approved", isPublished: true },
    ),
    false,
  );
  assert.equal(
    shouldNotifyApproval(
      { approvalStatus: "pending", isPublished: false },
      { approvalStatus: "rejected", isPublished: false },
    ),
    false,
  );
});
