import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/event_codec.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/event_social_link.dart';
import 'package:spotvibe_app/repositories/user_event_repository.dart';
import 'package:spotvibe_app/services/user_event_service.dart';

void main() {
  group('organizer social links', () {
    test('turns supported profile handles into official HTTPS URLs', () {
      expect(
        normalizeSocialProfileLink(SocialPlatform.instagram, '@spot.vibe'),
        'https://www.instagram.com/spot.vibe/',
      );
      expect(
        normalizeSocialProfileLink(SocialPlatform.facebook, 'spotvibe'),
        'https://www.facebook.com/spotvibe',
      );
      expect(
        normalizeSocialProfileLink(SocialPlatform.snapchat, 'spotvibe'),
        'https://www.snapchat.com/add/spotvibe',
      );
      expect(
        normalizeSocialProfileLink(SocialPlatform.tiktok, '@spotvibe'),
        'https://www.tiktok.com/@spotvibe',
      );
      expect(
        normalizeSocialProfileLink(SocialPlatform.youtube, '@spotvibe'),
        'https://www.youtube.com/@spotvibe',
      );
    });

    test('accepts official URLs but rejects a mismatched or unsafe host', () {
      expect(
        normalizeSocialProfileLink(
          SocialPlatform.instagram,
          'http://instagram.com/spotvibe',
        ),
        'https://instagram.com/spotvibe',
      );
      expect(
        normalizeSocialProfileLink(
          SocialPlatform.facebook,
          'https://www.facebook.com/spotvibe/',
        ),
        'https://www.facebook.com/spotvibe/',
      );
      expect(
        normalizeSocialProfileLink(
          SocialPlatform.instagram,
          'https://notinstagram.com/spotvibe',
        ),
        isNull,
      );
      expect(
        normalizeSocialProfileLink(
          SocialPlatform.tiktok,
          'javascript:alert(1)',
        ),
        isNull,
      );
      expect(
        normalizeSocialProfileLink(
          SocialPlatform.tiktok,
          'https://instagram.com/spotvibe',
        ),
        isNull,
      );
      expect(
        normalizeSocialProfileLink(
          SocialPlatform.youtube,
          'https://www.youtube.com/',
        ),
        isNull,
      );
    });

    test('storage keeps only known, safe platform links', () {
      final links = EventSocialLinks.fromStorage({
        'instagram': 'https://www.instagram.com/spotvibe/',
        'facebook': 'https://www.facebook.com/spotvibe',
        'snapchat': 'javascript:alert(1)',
        'unknown': 'https://example.com/not-shown',
      });

      expect(links.length, 2);
      expect(
        links[SocialPlatform.instagram],
        'https://www.instagram.com/spotvibe/',
      );
      expect(
        links[SocialPlatform.facebook],
        'https://www.facebook.com/spotvibe',
      );
      expect(links[SocialPlatform.snapchat], isNull);
      expect(
        links.entries.map((link) => link.platform),
        [SocialPlatform.instagram, SocialPlatform.facebook],
      );
    });

    test('reports the first invalid nonempty form field', () {
      expect(
        firstInvalidSocialPlatform({
          SocialPlatform.instagram: '@spotvibe',
          SocialPlatform.facebook: 'https://not-facebook.example/spotvibe',
        }),
        SocialPlatform.facebook,
      );
      expect(
        firstInvalidSocialPlatform({
          SocialPlatform.instagram: '@spotvibe',
          SocialPlatform.facebook: '',
        }),
        isNull,
      );
    });

    test('round-trips public organizer links through a feed event document', () {
      final socialLinks = EventSocialLinks.fromInput({
        SocialPlatform.instagram: '@spotvibe',
        SocialPlatform.youtube: 'https://youtube.com/@spotvibe',
      });
      final event = Event(
        id: 'social-event',
        title: 'Community Concert',
        description: 'A real community event.',
        dateTime: DateTime(2026, 9, 12, 18),
        endDateTime: DateTime(2026, 9, 12, 21),
        location: 'Downtown Plaza',
        address: '1 Main Street',
        city: 'El Paso',
        state: 'TX',
        imageUrl: '',
        category: 'Music',
        organizerName: 'SpotVibe',
        organizerAvatarUrl: '',
        socialLinks: socialLinks,
      );

      final stored = eventToMap(event, kind: 'user');
      final restored = eventFromMap(event.id, stored);

      expect(stored['socialLinks'], {
        'instagram': 'https://www.instagram.com/spotvibe/',
        'youtube': 'https://youtube.com/@spotvibe',
      });
      expect(
        restored.socialLinks[SocialPlatform.instagram],
        'https://www.instagram.com/spotvibe/',
      );
      expect(
        restored.socialLinks[SocialPlatform.youtube],
        'https://youtube.com/@spotvibe',
      );
    });

    test('a non-Premium creator can publish public organizer links', () async {
      final service = UserEventService(repository: UserEventRepository());
      final startsAt = DateTime.now().add(const Duration(days: 2));

      final event = await service.createEvent(
        creatorId: 'free-creator',
        title: 'Open Mic Night',
        description: 'A real event posted by a free creator.',
        dateTime: startsAt,
        endDateTime: startsAt.add(const Duration(hours: 3)),
        location: 'Community Hall',
        address: '1 Main Street',
        category: 'Music',
        organizerName: 'Free Creator',
        isPremiumListing: false,
        isCreatorPro: false,
        socialLinks: EventSocialLinks.fromInput({
          SocialPlatform.instagram: '@free_creator',
          SocialPlatform.snapchat: 'free_creator',
        }),
      );

      expect(event.isCreatorPro, isFalse);
      expect(
        event.socialLinks[SocialPlatform.instagram],
        'https://www.instagram.com/free_creator/',
      );
      expect(
        event.socialLinks[SocialPlatform.snapchat],
        'https://www.snapchat.com/add/free_creator',
      );
    });
  });
}
