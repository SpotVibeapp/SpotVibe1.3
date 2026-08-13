import 'package:uuid/uuid.dart';
import '../models/user_event.dart';
export '../models/user_event.dart' show RecurringType;

class UserEventRepository {
  final _uuid = const Uuid();
  final List<UserCreatedEvent> _events = _seedDemoEvents();

  /// Pre-seeded Premium events for the demo user so the dashboard
  /// has data on first login without requiring any event creation.
  static String get _seedWeekKey {
    final now = DateTime.now().toUtc();
    final thursday = now.add(Duration(days: 4 - now.weekday));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    final week = 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  static List<UserCreatedEvent> _seedDemoEvents() {
    final now = DateTime.now();
    return [
      UserCreatedEvent(
        id: 'demo_pro_1',
        creatorId: 'user_1',
        title: 'Trivia Night',
        description: 'Weekly pub trivia with prizes for the top three teams. Categories range from pop culture to science.',
        dateTime: now.add(const Duration(days: 3)),
        location: 'The Rusty Anchor Bar',
        address: '88 Harbor St',
        city: 'Austin',
        state: 'TX',
        zipCode: '78701',
        category: 'Social',
        organizerName: 'Alex Johnson',
        isPremiumListing: true,
        featuredWeekKey: _seedWeekKey,
        isCreatorPro: true,
        recurringType: RecurringType.weekly,
        contactWebsite: 'https://trivianights.example.com',
        contactPhone: '+1 (512) 555-0199',
        analyticsSearchImpressions: 842,
        analyticsViews: 145,
        analyticsSaves: 38,
        analyticsClicks: 32,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      UserCreatedEvent(
        id: 'demo_pro_2',
        creatorId: 'user_1',
        title: 'Indie Film Screening',
        description: 'Monthly independent film night featuring local filmmakers. Q&A with the director after each screening.',
        dateTime: now.add(const Duration(days: 12)),
        location: 'The Majestic Cinema',
        address: '210 Congress Ave',
        city: 'Austin',
        state: 'TX',
        zipCode: '78701',
        category: 'Arts',
        organizerName: 'Alex Johnson',
        isPremiumListing: false,
        isCreatorPro: true,
        recurringType: RecurringType.monthly,
        contactWebsite: 'https://indiefilm.example.com',
        analyticsSearchImpressions: 413,
        analyticsViews: 67,
        analyticsSaves: 21,
        analyticsClicks: 14,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];
  }

  Future<List<UserCreatedEvent>> getEventsForUser(String creatorId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _events.where((e) => e.creatorId == creatorId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<UserCreatedEvent>> getAllUserEvents() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_events)
      ..toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<UserCreatedEvent?> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

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
    bool isPremiumListing = false,
    bool isCreatorPro = false,
    RecurringType recurringType = RecurringType.none,
    String? contactPhone,
    String? contactWebsite,
    String? contactSocial,
    String? brandColor,
    String? brandLogoUrl,
    String? featuredWeekKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final event = UserCreatedEvent(
      id: _uuid.v4(),
      creatorId: creatorId,
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
      organizerName: organizerName,
      mapLink: mapLink,
      chatLink: chatLink,
      isPremiumListing: isPremiumListing,
      createdAt: DateTime.now(),
      isCreatorPro: isCreatorPro,
      recurringType: recurringType,
      contactPhone: contactPhone,
      contactWebsite: contactWebsite,
      contactSocial: contactSocial,
      brandColor: brandColor,
      brandLogoUrl: brandLogoUrl,
      featuredWeekKey: featuredWeekKey,
    );
    _events.add(event);
    return event;
  }

  Future<UserCreatedEvent> updateEvent(UserCreatedEvent updated) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _events.indexWhere((e) => e.id == updated.id);
    if (index == -1) throw StateError('Event not found: ${updated.id}');
    _events[index] = updated;
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _events.removeWhere((e) => e.id == id);
  }

  Future<void> incrementInterested(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    _events[index] = _events[index].copyWith(interestedCount: _events[index].interestedCount + 1);
  }

  Future<void> incrementAnalytics(
    String eventId, {
    int impressions = 0,
    int views = 0,
    int saves = 0,
    int clicks = 0,
  }) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final event = _events[index];
    _events[index] = event.copyWith(
      analyticsSearchImpressions: event.analyticsSearchImpressions + impressions,
      analyticsViews: event.analyticsViews + views,
      analyticsSaves: event.analyticsSaves + saves,
      analyticsClicks: event.analyticsClicks + clicks,
    );
  }
}
