import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' show Color;

import 'notification_backend_api.dart';

const _kChannelEvents = 'spotvibe_events';
const _kChannelUpdates = 'spotvibe_updates';
const _kChannelSocial = 'spotvibe_social';

NotificationBackend createNotificationBackend() => _IoNotificationBackend();

class _IoNotificationBackend implements NotificationBackend {
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    try {
      _initialized = await AwesomeNotifications().initialize(
        null,
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
            channelDescription:
                'Friend requests and activity from people you follow',
            defaultColor: const Color(0xFF6C5CE7),
            ledColor: const Color(0xFF6C5CE7),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
        ],
        debug: false,
      );
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  @override
  Future<bool> isAllowed() async {
    if (!_initialized) return false;
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> show({
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
      return false;
    }
  }
}
