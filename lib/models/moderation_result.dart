enum ModerationStatus { approved, flagged, rejected }

class ModerationResult {
  final ModerationStatus status;
  final String? category;
  final String? reason;

  const ModerationResult({
    required this.status,
    this.category,
    this.reason,
  });

  bool get isApproved => status == ModerationStatus.approved;
  bool get isFlagged => status == ModerationStatus.flagged;
  bool get isRejected => status == ModerationStatus.rejected;

  static const ModerationResult approved = ModerationResult(
    status: ModerationStatus.approved,
  );
}
