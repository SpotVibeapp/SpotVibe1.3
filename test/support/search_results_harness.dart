import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/event_save.dart';
import 'package:spotvibe_app/providers/auth_provider.dart';
import 'package:spotvibe_app/providers/event_provider.dart';
import 'package:spotvibe_app/providers/personalization_provider.dart';
import 'package:spotvibe_app/providers/subscription_provider.dart';
import 'package:spotvibe_app/repositories/event_repository.dart';
import 'package:spotvibe_app/repositories/mock_user_repository.dart';
import 'package:spotvibe_app/repositories/personalization_repository.dart';
import 'package:spotvibe_app/screens/events_screen.dart';
import 'package:spotvibe_app/services/auth_service.dart';
import 'package:spotvibe_app/services/event_service.dart';
import 'package:spotvibe_app/services/revenue_cat_service.dart';
import 'package:spotvibe_app/theme/theme.dart';

/// One screen configuration of the Galaxy Z Fold 8 that Blake tests on.
class FoldScreen {
  final String name;

  /// Physical pixels.
  final Size physicalSize;
  final double devicePixelRatio;

  /// Status bar (top) and gesture-nav (bottom) insets, logical pixels.
  final EdgeInsets systemInsets;

  const FoldScreen(
    this.name,
    this.physicalSize, {
    this.devicePixelRatio = 2.6,
    this.systemInsets = const EdgeInsets.only(top: 24, bottom: 16),
  });

  Size get logicalSize => physicalSize / devicePixelRatio;
}

const kFoldScreens = <FoldScreen>[
  FoldScreen('cover-portrait', Size(904, 2316)),
  FoldScreen('cover-landscape', Size(2316, 904)),
  FoldScreen('inner-portrait', Size(1812, 2176)),
  FoldScreen('inner-landscape', Size(2176, 1812)),
];

class _FixedEventRepository implements EventRepository {
  final List<Event> events;
  _FixedEventRepository(this.events);

  @override
  Future<Event?> getEventById(String id) async =>
      events.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<Event>> getEventsForLocation({
    required String city,
    required String state,
    required String zip,
    FeedArea? area,
  }) async =>
      events;

  @override
  Future<List<Event>> getUpcomingEvents({FeedArea? area}) async => events;

  @override
  Future<Map<String, EventSave>> getSaves() async => {};

  @override
  Future<void> setSave(
    String eventId, {
    required bool bookmarked,
    required bool interested,
  }) async {}
}

const _venueImages = [
  'assets/venues/plaza_theatre.jpg',
  'assets/venues/county_coliseum.jpg',
  'assets/venues/san_jacinto.jpg',
  'assets/venues/abraham_chavez.jpg',
  'assets/venues/don_haskins.jpg',
];

/// Realistic search results: long titles (two lines), long venue names, more
/// than one page so the pagination bar is present.
List<Event> searchResultEvents({int count = 20}) {
  final start = DateTime.now().add(const Duration(days: 2));
  return List.generate(count, (i) {
    return Event(
      id: 'event-$i',
      title: 'Live Music Night $i: Desert Sounds Showcase with Special Guests',
      description: 'A real listing used by the search results layout test.',
      dateTime: DateTime(start.year, start.month, start.day, 19).add(Duration(days: i)),
      location: 'Plaza Theatre Performing Arts Centre, Downtown El Paso',
      address: '125 Pioneer Plaza',
      city: 'El Paso',
      state: 'TX',
      imageUrl: _venueImages[i % _venueImages.length],
      category: 'Music',
      organizerName: 'El Paso Live Presents',
      organizerAvatarUrl: '',
    );
  });
}

/// Stubs the plugin channels the home screen touches so it renders headless.
void stubPlatformChannels() {
  SharedPreferences.setMockInitialValues({
    // The guided tour would otherwise cover the screen on first launch.
    'spotvibe_tour_seen': ['home'],
  });
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in const [
    'plugins.flutter.io/google_mobile_ads',
    'flutter.baseflow.com/geolocator',
    'flutter.baseflow.com/geolocator_android',
    'purchases_flutter',
  ]) {
    // Answer at the binary level: some plugins use custom message codecs.
    messenger.setMockMessageHandler(
      channel,
      (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
    );
  }
}

/// Pumps the real home/search screen ([EventsScreen]) at [screen] with
/// [textScale], then runs a keyword search so the search results are showing.
Future<EventProvider> pumpSearchResults(
  WidgetTester tester,
  FoldScreen screen, {
  double textScale = 1.0,
  String query = 'Music Night',
  List<Event>? events,
  Key? boundaryKey,
}) async {
  stubPlatformChannels();
  tester.view.devicePixelRatio = screen.devicePixelRatio;
  tester.view.physicalSize = screen.physicalSize;
  final insets = FakeViewPadding(
    top: screen.systemInsets.top * screen.devicePixelRatio,
    bottom: screen.systemInsets.bottom * screen.devicePixelRatio,
  );
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final eventService = EventService(
    repository: _FixedEventRepository(events ?? searchResultEvents()),
  );
  final eventProvider = EventProvider(service: eventService);
  final authProvider =
      AuthProvider(service: AuthService(repository: MockUserRepository()));
  final subscription = SubscriptionProvider(service: RevenueCatService());
  final personalization =
      PersonalizationProvider(repository: PersonalizationRepository());

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<EventService>.value(value: eventService),
        ChangeNotifierProvider<EventProvider>.value(value: eventProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: subscription),
        ChangeNotifierProvider<PersonalizationProvider>.value(
            value: personalization),
      ],
      child: RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EventsScreen(),
        ),
      ),
    ),
  );

  // Type the query into the real search field and submit it, as Blake does.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.enterText(find.byType(TextField).first, query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  FocusManager.instance.primaryFocus?.unfocus();
  // The header glow animates forever, so settle with bounded pumps.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return eventProvider;
}
