import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/road_trip_destinations.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/models/ai_event_search.dart';
import 'package:spotvibe_app/widgets/events/ai_event_search_assistant.dart';

void main() {
  test('AI search plan accepts only safe structured filter values', () {
    final plan = AiEventSearchPlan.fromMap({
      'searchText': '  live jazz   this weekend ',
      'category': 'Music',
      'datePreset': 'this_weekend',
      'requestedCity': 'Albuquerque',
      'requestedState': 'nm',
    });

    expect(plan.searchText, 'live jazz this weekend');
    expect(plan.category, 'Music');
    expect(plan.datePreset, 'this_weekend');
    expect(plan.requestedLocation?.displayName, 'Albuquerque, NM');
  });

  test('broad discovery wording does not become a literal provider keyword', () {
    final broad = AiEventSearchPlan.fromMap({
      'searchText': 'concerts in El Paso',
      'category': 'Music',
      'datePreset': 'all',
      'requestedCity': 'El Paso',
      'requestedState': 'TX',
    });
    final specific = AiEventSearchPlan.fromMap({
      'searchText': 'Bad Bunny concert in El Paso',
      'category': 'Music',
      'datePreset': 'all',
      'requestedCity': 'El Paso',
      'requestedState': 'TX',
    });

    expect(broad.specificSearchText, isNull);
    expect(specific.specificSearchText, 'bad bunny');
  });

  test('AI search plan falls back safely for malformed output', () {
    final plan = AiEventSearchPlan.fromMap({
      'searchText': 42,
      'category': 'Anything the model invented',
      'datePreset': 'next-month',
      'requestedCity': '',
      'requestedState': 'New Mexico',
    });

    expect(plan.searchText, isEmpty);
    expect(plan.category, isNull);
    expect(plan.datePreset, 'all');
    expect(plan.requestedLocation, isNull);
  });

  test('El Paso road-trip catalog includes Albuquerque but other cities stay local',
      () {
    final elPaso = roadTripDestinationsFor(city: 'El Paso', state: 'TX');

    expect(elPaso.map((place) => place.displayName), contains('Albuquerque, NM'));
    expect(roadTripDestinationsFor(city: 'Austin', state: 'TX'), isEmpty);
  });

  testWidgets('Ask SpotVibe card explains its sign-in requirement and opens',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AskSpotVibeCard(
            isSignedIn: false,
            onTap: () => opened = true,
          ),
        ),
      ),
    );

    expect(find.text('Ask SpotVibe'), findsOneWidget);
    expect(
      find.text('Sign in to get real event recommendations.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ask SpotVibe'));
    expect(opened, isTrue);
  });
}
