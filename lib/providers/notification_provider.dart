import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../repositories/notification_repository.dart';

/// Global [ChangeNotifier] that owns the in-app notification inbox.
///
/// Registered as a [ChangeNotifierProvider] in [main.dart] so the unread
/// badge on the bell icon stays live across all routes.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository})
      : _repo = repository;

  final NotificationRepository _repo;

  // ── Exposed state ──────────────────────────────────────────────────────────

  /// All notifications, newest first.
  List<NotificationItem> get all => _repo.getAll();

  /// Only reminder notifications.
  List<NotificationItem> get reminders =>
      _repo.getByType(NotificationType.reminder);

  /// Only new-events notifications.
  List<NotificationItem> get newEvents =>
      _repo.getByType(NotificationType.newEvents);

  /// Only social notifications.
  List<NotificationItem> get social =>
      _repo.getByType(NotificationType.social);

  int get unreadCount => _repo.unreadCount;

  // ── Actions ────────────────────────────────────────────────────────────────

  void markRead(String id) {
    _repo.markRead(id);
    notifyListeners();
  }

  void markAllRead() {
    _repo.markAllRead();
    notifyListeners();
  }

  void remove(String id) {
    _repo.remove(id);
    notifyListeners();
  }

  /// Called by [NotificationService] to push a new in-app notification.
  void push(NotificationItem item) {
    _repo.add(item);
    notifyListeners();
  }

  // ── Convenience helpers used by NotificationService ───────────────────────

  void pushReminder({
    required String id,
    required String title,
    required String subtitle,
    String? routePath,
  }) {
    push(NotificationItem(
      id: id,
      type: NotificationType.reminder,
      title: title,
      subtitle: subtitle,
      routePath: routePath,
      isUnread: true,
      createdAt: DateTime.now(),
    ));
  }

  void pushNewEvents({
    required String id,
    required String title,
    required String subtitle,
  }) {
    push(NotificationItem(
      id: id,
      type: NotificationType.newEvents,
      title: title,
      subtitle: subtitle,
      isUnread: true,
      createdAt: DateTime.now(),
    ));
  }

  void pushSocial({
    required String id,
    required SocialNotificationKind kind,
    required String title,
    required String subtitle,
    String? routePath,
  }) {
    push(NotificationItem(
      id: id,
      type: NotificationType.social,
      socialKind: kind,
      title: title,
      subtitle: subtitle,
      routePath: routePath,
      isUnread: true,
      createdAt: DateTime.now(),
    ));
  }
}
