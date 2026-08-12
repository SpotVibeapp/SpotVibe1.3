class EventComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String text;
  final DateTime createdAt;

  const EventComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
  });
}

class RsvpEntry {
  final String userId;
  final String userName;
  final String avatarUrl;
  final bool isPrivate;
  final DateTime rsvpAt;

  const RsvpEntry({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    this.isPrivate = false,
    required this.rsvpAt,
  });
}
