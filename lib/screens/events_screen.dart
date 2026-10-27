import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/el_paso_events.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/personalization_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/event_service.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';
import '../widgets/common/ad_banner.dart';
import '../widgets/common/category_chips.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/event_card_skeleton.dart';
import '../widgets/common/guided_tour.dart';
import '../widgets/common/paginated_events_list.dart';
import '../widgets/common/app_icon_mark.dart';
import '../widgets/common/spotvibe_logo.dart';
import '../widgets/events/ai_event_search_assistant.dart';
import '../widgets/events/filter_sheet.dart';
import '../widgets/events/home_discovery_hero.dart';
import '../widgets/events/search_header.dart';

/// Below this window height (logical px) the home screen switches to its
/// compact layout: side navigation rail in landscape and no ad upsell row.
const double _kCompactHeight = 480;

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _areaController = TextEditingController();
  final _keywordController = TextEditingController();
  final _pageController = FeedPageController();
  bool _searchOpen = false;
  final _locationService = LocationService();
  bool _fetchingLocation = false;

  // Guided-tour target keys (stable across rebuilds).
  final GlobalKey _tourKeyHeader = GlobalKey();
  final GlobalKey _tourKeySearch = GlobalKey();
  final GlobalKey _tourKeyFilter = GlobalKey();
  final GlobalKey _tourKeyCategories = GlobalKey();
  final GlobalKey _tourKeyCard = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Permission can be granted during onboarding before this screen is built.
    // Resolve coordinates once without prompting again, then reload the feed
    // with the user's actual nearby area.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _requestUserLocation(
          requestPermission: false,
          clearWhenActive: false,
          showFailure: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    _areaController.dispose();
    _keywordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _buildSuggestions(String query, EventProvider provider) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final seen = <String>{};
    final results = <String>[];

    for (final e in provider.events) {
      if (results.length >= 6) break;
      final t = e.title;
      if (t.toLowerCase().contains(q) && seen.add(t)) {
        results.add(t);
      }
    }

    for (final cat in provider.categories) {
      if (results.length >= 6) break;
      if (cat != 'All' && cat.toLowerCase().contains(q) && seen.add(cat)) {
        results.add(cat);
      }
    }

    return results;
  }

  Future<void> _requestUserLocation({
    bool requestPermission = true,
    bool clearWhenActive = true,
    bool showFailure = true,
  }) async {
    if (_fetchingLocation) return;
    final eventProvider = context.read<EventProvider>();

    if (eventProvider.hasUserLocation) {
      if (clearWhenActive) eventProvider.clearUserLocation();
      return;
    }

    setState(() => _fetchingLocation = true);
    final coords = await _locationService.getCurrentLocation(
      requestPermission: requestPermission,
    );
    if (!mounted) return;
    setState(() => _fetchingLocation = false);

    if (coords != null) {
      eventProvider.setUserLocation(coords.lat, coords.lng);
    } else if (showFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotGetLocation)),
      );
    }
  }

  Future<void> _openAiEventSearch({String initialQuery = ''}) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      await context.push('/login');
      return;
    }

    final eventProvider = context.read<EventProvider>();
    final area = eventProvider.areaQuery.trim();
    await showAiEventSearchAssistant(
      context,
      eventService: context.read<EventService>(),
      homeCity: area.isEmpty ? kElPasoCity : area,
      homeState: area.isEmpty ? kElPasoState : '',
      initialQuery: initialQuery,
      onOpenEvent: (event) {
        context.push('/event/${event.id}', extra: event);
      },
    );
  }

  void _toggleSearch(EventProvider eventProvider) {
    if (_searchOpen) {
      _closeSearch(eventProvider);
    } else {
      setState(() => _searchOpen = true);
    }
  }

  void _closeSearch(EventProvider eventProvider) {
    FocusManager.instance.primaryFocus?.unfocus();
    // The field debounces live searches; apply what was typed right away so
    // closing the panel never drops the last keystrokes.
    final typed = _keywordController.text;
    if (typed.trim() != eventProvider.searchQuery.trim() &&
        !(typed.trim().isNotEmpty &&
            eventProvider.areaQuery == typed.trim())) {
      eventProvider.search(typed);
    }
    setState(() => _searchOpen = false);
  }

  void _openFilters(EventProvider eventProvider) {
    FilterSheet.show(
      context,
      initialDatePreset: eventProvider.filterDate,
      initialDateFrom: eventProvider.filterDateFrom,
      initialDateTo: eventProvider.filterDateTo,
      initialPrice: eventProvider.filterPrice,
      initialCostType: eventProvider.filterCostType,
      initialTimeOfDay: eventProvider.filterTime,
      initialLocation: eventProvider.filterLocation,
      initialSources: eventProvider.selectedSources,
      initialRadius: eventProvider.searchRadius,
      onApply: ({
        datePreset = 'all',
        dateFrom,
        dateTo,
        priceFilter = 'all',
        costType,
        timeOfDay = 'all',
        locationQuery = '',
        sources = const {},
        radius = 25.0,
      }) {
        eventProvider.applyFilters(
          datePreset: datePreset,
          dateFrom: dateFrom,
          dateTo: dateTo,
          priceFilter: priceFilter,
          costType: costType,
          timeOfDay: timeOfDay,
          locationQuery: locationQuery,
          sources: sources,
          radius: radius,
        );
      },
      onClear: eventProvider.clearFilters,
    );
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 1:
        context.push('/gems');
        break;
      case 2:
        context.push('/map');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final personalization = context.watch<PersonalizationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final activeFilters = eventProvider.activeFilterCount;
    final hasAreaQuery = eventProvider.areaQuery.isNotEmpty;

    // Short landscape windows (the Galaxy Z Fold cover screen turned
    // sideways is only ~350 dp tall) cannot afford an 80 dp bottom bar: move
    // navigation to a side rail so the feed keeps its height.
    final size = MediaQuery.sizeOf(context);
    final compactHeight = size.height < _kCompactHeight;
    final useRail = compactHeight && size.width > size.height;

    // Everything above the cards scrolls away with the feed. When these
    // controls were pinned they used ~400 dp, leaving the cards a window
    // shorter than a single card (Blake: "unable to see a full event card").
    final hasSearchQuery = eventProvider.searchQuery.isNotEmpty;
    final iconButtonStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(40, 40),
      padding: const EdgeInsets.all(8),
    );

    // Everything above the cards scrolls away with the feed, and it is kept
    // small: search and Ask SpotVibe are icons in the top row (search expands
    // an inline panel), the categories are one slim scrolling row, and an
    // active search shows as a one-line chip. The old pinned header (two
    // search fields + a large Ask SpotVibe card) left no room for a card.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.spacingSm),
        _HomeHeaderGlow(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacingMd,
              right: AppTheme.spacingSm,
            ),
            child: Row(
              children: [
                const AppIconMark(size: 32, glow: false),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    key: _tourKeyHeader,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SpotVibeWordmark(
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        l10n.homeEditorialTagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: _tourKeySearch,
                  style: iconButtonStyle,
                  isSelected: _searchOpen,
                  tooltip: _searchOpen
                      ? MaterialLocalizations.of(context).closeButtonTooltip
                      : l10n.searchHint,
                  onPressed: () => _toggleSearch(eventProvider),
                  icon: Icon(
                    Icons.search_rounded,
                    color: hasSearchQuery || hasAreaQuery
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                  selectedIcon: Icon(Icons.close_rounded, color: colors.primary),
                ),
                IconButton(
                  key: const Key('home-ask-spotvibe'),
                  style: iconButtonStyle,
                  tooltip: l10n.askSpotVibe,
                  onPressed: () => _openAiEventSearch(
                    initialQuery: _keywordController.text,
                  ),
                  icon: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.brandGradient.createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      key: _tourKeyFilter,
                      style: iconButtonStyle,
                      onPressed: () => _openFilters(eventProvider),
                      icon: Icon(Icons.tune_rounded,
                          color: activeFilters > 0
                              ? colors.primary
                              : colors.onSurfaceVariant),
                      tooltip: l10n.filtersTooltip,
                    ),
                    if (activeFilters > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$activeFilters',
                              textScaler: TextScaler.noScaling,
                              style: text.labelSmall?.copyWith(
                                  color: colors.onPrimary, fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                _ProfileButton(
                  isLoggedIn: authProvider.isLoggedIn || authProvider.isGuest,
                  avatarUrl: authProvider.user?.avatarUrl,
                  onTap: () {
                    if (authProvider.isLoggedIn) {
                      context.push('/profile');
                    } else {
                      context.push('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        // Inline search panel: keyword + location fields. The controllers
        // live on this screen, so the query survives closing the panel.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _searchOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                  child: SearchHeader(
                    keywordController: _keywordController,
                    areaController: _areaController,
                    showProfile: false,
                    autofocusKeyword: !hasSearchQuery,
                    onSearch: eventProvider.search,
                    onKeywordSubmitted: (_) => _closeSearch(eventProvider),
                    onAreaSearch: (area) {
                      eventProvider.searchArea(area);
                    },
                    onProfileTap: () {},
                    isLoggedIn: authProvider.isLoggedIn || authProvider.isGuest,
                    onUseMyLocation:
                        _fetchingLocation ? null : _requestUserLocation,
                    isUsingMyLocation: eventProvider.hasUserLocation &&
                        !eventProvider.hasAreaSearch,
                    onSuggestionsRequest: (q) =>
                        _buildSuggestions(q, eventProvider),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        CategoryChips(
          key: _tourKeyCategories,
          categories: eventProvider.categories,
          selected: eventProvider.selectedCategory,
          onSelected: eventProvider.selectCategory,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        if (!_searchOpen && (hasSearchQuery || hasAreaQuery))
          _ActiveSearchChips(
            eventProvider: eventProvider,
            onClearQuery: () {
              _keywordController.clear();
              eventProvider.search('');
            },
            onClearArea: () {
              _areaController.clear();
              eventProvider.searchArea('');
            },
            onEdit: () => _toggleSearch(eventProvider),
          ),
      ],
    );

    final feed = NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(child: header),
      ],
      body: _EventsList(
        eventProvider: eventProvider,
        areaQuery: eventProvider.areaQuery,
        personalization: personalization,
        isRequestingLocation: _fetchingLocation,
        onRequestLocation: _fetchingLocation
            ? null
            : () {
                _requestUserLocation();
              },
        firstCardKey: _tourKeyCard,
        pageController: _pageController,
      ),
    );

    return Scaffold(
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: 0,
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore_rounded),
                  label: l10n.navDiscover,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.diamond_outlined),
                  selectedIcon: const Icon(Icons.diamond_rounded),
                  label: l10n.navGems,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map_rounded),
                  label: l10n.navMap,
                ),
              ],
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (useRail) ...[
              NavigationRail(
                selectedIndex: 0,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                groupAlignment: 0,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore_rounded),
                    label: Text(l10n.navDiscover),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.diamond_outlined),
                    selectedIcon: const Icon(Icons.diamond_rounded),
                    label: Text(l10n.navGems),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.map_outlined),
                    selectedIcon: const Icon(Icons.map_rounded),
                    label: Text(l10n.navMap),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: Column(
                children: [
                  Expanded(child: feed),
                  // Page navigation stays pinned (and slim) so the page
                  // numbers are always on screen while the feed scrolls.
                  FeedPaginationBar(controller: _pageController),
                  // Anchored banner ad for free users (collapses for Premium
                  // and on web). Sits between the feed and the navigation. On
                  // very short screens the upsell row under it is dropped so
                  // the ad slot does not eat a third of the height.
                  AdBanner(showRemoveAdsUpsell: !compactHeight),
                  GuidedTour(
                    tourId: 'home',
                    steps: [
                      TourStep(
                        targetKey: _tourKeyHeader,
                        title: l10n.tourHome1Title,
                        description: l10n.tourHome1Body,
                      ),
                      TourStep(
                        targetKey: _tourKeySearch,
                        title: l10n.tourHome2Title,
                        description: l10n.tourHome2Body,
                      ),
                      TourStep(
                        targetKey: _tourKeyFilter,
                        title: l10n.tourHome3Title,
                        description: l10n.tourHome3Body,
                      ),
                      TourStep(
                        targetKey: _tourKeyCategories,
                        title: l10n.tourHome4Title,
                        description: l10n.tourHome4Body,
                      ),
                      TourStep(
                        targetKey: _tourKeyCard,
                        title: l10n.tourHome5Title,
                        description: l10n.tourHome5Body,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact profile / sign-in avatar for the home top row.
class _ProfileButton extends StatelessWidget {
  final bool isLoggedIn;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.isLoggedIn,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.profile,
      onPressed: onTap,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(4),
      ),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: colors.primaryContainer,
        child: isLoggedIn
            ? ClipOval(
                child: Image.network(
                  avatarUrl ?? '',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.person,
                      size: 20, color: colors.onPrimaryContainer),
                ),
              )
            : Icon(Icons.person_outline_rounded,
                size: 20, color: colors.onPrimaryContainer),
      ),
    );
  }
}

/// One slim row showing what search is applied — the keyword (with its result
/// count) and/or the location — each with its own clear button. Tapping a
/// chip reopens the search panel to edit it.
class _ActiveSearchChips extends StatelessWidget {
  final EventProvider eventProvider;
  final VoidCallback onClearQuery;
  final VoidCallback onClearArea;
  final VoidCallback onEdit;

  const _ActiveSearchChips({
    required this.eventProvider,
    required this.onClearQuery,
    required this.onClearArea,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final query = eventProvider.searchQuery;
    final area = eventProvider.areaQuery;
    final sortingByDistance =
        eventProvider.sortByDistance && eventProvider.hasUserLocation;
    final maxChipWidth = MediaQuery.sizeOf(context).width * 0.72;

    return SingleChildScrollView(
      key: const Key('home-active-search'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingXs),
      child: Row(
        children: [
          if (query.isNotEmpty)
            _SearchChip(
              key: const Key('home-active-query'),
              icon: Icons.search_rounded,
              label: eventProvider.isLoading
                  ? '"$query"'
                  : l10n.searchResults(eventProvider.events.length, query),
              maxWidth: maxChipWidth,
              onTap: onEdit,
              onClear: onClearQuery,
            ),
          if (query.isNotEmpty && area.isNotEmpty)
            const SizedBox(width: AppTheme.spacingSm),
          if (area.isNotEmpty)
            _SearchChip(
              key: const Key('home-active-area'),
              icon: Icons.location_on_rounded,
              label: l10n.showingEventsIn(area),
              maxWidth: maxChipWidth,
              onTap: onEdit,
              onClear: onClearArea,
            ),
          if (query.isNotEmpty &&
              eventProvider.hasUserLocation &&
              !eventProvider.hasAreaSearch) ...[
            const SizedBox(width: AppTheme.spacingSm),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () =>
                  eventProvider.setSortByDistance(!sortingByDistance),
              icon: Icon(
                sortingByDistance
                    ? Icons.near_me_rounded
                    : Icons.calendar_today_rounded,
                size: AppTheme.iconSm,
              ),
              label: Text(
                sortingByDistance ? l10n.nearestFirst : l10n.byDate,
                style: text.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double maxWidth;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _SearchChip({
    super.key,
    required this.icon,
    required this.label,
    required this.maxWidth,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.28),
      shape: StadiumBorder(
        side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppTheme.iconSm, color: colors.primary),
              const SizedBox(width: AppTheme.spacingXs),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.clear,
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final EventProvider eventProvider;
  final String areaQuery;
  final PersonalizationProvider personalization;
  final bool isRequestingLocation;
  final VoidCallback? onRequestLocation;
  final GlobalKey? firstCardKey;
  final FeedPageController? pageController;

  const _EventsList({
    required this.eventProvider,
    required this.areaQuery,
    required this.personalization,
    required this.isRequestingLocation,
    required this.onRequestLocation,
    this.firstCardKey,
    this.pageController,
  });

  void _toggleDatePreset(String preset) {
    final isSelected =
        eventProvider.filterDate == preset &&
        eventProvider.filterDateFrom == null &&
        eventProvider.filterDateTo == null;

    eventProvider.applyFilters(
      datePreset: isSelected ? 'all' : preset,
      priceFilter: eventProvider.filterPrice,
      costType: eventProvider.filterCostType,
      timeOfDay: eventProvider.filterTime,
      locationQuery: eventProvider.filterLocation,
      sources: eventProvider.selectedSources,
      radius: eventProvider.searchRadius,
    );
  }

  void _toggleFreeFilter() {
    final isSelected =
        eventProvider.filterPrice == 'free' ||
        (eventProvider.filterPrice == 'all' &&
            eventProvider.filterCostType == 'free');

    eventProvider.applyFilters(
      datePreset: eventProvider.filterDate,
      dateFrom: eventProvider.filterDateFrom,
      dateTo: eventProvider.filterDateTo,
      priceFilter: isSelected ? 'all' : 'free',
      // The price tier is the source of truth for this shortcut. Clear the
      // legacy cost-type field so a previously selected "paid" filter cannot
      // conflict with a newly selected Free shortcut.
      costType: null,
      timeOfDay: eventProvider.filterTime,
      locationQuery: eventProvider.filterLocation,
      sources: eventProvider.selectedSources,
      radius: eventProvider.searchRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (eventProvider.isLoading) {
      return const EventFeedSkeleton();
    }

    if (eventProvider.error != null) {
      return EmptyStateView(
        variant: EmptyStateVariant.apiError,
        icon: Icons.cloud_off_rounded,
        title: l10n.errorTitle,
        subtitle: l10n.errorSubtitle,
        actionLabel: l10n.tryAgain,
        onAction: eventProvider.loadEvents,
        secondaryActionLabel: l10n.viewSavedEvents,
        onSecondaryAction: () => context.push('/saved-events'),
      );
    }

    if (eventProvider.events.isEmpty) {
      final hasFilters = eventProvider.activeFilterCount > 0 ||
          eventProvider.searchQuery.isNotEmpty;
      final isAreaSearch = areaQuery.isNotEmpty;
      final hasLocation = eventProvider.hasUserLocation;

      if (hasFilters) {
        return EmptyStateView(
          variant: EmptyStateVariant.filtersTooStrict,
          icon: Icons.manage_search_rounded,
          title: l10n.noMatchesTitle,
          subtitle: l10n.noMatchesSubtitle,
          actionLabel: l10n.clearFilters,
          onAction: () {
            eventProvider.clearFilters();
            eventProvider.search('');
          },
        );
      }

      if (isAreaSearch) {
        return EmptyStateView(
          variant: EmptyStateVariant.noEventsNearby,
          icon: Icons.location_off_rounded,
          title: l10n.noEventsNear(areaQuery),
          subtitle: l10n.noEventsNearSubtitle,
          actionLabel: l10n.increaseRadius,
          onAction: () => FilterSheet.show(
            context,
            initialRadius: eventProvider.searchRadius,
            initialDatePreset: eventProvider.filterDate,
            initialPrice: eventProvider.filterPrice,
            initialTimeOfDay: eventProvider.filterTime,
            initialSources: eventProvider.selectedSources,
            onApply: ({
              datePreset = 'all',
              dateFrom,
              dateTo,
              priceFilter = 'all',
              costType,
              timeOfDay = 'all',
              locationQuery = '',
              sources = const {},
              radius = 25.0,
            }) =>
                eventProvider.applyFilters(
              datePreset: datePreset,
              dateFrom: dateFrom,
              dateTo: dateTo,
              priceFilter: priceFilter,
              costType: costType,
              timeOfDay: timeOfDay,
              locationQuery: locationQuery,
              sources: sources,
              radius: radius,
            ),
            onClear: eventProvider.clearFilters,
          ),
          secondaryActionLabel: l10n.clearLocation,
          onSecondaryAction: () => eventProvider.searchArea(''),
        );
      }

      if (!hasLocation) {
        return EmptyStateView(
          variant: EmptyStateVariant.noLocation,
          icon: Icons.location_searching_rounded,
          title: l10n.locationNeededTitle,
          subtitle: l10n.locationNeededSubtitle,
          actionLabel: l10n.enableLocation,
          onAction: () => context
              .findAncestorStateOfType<_EventsScreenState>()
              ?._requestUserLocation(),
          secondaryActionLabel: l10n.browseAllEvents,
          onSecondaryAction: () => eventProvider.selectCategory('All'),
        );
      }

      return EmptyStateView(
        variant: EmptyStateVariant.generic,
        icon: Icons.event_busy_rounded,
        title: l10n.noEventsFoundTitle,
        subtitle: l10n.noEventsFoundSubtitle,
        actionLabel: l10n.increaseRadius,
        onAction: () => FilterSheet.show(
          context,
          initialRadius: eventProvider.searchRadius,
          initialDatePreset: eventProvider.filterDate,
          initialPrice: eventProvider.filterPrice,
          initialTimeOfDay: eventProvider.filterTime,
          initialSources: eventProvider.selectedSources,
          onApply: ({
            datePreset = 'all',
            dateFrom,
            dateTo,
            priceFilter = 'all',
            costType,
            timeOfDay = 'all',
            locationQuery = '',
            sources = const {},
            radius = 25.0,
          }) =>
              eventProvider.applyFilters(
            datePreset: datePreset,
            dateFrom: dateFrom,
            dateTo: dateTo,
            priceFilter: priceFilter,
            costType: costType,
            timeOfDay: timeOfDay,
            locationQuery: locationQuery,
            sources: sources,
            radius: radius,
          ),
          onClear: eventProvider.clearFilters,
        ),
      );
    }

    // The showcase belongs on the browse feed (home "All" and any category),
    // but not on a text search or a filtered result — those should take users
    // straight to what they asked for. It only appears when there is genuine
    // Premium value to show (featured/live events); otherwise the feed starts
    // with its normal cards instead of a filler card at the head of the page.
    final showShowcase = eventProvider.searchQuery.isEmpty &&
        eventProvider.activeFilterCount == 0;
    final heroEvents = showShowcase
        ? selectFeaturedHeroEvents(eventProvider.events)
        : const <Event>[];
    // Quick filters only make sense on the unfiltered "All" home feed.
    final showQuickFilters = eventProvider.selectedCategory == 'All';
    final heroIds = heroEvents.map((e) => e.id).toSet();

    return PaginatedEventsList(
      eventProvider: eventProvider,
      personalization: personalization,
      firstCardKey: firstCardKey,
      pageController: pageController,
      // On a keyword search the result chip already says how many matched,
      // so the large "Happening near you" heading gives its room to a card.
      showCountBanner: eventProvider.searchQuery.isEmpty,
      sectionTitle: l10n.homeHappeningNearYou,
      // Do not repeat a showcased card directly below itself, unless removing
      // it would empty the feed (a tiny one-event feed still shows its card).
      excludedEventIds: eventProvider.events.length > heroIds.length
          ? heroIds
          : const <String>{},
      feedHeader: [
        if (heroEvents.isNotEmpty)
          DiscoveryHeroCarousel(
            events: heroEvents,
            onTap: (event) {
              personalization.recordView(event);
              context.push('/event/${event.id}', extra: event);
            },
          ),
        if (showQuickFilters)
          HomeQuickFilters(
          isTodaySelected: eventProvider.filterDate == 'today',
          isWeekendSelected: eventProvider.filterDate == 'this_weekend',
          isFreeSelected:
              eventProvider.filterPrice == 'free' ||
              eventProvider.filterCostType == 'free',
          isNearMeSelected:
              eventProvider.hasUserLocation && !eventProvider.hasAreaSearch,
          isRequestingLocation: isRequestingLocation,
          onTodayTap: () => _toggleDatePreset('today'),
          onWeekendTap: () => _toggleDatePreset('this_weekend'),
          onFreeTap: _toggleFreeFilter,
          onNearMeTap: onRequestLocation,
        ),
      ],
      onEventTap: (event, _) {
        personalization.recordView(event);
        context.push('/event/${event.id}', extra: event);
      },
    );
  }
}

// ── Animated header glow ──────────────────────────────────────────────────────

/// A soft, slowly drifting brand-colored aura behind the home header. Very low
/// opacity and content sits on top, so contrast and usability are unaffected —
/// it just gives the top of the feed a gentle, living feel.
class _HomeHeaderGlow extends StatefulWidget {
  final Widget child;

  const _HomeHeaderGlow({required this.child});

  @override
  State<_HomeHeaderGlow> createState() => _HomeHeaderGlowState();
}

class _HomeHeaderGlowState extends State<_HomeHeaderGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -52,
          left: -24,
          right: -24,
          bottom: -12,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final t = _controller.value; // 0..1, ping-pongs
                final c1 = Color.lerp(
                  AppTheme.brandViolet,
                  AppTheme.brandCyan,
                  t * 0.6,
                )!;
                final c2 = Color.lerp(
                  AppTheme.brandPink,
                  AppTheme.brandViolet,
                  t * 0.8,
                )!;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.85, -0.7),
                      radius: 1.25,
                      colors: [
                        c1.withValues(alpha: isDark ? 0.22 : 0.13),
                        c2.withValues(alpha: isDark ? 0.13 : 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
