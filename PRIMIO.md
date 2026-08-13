# SpotVibe

## Overview
A local events discovery app where users browse upcoming events, RSVP (publicly or privately), see who else is attending, leave comments, and interact socially through friend requests and user blocking/reporting. Designed for community-driven engagement with a vibrant, modern aesthetic.

## User Event Creation
- Free users post events at no charge; up to **2 upcoming** events at a time (`kFreeUserActiveEventLimit = 2` in `pricing.dart`)
- Premium subscribers are exempt from the active-event limit — unlimited concurrent events
- Featured listing (`featuredWeekKey` = current ISO week) is a Premium perk, 1× per week; free events stay in the public feed without featured placement
- Each user-created event automatically gets a dedicated chat room keyed as `user_{eventId}` (ChatRepository removed — this is a legacy note; messaging has been removed)
- Event creators have admin rights: edit/delete from `MyEventsScreen` and `UserEventDetailScreen`; identity check is `auth.user.id == event.creatorId`
- `UserEventRepository` is app-global (registered in `main.dart`); `UserEventsProvider` and `CreateEventProvider` are route-scoped

## AI Moderation & Misconduct Security
- `AiModerationService` in `lib/services/ai_moderation_service.dart` — global `Provider`; rule/pattern engine; swap `moderateText()` for an HTTP call to upgrade to OpenAI Moderation API or Google Perspective API
- Two-tier content moderation: **rejected** (blocks submission) and **flagged** (warns but allows); **approved** passes silently
- Rejected categories: Hate Speech, Violence, Self-Harm, Sexual Content, Personal Information, **Harassment**, **Doxxing** (7 total)
- Flagged categories: Profanity, Spam, Contact Sharing (3 total)
- `moderateReport()` method on `AiModerationService` — lighter ruleset for report submission text; catches abusive reports before logging them
- **Strike system** (`MisconductService` + `MisconductRepository`): each rejected comment adds one strike; at `kStrikeThreshold = 3` the user is muted for `kMuteDuration = 24h`; muted users see `_MutedBanner` instead of the comment input with a countdown to unmute
- Strike counter shown inline: "Strike 2 of 3" appended to the rejection reason so users understand escalation
- **User reports** — `UserActionSheet` "Report User" opens `_UserReportSheet`: 8 category chips + optional 300-char reason field; reason is AI-moderated before logging; success shows confirmation screen
- **Event reports** — `QuickActionsSection` "Report this event" opens `_EventReportSheet`: 7 category chips + optional reason; same AI moderation + success screen flow
- Both report sheets are AI-moderated via `MisconductService.reportUser/reportEvent()` — abusive report text is rejected with an explanation banner
- `MisconductRepository` — in-memory store for strikes, mute expiry timestamps, `UserReport` and `EventReport` value objects; ready to swap for Supabase/Firebase backend
- `MisconductService` registered globally in `main.dart` alongside `MisconductRepository`; both depend on global `AiModerationService`

## Tech Stack & Key Decisions
- purchases_flutter (RevenueCat) for subscription management — entitlement ID is `pro`; API keys are placeholders in `revenue_cat_service.dart` (replace before release)
- RevenueCat is mobile-only — all calls in `RevenueCatService` are guarded with `kIsWeb` and `_initialized` checks so web never crashes
- Provider + ChangeNotifier for state — route-scoped providers keep memory lean and disposal automatic
- go_router for navigation — enables deep linking to event detail pages via `/event/:id`
- shared_preferences for dark mode persistence — lightweight key-value storage for theme preference
- Mock repositories simulate backend — all data access is behind repository interfaces ready for real API integration
- cached_network_image for event images — scraped URLs are loaded with proper caching and error fallbacks
- google_fonts (Plus Jakarta Sans) — modern, friendly typeface fitting the social/events personality

## Architecture
- Three-layer: UI → Providers → Services → Repositories → Models
- Repositories are app-global (stateless data access, shared across routes)
- Services + Providers are route-scoped: created in GoRoute builders, auto-disposed on navigation
- AuthProvider and ThemeProvider are app-global — they survive navigation changes
- EventProvider is re-created on home route visit to always show fresh data
- RsvpProvider is event-scoped, created per event detail route (both `/event/:id` and `/user-event/:id`)
- RsvpRepository is app-global (registered in `main.dart`); its in-memory maps persist for the session

## Conventions
- One provider per screen concern, wired in `app_router.dart` route builders
- Widgets in `widgets/common/` take all data via constructor params — never access providers
- Screen-specific widgets live in `widgets/events/`, `widgets/chat/` etc.
- New screens: add GoRoute in `app_router.dart`, wire providers in builder, create screen file
- All user interaction features (follow/unfollow, block, report) surface via `UserActionSheet` bottom sheet
- Event images come from URLs (simulating scraped content) loaded via CachedNetworkImage

## Personalization Engine

- **`UserBehaviorProfile`** (`lib/models/user_behavior_profile.dart`) — immutable model; three signal tiers: `categoriesAttended` (weight ×10), `categoriesSaved` (×4), `categoriesViewed` (×1); rolling average price + preferred days/times; full JSON serialization for SharedPrefs; `isWarm` threshold: ≥3 views OR ≥1 save before ranking is enabled
- **`PersonalizationRepository`** (`lib/repositories/personalization_repository.dart`) — SharedPrefs-backed; `loadProfile()`/`saveProfile()`/`clearProfile()`; all errors silenced, returns blank profile as fallback
- **`PersonalizationService`** (`lib/services/personalization_service.dart`) — pure stateless scoring engine; `scoreEvent()` applies 5 weighted factors: (1) category interest score, (2) +5 price match if ≤1.5× avg, (3) +0–10 proximity, (4) +3 time-of-day match, (5) +0–5 recency boost; `rank()` returns sorted event list
- **`PersonalizationProvider`** (`lib/providers/personalization_provider.dart`) — global `ChangeNotifier` registered in `main.dart`; exposes `recordView(event)`, `recordSave(event)`, `recordAttend(event)`; `isActive` bool drives banner visibility; `topCategories` list feeds the banner copy; `reset()` wipes all signals
- **Feed integration**: `EventProvider` accepts optional `PersonalizationProvider personalizationProvider`; after `getUpcomingEvents()` resolves and filters, calls `_personalization.rank()` when `!sortByDistance && _personalization != null`; distance sort takes priority over personalization to respect explicit user intent
- **Tracking hooks**: view fires in `_EventsList.onTap` (before `context.push`); save fires in `EventProvider.toggleBookmark()` when `updated.isBookmarked`; attend hook is on `PersonalizationProvider.recordAttend()` — wire into RsvpProvider RSVP confirmation when ready
- **`PersonalizationBanner`** (`lib/widgets/common/personalization_banner.dart`) — slide+fade animated strip shown in `EventsScreen` when `personalization.isActive && searchQuery.isEmpty && activeFilterCount == 0 && !sortByDistance`; tapping opens an explanation sheet with top categories + "Reset my preferences" CTA
- **"Cold" vs "Warm" profile**: banner and re-ranking are suppressed until `isWarm` is true (≥3 views or ≥1 save) — avoids premature re-ordering that would confuse new users

## Share Functionality

- **Share entry point**: `QuickActionsSection` Share button calls `showEventShareSheet()` from `lib/widgets/events/event_share_card.dart`
- **Share options sheet** (`_ShareSheet`): three actions — "Share as Card" (image capture via `RenderRepaintBoundary`, shared via `Share.shareXFiles`), "Share with Link" (rich text message via `Share.share`), "Copy Link" (clipboard tile showing the URL inline)
- **Rich share message**: built by `DeepLinkService._buildShareMessage()` — "Check out [title]! + 📅 date + 📍 venue + Branch link"; Branch link resolved via `DeepLinkService.branchEventLink()`, falls back to plain HTTPS
- **Share card graphic** (`_ShareCardGraphic`): 1.91:1 Open Graph ratio; event image background + left-to-right dark gradient; brand pill top-left; category chip + title + date + venue + cost badge on left; `spotvibe.app` watermark bottom-right; captured at `pixelRatio: 3.0`
- **Web guard**: image capture button replaced by an info tile; "Share with Link" still available on web via `Share.share`; "Copy Link" always available; `shareEvent()` in `DeepLinkService` falls back to clipboard on web
- **`ShareAnalyticsService`** (`lib/services/share_analytics_service.dart`): in-memory tracker recording `(eventId, category, method)` per share; `ShareMethod` constants: `card`, `link`, `clipboard`, `instagramStory`; `_sendToBackend()` stub ready for Firebase Analytics wiring
- **`DeepLinkService.shareEvent()`** upgraded: accepts optional `eventDateTime`/`eventLocation`; calls `branchEventLink()` for attributed deep link; uses `Share.share()` on mobile; `copyEventLink()` is a new lightweight clipboard-only fallback

## Instagram Story Sharing
- "Story" button lives in the action row (`EventDetailScreen`) and SliverAppBar (`UserEventDetailScreen`) — opens `_StorySheet` bottom sheet via `showInstagramStorySheet()` in `lib/widgets/events/story_card.dart`
- Story card preview is a 9:16 `AspectRatio` wrapped in `RepaintBoundary`; captured via `RenderRepaintBoundary.toImage(pixelRatio: 3.0)` → PNG bytes → saved to `Directory.systemTemp` → shared via `share_plus` `Share.shareXFiles()`
- Two actions in the sheet: **"Save & Share Story Card"** (native OS share sheet — user picks Instagram from the list) and **"Open Instagram"** (launches `instagram://app` via `url_launcher`, fallback to `https://www.instagram.com`)
- Web guard: on `kIsWeb` the sheet shows a message directing users to the mobile app instead of the share buttons
- `share_plus: ^10.1.4` added to `pubspec.yaml` PRIMIO_ADDITIONS; `path_provider` was already present but not needed since `Directory.systemTemp` (`dart:io`) is used directly
- `formatStoryDate(DateTime)` helper in `story_card.dart` formats dates for the story overlay — import and use in both detail screens

## Deep Links
- Deep link base URL is `https://vibely.app` — curated events: `/event/{id}`, user-created events: `/user-event/{id}`
- `DeepLinkService.shareEvent()` copies the link to the clipboard and shows a SnackBar; `pathFromUri()` converts both `https://vibely.app/…` and `vibely://…` URIs to GoRouter paths
- Both `/event/:id` and `/user-event/:id` are **top-level** GoRoutes (not nested under `/`) so they work on cold-start
- Cold-start curated event deep links use `_EventDeepLinkLoader` (in `app_router.dart`); user-event deep links use `_UserEventDetailLoader`; in-app navigation passes `Event` via `state.extra` to skip the async load
- **Runtime deep link listener**: `app_links: ^6.3.4` — `_SpotVibeAppState.initState()` subscribes to `AppLinks().uriLinkStream`; on every incoming URI it calls `DeepLinkService.pathFromUri()` and `_router.go(path)`; web-guarded with `kIsWeb`
- **Cold-start URI priority** (resolved in `main()` before `runApp`): (1) `AppLinks().getInitialLink()` from OS, (2) stored pending link from `DeepLinkService.consumePendingLink()`, (3) `/permissions` on first launch, (4) `/` for returning users
- **First-install deep link flow** (deferred): `AppRouter.build()` has a `redirect` callback — if an event path arrives but permissions haven't been shown, it saves the path via `DeepLinkService.savePendingLink()` and sends the user to `/permissions`; `PermissionPromptScreen._finish()` calls `consumePendingLink()` and restores the event path after `markAsked()`
- **Pending link storage**: `SharedPreferences` key `spotvibe_pending_deep_link`; save/consume are atomic (consume removes immediately after reading)
- Android: `autoVerify` HTTPS intent-filters cover both path patterns + `spotvibe://` custom-scheme filter for `app_links`; requires `/.well-known/assetlinks.json` on `spotvibe.app` before App Links verification passes in production
- iOS: `CFBundleURLTypes` registers `spotvibe://`; `FlutterDeepLinkingEnabled = true` in `Info.plist` ensures GoRouter receives the initial URI on cold start; for Universal Links add `com.apple.developer.associated-domains` (`applinks:spotvibe.app`) in Xcode entitlements
- **Truly deferred deep links** (app not yet installed): handled by `BranchService` in `deep_link_service.dart` using `flutter_branch_sdk: ^6.7.0`; Branch stores the link server-side on click and delivers it to `FlutterBranchSdk.initSession()` on first post-install open; `BranchService.getInitialLink()` is the highest-priority cold-start source in `main()`, above `app_links`
- **Branch key placeholders**: `key_live_REPLACE_WITH_BRANCH_LIVE_KEY` and `key_test_REPLACE_WITH_BRANCH_TEST_KEY` appear in both `AndroidManifest.xml` and `Info.plist`; replace with real keys from the Branch dashboard before release; also replace `REPLACE_WITH_BRANCH_URI_SCHEME` and `REPLACE_WITH_BRANCH_APP_DOMAIN` in both files
- **Branch short links**: `DeepLinkService.branchEventLink()` generates Branch short URLs for sharing (falls back to plain HTTPS link on web or if Branch is unavailable); wire this into `shareEvent()` callers when ready to replace clipboard-only sharing with Branch-attributed links
- **Runtime Branch stream**: `BranchService.linkStream` wraps `FlutterBranchSdk.initSession()` and is subscribed in `_SpotVibeAppState.initState()` alongside `app_links.uriLinkStream`; both listeners call `_router.go(path)` so either source can navigate the running app

## Creator Tiers

- **Free creators**: up to **2 upcoming one-time events**, basic page (title/description/photo/location/time), appears in public feed — **no charge**; limit enforced in `CreateEventScreen` via `canPostAnotherFreeEvent`
- **Premium** (`kPremiumMonthlyPrice = 12.99` after a **7-day free trial**): recurring events, featured placement 1×/week, live analytics, custom branding, contact button, no ads, claims after verify; first 25 venues lock **$9.99/month** (`kFoundingMonthlyPrice`); `isCreatorPro = true` on `UserCreatedEvent` (field name preserved); exempt from the free-event cap
- Launch is monthly only. Configure the same 7-day intro and optional founding product in App Store / Play / RevenueCat so store charges match the in-app copy.
- **Paywalls**: `/premium-paywall` → `CreatorProPaywallScreen` (teal); `/premium-plus-paywall` → `PremiumPlusPaywallScreen` (amber-red); `/paywall` redirects to `/premium-paywall`
- **Email list**: `/email-list/:id` → `EmailListScreen` — shows collected attendee emails with copy-to-clipboard; attendee opt-in via `_EmailOptInBanner` in `UserEventDetailScreen` (UI-only, no backend wired)
- **Premium Dashboard** at `/creator-dashboard` (`CreatorDashboardScreen`) — shows all `isCreatorPro` events (including Plus); Plus events show shares + new-viewers sentence + email list button; Plus badge displayed in card header
- Three demo events pre-seeded for `user_1`: `demo_pro_1` (Trivia Night, Premium), `demo_pro_2` (Indie Film Screening, Premium), `demo_plus_1` (Downtown Food & Music Festival, Premium Plus)
- Analytics at `/event-analytics/:id` — Plus events show additional Shares + New Users stat row and a traffic source linear progress breakdown card
- `_PremiumFeaturesSection` + `_PremiumPlusFeaturesSection` in `CreateEventScreen` — each shows upgrade card when locked; Plus section exposes email list and cross-promotion toggles when unlocked
- `MyEventsScreen` shows `_EventAnalyticsRow` (analytics) and `_EmailListRow` (email list) beneath Premium / Plus event cards; shows both upgrade banners at bottom when user has no events of that tier
- `creatorTeal` / `creatorTealLight` — Premium surfaces; `premiumPlus` / `premiumPlusLight` (amber-red) — Premium Plus surfaces; `proGold` / `proGoldLight` — reminder notification icons only

## Event Map with Clustering
- `EventMapScreen` at `/map` — full-screen `FlutterMap` (OpenStreetMap tiles, no API key) accessible via the map icon in the `EventsScreen` header
- Clustering via `flutter_map_marker_cluster: ^1.4.0`; markers within 60px radius merge into a purple `_ClusterBubble` showing the count (e.g. "10"); clusters disperse as the user zooms past zoom level 14
- Single-event markers are `_EventMarkerDot` — a circular dot coloured by `EventSource.brandColor` with the source icon inside; tapping shows a `_EventMapPreview` bottom sheet with a "View Event" button that pushes `/event/:id`
- Only events with non-zero lat/lng appear on the map; events with `latitude == 0 && longitude == 0` are silently skipped
- Every hardcoded event in `event_repository.dart` now has real coordinates; the deterministic `_generateEventsForLocation` generator also assigns jittered coordinates (±0.01°, ~1 km) using `_kCityCoords` city-centre map added at the top of the file
- `flutter_map: ^7.0.2`, `flutter_map_marker_cluster: ^1.4.0`, `latlong2: ^0.9.1` added to `pubspec.yaml` PRIMIO_ADDITIONS
- `/map` route wired in `app_router.dart` with its own route-scoped `EventService` + `EventProvider` (reads global `EventExpiryService`) so the map feed also auto-expires

## Event Expiry (Cron-style)
- `EventExpiryService` in `lib/services/event_expiry_service.dart` — global `ChangeNotifier` backed by `Timer.periodic(Duration(minutes: 1))`; registered as a `ChangeNotifierProvider` in `main.dart` global MultiProvider
- `EventProvider` accepts an optional `EventExpiryService expiryService` in its constructor; on init it calls `_expiry?.addListener(_onExpiryTick)` and removes the listener in `dispose()`; each tick calls `loadEvents()` which already filters `e.dateTime.isAfter(DateTime.now())` — no separate archive flag needed
- Both the `/` (home feed) and `/map` route builders pass `context.read<EventExpiryService>()` into `EventProvider` so both feeds stay future-only in real time
- `forceExpiry()` public method on `EventExpiryService` triggers an immediate sweep (useful for testing)

## Add to Calendar
- `AddToCalendarButton` in `lib/widgets/events/add_to_calendar_button.dart` — full-width `OutlinedButton.icon` placed on both `EventDetailScreen` (below the 3-button action row) and `UserEventDetailScreen` (below the info rows, above the organizer Divider)
- iOS → opens Apple Calendar via `add_2_calendar`; Android → opens Google Calendar / device picker via `add_2_calendar`; Web → constructs a Google Calendar `render?action=TEMPLATE` URL and opens it via `url_launcher`
- End time defaults to `startTime + 2 hours` since neither model stores an explicit end time
- `add_2_calendar: ^3.0.1` added to `pubspec.yaml` PRIMIO_ADDITIONS
- Label adapts per platform: "Add to Apple Calendar" on iOS, "Add to Google Calendar" on Android and Web

## Venue Claim Feature
- `ClaimVenueBanner` in `lib/widgets/events/claim_venue_banner.dart` — subtle banner at the bottom of `EventDetailScreen` (auto-generated events only, not `UserEventDetailScreen`)
- Tapping navigates to `/claim-venue` passing the `Event` object as `state.extra`
- `/claim-venue` uses the global `SubscriptionProvider`
- Everyone sees the verify form first. First approved claim is free. Later claims need Premium to unlock edits.
- Work-domain emails auto-approve; personal inboxes stay pending for review. Claims persist to `event_claims`.

## Notification System

- Three notification types via `NotificationType` enum: `reminder`, `newEvents`, `social`; `SocialNotificationKind` sub-types: `comment`, `friendRsvp`, `friendRequest`, `interested`
- `NotificationRepository` — in-memory store with 10 pre-seeded notifications (3 reminders, 3 new-events, 4 social); exposes `add/markRead/markAllRead/remove`
- `NotificationProvider` — global `ChangeNotifier` wrapping the repo; registered in `main.dart` MultiProvider; drives the live bell badge in `EventsScreen` and the full inbox in `NotificationsScreen`
- `NotificationPreferencesRepository` — `SharedPreferences`-backed settings: `eventReminders`, `weeklyDigest`, `socialComments`, `socialFriendRsvp`, `socialFriendRequests`, and per-category toggles (key prefix `notif_pref_cat_`); all default to `true`
- `NotificationPreferencesProvider` — route-scoped; created in the `/notification-preferences` route builder; loads async from `SharedPreferencesRepository` on init; `kNotificationCategories` list of 10 categories lives in `notification_preferences_provider.dart`
- `NotificationsScreen` — 4-tab (`All / Reminders / Events / Social`) screen; each tab shows unread count badge; tiles are swipe-to-dismiss; tap navigates to `routePath` if set; "Mark all read" AppBar action; gear icon → `/notification-preferences`
- `NotificationPreferencesScreen` — three sections: Event Reminders (toggle), New Events (weekly digest toggle + category `FilterChip` grid), Social (3 toggles)
- `NotificationService` new methods: `notifyEventStartingSoon`, `notifyEventTomorrow`, `notifyEventTonight` (reminder trio); `notifyNewEventsNearby`, `notifyWeeklyDigest` (discovery); `notifyNewComments`, `notifyFriendRsvp` (social)
- Bell icon in `EventsScreen` shows a live red badge (`colors.error`) with count via `context.watch<NotificationProvider>().unreadCount`; badge hidden at 0
- Push (device) notifications still use `awesome_notifications` channels; in-app inbox is separate — both are updated in parallel when `NotificationService` methods are called

## First-Time Onboarding
- `OnboardingScreen` at `/onboarding` — 4-page `PageView` shown once on first launch: **Welcome** (animated hero + feature pills), **Permissions** (location + notifications), **Interests** (12-category chip grid), **Ready** (animated confirmation)
- `OnboardingRepository` in `lib/repositories/onboarding_repository.dart` — SharedPrefs-backed; stores `spotvibe_onboarding_done` (bool) and `spotvibe_interests` (comma-separated categories); registered as a global `Provider` in `main.dart`
- First-launch detection: `main()` checks `PermissionService.hasAskedBefore()` — if false, also checks `OnboardingRepository.isOnboardingDone()`; sends user to `/onboarding` unless already done
- `OnboardingScreen._finish()` saves interests → calls `onboardingRepository.markDone()` + `permissionService.markAsked()` → restores pending deep link or goes to `/`
- Deep-link redirect in `AppRouter.build()` now points first-install users to `/onboarding` (was `/permissions`); `/permissions` route is preserved for returning users who navigate there
- `EventProvider.setInitialInterests(List<String>)` maps interest labels to known categories and calls `selectCategory()` so the feed is pre-filtered on first open; called by consumers after onboarding completes (wire into `/` route builder when interests are loaded at startup)
- 12 interest options: Music, Sports, Food & Drink, Arts, Nightlife, Comedy, Community, Tech, Fitness, Family, Outdoor, Film — each with a Material icon; defined as `_kInterests` const list in `onboarding_screen.dart`
- Skip at any step calls `_finish()` directly — saves whatever state exists (empty interests = show all); users are never blocked from entering the app

## Search & Distance System
- `LocationService` in `lib/services/location_service.dart` — wraps `geolocator: ^13.0.2`; `getCurrentLocation()` returns `({double lat, double lng})?`; web-guarded (returns null on `kIsWeb`); handles permission request flow
- `EventProvider` holds `_userLat`/`_userLng`/`_sortByDistance`; `setUserLocation(lat, lng)` stores GPS + enables distance sort + reloads; `clearUserLocation()` resets; `distanceFor(Event)` returns haversine miles or null; `hasUserLocation` bool
- `EventService.getUpcomingEvents()` accepts `userLat`/`userLng`/`sortByDistance` — when GPS is present: filters by `searchRadius` miles (skipping events with lat==lng==0), then sorts by ascending distance when `sortByDistance=true`
- Haversine helper `_haversineDistanceMiles()` lives as a private top-level function in both `event_provider.dart` and `event_service.dart` (duplication intentional — no shared math util file)
- `EventCard` accepts optional `distanceMiles` — renders a purple `primaryContainer` chip with `Icons.near_me_rounded` and "X.X mi" next to the location row; chips <0.1 mi show "<0.1 mi"
- `SearchHeader` accepts `onUseMyLocation` callback + `isUsingMyLocation` bool — shows `Icons.near_me_outlined`/`Icons.near_me_rounded` suffix button in the area field; active state tints field border and fill
- `_SearchResultsHeader` in `EventsScreen` — shows "N results for 'query'" strip when keyword search is active; includes a sort toggle (By date ↔ Nearest first) only when `hasUserLocation` is true
- **Auto-location on startup**: `_EventsScreenState.initState()` calls `_autoApplyLocation()` via `addPostFrameCallback`; checks `LocationService.hasPermission()` first (never shows OS dialog silently), then calls `getCurrentLocation()` and `eventProvider.setUserLocation()` — feed sorts by distance automatically on every open when permission is already granted
- `_requestUserLocation()` in `_EventsScreenState` — manual tap path; calls `LocationService`, shows SnackBar on failure; tapping again when location is active calls `clearUserLocation()`; also triggers the OS permission dialog for first-time users

## Event Detail Page
- `AttendeesSection` now has a `_SocialProofHeader` at the top — overlapping 36px avatar circles (first 5, `AppTheme.borderSelected` white border gap) + a `+N` overflow bubble in `primaryContainer` + "X people are going / Be part of the experience" copy; existing name grid renders below it unchanged
- `PracticalDetailsSection` (new file `widgets/events/practical_details_section.dart`) — Practical Info card with coloured icon squares for: Weather, Parking, Duration (derived from category), Age Restriction (derived from category+cost heuristics; only shown when applicable), Accessibility; no new model fields needed
- `QuickActionsSection` (new file `widgets/events/quick_actions_section.dart`) — replaces the old 3-button row + `AddToCalendarButton`; shows 4 icon-tile quick actions (Calendar opens a bottom sheet with `AddToCalendarButton`, Directions, Share, Story) + full-width `AddToCalendarButton` + a subtle `TextButton.icon` "Report this event" link with `colors.error` styling
- `SimilarEventsSection` (new file `widgets/events/similar_events_section.dart`) — horizontal 160×200 card list filtered by same `category`, excludes current event, reads from `EventProvider`; hides itself when empty; each card taps to `context.push('/event/:id')`
- Layout order in `EventDetailScreen`: Category+Cost → Title → Info card → **Quick Actions** → **Practical Details** → Counter row → RSVP → About → Organizer → ClaimVenueBanner → AttendeesSection → **Similar Events** → Comments

## Empty States & Error Handling
- `EmptyStateView` in `widgets/common/empty_state_view.dart` — animated (scale + fade entrance) with `EmptyStateVariant` enum driving per-state gradient icon bg, icon colour, and CTA icon; supports optional `secondaryActionLabel`/`onSecondaryAction` as a `TextButton`
- Six variants: `generic` (purple), `filtersTooStrict` (purple/secondary), `noEventsNearby` (amber), `noLocation` (amber/orange), `apiError` (red error), `noSavedEvents` (teal)
- `_EventsList` in `events_screen.dart` picks the correct variant via a 6-case decision tree in priority order: loading spinner → API error (`apiError`) → active filters/search + empty (`filtersTooStrict`) → area search + empty (`noEventsNearby`, "Increase Radius" opens `FilterSheet`) → no GPS + empty (`noLocation`, "Enable Location" calls `_requestUserLocation()` via `findAncestorStateOfType`) → generic fallback
- API error state shows a secondary "View Saved Events" CTA that pushes `/saved-events`; `noLocation` shows a secondary "Browse All Events" CTA; `noEventsNearby` shows a secondary "Clear Location" CTA
- `SavedEventsScreen` at `/saved-events` — reads `eventProvider.events.where((e) => e.isBookmarked)`; shows count badge in AppBar when bookmarks exist; shows `noSavedEvents` empty state with "Explore Events" CTA that calls `context.go('/')`; "Saved Events" tile in `ProfileScreen` navigates here
- `/saved-events` route in `app_router.dart` creates its own route-scoped `EventProvider` + `EventService` (same pattern as `/map`)

## Pagination

- **`PaginatedEventsList`** (`lib/widgets/common/paginated_events_list.dart`) — `StatefulWidget` that slices `eventProvider.events` into pages of `kEventsPerPage = 15`; replaces the raw `ListView.builder` previously in `_EventsList`
- **Count banner** (`_EventCountBanner`) — shows "Showing 1–15 of 47 events" or "Showing all 12 events" when ≤15 results; always visible above the cards
- **`_PaginationBar`** — sticky bottom bar with Previous / Next `_NavButton`s + "Page N of M" label + animated `_PageDots` row (dots only rendered when ≤7 pages, otherwise label alone suffices)
- **Auto-reset**: `didUpdateWidget` compares event list identity via ID array; resets `_currentPage = 0` whenever the list changes (new filter, category, search, or fresh load) — users never land mid-page after filtering
- **Navigation callback**: `onEventTap(event, globalIndex)` propagates to `_EventsList` in `events_screen.dart` which handles go_router push + personalization view tracking; `PaginatedEventsList` itself has no router dependency
- **`_EventsList` in `events_screen.dart`** — unchanged for empty-state routing logic; its `ListView.builder` case is now `PaginatedEventsList(...)`; `event_card.dart` import removed from screen (now lives in the paginated widget)

## AI Event Assistant
- `EventAssistantService` — stateless NLP engine that parses natural language queries against the full event list; detects category, price, date/time, city, and keyword intents; returns up to 5 matching events sorted by date
- `EventAssistantProvider` — route-scoped `ChangeNotifier`; manages chat message list, typing state, and cached event list; `initialize()` fetches all events once for fast local querying
- Chat screen at `/assistant` — message bubbles, typing indicator with bouncing dots, quick suggestion chips (hidden after first message), event suggestion tiles with date badge + tap-to-navigate
- Entry point: sparkle icon button (`Icons.auto_awesome_rounded`) in `EventsScreen` header row, tinted `colors.primary`
- Intent categories: category (12 types), price (free/under-X/cheap), time (today/tonight/tomorrow/weekend/this-week/next-week), location (matched against event cities), keyword fallback on title/description/tags
- All widgets in `lib/widgets/assistant/` as separate public classes: `AssistantMessageBubble`, `UserMessageBubble`, `TypingIndicator`, `AssistantInputBar`, `SuggestionChipsRow`

## Key Patterns & Gotchas
- **Event feed architecture (critical):** Triple-API: (1) ~62 curated hardcoded events always present; (2) Ticketmaster — concerts/sports/arts (live key); (3) PredictHQ — 500+ aggregated sources (live key); (4) Eventbrite — community/fitness/workshop events (live key). All three APIs run **concurrently** via `Future.wait` in `EventRepository`. Results merged and deduplicated by `_merge()`. Yelp API is not used.
- **API keys**: Ticketmaster (`_kTicketmasterApiKey` in `ticketmaster_service.dart`, live); PredictHQ (`_kPredictHqToken` in `predicthq_service.dart`, live); Eventbrite (`_kEventbriteToken` in `eventbrite_service.dart`, live).
- **API deduplication**: curated=`evt_*`, Ticketmaster=`tm_*`, PredictHQ=`phq_*`, Eventbrite=`eb_*`. `_merge()` deduplicates by ID — curated events always take precedence.
- **EventSource enum**: 8 values — `facebook`, `instagram`, `twitter`, `google`, `ticketmaster`, `predicthq`, `eventbrite`, `local`. `yelp` has been removed. Any exhaustive switch on `EventSource` must handle all 8 cases.
- All curated events are real and verifiable: community events reference real venue types; stadium events (IDs `evt_stad_001`–`evt_stad_030`) reference real artists on real current tours and real sports matchups — all dates are relative (today + daysOffset) so they stay permanently upcoming
- Stadium events span El Paso County Coliseum, Southwest University Park, MSG, Crypto.com Arena, United Center, Toyota Center, AT&T Stadium (Arlington TX), Moody Center, Kaseya Center, loanDepot park, Bridgestone Arena, Chase Center, Oracle Park, Climate Pledge Arena, Coors Field, State Farm Arena, TD Garden, Gillette Stadium, Wells Fargo Center, T-Mobile Arena, Moda Center, Smoothie King Center, Capital One Arena, Frost Bank Center
- AT&T Stadium events use `city: 'Arlington'` (not `'Dallas'`); Gillette Stadium uses `city: 'Foxborough'`
- `_kCityCoords` and `_coordsForCity()` helper remain at the top of the file for map coordinate lookup
- Search radius lives in `EventProvider._searchRadius` (default 25 mi; 100 = "Any distance") — set via `setSearchRadius()` or `applyFilters(radius:)`; reset to 25.0 by `clearFilters()`; radius filter only runs when user has GPS coords
- Haversine distance filtering runs inside `EventService.getUpcomingEvents()` using real event lat/lng coordinates; events with lat==0 && lng==0 are kept but sorted last (not dropped)
- `FilterQuickChips` in `widgets/common/filter_quick_chips.dart` — Airbnb-style horizontal chip row always visible below the category chips; shows Date / Price / Time / Sources chips with active (filled primary) vs inactive (outlined) state; a **"Clear all"** chip prepends the row whenever `activeFilterCount > 0`; tapping any non-clear chip opens `FilterSheet.show()`; tapping Clear all calls `eventProvider.clearFilters()`
- `SearchHeader` autocomplete: `onSuggestionsRequest` callback (optional `List<String> Function(String)`) feeds a `CompositedTransformFollower` overlay (`_AutocompleteDropdown`) anchored via `LayerLink` to the keyword field; overlay appears on text change, hides on blur/submit/clear; `_EventsScreenState._buildSuggestions()` returns up to 6 matches from event titles then category names
- `FilterSheet` is a `DraggableScrollableSheet` with five sections: **Date** (preset chips: all/today/tomorrow/this_weekend/this_week/custom + custom date pickers when selected), **Price** (all/free/under_20/under_50), **Time of Day** (all/morning/afternoon/evening/night), **Distance** slider (5–100 mi), **Location** text field, **Event Sources** chips
- Filter state in `EventProvider`: `filterDate` (preset string), `filterPrice`, `filterTime` — alongside legacy `filterDateFrom/To`, `filterCostType`; `activeFilterCount` counts each non-default value; `applyFilters()` accepts all six filter axes
- `EventService.getUpcomingEvents()` applies date presets (today/tomorrow/this_weekend/this_week) as concrete `DateTime` range math; price tiers map to `e.cost` comparisons; time-of-day slots map to `e.dateTime.hour` ranges (morning 6–12, afternoon 12–17, evening 17–21, night 21–6)
- `kDatePresets`, `kPriceOptions`, `kTimeSlots` constant lists in `filter_sheet.dart` define the chip data; icons come from `Icons.*` and are optional on `_FilterChip`
- RSVP privacy: `RsvpEntry.isPrivate = true` hides name from `AttendeesSection` but still increments `totalRsvpCount`; private entries shown as a "+N private" lock tile
- Messaging is fully removed — `chat_message.dart`, `chat_provider.dart`, `chat_repository.dart`, `chat_service.dart` are deleted; no `/messages` route exists; `ChatRepository` is removed from `main.dart`
- `CommentSection`, `RsvpButton`, and `AttendeesSection` are provider-aware widgets in `widgets/events/` — they read `RsvpProvider` directly; do NOT move them to `widgets/common/`

## Follow System
- **`FollowRepository`** (`lib/repositories/follow_repository.dart`) — in-memory follow graph; `follow/unfollow/isFollowing/followerCount/followingCount/getFollowers/getFollowing`; seeded: `user_1` follows `user_2`, `user_3`, `user_4`, `organizer_1`
- **`FollowProvider`** (`lib/providers/follow_provider.dart`) — global `ChangeNotifier` in `main.dart`; `toggleFollow(currentUserId, targetId)` returns new bool state; `isFollowing()`, `followerCount()`, `followingCount()` consumed by UI
- **`UserActionSheet`** — "Follow / Unfollow" replaces "Add Friend"; callers pass `isFollowing` bool + `onToggleFollow` callback; `CommentSection` and `_OrganizerRow` both call `FollowProvider.toggleFollow()` with a SnackBar confirmation
- **`FollowStatsRow`** (`lib/widgets/common/follow_stats_row.dart`) — displays Followers / Following counts with K/M abbreviation; shown on `ProfileScreen` between email and Pro tile
- **ProfileScreen changes** — Messages tile removed; Friends tile replaced by `FollowStatsRow` pulling live counts from `FollowProvider`; `context.watch<FollowProvider>()` used so counts update reactively

## Media Attachments
- `image_picker: ^1.1.2` added — cross-platform (Android, iOS, Web); used for picking images from camera/gallery and videos from gallery
- `attachedImagePaths` + `attachedVideoPaths` (`List<String>`) fields on `UserCreatedEvent` — store local XFile paths; defaults to empty lists so all existing events are unaffected
- `MediaAttachmentSection` in `lib/widgets/create_event/media_attachment_section.dart` — self-contained widget: image grid (up to 8) with 3-column thumbnails + remove buttons; video list (up to 2) with file-name tiles; per-action `_PickerChip` buttons; web-guarded (camera chip hidden, gallery uses single-pick on web)
- Android permissions added: `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `CAMERA`, `READ_EXTERNAL_STORAGE` (max SDK 32 for Android ≤12 fallback)
- iOS plist keys added: `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`
- `_LocalMediaGallery` widget in `user_event_detail_screen.dart` — shows attached images as a tappable 3-column grid (fullscreen dialog on tap) and attached videos as play-tile rows; rendered before the YouTube/Vimeo `_VideoSection`
- Cover Image URL and Video URL text fields preserved in Create Event as a "paste a URL" fallback; they now appear after the media section under the same Extras heading
- **No backend yet:** picked file paths are stored in-memory on the model; wire a real storage upload (e.g. Firebase Storage or Supabase Storage) before persisting to a production backend

## Design System
- Vibrant purple primary (#6C5CE7) with teal accent for free events — energetic yet approachable for a social events app
- Plus Jakarta Sans for all typography — modern geometric sans-serif with excellent readability
- Soft elevation via subtle borders + box shadows rather than Material elevation for a cleaner look
- 8px spacing grid with generous whitespace; 16px large radius cards for friendly, modern feel
- Category-to-gradient mapping lives in `EventImagePlaceholder._gradientsForCategory()` — extend it when adding new event categories
- Each `EventSource` has its own brand color used consistently in `SourceBadge`, `FilterSheet` source chips, and `EventDetailScreen` attribution row
