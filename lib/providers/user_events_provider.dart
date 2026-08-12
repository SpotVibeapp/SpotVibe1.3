import 'package:flutter/foundation.dart';
import '../models/user_event.dart';
import '../services/user_event_service.dart';

class UserEventsProvider extends ChangeNotifier {
  final UserEventService _service;
  final String _creatorId;

  List<UserCreatedEvent> _events = [];
  bool _isLoading = false;
  String? _error;

  UserEventsProvider({required UserEventService service, required String creatorId})
      : _service = service,
        _creatorId = creatorId;

  List<UserCreatedEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _events = await _service.getMyEvents(_creatorId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEvent(UserCreatedEvent event) async {
    try {
      _events = [event, ..._events];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEvent(UserCreatedEvent updated) async {
    try {
      final saved = await _service.updateEvent(updated);
      final index = _events.indexWhere((e) => e.id == saved.id);
      if (index != -1) {
        _events[index] = saved;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _service.deleteEvent(eventId, _creatorId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
