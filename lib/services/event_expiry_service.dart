import 'dart:async';
import 'package:flutter/foundation.dart';

/// Fires a notification every minute so that route-scoped [EventProvider]s
/// and [UserEventsProvider]s can reload their lists and automatically drop
/// any event whose start-time has passed.
///
/// Register once as a global [Provider] in main.dart; every provider that
/// cares about expiry should add a listener in its constructor and remove it
/// in its own [dispose].
class EventExpiryService extends ChangeNotifier {
  static const _kInterval = Duration(minutes: 1);

  Timer? _timer;
  DateTime _lastTick = DateTime.now();

  EventExpiryService() {
    _start();
  }

  DateTime get lastTick => _lastTick;

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_kInterval, (_) {
      _lastTick = DateTime.now();
      notifyListeners(); // wake every subscribed provider
    });
  }

  /// Force an immediate expiry sweep right now (used by tests / debug).
  void forceExpiry() {
    _lastTick = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
