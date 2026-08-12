import 'package:flutter/foundation.dart';
import '../models/user_event.dart';
import '../services/user_event_service.dart';

export '../models/user_event.dart' show RecurringType;

enum CreateEventStatus { idle, submitting, success, error }

class CreateEventProvider extends ChangeNotifier {
  final UserEventService _service;
  final String _creatorId;
  final String _creatorName;

  CreateEventStatus _status = CreateEventStatus.idle;
  String? _errorMessage;
  UserCreatedEvent? _createdEvent;

  // Editing an existing event?
  UserCreatedEvent? _editingEvent;

  CreateEventProvider({
    required UserEventService service,
    required String creatorId,
    required String creatorName,
  })  : _service = service,
        _creatorId = creatorId,
        _creatorName = creatorName;

  CreateEventStatus get status => _status;
  bool get isSubmitting => _status == CreateEventStatus.submitting;
  String? get errorMessage => _errorMessage;
  UserCreatedEvent? get createdEvent => _createdEvent;
  bool get isEditing => _editingEvent != null;
  UserCreatedEvent? get editingEvent => _editingEvent;

  void loadForEditing(UserCreatedEvent event) {
    _editingEvent = event;
    notifyListeners();
  }

  Future<UserCreatedEvent?> submit({
    required String title,
    required String description,
    required DateTime dateTime,
    required String location,
    required String address,
    String city = '',
    String state = '',
    String zipCode = '',
    double? cost,
    String imageUrl = '',
    String? videoUrl,
    required String category,
    String? mapLink,
    String? chatLink,
    required bool isPremiumListing,
    bool isCreatorPro = false,
    RecurringType recurringType = RecurringType.none,
    String? contactPhone,
    String? contactWebsite,
    String? contactSocial,
    String? brandColor,
    String? brandLogoUrl,
  }) async {
    _status = CreateEventStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCreatedEvent result;

      if (_editingEvent != null) {
        final updated = _editingEvent!.copyWith(
          title: title,
          description: description,
          dateTime: dateTime,
          location: location,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          cost: cost,
          clearCost: cost == null,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          clearVideoUrl: videoUrl == null || videoUrl.isEmpty,
          category: category,
          mapLink: mapLink,
          clearMapLink: mapLink == null || mapLink.isEmpty,
          chatLink: chatLink,
          clearChatLink: chatLink == null || chatLink.isEmpty,
          recurringType: recurringType,
          contactPhone: contactPhone,
          clearContactPhone: contactPhone == null || contactPhone.isEmpty,
          contactWebsite: contactWebsite,
          clearContactWebsite: contactWebsite == null || contactWebsite.isEmpty,
          contactSocial: contactSocial,
          clearContactSocial: contactSocial == null || contactSocial.isEmpty,
          brandColor: brandColor,
          clearBrandColor: brandColor == null || brandColor.isEmpty,
          brandLogoUrl: brandLogoUrl,
          clearBrandLogoUrl: brandLogoUrl == null || brandLogoUrl.isEmpty,
        );
        result = await _service.updateEvent(updated);
      } else {
        result = await _service.createEvent(
          creatorId: _creatorId,
          title: title,
          description: description,
          dateTime: dateTime,
          location: location,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          cost: cost,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          category: category,
          organizerName: _creatorName,
          mapLink: mapLink,
          chatLink: chatLink,
          isPremiumListing: isPremiumListing,
          isCreatorPro: isCreatorPro,
          recurringType: recurringType,
          contactPhone: contactPhone,
          contactWebsite: contactWebsite,
          contactSocial: contactSocial,
          brandColor: brandColor,
          brandLogoUrl: brandLogoUrl,
        );
      }

      _createdEvent = result;
      _status = CreateEventStatus.success;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ArgumentError: ', '');
      _status = CreateEventStatus.error;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_status == CreateEventStatus.error) {
      _status = CreateEventStatus.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
