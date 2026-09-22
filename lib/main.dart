import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/moderation_provider.dart';
import 'providers/partner_promo_provider.dart';
import 'repositories/firebase_event_repository.dart';
import 'repositories/firebase_gem_repository.dart';
import 'repositories/firebase_rsvp_repository.dart';
import 'repositories/firebase_user_event_repository.dart';
import 'repositories/firebase_user_repository.dart';
import 'repositories/follow_repository.dart';
import 'repositories/mock_user_repository.dart';
import 'repositories/moderation_repository.dart';
import 'repositories/onboarding_repository.dart';
import 'repositories/event_claim_repository.dart';
import 'repositories/founding_member_repository.dart';
import 'repositories/gem_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/notification_preferences_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/partner_promo_repository.dart';
import 'repositories/personalization_repository.dart';
import 'repositories/rsvp_repository.dart';
import 'repositories/user_event_repository.dart';
import 'repositories/user_repository.dart';
import 'router/app_router.dart';
import 'services/ad_consent_service.dart';
import 'services/ads_service.dart';
import 'services/ai_moderation_service.dart';
import 'services/gem_service.dart';
import 'services/event_analytics_service.dart';
import 'services/event_expiry_service.dart';
import 'services/auth_service.dart';
import 'services/deep_link_service.dart';
import 'services/jambase_service.dart';
import 'services/live_event_source.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/personalization_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/seatgeek_service.dart';
import 'services/ticketmaster_service.dart';
import 'providers/follow_provider.dart';
import 'providers/personalization_provider.dart';
import 'theme/theme.dart';
import 'widgets/common/animated_splash.dart';

/// First Flutter frame is the branded splash. Backend init runs underneath
/// it so the user never sits on the native launch screen (small icon / blank
/// color) waiting for Firebase, ads, and deep links.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootApp());
}

class _BootApp extends StatefulWidget {
  const _BootApp();

  @override
  State<_BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<_BootApp> {
  Widget? _app;
  bool _ready = false;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // ── Firebase / user backend ───────────────────────────────────────────
    // Real auth when Firebase is configured for this platform. Release builds
    // MUST be configured — see _createBackend(): a store build that cannot
    // reach Firebase shows a clear error instead of silently accepting fake
    // logins. Debug/profile builds still fall back to in-memory mocks.
    final backend = await _createBackend();

    // ── Crashlytics ────────────────────────────────────────────────────────
    // Route uncaught Flutter framework errors and async/platform errors to
    // Firebase Crashlytics so we get real crash reports from testers and users.
    // Only active in release/profile (debug crashes are noisy and local), and
    // only when Firebase actually initialized (skipped for the mock backend).
    if (backend != null && !kIsWeb) {
      try {
        final crashlytics = FirebaseCrashlytics.instance;
        await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          crashlytics.recordFlutterFatalError(details);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          crashlytics.recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e) {
        if (kDebugMode) debugPrint('[crashlytics] setup failed: $e');
      }
    }

    final revenueCatService = RevenueCatService();
    await revenueCatService.initialize();
    final notificationService = NotificationService();
    await notificationService.initialize();
    final permissionService = PermissionService();

    // ── Ads (banner ads for free users; ad-free is a Premium benefit) ──────
    // Request UMP consent, then initialize the Mobile Ads SDK. Both no-op on
    // web and are wrapped so an ad failure can never block startup.
    await AdConsentService.ensureConsent();
    await AdsService.initialize();

    // ── Resolve the initial deep link path ────────────────────────────────
    // Priority order (highest → lowest):
    //   1. OS cold-start URI — delivered by app_links
    //   2. Pending link      — saved from a previous session
    //   3. /onboarding       — first-ever launch
    //   4. /                 — all subsequent normal launches
    String initialLocation = '/';
    String? coldLinkUri;

    if (!kIsWeb) {
      try {
        final appLinks = AppLinks();
        final coldUri = await appLinks.getInitialLink();
        if (coldUri != null) {
          if (kDebugMode) debugPrint('[deepLink] cold-start uri=$coldUri');
          final path = DeepLinkService.pathFromUri(coldUri.toString());
          if (kDebugMode) debugPrint('[deepLink] cold-start parsed path=$path');
          if (path != null) {
            initialLocation = path;
            coldLinkUri = coldUri.toString();
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[deepLink] cold-start read failed: $e');
      }
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

    if (!mounted) return;

    final Widget next;
    if (backend == null) {
      next = _BackendUnavailableApp(onRetry: main);
    } else {
      next = SpotVibeApp(
        userRepository: backend.users,
        eventRepository: backend.events,
        rsvpRepository: backend.rsvps,
        userEventRepository: backend.userEvents,
        gemRepository: backend.gems,
        claimRepository: backend.claims,
        foundingRepository: backend.founding,
        moderationRepository: backend.moderation,
        partnerPromoRepository: backend.partnerPromoCodes,
        revenueCatService: revenueCatService,
        notificationService: notificationService,
        permissionService: permissionService,
        initialLocation: initialLocation,
        initialLinkUri: coldLinkUri,
      );
    }

    setState(() {
      _app = next;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_splashDone && _app != null) return _app!;

    return MaterialApp(
      title: 'SpotVibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C5CE7),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, _) {
        if (deviceLocale != null && deviceLocale.languageCode == 'es') {
          return const Locale('es');
        }
        return const Locale('en');
      },
      home: AnimatedSplashScreen(
        isReady: _ready,
        onFinished: () {
          if (mounted) setState(() => _splashDone = true);
        },
      ),
    );
  }
}

class _AppBackend {
  final UserRepository users;
  final EventRepository events;
  final RsvpRepository rsvps;
  final UserEventRepository userEvents;
  final GemRepository gems;
  final EventClaimRepository claims;
  final FoundingMemberRepository founding;
  final ModerationRepository moderation;
  final PartnerPromoRepository partnerPromoCodes;
  const _AppBackend({
    required this.users,
    required this.events,
    required this.rsvps,
    required this.userEvents,
    required this.gems,
    required this.claims,
    required this.founding,
    required this.moderation,
    required this.partnerPromoCodes,
  });
}

/// Resolves the active app locale: the user's manual choice when set,
/// otherwise any Spanish device locale → `es`, everything else → `en`.
Locale _resolveLocale(Locale? manual, Locale? device) {
  if (manual != null) return manual;
  if (device != null && device.languageCode == 'es') return const Locale('es');
  return const Locale('en');
}

/// Effective locale for non-widget code (e.g. SubscriptionProvider labels).
Locale _effectiveLocale(LocaleProvider provider) {
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  return _resolveLocale(provider.locale, device);
}

/// Initializes Firebase and returns real repos, in-memory mocks (debug only),
/// or `null` when a release build cannot reach Firebase.
Future<_AppBackend?> _createBackend() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('Firebase initialized — auth + events/RSVPs enabled.');
    final events = FirebaseEventRepository();
    await events.ensureSeeded();
    return _AppBackend(
      users: FirebaseUserRepository(),
      events: events,
      rsvps: FirebaseRsvpRepository(),
      userEvents: FirebaseUserEventRepository(),
      gems: FirebaseGemRepository(),
      claims: FirebaseEventClaimRepository(),
      founding: FirebaseFoundingMemberRepository(),
      moderation: FirebaseModerationRepository(),
      partnerPromoCodes: FirebasePartnerPromoRepository(),
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
      gems: GemRepository(),
      claims: MockEventClaimRepository(),
      founding: MockFoundingMemberRepository(),
      moderation: MockModerationRepository(),
      partnerPromoCodes: MockPartnerPromoRepository(),
    );
  }
}

/// Shown when the app cannot reach its backend at startup. For real users this
/// is almost always a temporary connection problem, so it shows friendly copy
/// and a Retry button. In debug/profile builds it also surfaces the developer
/// hint (misconfigured Firebase) to speed up local setup.
class _BackendUnavailableApp extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _BackendUnavailableApp({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotVibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C5CE7),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Can't connect right now",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SpotVibe needs an internet connection to load events. '
                    'Please check your Wi-Fi or mobile data and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.35),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  if (!kReleaseMode) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Developer note: Firebase is not configured for this '
                      'build. Run\nflutterfire configure --project=spotvibe-cfa08\n'
                      'and rebuild.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
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
  final GemRepository gemRepository;
  final EventClaimRepository claimRepository;
  final FoundingMemberRepository foundingRepository;
  final ModerationRepository moderationRepository;
  final PartnerPromoRepository partnerPromoRepository;
  final RevenueCatService revenueCatService;
  final NotificationService notificationService;
  final PermissionService permissionService;
  final String initialLocation;
  final String? initialLinkUri;

  const SpotVibeApp({
    super.key,
    required this.userRepository,
    required this.eventRepository,
    required this.rsvpRepository,
    required this.userEventRepository,
    required this.gemRepository,
    required this.claimRepository,
    required this.foundingRepository,
    required this.moderationRepository,
    required this.partnerPromoRepository,
    required this.revenueCatService,
    required this.notificationService,
    required this.permissionService,
    required this.initialLocation,
    this.initialLinkUri,
  });

  @override
  State<SpotVibeApp> createState() => _SpotVibeAppState();
}

class _SpotVibeAppState extends State<SpotVibeApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  String? _lastResumeLinkUri;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(initialLocation: widget.initialLocation);
    _lastResumeLinkUri = widget.initialLinkUri;
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
      // app_links: handles https App Links, universal links, and spotvibe://
      // custom-scheme URIs while the app is running. Uses the same _appLinks
      // instance as the resume check — two instances would double-handle the
      // warm-tap delivery.
      _appLinks.uriLinkStream.listen((uri) {
        if (kDebugMode) debugPrint('[deepLink] stream uri=$uri');
        _lastResumeLinkUri = uri.toString();
        final path = DeepLinkService.pathFromUri(uri.toString());
        if (kDebugMode) debugPrint('[deepLink] stream parsed path=$path');
        if (path != null) _router.go(path);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      _checkLatestLink();
    }
  }

  Future<void> _checkLatestLink() async {
    try {
      final uri = await _appLinks.getLatestLink();
      if (uri == null) {
        if (kDebugMode) debugPrint('[deepLink] resume-check: no link');
        return;
      }
      if (uri.toString() == _lastResumeLinkUri) {
        if (kDebugMode) {
          debugPrint('[deepLink] resume-check skip duplicate: $uri');
        }
        return;
      }
      _lastResumeLinkUri = uri.toString();
      if (kDebugMode) debugPrint('[deepLink] resume-check uri=$uri');
      final path = DeepLinkService.pathFromUri(uri.toString());
      if (kDebugMode) debugPrint('[deepLink] resume-check parsed path=$path');
      if (path != null) _router.go(path);
    } catch (e) {
      if (kDebugMode) debugPrint('[deepLink] resume-check failed: $e');
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AiModerationService()),
        ChangeNotifierProvider(create: (_) => EventExpiryService()),
        Provider<EventRepository>(create: (_) => widget.eventRepository),
        Provider<GemRepository>(create: (_) => widget.gemRepository),
        Provider<GemService>(
          create: (ctx) => GemService(
            repository: ctx.read<GemRepository>(),
            moderation: ctx.read<AiModerationService>(),
          ),
        ),
        Provider(create: (_) => TicketmasterService()),
        Provider(create: (_) => SeatGeekService()),
        // Answers persist across launches: the Developer plan is 1,000
        // requests a month, and the feed refreshes every minute.
        Provider(create: (_) => JamBaseService(store: PrefsJamBaseStore())),
        // Every live listing provider the feed merges. Adding a source is
        // one new LiveEventSource file plus one line here; an unconfigured
        // key just means that provider contributes nothing.
        Provider<List<LiveEventSource>>(
          create: (ctx) => List<LiveEventSource>.unmodifiable([
            ctx.read<TicketmasterService>(),
            ctx.read<SeatGeekService>(),
            ctx.read<JamBaseService>(),
          ]),
        ),
        Provider<UserRepository>(create: (_) => widget.userRepository),
        Provider(create: (_) => FollowRepository()),
        Provider<RsvpRepository>(create: (_) => widget.rsvpRepository),
        Provider<UserEventRepository>(create: (_) => widget.userEventRepository),
        Provider<EventClaimRepository>(create: (_) => widget.claimRepository),
        Provider<FoundingMemberRepository>(create: (_) => widget.foundingRepository),
        Provider<ModerationRepository>(create: (_) => widget.moderationRepository),
        Provider<PartnerPromoRepository>(create: (_) => widget.partnerPromoRepository),
        ChangeNotifierProvider(
          create:
              (ctx) => ModerationProvider(
                repository: ctx.read<ModerationRepository>(),
                claimsRepository: ctx.read<EventClaimRepository>(),
                gemService: ctx.read<GemService>(),
              ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PartnerPromoProvider(repository: ctx.read<PartnerPromoRepository>()),
        ),
        Provider(
          create: (ctx) => EventAnalyticsService(repository: ctx.read<UserEventRepository>()),
        ),
        Provider(create: (_) => NotificationRepository()),
        Provider(create: (_) => NotificationPreferencesRepository()),
        Provider(create: (_) => OnboardingRepository()),
        Provider(create: (_) => PersonalizationRepository()),
        ChangeNotifierProvider(
          create: (ctx) => NotificationProvider(repository: ctx.read<NotificationRepository>()),
        ),
        ChangeNotifierProvider(
          create:
              (ctx) => PersonalizationProvider(
                repository: ctx.read<PersonalizationRepository>(),
                service: const PersonalizationService(),
              ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FollowProvider(repository: ctx.read<FollowRepository>()),
        ),
        Provider(create: (_) => widget.revenueCatService),
        Provider(create: (_) => widget.notificationService),
        Provider(create: (_) => widget.permissionService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
        ChangeNotifierProvider(
          create:
              (ctx) => AuthProvider(
                service: AuthService(repository: ctx.read<UserRepository>()),
                notificationService: ctx.read<NotificationService>(),
                revenueCatService: ctx.read<RevenueCatService>(),
              )..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (ctx) {
            final sub = SubscriptionProvider(
              service: ctx.read<RevenueCatService>(),
              founding: ctx.read<FoundingMemberRepository>(),
              currentUserId: () => ctx.read<AuthProvider>().user?.id,
              currentUserEmail: () => ctx.read<AuthProvider>().user?.email,
            );
            // Keep the subscription labels in the active language.
            final localeProvider = ctx.read<LocaleProvider>();
            sub.setLocale(_effectiveLocale(localeProvider));
            localeProvider.addListener(() {
              sub.setLocale(_effectiveLocale(localeProvider));
            });
            // Re-check account-derived access (e.g. the store-review Premium
            // override) whenever the signed-in user changes.
            final authProvider = ctx.read<AuthProvider>();
            authProvider.addListener(sub.refreshAccountAccess);
            sub.initialize();
            return sub;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final localeProvider = context.watch<LocaleProvider>();
          return MaterialApp.router(
            title: 'SpotVibe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              return _resolveLocale(localeProvider.locale, deviceLocale);
            },
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
          );
        },
      ),
    );
  }
}
