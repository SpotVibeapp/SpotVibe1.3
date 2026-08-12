import '../models/notification_item.dart';

/// In-memory notification store.  Replace with a real backend or push-delivery
/// system when a server is available.
class NotificationRepository {
  final List<NotificationItem> _items = _seed();

  // ── Read ───────────────────────────────────────────────────────────────────

  List<NotificationItem> getAll() =>
      List.unmodifiable(_items)..toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<NotificationItem> getByType(NotificationType type) =>
      _items.where((n) => n.type == type).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadCount => _items.where((n) => n.isUnread).length;

  // ── Write ──────────────────────────────────────────────────────────────────

  void add(NotificationItem item) {
    _items.insert(0, item);
  }

  void markRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1) _items[idx] = _items[idx].copyWith(isUnread: false);
  }

  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isUnread: false);
    }
  }

  void remove(String id) => _items.removeWhere((n) => n.id == id);

  // ── Seed data ──────────────────────────────────────────────────────────────

  static List<NotificationItem> _seed() {
    final now = DateTime.now();
    return [
      // ── A. Event Reminders ────────────────────────────────────────────────
      NotificationItem(
        id: 'rem_1',
        type: NotificationType.reminder,
        title: 'Your event starts in 1 hour',
        subtitle: 'Trivia Night · The Rusty Anchor Bar · Tonight',
        routePath: '/user-event/demo_pro_1',
        isUnread: true,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      NotificationItem(
        id: 'rem_2',
        type: NotificationType.reminder,
        title: 'Your event is tomorrow at 7:00 PM',
        subtitle: 'Indie Film Screening · The Majestic Cinema',
        routePath: '/user-event/demo_pro_2',
        isUnread: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: 'rem_3',
        type: NotificationType.reminder,
        title: "Don't forget: Trivia Night tonight at 7:00 PM",
        subtitle: 'The Rusty Anchor Bar · Austin, TX',
        routePath: '/user-event/demo_pro_1',
        isUnread: false,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      // ── B. New Events Notifications ────────────────────────────────────────
      NotificationItem(
        id: 'evt_1',
        type: NotificationType.newEvents,
        title: '5 new music events near you this weekend',
        subtitle: 'Austin, TX · Friday → Sunday',
        isUnread: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationItem(
        id: 'evt_2',
        type: NotificationType.newEvents,
        title: 'Weekly digest: 12 events you might like',
        subtitle: 'Music, Social & Arts · This week in Austin',
        isUnread: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      NotificationItem(
        id: 'evt_3',
        type: NotificationType.newEvents,
        title: '3 new Comedy events near you',
        subtitle: 'Matches your Comedy preference · Austin, TX',
        isUnread: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      // ── C. Social Notifications ────────────────────────────────────────────
      NotificationItem(
        id: 'soc_1',
        type: NotificationType.social,
        socialKind: SocialNotificationKind.comment,
        title: '3 new comments on your event',
        subtitle: 'Trivia Night · View all comments',
        routePath: '/user-event/demo_pro_1',
        isUnread: true,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      NotificationItem(
        id: 'soc_2',
        type: NotificationType.social,
        socialKind: SocialNotificationKind.friendRsvp,
        title: 'Jordan Lee is going to Indie Film Screening',
        subtitle: 'Your friend just RSVP\'d · Tap to see who\'s going',
        routePath: '/user-event/demo_pro_2',
        isUnread: true,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      NotificationItem(
        id: 'soc_3',
        type: NotificationType.social,
        socialKind: SocialNotificationKind.interested,
        title: 'Alex Rivera is interested in your event',
        subtitle: 'Trivia Night · 8 people interested now',
        routePath: '/user-event/demo_pro_1',
        isUnread: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationItem(
        id: 'soc_4',
        type: NotificationType.social,
        socialKind: SocialNotificationKind.friendRequest,
        title: 'Sam Torres sent you a friend request',
        subtitle: '2 mutual events · Tap to respond',
        isUnread: false,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }
}
