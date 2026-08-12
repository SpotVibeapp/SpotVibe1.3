import '../models/user_event.dart';
import '../repositories/user_event_repository.dart';

export '../models/user_event.dart' show RecurringType;

/// Pricing for event creation.
/// Non-Creator-Pro users: $4.99 one-time charge per event.
/// Creator Pro subscribers ($9.99/month): unlimited recurring events + premium features.
/// SpotVibe Pro subscribers ($24.99/month): unlimited event creation at no extra cost.
const double kBasicEventCreationPrice = 4.99;
const double kProMonthlyPrice = 24.99;

/// Monthly price for the Creator Pro tier (event hosting features).
const double kCreatorProMonthlyPrice = 9.99;

class UserEventService {
  final UserEventRepository _repository;

  UserEventService({required UserEventRepository repository}) : _repository = repository;

  Future<List<UserCreatedEvent>> getMyEvents(String creatorId) =>
      _repository.getEventsForUser(creatorId);

  Future<List<UserCreatedEvent>> getAllUserEvents() => _repository.getAllUserEvents();

  Future<UserCreatedEvent?> getEventById(String id) => _repository.getEventById(id);

  Future<UserCreatedEvent> createEvent({
    required String creatorId,
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
    required String organizerName,
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
    if (title.trim().isEmpty) throw ArgumentError('Event title is required.');
    if (description.trim().isEmpty) throw ArgumentError('Description is required.');
    if (location.trim().isEmpty) throw ArgumentError('Location is required.');

    return _repository.createEvent(
      creatorId: creatorId,
      title: title.trim(),
      description: description.trim(),
      dateTime: dateTime,
      location: location.trim(),
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      zipCode: zipCode.trim(),
      cost: cost,
      imageUrl: imageUrl.trim(),
      videoUrl: (videoUrl?.trim().isNotEmpty == true) ? videoUrl!.trim() : null,
      category: category,
      organizerName: organizerName,
      mapLink: mapLink?.trim().isNotEmpty == true ? mapLink!.trim() : null,
      chatLink: chatLink?.trim().isNotEmpty == true ? chatLink!.trim() : null,
      isPremiumListing: isPremiumListing,
      isCreatorPro: isCreatorPro,
      recurringType: recurringType,
      contactPhone: contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
      contactWebsite: contactWebsite?.trim().isNotEmpty == true ? contactWebsite!.trim() : null,
      contactSocial: contactSocial?.trim().isNotEmpty == true ? contactSocial!.trim() : null,
      brandColor: brandColor?.trim().isNotEmpty == true ? brandColor!.trim() : null,
      brandLogoUrl: brandLogoUrl?.trim().isNotEmpty == true ? brandLogoUrl!.trim() : null,
    );
  }

  Future<UserCreatedEvent> updateEvent(UserCreatedEvent event) async {
    if (event.title.trim().isEmpty) throw ArgumentError('Event title is required.');
    return _repository.updateEvent(event);
  }

  Future<void> deleteEvent(String eventId, String requestingUserId) async {
    final event = await _repository.getEventById(eventId);
    if (event == null) return;
    if (event.creatorId != requestingUserId) {
      throw StateError('Only the creator can delete this event.');
    }
    await _repository.deleteEvent(eventId);
  }

  bool isCreator(UserCreatedEvent event, String userId) => event.creatorId == userId;
}
