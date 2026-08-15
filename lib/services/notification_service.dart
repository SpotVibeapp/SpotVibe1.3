import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

/// Channel IDs — one per logical notification category.
const _kChannelEvents = 'spotvibe_events';
const _kChannelUpdates = 'spotvibe_updates';
const _kChannelSocial = 'spotvibe_social';

/// Unique notification IDs per category (incremented in-memory).
int _nextId = 1;
int _nextNotifId() => _nextId++;

class NotificationService {
  bool _initialized = false;

  /// Call once from [main()] before [runApp].
  Future<void> initialize() async {
    // awesome_notifications is mobile-only; no-op on web.
    if (kIsWeb) return;

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
          channelDescription: 'Updates on events you bookmarked or are interested in',
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

  }

  // ── Permission guard ────────────────────────────────────────────────────────

  bool get _canSend => !kIsWeb && _initialized;

  // ── New event discovered ────────────────────────────────────────────────────

  /// Called when [count] new events are loaded for the user's area.
  Future<void> notifyNewEvents({
    required int count,
    required String areaLabel,
  }) async {
    if (!_canSend || count == 0) return;
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

  // ── Bookmark / interested update ────────────────────────────────────────────

  /// Called when the user bookmarks an event.
  Future<void> notifyBookmarked(String eventTitle) async {
    if (!_canSend) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: '🔖 Event Saved',
      body: '"$eventTitle" has been added to your bookmarks. We\'ll keep you posted on updates!',
    );
  }

  /// Called when the user marks interested in an event.
  Future<void> notifyInterested(String eventTitle) async {
    if (!_canSend) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: '⭐ You\'re Interested',
      body: 'You\'ll get updates about "$eventTitle" as the date approaches.',
    );
  }

  // ── Friend request ──────────────────────────────────────────────────────────

  /// Called when the current user sends a friend request (confirms action) or
  /// when a simulated inbound friend request is received.
  Future<void> notifyFriendRequest({
    required String fromName,
    bool isSentByMe = false,
  }) async {
    if (!_canSend) return;
    if (isSentByMe) {
      await _send(
        id: _nextNotifId(),
        channelKey: _kChannelSocial,
        title: '👋 Friend Request Sent',
        body: 'Your friend request to $fromName has been sent!',
      );
    } else {
      await _send(
        id: _nextNotifId(),
        channelKey: _kChannelSocial,
        title: '🤝 New Friend Request',
        body: '$fromName wants to connect with you on SpotVibe.',
      );
    }
  }

  // ── A. Event Reminders ──────────────────────────────────────────────────────

  /// "Your event starts in 1 hour" — send 60 minutes before event start.
  Future<void> notifyEventStartingSoon({
    required String eventTitle,
    required String locationLabel,
  }) async {
    if (!_canSend) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: '⏰ Your event starts in 1 hour',
      body: '$eventTitle · $locationLabel',
    );
  }

  /// "Your event is tomorrow at [time]" — send ~24 hours before event start.
  Future<void> notifyEventTomorrow({
    required String eventTitle,
    required String timeLabel,
    required String locationLabel,
  }) async {
    if (!_canSend) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: 'Your event is tomorrow at $timeLabel',
      body: '$eventTitle · $locationLabel',
    );
  }

  /// "Don't forget: [Event] tonight at [time]" — send day-of at 3 PM.
  Future<void> notifyEventTonight({
    required String eventTitle,
    required String timeLabel,
    required String locationLabel,
  }) async {
    if (!_canSend) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelUpdates,
      title: "⏰ Don't forget: $eventTitle tonight at $timeLabel",
      body: locationLabel,
    );
  }

  // ── B. New Events Digest ────────────────────────────────────────────────────

  /// "5 new music events near you this weekend" — category-aware alert.
  Future<void> notifyNewEventsNearby({
    required int count,
    required String category,
    required String areaLabel,
    required String timePeriod,
  }) async {
    if (!_canSend || count == 0) return;
    final plural = count == 1 ? '1 new $category event' : '$count new $category events';
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelEvents,
      title: '🎉 $plural near you $timePeriod',
      body: '$areaLabel · Tap to explore',
    );
  }

  /// Weekly Friday morning digest.
  Future<void> notifyWeeklyDigest({
    required int eventCount,
    required List<String> categories,
    required String areaLabel,
  }) async {
    if (!_canSend || eventCount == 0) return;
    final catLine = categories.take(3).join(', ');
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelEvents,
      title: '📅 Weekly digest: $eventCount events you might like',
      body: '$catLine · This week in $areaLabel',
    );
  }

  // ── C. Social Notifications ─────────────────────────────────────────────────

  /// "3 new comments on your event"
  Future<void> notifyNewComments({
    required String eventTitle,
    required int commentCount,
  }) async {
    if (!_canSend || commentCount == 0) return;
    final label = commentCount == 1 ? '1 new comment' : '$commentCount new comments';
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelSocial,
      title: '💬 $label on your event',
      body: eventTitle,
    );
  }

  /// "Your friend is going to [Event Name]"
  Future<void> notifyFriendRsvp({
    required String friendName,
    required String eventTitle,
  }) async {
    if (!_canSend) return;
    await _send(
      id: _nextNotifId(),
      channelKey: _kChannelSocial,
      title: '🙌 $friendName is going to $eventTitle',
      body: 'Tap to see who else is going',
    );
  }

  // ── Internal send helper ────────────────────────────────────────────────────

  Future<void> _send({
    required int id,
    required String channelKey,
    required String title,
    required String body,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
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
    }
  }
}
