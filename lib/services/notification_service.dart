import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import '../repositories/notification_preferences_repository.dart';

/// Channel IDs — one per logical notification category.
const _kChannelEvents = 'spotvibe_events';
const _kChannelUpdates = 'spotvibe_updates';
const _kChannelSocial = 'spotvibe_social';

/// Unique notification IDs per category (incremented in-memory).
int _nextId = 1;
int _nextNotifId() => _nextId++;

/// Local, device-side notifications for actions and server-confirmed events.
///
/// This service never invents background activity: a feed refresh is not proof
/// that a new event was published. True remote/background alerts require a
/// future Firebase Cloud Messaging delivery path.
class NotificationService {
  NotificationService({NotificationPreferencesRepository? preferences})
      : _preferences = preferences ?? NotificationPreferencesRepository();

  final NotificationPreferencesRepository _preferences;
  bool _initialized = false;

  /// Call once from [main()] before [runApp].
  Future<void> initialize() async {
    // awesome_notifications is mobile-only; no-op on web.
    if (kIsWeb) return;

    try {
      _initialized = await AwesomeNotifications().initialize(
        null, // use default app icon
        [
          NotificationChannel(
            channelKey: _kChannelEvents,
            channelName: 'New Events',
            channelDescription: 'Notifications about new events near you',
            defaultColor: const Color(0xFF6C5CE7),
            ledColor: const Color(0xFF6C5CE7),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: _kChannelUpdates,
            channelName: 'Event Updates',
            channelDescription:
                'Updates on events you bookmarked or are interested in',
            defaultColor: const Color(0xFF6C5CE7),
            ledColor: const Color(0xFF6C5CE7),
            importance: NotificationImportance.Default,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: _kChannelSocial,
            channelName: 'Social',
            channelDescription: 'Friend requests and activity from people you follow',
            defaultColor: const Color(0xFF6C5CE7),
            ledColor: const Color(0xFF6C5CE7),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
        ],
        debug: false,
      );
    } catch (_) {
      // Notification setup must never prevent the app from launching.
      _initialized = false;
    }
  }

  Future<bool> _canSend() async {
    if (kIsWeb || !_initialized) return false;
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canSendWith(Future<bool> preference) async {
    if (!await _canSend()) return false;
    return await preference;
  }

  /// Sends an explicit, user-requested device test. It is not a fictional
  /// event, reminder, or social alert.
  Future<bool> sendTestNotification({
    required String title,
    required String body,
  }) async {
    if (!await _canSend()) return false;
    return _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: title,
      body: body,
    );
  }

  // ── Server-confirmed new event ────────────────────────────────────────────

  /// Reserved for a future server-confirmed event delivery trigger.
  ///
  /// Do not call this because a search or feed refresh returned events.
  Future<void> notifyNewEvents({
    required int count,
    required String areaLabel,
  }) async {
    if (!await _canSendWith(_preferences.getWeeklyDigest()) || count == 0) {
      return;
    }
    final body = count == 1
        ? '1 new event found near $areaLabel'
        : '$count new events found near $areaLabel';
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelEvents,
      title: '🎉 New Events on SpotVibe',
      body: body,
    );
  }

  // ── Bookmark / interested update ──────────────────────────────────────────

  /// Confirms the user's own save action if event-update alerts are enabled.
  Future<void> notifyBookmarked(String eventTitle) async {
    if (!await _canSendWith(_preferences.getEventReminders())) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: '🔖 Event Saved',
      body: '"$eventTitle" has been added to your bookmarks.',
    );
  }

  /// Confirms the user's own interested action if event-update alerts are enabled.
  Future<void> notifyInterested(String eventTitle) async {
    if (!await _canSendWith(_preferences.getEventReminders())) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: '⭐ You\'re Interested',
      body: '"$eventTitle" has been marked as interested.',
    );
  }

  // ── Friend request ─────────────────────────────────────────────────────────

  /// Confirms the current user's real friend-request action.
  Future<void> notifyFriendRequest({
    required String fromName,
    bool isSentByMe = false,
  }) async {
    if (!await _canSendWith(_preferences.getSocialFriendRequests())) return;
    if (isSentByMe) {
      await _send(
        id: _nextNotifId(),
        channelKey: _kChannelSocial,
        title: '👋 Friend Request Sent',
        body: 'Your friend request to $fromName has been sent!',
      );
      return;
    }

    // Inbound requests must only be called from a real backend event.
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelSocial,
      title: '🤝 New Friend Request',
      body: '$fromName wants to connect with you on SpotVibe.',
    );
  }

  // ── Event reminders ───────────────────────────────────────────────────────

  Future<void> notifyEventStartingSoon({
    required String eventTitle,
    required String locationLabel,
  }) async {
    if (!await _canSendWith(_preferences.getEventReminders())) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: '⏰ Your event starts in 1 hour',
      body: '$eventTitle · $locationLabel',
    );
  }

  Future<void> notifyEventTomorrow({
    required String eventTitle,
    required String timeLabel,
    required String locationLabel,
  }) async {
    if (!await _canSendWith(_preferences.getEventReminders())) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: 'Your event is tomorrow at $timeLabel',
      body: '$eventTitle · $locationLabel',
    );
  }

  Future<void> notifyEventTonight({
    required String eventTitle,
    required String timeLabel,
    required String locationLabel,
  }) async {
    if (!await _canSendWith(_preferences.getEventReminders())) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: "⏰ Don't forget: $eventTitle tonight at $timeLabel",
      body: locationLabel,
    );
  }

  // ── Discovery alerts ──────────────────────────────────────────────────────

  Future<void> notifyNewEventsNearby({
    required int count,
    required String category,
    required String areaLabel,
    required String timePeriod,
  }) async {
    if (!await _canSendWith(_preferences.getCategoryEnabled(category)) ||
        count == 0) {
      return;
    }
    final plural =
        count == 1 ? '1 new $category event' : '$count new $category events';
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelEvents,
      title: '🎉 $plural near you $timePeriod',
      body: '$areaLabel · Tap to explore',
    );
  }

  Future<void> notifyWeeklyDigest({
    required int eventCount,
    required List<String> categories,
    required String areaLabel,
  }) async {
    if (!await _canSendWith(_preferences.getWeeklyDigest()) ||
        eventCount == 0) {
      return;
    }
    final catLine = categories.take(3).join(', ');
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelEvents,
      title: '📅 Weekly digest: $eventCount events you might like',
      body: '$catLine · This week in $areaLabel',
    );
  }

  // ── Social notifications ──────────────────────────────────────────────────

  Future<void> notifyNewComments({
    required String eventTitle,
    required int commentCount,
  }) async {
    if (!await _canSendWith(_preferences.getSocialComments()) ||
        commentCount == 0) {
      return;
    }
    final label =
        commentCount == 1 ? '1 new comment' : '$commentCount new comments';
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelSocial,
      title: '💬 $label on your event',
      body: eventTitle,
    );
  }

  Future<void> notifyFriendRsvp({
    required String friendName,
    required String eventTitle,
  }) async {
    if (!await _canSendWith(_preferences.getSocialFriendRsvp())) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelSocial,
      title: '🙌 $friendName is going to $eventTitle',
      body: 'Tap to see who else is going',
    );
  }

  Future<bool> _send({
    required int id,
    required String channelKey,
    required String title,
    required String body,
  }) async {
    try {
      return await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          autoDismissible: true,
        ),
      );
    } catch (_) {
      // Never crash the app due to a notification failure.
      return false;
    }
  }
}
