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

/// A 1:1 conversation between an event's host and one attendee
/// (`event_dms/{eventId}_{hostId}_{attendeeId}`). Written only by Cloud
/// Functions; see MESSAGING.md.
class EventDirectThread {
  final String id;
  final String eventId;
  final String eventTitle;
  final String hostId;
  final String attendeeId;
  final List<String> participants;
  final DateTime? lastMessageAt;
  final String lastPreview;
  final String lastAuthorId;
  final String startedBy;
  final Map<String, int> unread;
  final Map<String, String> names;

  const EventDirectThread({
    required this.id,
    required this.eventId,
    required this.hostId,
    required this.attendeeId,
    this.eventTitle = '',
    this.participants = const [],
    this.lastMessageAt,
    this.lastPreview = '',
    this.lastAuthorId = '',
    this.startedBy = '',
    this.unread = const {},
    this.names = const {},
  });

  factory EventDirectThread.fromMap(String id, Map<String, dynamic> data) {
    final ms = (data['lastMessageAtMs'] as num?)?.toInt();
    final hostId = data['hostId'] as String? ?? '';
    final attendeeId = data['attendeeId'] as String? ?? '';
    final rawParts = data['participants'];
    final unread = <String, int>{};
    final rawUnread = data['unread'];
    if (rawUnread is Map) {
      rawUnread.forEach((k, v) {
        if (k is String && v is num) unread[k] = v.toInt();
      });
    }
    final names = <String, String>{};
    final rawNames = data['names'];
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        if (k is String && v is String) names[k] = v;
      });
    }
    return EventDirectThread(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? '',
      hostId: hostId,
      attendeeId: attendeeId,
      participants: rawParts is List
          ? rawParts.whereType<String>().toList()
          : [hostId, attendeeId].where((e) => e.isNotEmpty).toList(),
      lastMessageAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      lastPreview: data['lastPreview'] as String? ?? '',
      lastAuthorId: data['lastAuthorId'] as String? ?? '',
      startedBy: data['startedBy'] as String? ?? '',
      unread: unread,
      names: names,
    );
  }

  bool isHost(String uid) => uid.isNotEmpty && uid == hostId;

  /// The person on the other side of the conversation from [uid].
  String otherParticipant(String uid) => uid == hostId ? attendeeId : hostId;

  int unreadFor(String uid) => unread[uid] ?? 0;

  /// Stored display name for [uid], or empty if unknown.
  String nameOf(String uid) => (names[uid] ?? '').trim();

  bool lastMessageIsMine(String uid) => lastAuthorId.isNotEmpty && lastAuthorId == uid;
}

/// Client mirror of the server's `dmSendDecision` (functions/lib/eventMessaging.js),
/// used only to pick the right UI (paywall vs composer). The server is the
/// source of truth.
class DirectMessagePolicy {
  const DirectMessagePolicy._();

  static const int maxLength = 1000;

  /// Hosts need Premium only to start a conversation; replies are free.
  static bool hostNeedsPremium({required bool threadExists, required bool isPremium}) =>
      !threadExists && !isPremium;

  /// RSVP'd attendees can always start a conversation with the host.
  static bool attendeeCanStart({required bool hasRsvp, required bool threadExists}) =>
      threadExists || hasRsvp;

  static String unreadLabel(int count) => count > 9 ? '9+' : '$count';

  static int totalUnread(Iterable<EventDirectThread> threads, String uid) =>
      threads.fold(0, (sum, t) => sum + t.unreadFor(uid));
}
