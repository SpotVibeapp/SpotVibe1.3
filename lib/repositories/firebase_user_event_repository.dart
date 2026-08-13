import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/event_codec.dart';
import '../models/user_event.dart';
import 'user_event_repository.dart';

/// Persists user-created events to `user_events/{id}` and mirrors a feed
/// document into `events/{id}` so they show up next to curated listings.
class FirebaseUserEventRepository extends UserEventRepository {
  FirebaseUserEventRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
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
  }) {
    return _guard(() async {
      final event = UserCreatedEvent(
        id: _uuid.v4(),
        creatorId: creatorId,
        title: title,
        description: description,
        dateTime: dateTime,
        location: location,
        address: address,
        city: city.isEmpty ? 'El Paso' : city,
        state: state.isEmpty ? 'TX' : state,
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
      final payload = {
        ...userEventToMap(event),
        'dateTime': Timestamp.fromDate(event.dateTime),
        'createdAt': FieldValue.serverTimestamp(),
      };
      final batch = _db.batch();
      batch.set(_userEvents.doc(event.id), payload);
      batch.set(_events.doc(event.id), payload);
      await batch.commit();
      return event;
    }, () => super.createEvent(
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
          isCreatorPro: isCreatorPro,
          recurringType: recurringType,
          contactPhone: contactPhone,
          contactWebsite: contactWebsite,
          contactSocial: contactSocial,
          brandColor: brandColor,
          brandLogoUrl: brandLogoUrl,
          featuredWeekKey: featuredWeekKey,
        ));
  }

  @override
  Future<UserCreatedEvent> updateEvent(UserCreatedEvent updated) {
    return _guard(() async {
      final payload = {
        ...userEventToMap(updated),
        'dateTime': Timestamp.fromDate(updated.dateTime),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = _db.batch();
      batch.set(_userEvents.doc(updated.id), payload, SetOptions(merge: true));
      batch.set(_events.doc(updated.id), payload, SetOptions(merge: true));
      await batch.commit();
      return updated;
    }, () => super.updateEvent(updated));
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
  Future<void> incrementInterested(String eventId) {
    return _guard(() async {
      await _userEvents.doc(eventId).update({
        'interestedCount': FieldValue.increment(1),
      });
      await _events.doc(eventId).set({
        'interestedCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }, () => super.incrementInterested(eventId));
  }

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
    try {
      final patch = <String, dynamic>{};
      if (impressions != 0) {
        patch['analyticsSearchImpressions'] = FieldValue.increment(impressions);
      }
      if (views != 0) patch['analyticsViews'] = FieldValue.increment(views);
      if (saves != 0) patch['analyticsSaves'] = FieldValue.increment(saves);
      if (clicks != 0) patch['analyticsClicks'] = FieldValue.increment(clicks);
      if (patch.isEmpty) return;
      await _userEvents.doc(eventId).set(patch, SetOptions(merge: true));
      await _events.doc(eventId).set(patch, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Analytics increment skipped ($e)');
    }
  }
}
