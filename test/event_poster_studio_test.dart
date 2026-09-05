import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/widgets/events/event_poster_studio.dart';

void main() {
  group('posterLocationLine', () {
    test('uses venue and city/state without exposing a blank address', () {
      expect(
        posterLocationLine(
          venue: 'The Pool Hall',
          address: '123 Main Street',
          city: 'El Paso',
          state: 'TX',
        ),
        'The Pool Hall · El Paso, TX',
      );
    });

    test('falls back to the address when no venue is supplied', () {
      expect(
        posterLocationLine(
          venue: '',
          address: '123 Main Street',
          city: '',
          state: '',
        ),
        '123 Main Street',
      );
    });

    test('does not add separators for empty fields', () {
      expect(
        posterLocationLine(venue: '', address: '', city: 'El Paso', state: ''),
        'El Paso',
      );
    });
  });

  group('posterTimeLabel', () {
    test('uses the exact same-day start and end time', () {
      expect(
        posterTimeLabel(
          DateTime(2026, 9, 12, 20),
          DateTime(2026, 9, 12, 23, 30),
        ),
        '8:00 PM – 11:30 PM',
      );
    });

    test('keeps legacy posters compatible when no end was stored', () {
      expect(posterTimeLabel(DateTime(2026, 9, 12, 20), null), '8:00 PM');
    });
  });

  group('posterPriceLabel', () {
    test('shows a structured free label when price is omitted or zero', () {
      expect(posterPriceLabel(null, freeLabel: 'Free'), 'FREE');
      expect(posterPriceLabel(0, freeLabel: 'Gratis'), 'GRATIS');
    });

    test('formats entered ticket prices exactly', () {
      expect(posterPriceLabel(12.5, freeLabel: 'Free'), r'$12.50');
      expect(posterPriceLabel(99, freeLabel: 'Free'), r'$99.00');
    });
  });

  testWidgets('poster graphic uses the exact structured event details',
      (tester) async {
    final details = EventPosterDetails(
      title: 'Pool Night',
      dateTime: DateTime(2026, 9, 12, 20),
      venue: 'The Pool Hall',
      address: '123 Main Street',
      city: 'El Paso',
      state: 'TX',
      cost: 12.5,
      category: 'Social',
      backgroundImageUrl: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 450,
            child: EventPosterGraphic(
              details: details,
              template: PosterTemplate.editorial,
              alignment: PosterTextAlignment.left,
              showVenue: true,
              showPrice: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pool Night'), findsOneWidget);
    expect(find.text('The Pool Hall · El Paso, TX'), findsOneWidget);
    expect(find.text(r'$12.50'), findsOneWidget);
  });
}
