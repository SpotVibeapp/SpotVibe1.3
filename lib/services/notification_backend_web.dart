import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'notification_backend_api.dart';

NotificationBackend createNotificationBackend() => _WebNotificationBackend();

class _WebNotificationBackend implements NotificationBackend {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> isAllowed() async {
    try {
      return web.Notification.permission == 'granted';
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] permission read failed: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final result = await web.Notification.requestPermission().toDart;
      return result.toDart == 'granted';
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] permission request failed: $e');
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
      if (web.Notification.permission != 'granted') return false;
      web.Notification(title, web.NotificationOptions(body: body));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] show failed: $e');
      return false;
    }
  }
}
