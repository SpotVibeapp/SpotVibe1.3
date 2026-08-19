import '../models/notification_item.dart';

/// In-memory notification inbox.
///
/// It deliberately starts empty: a production app must never show fictional
/// reminders, social activity, or events that do not belong to the user.
/// Wire real push/backend events into [add] as those capabilities are shipped.
class NotificationRepository {
  final List<NotificationItem> _items = [];

  // ── Read ───────────────────────────────────────────────────────────────────

  /// A newest-first, immutable snapshot of actual in-app notifications.
  List<NotificationItem> getAll() {
    final sorted = List<NotificationItem>.from(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  /// A newest-first, immutable snapshot limited to [type].
  List<NotificationItem> getByType(NotificationType type) {
    final sorted = _items.where((item) => item.type == type).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  int get unreadCount => _items.where((item) => item.isUnread).length;

  // ── Write ──────────────────────────────────────────────────────────────────

  void add(NotificationItem item) {
    _items.insert(0, item);
  }

  void markRead(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) _items[index] = _items[index].copyWith(isUnread: false);
  }

  void markAllRead() {
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(isUnread: false);
    }
  }

  void remove(String id) => _items.removeWhere((item) => item.id == id);
}
