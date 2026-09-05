import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/event_codec.dart';
import 'package:spotvibe_app/data/media_urls.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/user_event.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';
import 'package:spotvibe_app/services/user_event_service.dart';

void main() {
  test('Free creators get a useful basic listing while Premium gets full media',
      () {
    final free = eventMediaAllowance(isPremium: false, isAdmin: false);
    final premium = eventMediaAllowance(isPremium: true, isAdmin: false);
    final admin = eventMediaAllowance(isPremium: false, isAdmin: true);

    expect(free.maxPhotos, 1);
    expect(free.maxVideos, 1);
    expect(free.hasFullGallery, isFalse);
    expect(premium.maxPhotos, 5);
    expect(premium.maxVideos, 3);
    expect(admin.hasFullGallery, isTrue);
  });

  test('normalizes media URLs without duplicate cover media', () {
    expect(
      normalizeMediaUrls([
        ' https://example.test/cover.jpg ',
        'https://example.test/cover.jpg',
        '',
        null,
        'https://example.test/photo-2.jpg',
      ]),
      [
        'https://example.test/cover.jpg',
        'https://example.test/photo-2.jpg',
      ],
    );
    expect(mediaUrlsFromValue('not-a-list'), isEmpty);
  });

  test('public event media galleries round-trip through stored event data', () {
    const photos = [
      'https://example.test/cover.jpg',
      'https://example.test/photo-2.jpg',
    ];
    const videos = [
      'https://example.test/video-1.mp4',
      'https://example.test/video-2.mp4',
    ];
    final event = Event(
      id: 'event-1',
      title: 'Pool Night',
      description: 'A real event.',
      dateTime: DateTime(2026, 9, 12, 20),
      endDateTime: DateTime(2026, 9, 12, 23),
      location: 'The Pool Hall',
      address: '123 Main St',
      imageUrl: photos.first,
      imageUrls: photos,
      videoUrl: videos.first,
      videoUrls: videos,
      category: 'Social',
      organizerName: 'SpotVibe',
      organizerAvatarUrl: '',
    );

    final restored = eventFromMap(event.id, eventToMap(event, kind: 'user'));

    expect(restored.allImageUrls, photos);
    expect(restored.allVideoUrls, videos);
    expect(restored.imageUrl, photos.first);
    expect(restored.videoUrl, videos.first);
    expect(restored.endDateTime, event.endDateTime);
  });

  test('creator events keep all media while mirroring first media for legacy readers',
      () {
    final event = UserCreatedEvent(
      id: 'event-2',
      creatorId: 'creator-1',
      title: 'Pool Night',
      description: 'A real event.',
      dateTime: DateTime(2026, 9, 12, 20),
      endDateTime: DateTime(2026, 9, 12, 23),
      location: 'The Pool Hall',
      address: '123 Main St',
      imageUrl: 'https://example.test/cover.jpg',
      imageUrls: const [
        'https://example.test/cover.jpg',
        'https://example.test/photo-2.jpg',
      ],
      videoUrl: 'https://example.test/video-1.mp4',
      videoUrls: const [
        'https://example.test/video-1.mp4',
        'https://example.test/video-2.mp4',
      ],
      category: 'Social',
      organizerName: 'SpotVibe',
      createdAt: DateTime(2026, 9, 1),
    );

    final stored = userEventToMap(event);
    final restored = userEventFromMap(event.id, stored);

    expect(restored.allImageUrls, event.allImageUrls);
    expect(restored.allVideoUrls, event.allVideoUrls);
    expect(stored['imageUrl'], event.imageUrl);
    expect(stored['videoUrl'], event.videoUrl);
    expect(restored.endDateTime, event.endDateTime);
  });

  test('event service requires an end after the start time', () async {
    final service = UserEventService(repository: UserEventRepository());
    final start = DateTime.now().add(const Duration(days: 3));

    await expectLater(
      service.createEvent(
        creatorId: 'creator-1',
        title: 'Invalid timing',
        description: 'A listing with an invalid event window.',
        dateTime: start,
        endDateTime: start,
        location: 'The Pool Hall',
        address: '123 Main St',
        category: 'Social',
        organizerName: 'SpotVibe',
        isPremiumListing: false,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('event service enforces five-photo and three-video limits', () async {
    final service = UserEventService(repository: UserEventRepository());

    await expectLater(
      service.createEvent(
        creatorId: 'creator-1',
        title: 'Five photos',
        description: 'A real event with a complete gallery.',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        endDateTime: DateTime.now().add(const Duration(days: 3, hours: 3)),
        location: 'The Pool Hall',
        address: '123 Main St',
        imageUrl: 'https://example.test/photo-1.jpg',
        imageUrls: List.generate(
          5,
          (index) => 'https://example.test/photo-${index + 1}.jpg',
        ),
        videoUrls: List.generate(
          3,
          (index) => 'https://example.test/video-${index + 1}.mp4',
        ),
        category: 'Social',
        organizerName: 'SpotVibe',
        isPremiumListing: false,
      ),
      completes,
    );

    await expectLater(
      service.createEvent(
        creatorId: 'creator-1',
        title: 'Too many photos',
        description: 'A real event with too many images.',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        endDateTime: DateTime.now().add(const Duration(days: 3, hours: 3)),
        location: 'The Pool Hall',
        address: '123 Main St',
        imageUrl: 'https://example.test/cover.jpg',
        imageUrls: List.generate(
          5,
          (index) => 'https://example.test/photo-${index + 2}.jpg',
        ),
        category: 'Social',
        organizerName: 'SpotVibe',
        isPremiumListing: false,
      ),
      throwsA(isA<ArgumentError>()),
    );

    await expectLater(
      service.createEvent(
        creatorId: 'creator-1',
        title: 'Too many videos',
        description: 'A real event with too many video clips.',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        endDateTime: DateTime.now().add(const Duration(days: 3, hours: 3)),
        location: 'The Pool Hall',
        address: '123 Main St',
        videoUrls: List.generate(
          4,
          (index) => 'https://example.test/video-${index + 1}.mp4',
        ),
        category: 'Social',
        organizerName: 'SpotVibe',
        isPremiumListing: false,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
