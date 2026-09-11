/// A user-submitted moderation report (see `user_reports` in Firestore).
///
/// Reports may target a user, or a piece of content (an event or a hidden
/// gem). Content reports carry [contentType] ('event' / 'gem') and [contentId]
/// so an admin can locate the reported item.
class UserReport {
  final String id;
  final String reportedUserId;
  final String reportedById;
  final String reason;

  /// '' for user reports; 'event' or 'gem' for content reports.
  final String contentType;

  /// The reported event/gem id, when this is a content report.
  final String contentId;

  final DateTime createdAt;

  const UserReport({
    required this.id,
    required this.reportedUserId,
    required this.reportedById,
    required this.reason,
    this.contentType = '',
    this.contentId = '',
    required this.createdAt,
  });
}
