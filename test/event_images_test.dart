import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/event_images.dart';

void main() {
  group('isGenericEventImage', () {
    test('treats a missing or empty URL as no real image', () {
      expect(isMissingEventImage(''), isTrue);
      expect(isGenericEventImage(''), isTrue);
      expect(hasRealEventImage(''), isFalse);
    });

    test('treats ui-avatars placeholders as no real image', () {
      const url =
          'https://ui-avatars.com/api/?name=TM&size=200&background=026CDF&color=fff';
      expect(isMissingEventImage(url), isTrue);
      expect(isGenericEventImage(url), isTrue);
    });

    test('treats Ticketmaster /dam/c/ classification stock as generic', () {
      const stock =
          'https://s1.ticketm.net/dam/c/fbc/baseball-glove_TABLET_LANDSCAPE_LARGE_16_9.jpg';
      expect(isStockTicketmasterImage(stock), isTrue);
      expect(isGenericEventImage(stock), isTrue);
      expect(hasRealEventImage(stock), isFalse);
    });

    test('keeps unique Ticketmaster attraction art', () {
      const art = 'https://s1.ticketm.net/dam/a/abc/bad-bunny-16_9.jpg';
      expect(isStockTicketmasterImage(art), isFalse);
      expect(isGenericEventImage(art), isFalse);
      expect(hasRealEventImage(art), isTrue);
    });

    test('treats the app bundled venue fallback assets as stock', () {
      expect(isAppStockFallbackImage('assets/venues/southwest_university_park.jpg'),
          isTrue);
      expect(
        isGenericEventImage('assets/venues/county_coliseum.jpg'),
        isTrue,
      );
    });

    test('does not invent SeatGeek or JamBase URL patterns', () {
      // Those providers have no additional default-image patterns in this
      // codebase. A real performer photo should still show.
      expect(
        isGenericEventImage(
          'https://seatgeek.com/images/performers/khruangbin/huge.jpg',
        ),
        isFalse,
      );
    });
  });

  group('eventPlaceholderHeadline', () {
    test('uses the event title when it is a real name', () {
      expect(
        eventPlaceholderHeadline(
          title: 'El Paso Chihuahuas vs. Round Rock Express',
          venue: 'Southwest University Park',
        ),
        'El Paso Chihuahuas vs. Round Rock Express',
      );
    });

    test('falls back to the venue when the title is missing or tiny', () {
      expect(
        eventPlaceholderHeadline(title: '', venue: 'Plaza Theatre'),
        'Plaza Theatre',
      );
      expect(
        eventPlaceholderHeadline(title: 'AB', venue: 'Plaza Theatre'),
        'Plaza Theatre',
      );
    });

    test('falls back to the venue when the title just repeats it', () {
      expect(
        eventPlaceholderHeadline(
          title: 'Plaza Theatre',
          venue: 'Plaza Theatre',
        ),
        'Plaza Theatre',
      );
    });
  });
}
