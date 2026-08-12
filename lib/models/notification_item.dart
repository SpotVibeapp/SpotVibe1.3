import 'package:flutter/material.dart';

/// The high-level bucket a notification belongs to.
enum NotificationType { reminder, newEvents, social }

/// Which social sub-event triggered a social notification.
enum SocialNotificationKind { comment, friendRsvp, friendRequest, interested }

@immutable
class NotificationItem {
  final String id;
  final NotificationType type;
  final SocialNotificationKind? socialKind;

  /// Human-readable title line (bolded in the tile).
  final String title;

  /// Secondary line — time / location context.
  final String subtitle;

  /// Optional deep-link path for tap navigation (e.g. '/user-event/demo_pro_1').
  final String? routePath;

  /// Whether the user has not yet opened/dismissed this notification.
  final bool isUnread;

  /// Wall-clock time this notification was generated.
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    this.socialKind,
    required this.title,
    required this.subtitle,
    this.routePath,
    this.isUnread = true,
    required this.createdAt,
  });

  NotificationItem copyWith({bool? isUnread}) => NotificationItem(
        id: id,
        type: type,
        socialKind: socialKind,
        title: title,
        subtitle: subtitle,
        routePath: routePath,
        isUnread: isUnread ?? this.isUnread,
        createdAt: createdAt,
      );

  // ── Derived helpers ────────────────────────────────────────────────────────

  IconData get icon {
    switch (type) {
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.newEvents:
        return Icons.celebration_rounded;
      case NotificationType.social:
        switch (socialKind) {
          case SocialNotificationKind.comment:
            return Icons.chat_bubble_rounded;
          case SocialNotificationKind.friendRsvp:
            return Icons.person_pin_circle_rounded;
          case SocialNotificationKind.friendRequest:
            return Icons.person_add_rounded;
          case SocialNotificationKind.interested:
            return Icons.favorite_rounded;
          case null:
            return Icons.notifications_rounded;
        }
    }
  }

  Color iconColor(ColorScheme colors, {Color? teal, Color? gold}) {
    switch (type) {
      case NotificationType.reminder:
        return gold ?? colors.tertiary;
      case NotificationType.newEvents:
        return colors.primary;
      case NotificationType.social:
        switch (socialKind) {
          case SocialNotificationKind.comment:
            return teal ?? colors.secondary;
          case SocialNotificationKind.friendRsvp:
            return colors.primary;
          case SocialNotificationKind.friendRequest:
            return colors.primary;
          case SocialNotificationKind.interested:
            return const Color(0xFFE84393);
          case null:
            return colors.primary;
        }
    }
  }

  /// Relative time label for the subtitle row.
  static String relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
