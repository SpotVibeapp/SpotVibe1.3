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
  // Real auth when Firebase is configured for this platform; falls back to
  // the in-memory mock so the app still runs everywhere else (e.g. Android/
  // iOS builds before `flutterfire configure` has been run).
  final backend = await _createBackend();
  final userRepository = backend.users;

  final revenueCatService = RevenueCatService();
  await revenueCatService.initialize();
  final notificationService = NotificationService();
  await notificationService.initialize();
  final permissionService = PermissionService();

  // ── Initialise Branch SDK ─────────────────────────────────────────────────
  final branchService = BranchService();
  await branchService.initialize();

  // ── Resolve the initial deep link path ────────────────────────────────────
  // Priority order (highest → lowest):
  //   1. Branch deferred link  — survives a fresh install across the App Store
  //   2. OS cold-start URI     — delivered by app_links when app was already installed
  //   3. Pending link          — saved from a previous session interrupted by /permissions
  //   4. /permissions          — first-ever launch (permissions not yet asked)
  //   5. /                     — all subsequent normal launches
  String initialLocation = '/';

  if (!kIsWeb) {
    // 1. Branch — highest priority: covers post-install deferred scenario.
    final branchPath = await branchService.getInitialLink();
    if (branchPath != null) {
      initialLocation = branchPath;
    } else {
      // 2. OS cold-start URI via app_links.
      try {
        final appLinks = AppLinks();
        final coldUri = await appLinks.getInitialLink();
        if (coldUri != null) {
          final path = DeepLinkService.pathFromUri(coldUri.toString());
          if (path != null) initialLocation = path;
        }
      } catch (_) {}
    }
  }

  if (initialLocation == '/') {
    // 3. Pending link stored from a previous session (permissions flow).
    final pending = await DeepLinkService.consumePendingLink();
    if (pending != null) {
      initialLocation = pending;
    } else {
      // 4 & 5. Normal startup.
      final hasAsked = await permissionService.hasAskedBefore();
      if (!hasAsked) {
        // Check onboarding repo as the canonical first-launch gate.
        final onboardingRepo = OnboardingRepository();
        final onboardingDone = await onboardingRepo.isOnboardingDone();
        initialLocation = onboardingDone ? '/' : '/onboarding';
      }
    }
  }

  runApp(SpotVibeApp(
    userRepository: userRepository,
    eventRepository: backend.events,
    rsvpRepository: backend.rsvps,
    userEventRepository: backend.userEvents,
    claimRepository: backend.claims,
    foundingRepository: backend.founding,
    revenueCatService: revenueCatService,
    notificationService: notificationService,
    permissionService: permissionService,
    branchService: branchService,
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

/// Initializes Firebase and returns real repos, or in-memory mocks when
/// Firebase isn't configured on this platform.
Future<_AppBackend> _createBackend() async {
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
    debugPrint('Firebase unavailable ($e) — using mock repositories.');
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
  final BranchService branchService;
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
    required this.branchService,
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
      // ── Runtime deep link listeners ──────────────────────────────────────
      // Branch: handles foreground links and subsequent session links.
      widget.branchService.linkStream.listen((path) => _router.go(path));

      // app_links: fallback for spotvibe:// custom-scheme URIs and HTTPS
      // App Links that Branch doesn't intercept (e.g. direct share copies).
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