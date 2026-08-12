import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/notification_preferences_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/event.dart';
import '../models/user_event.dart';
import '../providers/notification_provider.dart';
import '../providers/notification_preferences_provider.dart';
import '../repositories/notification_preferences_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/create_event_provider.dart';
import '../providers/event_provider.dart';
import '../providers/personalization_provider.dart';
import '../providers/rsvp_provider.dart';
import '../providers/user_events_provider.dart';
import '../repositories/event_repository.dart';
import '../repositories/rsvp_repository.dart';
import '../repositories/user_event_repository.dart';
import '../screens/create_event_screen.dart';
import '../screens/creator_analytics_screen.dart';
import '../screens/creator_dashboard_screen.dart';
import '../screens/creator_pro_paywall_screen.dart';
import '../screens/event_map_screen.dart';
import '../services/event_expiry_service.dart';
import '../screens/onboarding_screen.dart';
import '../repositories/onboarding_repository.dart';
import '../screens/permission_prompt_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/events_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_events_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/user_event_detail_screen.dart';
import '../screens/saved_events_screen.dart';
import '../screens/venue_claim_screen.dart';
import '../providers/subscription_provider.dart';
import '../services/deep_link_service.dart';
import '../services/event_service.dart';
import '../services/ticketmaster_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/user_event_service.dart';

class AppRouter {
  static EventService _eventService(
    BuildContext context,
    EventRepository eventRepo,
  ) {
    return EventService(
      repository: eventRepo,
      ticketmaster: context.read<TicketmasterService>(),
    );
  }

  /// Build the router.  [initialLocation] is resolved at startup:
  ///  - `/permissions` on first-ever launch (permissions not yet asked)
  ///  - a stored pending deep link path if one was saved before permissions
  ///  - `/` for all subsequent normal launches
  static GoRouter build({String initialLocation = '/'}) {
    return GoRouter(
      initialLocation: initialLocation,
      // Redirect any unhandled navigation exceptions back to home.
      onException: (_, state, router) => router.go('/'),
      // Deep link redirect: if a link arrives pointing at an event page but
      // permissions haven't been shown yet, save the path and send the user
      // through the permission screen first.
      redirect: (context, state) async {
        final path = state.uri.toString();
        final isEventPath =
            path.startsWith('/event/') || path.startsWith('/user-event/');
        if (!isEventPath) return null;

        final permSvc = context.read<PermissionService>();
        final hasAsked = await permSvc.hasAskedBefore();
        if (hasAsked) return null; // permissions done — go straight to event

        // First install: save the path, then show onboarding.
        await DeepLinkService.savePendingLink(path);
        return '/onboarding';
      },
      routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          final permSvc = context.read<PermissionService>();
          final onboardingRepo = context.read<OnboardingRepository>();
          return OnboardingScreen(
            permissionService: permSvc,
            onboardingRepository: onboardingRepo,
          );
        },
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) {
          final permSvc = context.read<PermissionService>();
          return PermissionPromptScreen(permissionService: permSvc);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) {
          final notifProvider = context.read<NotificationProvider>();
          return ChangeNotifierProvider.value(
            value: notifProvider,
            child: const NotificationsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (context, state) {
          final prefsRepo =
              context.read<NotificationPreferencesRepository>();
          return ChangeNotifierProvider(
            create: (_) =>
                NotificationPreferencesProvider(repository: prefsRepo),
            child: const NotificationPreferencesScreen(),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final eventRepo = context.read<EventRepository>();
          final notifs = context.read<NotificationService>();
          final expiry = context.read<EventExpiryService>();
          final personalization = context.read<PersonalizationProvider>();
          return MultiProvider(
            providers: [
              Provider(create: (ctx) => _eventService(ctx, eventRepo)),
              ChangeNotifierProvider(
                create: (ctx) => EventProvider(
                  service: ctx.read<EventService>(),
                  notificationService: notifs,
                  expiryService: expiry,
                  personalizationProvider: personalization,
                )..loadEvents(),
              ),
            ],
            child: const EventsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) {
          final eventRepo = context.read<EventRepository>();
          final notifs = context.read<NotificationService>();
          final expiry = context.read<EventExpiryService>();
          return MultiProvider(
            providers: [
              Provider(create: (ctx) => _eventService(ctx, eventRepo)),
              ChangeNotifierProvider(
                create: (ctx) => EventProvider(
                  service: ctx.read<EventService>(),
                  notificationService: notifs,
                  expiryService: expiry,
                )..loadEvents(),
              ),
            ],
            child: const EventMapScreen(),
          );
        },
      ),
      // Top-level route so deep links work on cold start (no state.extra needed).
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          // In-app navigation passes the Event object via extra to avoid a
          // redundant async load. A cold-start deep link has no extra, so we
          // fall back to loading the event by ID from the repository.
          final eventExtra = state.extra as Event?;
          final eventRepo = context.read<EventRepository>();
          final rsvpRepo = context.read<RsvpRepository>();
          final notifs = context.read<NotificationService>();
          final auth = context.read<AuthProvider>();
          if (eventExtra != null) {
            return MultiProvider(
              providers: [
                Provider(create: (ctx) => _eventService(ctx, eventRepo)),
                ChangeNotifierProvider(
                  create: (ctx) => EventProvider(
                    service: ctx.read<EventService>(),
                    notificationService: notifs,
                  )..seedEvents([eventExtra]),
                ),
                ChangeNotifierProvider(
                  create: (_) => RsvpProvider(
                    repository: rsvpRepo,
                    eventId: eventExtra.id,
                    currentUserId: auth.user?.id ?? 'guest',
                  )..load(),
                ),
              ],
              child: EventDetailScreen(event: eventExtra),
            );
          }
          // Cold-start: load event by ID asynchronously.
          return _EventDeepLinkLoader(
            eventId: eventId,
            eventRepo: eventRepo,
            ticketmaster: context.read<TicketmasterService>(),
            rsvpRepo: rsvpRepo,
            notifs: notifs,
            auth: auth,
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/saved-events',
        builder: (context, state) {
          final eventRepo = context.read<EventRepository>();
          return ChangeNotifierProvider(
            create: (_) => EventProvider(
              service: _eventService(context, eventRepo),
              expiryService: context.read<EventExpiryService>(),
            )..loadEvents(),
            child: const SavedEventsScreen(),
          );
        },
      ),

      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/creator-pro-paywall',
        builder: (context, state) => const CreatorProPaywallScreen(),
      ),
      GoRoute(
        path: '/creator-dashboard',
        builder: (context, state) {
          final auth = context.read<AuthProvider>();
          if (!auth.isLoggedIn || auth.isGuest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final userEventRepo = context.read<UserEventRepository>();
          final service = UserEventService(repository: userEventRepo);
          return ChangeNotifierProvider(
            create: (_) => UserEventsProvider(
              service: service,
              creatorId: auth.user!.id,
            ),
            child: const CreatorDashboardScreen(),
          );
        },
      ),
      GoRoute(
        path: '/event-analytics/:id',
        builder: (context, state) {
          final event = state.extra as UserCreatedEvent;
          return CreatorAnalyticsScreen(event: event);
        },
      ),
      GoRoute(
        path: '/claim-venue',
        builder: (context, state) {
          final event = state.extra as Event;
          final revCat = context.read<RevenueCatService>();
          return ChangeNotifierProvider(
            create: (_) => SubscriptionProvider(service: revCat)..initialize(),
            child: VenueClaimScreen(event: event),
          );
        },
      ),
      GoRoute(
        path: '/my-events',
        builder: (context, state) {
          final auth = context.read<AuthProvider>();
          if (!auth.isLoggedIn || auth.isGuest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final userEventRepo = context.read<UserEventRepository>();
          final service = UserEventService(repository: userEventRepo);
          return ChangeNotifierProvider(
            create: (_) => UserEventsProvider(
              service: service,
              creatorId: auth.user!.id,
            ),
            child: const MyEventsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/create-event',
        builder: (context, state) {
          final auth = context.read<AuthProvider>();
          if (!auth.isLoggedIn || auth.isGuest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final userEventRepo = context.read<UserEventRepository>();
          final service = UserEventService(repository: userEventRepo);
          return MultiProvider(
            providers: [
              Provider(create: (_) => service),
              ChangeNotifierProvider(
                create: (_) => CreateEventProvider(
                  service: service,
                  creatorId: auth.user!.id,
                  creatorName: auth.user!.displayName,
                ),
              ),
            ],
            child: const CreateEventScreen(),
          );
        },
      ),
      GoRoute(
        path: '/edit-event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final auth = context.read<AuthProvider>();
          final userEventRepo = context.read<UserEventRepository>();
          final service = UserEventService(repository: userEventRepo);
          // Load event synchronously from repo — wrapped in FutureBuilder in the route
          return MultiProvider(
            providers: [
              Provider(create: (_) => service),
              ChangeNotifierProvider(
                create: (_) => CreateEventProvider(
                  service: service,
                  creatorId: auth.user?.id ?? 'user_1',
                  creatorName: auth.user?.displayName ?? 'Anonymous',
                ),
              ),
            ],
            child: _EditEventLoader(eventId: eventId, service: service),
          );
        },
      ),
      GoRoute(
        path: '/user-event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          final rsvpRepo = context.read<RsvpRepository>();
          final auth = context.read<AuthProvider>();
          final userEventRepo = context.read<UserEventRepository>();
          final service = UserEventService(repository: userEventRepo);
          return ChangeNotifierProvider(
            create: (_) => RsvpProvider(
              repository: rsvpRepo,
              eventId: 'user_$eventId',
              currentUserId: auth.user?.id ?? 'guest',
            )..load(),
            child: _UserEventDetailLoader(eventId: eventId, service: service),
          );
        },
      ),
    ],
    );
  }
}

/// Loads a curated [Event] by ID from [EventRepository] for cold-start deep links.
/// Shows a loading spinner while the async fetch is in progress, and redirects
/// to `/` with an error SnackBar if the event is not found.
class _EventDeepLinkLoader extends StatefulWidget {
  final String eventId;
  final EventRepository eventRepo;
  final TicketmasterService ticketmaster;
  final RsvpRepository rsvpRepo;
  final NotificationService notifs;
  final AuthProvider auth;

  const _EventDeepLinkLoader({
    required this.eventId,
    required this.eventRepo,
    required this.ticketmaster,
    required this.rsvpRepo,
    required this.notifs,
    required this.auth,
  });

  @override
  State<_EventDeepLinkLoader> createState() => _EventDeepLinkLoaderState();
}

class _EventDeepLinkLoaderState extends State<_EventDeepLinkLoader> {
  Event? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var event = await widget.eventRepo.getEventById(widget.eventId);
    event ??= await widget.ticketmaster.getEventById(widget.eventId);
    if (!mounted) return;
    if (event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event not found or no longer available.')),
      );
      context.go('/');
      return;
    }
    setState(() {
      _event = event;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MultiProvider(
      providers: [
        Provider(create: (_) => EventService(repository: widget.eventRepo)),
        ChangeNotifierProvider(
          create: (ctx) => EventProvider(
            service: ctx.read<EventService>(),
            notificationService: widget.notifs,
          )..seedEvents([_event!]),
        ),
        ChangeNotifierProvider(
          create: (_) => RsvpProvider(
            repository: widget.rsvpRepo,
            eventId: _event!.id,
            currentUserId: widget.auth.user?.id ?? 'guest',
          )..load(),
        ),
      ],
      child: EventDetailScreen(event: _event!),
    );
  }
}

/// Loads a user-created event from the repository and passes it to [UserEventDetailScreen].
class _UserEventDetailLoader extends StatefulWidget {
  final String eventId;
  final UserEventService service;

  const _UserEventDetailLoader({required this.eventId, required this.service});

  @override
  State<_UserEventDetailLoader> createState() => _UserEventDetailLoaderState();
}

class _UserEventDetailLoaderState extends State<_UserEventDetailLoader> {
  UserCreatedEvent? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final event = await widget.service.getEventById(widget.eventId);
    if (mounted) setState(() { _event = event; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_event == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Event not found.')));
    return UserEventDetailScreen(event: _event!);
  }
}

/// Helper widget to load an event from the repository and pass it to [CreateEventScreen] for editing.
class _EditEventLoader extends StatefulWidget {
  final String eventId;
  final UserEventService service;

  const _EditEventLoader({required this.eventId, required this.service});

  @override
  State<_EditEventLoader> createState() => _EditEventLoaderState();
}

class _EditEventLoaderState extends State<_EditEventLoader> {
  UserCreatedEvent? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final event = await widget.service.getEventById(widget.eventId);
    if (mounted) setState(() { _event = event; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_event == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Event not found.')));
    return CreateEventScreen(editingEvent: _event);
  }
}
