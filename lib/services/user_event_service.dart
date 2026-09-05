import '../data/event_time.dart';
import '../data/media_urls.dart';
import '../data/pricing.dart';
import '../models/user_event.dart';
import '../repositories/user_event_repository.dart';

export '../data/pricing.dart'
    show kPremiumMonthlyPrice, kPremiumMonthlyLabel, kFreePrice;
export '../models/user_event.dart' show RecurringType;

/// Legacy aliases — launch pricing is Free vs $12.99/month Premium.
const double kBasicEventCreationPrice = kFreePrice;
const double kProMonthlyPrice = kPremiumMonthlyPrice;
const double kCreatorProMonthlyPrice = kPremiumMonthlyPrice;

class UserEventService {
  final UserEventRepository _repository;

  UserEventService({required UserEventRepository repository}) : _repository = repository;

  Future<List<UserCreatedEvent>> getMyEvents(String creatorId) =>
      _repository.getEventsForUser(creatorId);

  Future<List<UserCreatedEvent>> getAllUserEvents() => _repository.getAllUserEvents();

  Future<UserCreatedEvent?> getEventById(String id) => _repository.getEventById(id);

  Future<UserCreatedEvent> createEvent({
    String? id,
    required String creatorId,
    required String title,
    required String description,
    required DateTime dateTime,
    required DateTime endDateTime,
    required String location,
    required String address,
    String city = '',
    String state = '',
    String zipCode = '',
    double? cost,
    String imageUrl = '',
    List<String> imageUrls = const [],
    String? videoUrl,
    List<String> videoUrls = const [],
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
    if (!hasValidEventWindow(dateTime, endDateTime)) {
      throw ArgumentError('End date and time must be after the start.');
    }
    if (!isCreatorPro && recurringType != RecurringType.none) {
      throw ArgumentError('Recurring events require SpotVibe Premium.');
    }

    final normalizedImages = normalizeMediaUrls([imageUrl, ...imageUrls]);
    final normalizedVideos = normalizeMediaUrls([videoUrl, ...videoUrls]);
    if (normalizedImages.length > kMaxEventPhotos) {
      throw ArgumentError('Events can include up to $kMaxEventPhotos photos.');
    }
    if (normalizedVideos.length > kMaxEventVideos) {
      throw ArgumentError('Events can include up to $kMaxEventVideos videos.');
    }

    var listing = isPremiumListing && isCreatorPro;
    String? featuredWeekKey;
    if (isCreatorPro) {
      final week = isoWeekKey(DateTime.now());
      final mine = await _repository.getEventsForUser(creatorId);
      final alreadyFeatured =
          mine.any((e) => e.featuredWeekKey == week);
      if (!alreadyFeatured) {
        listing = true;
        featuredWeekKey = week;
      }
    }

    return _repository.createEvent(
      id: id,
      creatorId: creatorId,
      title: title.trim(),
      description: description.trim(),
      dateTime: dateTime,
      endDateTime: endDateTime,
      location: location.trim(),
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      zipCode: zipCode.trim(),
      cost: cost,
      imageUrl: normalizedImages.isEmpty ? '' : normalizedImages.first,
      imageUrls: normalizedImages,
      videoUrl: normalizedVideos.isEmpty ? null : normalizedVideos.first,
      videoUrls: normalizedVideos,
      category: category,
      organizerName: organizerName,
      mapLink: mapLink?.trim().isNotEmpty == true ? mapLink!.trim() : null,
      chatLink: chatLink?.trim().isNotEmpty == true ? chatLink!.trim() : null,
      isPremiumListing: listing,
      isCreatorPro: isCreatorPro,
      recurringType: recurringType,
      contactPhone: contactPhone?.trim().isNotEmpty == true ? contactPhone!.trim() : null,
      contactWebsite: contactWebsite?.trim().isNotEmpty == true ? contactWebsite!.trim() : null,
      contactSocial: contactSocial?.trim().isNotEmpty == true ? contactSocial!.trim() : null,
      brandColor: brandColor?.trim().isNotEmpty == true ? brandColor!.trim() : null,
      brandLogoUrl: brandLogoUrl?.trim().isNotEmpty == true ? brandLogoUrl!.trim() : null,
      featuredWeekKey: featuredWeekKey,
    );
  }

  Future<UserCreatedEvent> updateEvent(UserCreatedEvent event) async {
    if (event.title.trim().isEmpty) throw ArgumentError('Event title is required.');
    if (!hasValidEventWindow(event.dateTime, event.endDateTime)) {
      throw ArgumentError('End date and time must be after the start.');
    }
    if (normalizeMediaUrls([event.imageUrl, ...event.imageUrls]).length >
        kMaxEventPhotos) {
      throw ArgumentError('Events can include up to $kMaxEventPhotos photos.');
    }
    if (normalizeMediaUrls([event.videoUrl, ...event.videoUrls]).length >
        kMaxEventVideos) {
      throw ArgumentError('Events can include up to $kMaxEventVideos videos.');
    }
    return _repository.updateEvent(event);
  }

  /// Applies a creator's new public organizer name to their existing event
  /// mirrors. This never changes ownership or a venue claim.
  Future<int> updateOrganizerNameForCreator(
    String creatorId,
    String organizerName,
  ) {
    final name = organizerName.trim();
    if (name.isEmpty) throw ArgumentError('Organizer name is required.');
    return _repository.updateOrganizerNameForCreator(creatorId, name);
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
