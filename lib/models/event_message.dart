class EventMessage {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final bool hidden;

  const EventMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.hidden = false,
  });

  factory EventMessage.fromMap(String id, Map<String, dynamic> data) {
    final ms = (data['createdAtMs'] as num?)?.toInt();
    return EventMessage(
      id: id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: ms != null
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.now(),
      hidden: data['hidden'] == true,
    );
  }
}

class EventDirectThread {
  final String id;
  final String eventId;
  final String hostId;
  final String attendeeId;
  final DateTime? lastMessageAt;
  final String lastPreview;

  const EventDirectThread({
    required this.id,
    required this.eventId,
    required this.hostId,
    required this.attendeeId,
    this.lastMessageAt,
    this.lastPreview = '',
  });

  factory EventDirectThread.fromMap(String id, Map<String, dynamic> data) {
    final ms = (data['lastMessageAtMs'] as num?)?.toInt();
    return EventDirectThread(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      hostId: data['hostId'] as String? ?? '',
      attendeeId: data['attendeeId'] as String? ?? '',
      lastMessageAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      lastPreview: data['lastPreview'] as String? ?? '',
    );
  }
}
