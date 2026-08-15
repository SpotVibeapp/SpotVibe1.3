import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'repositories/firebase_event_repository.dart';
import 'repositories/firebase_rsvp_repository.dart';
import 'repositories/firebase_user_event_repository.dart';
import 'repositories/firebase_user_repository.dart';
import 'repositories/follow_repository.dart';
import 'repositories/mock_user_repository.dart';
import 'repositories/onboarding_repository.dart';
import 'repositories/event_claim_repository.dart';
import 'repositories/founding_member_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/notification_preferences_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/personalization_repository.dart';
import 'repositories/rsvp_repository.dart';
import 'repositories/user_event_repository.dart';
import 'repositories/user_repository.dart';
import 'router/app_router.dart';
import 'services/ai_moderation_service.dart';
import 'services/event_analytics_service.dart';
import 'services/event_expiry_service.dart';
import 'services/auth_service.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/personalization_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/ticketmaster_service.dart';
import 'providers/follow_provider.dart';
import 'providers/personalization_provider.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase / user backend ───────────────────────────────────────────────
  // Real auth when Firebase is configured for this platform. Release builds
  // MUST be configured — see _createBackend(): a store build that cannot
  // reach Firebase shows a clear error instead of silently accepting fake
  // logins. Debug/profile builds still fall back to in-memory mocks.
  final backend = await _createBackend();

  final revenueCatService = RevenueCatService();
  await revenueCatService.initialize();
  final notificationService = NotificationService();
  await notificationService.initialize();
  final permissionService = PermissionService();

  // ── Resolve the initial deep link path ────────────────────────────────────
  // Priority order (highest → lowest):
  //   1. OS cold-start URI     — delivered by app_links (App Links / custom scheme)
  //   2. Pending link          — saved from a previous session interrupted by /permissions
  //   3. /permissions          — first-ever launch (permissions not yet asked)
  //   4. /                     — all subsequent normal launches
  String initialLocation = '/';

  if (!kIsWeb) {
    try {
      final appLinks = AppLinks();
      final coldUri = await appLinks.getInitialLink();
      if (coldUri != null) {
        final path = DeepLinkService.pathFromUri(coldUri.toString());
        if (path != null) initialLocation = path;
      }
    } catch (_) {}
  }

  if (initialLocation == '/') {
    final pending = await DeepLinkService.consumePendingLink();
    if (pending != null) {
      initialLocation = pending;
    } else {
      final hasAsked = await permissionService.hasAskedBefore();
      if (!hasAsked) {
        final onboardingRepo = OnboardingRepository();
        final onboardingDone = await onboardingRepo.isOnboardingDone();
        initialLocation = onboardingDone ? '/' : '/onboarding';
      }
    }
  }

  if (backend == null) {
    runApp(const _BackendUnavailableApp());
    return;
  }

  runApp(SpotVibeApp(
    userRepository: backend.users,
    eventRepository: backend.events,
    rsvpRepository: backend.rsvps,
    userEventRepository: backend.userEvents,
    claimRepository: backend.claims,
    foundingRepository: backend.founding,
    revenueCatService: revenueCatService,
    notificationService: notificationService,
    permissionService: permissionService,
    initialLocation: initialLocation,
  ));
}

class _AppBackend {
  final UserRepository users;
  final EventRepository events;
  final RsvpRepository rsvps;
  final UserEventRepository userEvents;
  final EventClaimRepository claims;
  final FoundingMemberRepository founding;
  const _AppBackend({
    required this.users,
    required this.events,
    required this.rsvps,
    required this.userEvents,
    required this.claims,
    required this.founding,
  });
}

/// Initializes Firebase and returns real repos, in-memory mocks (debug only),
/// or `null` when a release build cannot reach Firebase.
Future<_AppBackend?> _createBackend() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized — auth + events/RSVPs enabled.');
    final events = FirebaseEventRepository();
    await events.ensureSeeded();
    return _AppBackend(
      users: FirebaseUserRepository(),
      events: events,
      rsvps: FirebaseRsvpRepository(),
      userEvents: FirebaseUserEventRepository(),
      claims: FirebaseEventClaimRepository(),
      founding: FirebaseFoundingMemberRepository(),
    );
  } catch (e) {
    debugPrint('Firebase unavailable ($e).');
    if (kReleaseMode) {
      // Store builds must never silently ship mock auth.
      return null;
    }
    debugPrint('Using mock repositories (debug/profile only).');
    return _AppBackend(
      users: MockUserRepository(),
      events: MockEventRepository(),
      rsvps: MockRsvpRepository(),
      userEvents: UserEventRepository(),
      claims: MockEventClaimRepository(),
      founding: MockFoundingMemberRepository(),
    );
  }
}

/// Shown when a release build cannot reach Firebase. Fails loud and clear
/// instead of accepting fake logins.
class _BackendUnavailableApp extends StatelessWidget {
  const _BackendUnavailableApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotVibe',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_off_rounded, size: 56),
                SizedBox(height: 16),
                Text(
                  'SpotVibe could not connect to its backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'This build is not configured with Firebase.\n'
                  'Run flutterfire configure --project=spotvibe-cfa08 and rebuild.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SpotVibeApp extends StatefulWidget {
  final UserRepository userRepository;
  final EventRepository eventRepository;
  final RsvpRepository rsvpRepository;
  final UserEventRepository userEventRepository;
  final EventClaimRepository claimRepository;
  final FoundingMemberRepository foundingRepository;
  final RevenueCatService revenueCatService;
  final NotificationService notificationService;
  final PermissionService permissionService;
  final String initialLocation;

  const SpotVibeApp({
    super.key,
    required this.userRepository,
    required this.eventRepository,
    required this.rsvpRepository,
    required this.userEventRepository,
    required this.claimRepository,
    required this.foundingRepository,
    required this.revenueCatService,
    required this.notificationService,
    required this.permissionService,
    required this.initialLocation,
  });

  @override
  State<SpotVibeApp> createState() => _SpotVibeAppState();
}

class _SpotVibeAppState extends State<SpotVibeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(initialLocation: widget.initialLocation);

    if (!kIsWeb) {
      // app_links: handles https App Links, universal links, and spotvibe://
      // custom-scheme URIs while the app is running.
      final appLinks = AppLinks();
      appLinks.uriLinkStream.listen((uri) {
        final path = DeepLinkService.pathFromUri(uri.toString());
        if (path != null) _router.go(path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AiModerationService()),
        ChangeNotifierProvider(create: (_) => EventExpiryService()),
        Provider<EventRepository>(create: (_) => widget.eventRepository),
        Provider(create: (_) => TicketmasterService()),
        Provider<UserRepository>(create: (_) => widget.userRepository),
        Provider(create: (_) => FollowRepository()),
        Provider<RsvpRepository>(create: (_) => widget.rsvpRepository),
        Provider<UserEventRepository>(create: (_) => widget.userEventRepository),
        Provider<EventClaimRepository>(create: (_) => widget.claimRepository),
        Provider<FoundingMemberRepository>(create: (_) => widget.foundingRepository),
        Provider(
          create: (ctx) => EventAnalyticsService(
            repository: ctx.read<UserEventRepository>(),
          ),
        ),
        Provider(create: (_) => NotificationRepository()),
        Provider(create: (_) => NotificationPreferencesRepository()),
        Provider(create: (_) => OnboardingRepository()),
        Provider(create: (_) => PersonalizationRepository()),
        ChangeNotifierProvider(
          create: (ctx) =>
              NotificationProvider(repository: ctx.read<NotificationRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PersonalizationProvider(
            repository: ctx.read<PersonalizationRepository>(),
            service: const PersonalizationService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FollowProvider(
            repository: ctx.read<FollowRepository>(),
          ),
        ),
        Provider(create: (_) => widget.revenueCatService),
        Provider(create: (_) => widget.notificationService),
        Provider(create: (_) => widget.permissionService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(
            service: AuthService(repository: ctx.read<UserRepository>()),
            notificationService: ctx.read<NotificationService>(),
          )..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SubscriptionProvider(
            service: ctx.read<RevenueCatService>(),
            founding: ctx.read<FoundingMemberRepository>(),
            currentUserId: () => ctx.read<AuthProvider>().user?.id,
          )..initialize(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'SpotVibe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
