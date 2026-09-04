import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/pricing.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/widgets/events/home_discovery_hero.dart';

Event _event(String id, {String? featuredWeekKey}) {
  return Event(
    id: id,
    title: 'Real event $id',
    description: 'A real listing used by the home feed.',
    dateTime: DateTime(2026, 9, 5, 19),
    location: 'Real Venue',
    address: '1 Main Street',
    city: 'El Paso',
    state: 'TX',
    imageUrl: 'assets/venues/plaza_theatre.jpg',
    category: 'Music',
    organizerName: 'Real Organizer',
    organizerAvatarUrl: '',
    featuredWeekKey: featuredWeekKey,
  );
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('selectDiscoveryHeroEvent', () {
    final now = DateTime(2026, 9, 4, 12);

    test('prioritizes a real event featured in the current week', () {
      final first = _event('first');
      final featured = _event(
        'featured',
        featuredWeekKey: isoWeekKey(now),
      );

      expect(
        selectDiscoveryHeroEvent([first, featured], now: now),
        same(featured),
      );
    });

    test('falls back to the feed-ranked event instead of inventing one', () {
      final first = _event('first');
      final staleFeatured = _event(
        'stale',
        featuredWeekKey: isoWeekKey(DateTime(2026, 8, 20)),
      );

      expect(
        selectDiscoveryHeroEvent([first, staleFeatured], now: now),
        same(first),
      );
    });

    test('returns no hero event when the feed is empty', () {
      expect(selectDiscoveryHeroEvent(const <Event>[], now: now), isNull);
    });
  });

  testWidgets('hero shows and opens the supplied genuine event', (tester) async {
    final event = _event('featured');
    var opened = false;

    await tester.pumpWidget(
      _testApp(
        HomeDiscoveryHero(
          event: event,
          onTap: () => opened = true,
        ),
      ),
    );

    expect(find.text(event.title), findsOneWidget);
    await tester.tap(find.text(event.title));
    expect(opened, isTrue);
  });

  testWidgets('quick filters keep all four discovery actions tappable',
      (tester) async {
    var todayTaps = 0;
    var weekendTaps = 0;
    var freeTaps = 0;
    var nearMeTaps = 0;

    await tester.pumpWidget(
      _testApp(
        HomeQuickFilters(
          isTodaySelected: false,
          isWeekendSelected: false,
          isFreeSelected: false,
          isNearMeSelected: false,
          isRequestingLocation: false,
          onTodayTap: () => todayTaps++,
          onWeekendTap: () => weekendTaps++,
          onFreeTap: () => freeTaps++,
          onNearMeTap: () => nearMeTaps++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-quick-filter-today')));
    await tester.tap(find.byKey(const Key('home-quick-filter-weekend')));
    await tester.tap(find.byKey(const Key('home-quick-filter-free')));
    await tester.tap(find.byKey(const Key('home-quick-filter-near-me')));

    expect(todayTaps, 1);
    expect(weekendTaps, 1);
    expect(freeTaps, 1);
    expect(nearMeTaps, 1);
  });
}
