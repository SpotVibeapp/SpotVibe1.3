/// A user-submitted moderation report (see `user_reports` in Firestore).
class UserReport {
  final String id;
  final String reportedUserId;
  final String reportedById;
  final String reason;
  final DateTime createdAt;

  const UserReport({
    required this.id,
    required this.reportedUserId,
    required this.reportedById,
    required this.reason,
    required this.createdAt,
  });
}
