function shouldNotifyApproval(before, after) {
  return (
    before?.approvalStatus === "pending" &&
    after?.approvalStatus === "approved" &&
    after?.isPublished === true
  );
}

module.exports = { shouldNotifyApproval };
