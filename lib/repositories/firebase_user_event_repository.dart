import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../data/event_codec.dart';
import '../models/user_event.dart';
import '../models/event_social_link.dart';
import 'user_event_repository.dart';

/// Fields a client must never write on an event doc: the paid weekly
/// feature (set by the `featureEvent` Cloud Function) and the public
/// counters (only ever bumped atomically, see [incrementAnalytics] and
/// FirebaseEventRepository's save transaction). firestore.rules enforces it.
const List<String> kServerManagedEventFields = ['featuredWeekKey', 'featuredAt'];
const List<String> kEventCounterFields = [
  'analyticsSearchImpressions',
  'analyticsViews',
  'analyticsSaves',
  'analyticsClicks',
  'bookmarkedCount',
  'interestedCount',
];

/// The creator-writable part of an event payload. New docs keep their zeroed
/// counters (rules require them to start at 0); updates drop the counters so
/// a stale local copy can never overwrite live numbers.
@visibleForTesting
Map<String, dynamic> clientEventPayload(
  Map<String, dynamic> payload, {
  required bool isCreate,
}) {
  final out = Map<String, dynamic>.of(payload);
  for (final key in kServerManagedEventFields) {
    out.remove(key);
  }
  if (!isCreate) {
    for (final key in kEventCounterFields) {
      out.remove(key);
    }
  }
  return out;
}

/// Persists user-created events to `user_events/{id}` and mirrors a feed
/// document into `events/{id}` so they show up next to curated listings.
class FirebaseUserEventRepository extends UserEventRepository {
  FirebaseUserEventRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functionsOverride = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  final _uuid = const Uuid();
  bool _useFallback = false;

  CollectionReference<Map<String, dynamic>> get _userEvents =>
      _db.collection('user_events');

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  Future<T> _guard<T>(Future<T> Function() action, Future<T> Function() orElse) async {
    if (_useFallback) return orElse();
    try {
      return await action();
    } catch (e) {
      debugPrint('Firestore user events unavailable ($e) — using in-memory store.');
      _useFallback = true;
      return orElse();
    }
  }

  @override
  Future<List<UserCreatedEvent>> getEventsForUser(String creatorId) {
    return _guard(() async {
      final snap = await _userEvents
          .where('creatorId', isEqualTo: creatorId)
          .limit(100)
          .get();
      final list = snap.docs
          .map((d) => userEventFromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }, () => super.getEventsForUser(creatorId));
  }

  @override
  Future<List<UserCreatedEvent>> getAllUserEvents() {
    return _guard(() async {
      final snap = await _userEvents.limit(200).get();
      final list = snap.docs
          .map((d) => userEventFromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return list;
    }, () => super.getAllUserEvents());
  }

  @override
  Future<UserCreatedEvent?> getEventById(String id) {
    return _guard(() async {
      final doc = await _userEvents.doc(id).get();
      if (!doc.exists || doc.data() == null) return super.getEventById(id);
      return userEventFromMap(doc.id, doc.data()!);
    }, () => super.getEventById(id));
  }

  @override
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
    bool isPremiumListing = false,
    bool isCreatorPro = false,
    RecurringType recurringType = RecurringType.none,
    String? contactPhone,
    String? contactWebsite,
    String? contactSocial,
    EventSocialLinks socialLinks = const EventSocialLinks.empty(),
    String? brandColor,
    String? brandLogoUrl,
    String? featuredWeekKey,
  }) {
    return _guard(() async {
      final event = UserCreatedEvent(
        id: id ?? _uuid.v4(),
        creatorId: creatorId,
        title: title,
        description: description,
        dateTime: dateTime,
        endDateTime: endDateTime,
        location: location,
        address: address,
        city: city.isEmpty ? 'El Paso' : city,
        state: state.isEmpty ? 'TX' : state,
        zipCode: zipCode,
        cost: cost,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        videoUrls: videoUrls,
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
        socialLinks: socialLinks,
        brandColor: brandColor,
        brandLogoUrl: brandLogoUrl,
        featuredWeekKey: featuredWeekKey,
      );
      final payload = clientEventPayload({
        ...userEventToMap(event),
        'dateTime': Timestamp.fromDate(event.dateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),
        'createdAt': FieldValue.serverTimestamp(),
      }, isCreate: true);
      final batch = _db.batch();
      batch.set(_userEvents.doc(event.id), payload);
      batch.set(_events.doc(event.id), payload);
      await batch.commit();
      return event;
    }, () => super.createEvent(
          id: id,
          creatorId: creatorId,
          title: title,
          description: description,
          dateTime: dateTime,
          endDateTime: endDateTime,
          location: location,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          cost: cost,
          imageUrl: imageUrl,
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          videoUrls: videoUrls,
          category: category,
          organizerName: organizerName,
          mapLink: mapLink,
          chatLink: chatLink,
          isPremiumListing: isPremiumListing,
          isCreatorPro: isCreatorPro,
          recurringType: recurringType,
          contactPhone: contactPhone,
          contactWebsite: contactWebsite,
          contactSocial: contactSocial,
          socialLinks: socialLinks,
          brandColor: brandColor,
          brandLogoUrl: brandLogoUrl,
          featuredWeekKey: featuredWeekKey,
        ));
  }

  @override
  Future<UserCreatedEvent> updateEvent(UserCreatedEvent updated) {
    return _guard(() async {
      final payload = clientEventPayload({
        ...userEventToMap(updated),
        'dateTime': Timestamp.fromDate(updated.dateTime),
        if (updated.endDateTime != null)
          'endDateTime': Timestamp.fromDate(updated.endDateTime!),
        'updatedAt': FieldValue.serverTimestamp(),
      }, isCreate: false);
      final batch = _db.batch();
      batch.set(_userEvents.doc(updated.id), payload, SetOptions(merge: true));
      batch.set(_events.doc(updated.id), payload, SetOptions(merge: true));
      await batch.commit();
      return updated;
    }, () => super.updateEvent(updated));
  }

  @override
  Future<int> updateOrganizerNameForCreator(
    String creatorId,
    String organizerName,
  ) {
    final name = organizerName.trim();
    if (name.isEmpty) return Future.value(0);

    return _guard(() async {
      final snapshot = await _userEvents
          .where('creatorId', isEqualTo: creatorId)
          .get();
      final changed = snapshot.docs
          .where((doc) => doc.data()['organizerName'] != name)
          .toList();

      // Each event has two mirrored documents. Keep batches below Firestore's
      // 500-operation limit even for prolific organizers.
      for (var offset = 0; offset < changed.length; offset += 200) {
        final batch = _db.batch();
        for (final doc in changed.skip(offset).take(200)) {
          final patch = <String, dynamic>{
            'organizerName': name,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          batch.update(doc.reference, patch);
          batch.set(_events.doc(doc.id), patch, SetOptions(merge: true));
        }
        await batch.commit();
      }
      return changed.length;
    }, () => super.updateOrganizerNameForCreator(creatorId, name));
  }

  @override
  Future<void> deleteEvent(String id) {
    return _guard(() async {
      final batch = _db.batch();
      batch.delete(_userEvents.doc(id));
      batch.delete(_events.doc(id));
      await batch.commit();
    }, () => super.deleteEvent(id));
  }

  @override
  Future<String?> requestWeeklyFeature(String eventId, String creatorId) async {
    if (_useFallback) return super.requestWeeklyFeature(eventId, creatorId);
    try {
      final callable =
          _functions.httpsCallableFromUrl(AppConfig.featureEventFunctionUrl);
      final result =
          await callable.call<Map<String, dynamic>>({'eventId': eventId});
      final data = Map<String, dynamic>.from(result.data);
      if (data['featured'] != true) return null;
      final week = data['featuredWeekKey'];
      return week is String && week.isNotEmpty ? week : null;
    } catch (e) {
      debugPrint('Weekly feature request failed ($e).');
      return null;
    }
  }

  /// Bumps Premium analytics counters. Each counter is its own atomic
  /// `FieldValue.increment(1)` write on each mirror: firestore.rules only
  /// accept exactly +1 on exactly one analytics field per write.
  @override
  Future<void> incrementAnalytics(
    String eventId, {
    int impressions = 0,
    int views = 0,
    int saves = 0,
    int clicks = 0,
  }) async {
    if (_useFallback) {
      await super.incrementAnalytics(
        eventId,
        impressions: impressions,
        views: views,
        saves: saves,
        clicks: clicks,
      );
      return;
    }
    final fields = analyticsIncrementFields(
      impressions: impressions,
      views: views,
      saves: saves,
      clicks: clicks,
    );
    for (final field in fields) {
      for (final ref in [_userEvents.doc(eventId), _events.doc(eventId)]) {
        try {
          // update(), not set(merge): never create a doc for a listing that
          // has no mirror (e.g. aggregator rows have no user_events doc).
          await ref.update({field: FieldValue.increment(1)});
        } catch (e) {
          debugPrint('Analytics increment skipped for ${ref.path} ($e)');
        }
      }
    }
  }
}

/// One entry per +1 to apply. Counts above 1 are clamped to a single bump:
/// rules accept exactly +1 per write and the app never records more than
/// one event per call.
@visibleForTesting
List<String> analyticsIncrementFields({
  int impressions = 0,
  int views = 0,
  int saves = 0,
  int clicks = 0,
}) {
  return [
    if (impressions > 0) 'analyticsSearchImpressions',
    if (views > 0) 'analyticsViews',
    if (saves > 0) 'analyticsSaves',
    if (clicks > 0) 'analyticsClicks',
  ];
}
