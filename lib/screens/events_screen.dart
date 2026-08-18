import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/personalization_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';
import '../widgets/common/category_chips.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/event_card_skeleton.dart';
import '../widgets/common/guided_tour.dart';
import '../widgets/common/paginated_events_list.dart';
import '../widgets/common/app_icon_mark.dart';
import '../widgets/common/spotvibe_logo.dart';
import '../widgets/events/filter_sheet.dart';
import '../widgets/events/search_header.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _areaController = TextEditingController();
  final _locationService = LocationService();
  bool _fetchingLocation = false;

  // Guided-tour target keys (stable across rebuilds).
  final GlobalKey _tourKeyHeader = GlobalKey();
  final GlobalKey _tourKeySearch = GlobalKey();
  final GlobalKey _tourKeyFilter = GlobalKey();
  final GlobalKey _tourKeyCategories = GlobalKey();
  final GlobalKey _tourKeyCard = GlobalKey();

  @override
  void dispose() {
    _areaController.dispose();
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

  Future<void> _requestUserLocation() async {
    if (_fetchingLocation) return;
    final eventProvider = context.read<EventProvider>();

    if (eventProvider.hasUserLocation) {
      eventProvider.clearUserLocation();
      return;
    }

    setState(() => _fetchingLocation = true);
    final coords = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _fetchingLocation = false);

    if (coords != null) {
      eventProvider.setUserLocation(coords.lat, coords.lng);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotGetLocation)),
      );
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingMd),
            _HomeHeaderGlow(
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Row(
                children: [
                  const AppIconMark(size: 34, glow: false),
                  const SizedBox(width: AppTheme.spacingSm),
                  SpotVibeWordmark(
                    key: _tourKeyHeader,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        key: _tourKeyFilter,
                        onPressed: () => FilterSheet.show(
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
                        ),
                        icon: Icon(Icons.tune_rounded,
                            color: activeFilters > 0 ? colors.primary : colors.onSurfaceVariant),
                        tooltip: l10n.filtersTooltip,
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          top: 6,
                          right: 6,
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
                                style: text.labelSmall
                                    ?.copyWith(color: colors.onPrimary, fontSize: 9),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            SearchHeader(
              key: _tourKeySearch,
              areaController: _areaController,
              onSearch: eventProvider.search,
              onAreaSearch: (area) {
                eventProvider.searchArea(area);
              },
              onProfileTap: () {
                if (authProvider.isLoggedIn) {
                  context.push('/profile');
                } else {
                  context.push('/login');
                }
              },
              isLoggedIn: authProvider.isLoggedIn || authProvider.isGuest,
              avatarUrl: authProvider.user?.avatarUrl,
              onUseMyLocation: _fetchingLocation ? null : _requestUserLocation,
              isUsingMyLocation: eventProvider.hasUserLocation,
              onSuggestionsRequest: (q) => _buildSuggestions(q, eventProvider),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            CategoryChips(
              key: _tourKeyCategories,
              categories: eventProvider.categories,
              selected: eventProvider.selectedCategory,
              onSelected: eventProvider.selectCategory,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            if (hasAreaQuery)
              _ActiveAreaStrip(
                areaQuery: eventProvider.areaQuery,
                searchRadius: eventProvider.searchRadius,
                onClear: () {
                  _areaController.clear();
                  eventProvider.searchArea('');
                },
              ),
            if (eventProvider.searchQuery.isNotEmpty && !eventProvider.isLoading)
              _SearchResultsHeader(eventProvider: eventProvider),
            Expanded(
              child: _EventsList(
                eventProvider: eventProvider,
                areaQuery: eventProvider.areaQuery,
                personalization: personalization,
                firstCardKey: _tourKeyCard,
              ),
            ),
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
    );
  }
}

class _ActiveAreaStrip extends StatelessWidget {
  final String areaQuery;
  final double searchRadius;
  final VoidCallback onClear;
  const _ActiveAreaStrip({
    required this.areaQuery,
    required this.searchRadius,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, size: AppTheme.iconSm, color: colors.primary),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Text(
                l10n.showingEventsIn(areaQuery),
                style: text.labelSmall?.copyWith(color: colors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Text(
                l10n.clear,
                style: text.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  final EventProvider eventProvider;
  const _SearchResultsHeader({required this.eventProvider});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final count = eventProvider.events.length;
    final query = eventProvider.searchQuery;
    final sortingByDistance =
        eventProvider.sortByDistance && eventProvider.hasUserLocation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: AppTheme.iconSm, color: colors.onSurfaceVariant),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              l10n.searchResults(count, query),
              style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (eventProvider.hasUserLocation)
            GestureDetector(
              onTap: () => eventProvider.setSortByDistance(!sortingByDistance),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sortingByDistance
                        ? Icons.near_me_rounded
                        : Icons.calendar_today_rounded,
                    size: AppTheme.iconSm,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    sortingByDistance ? l10n.nearestFirst : l10n.byDate,
                    style: text.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final EventProvider eventProvider;
  final String areaQuery;
  final PersonalizationProvider personalization;
  final GlobalKey? firstCardKey;

  const _EventsList({
    required this.eventProvider,
    required this.areaQuery,
    required this.personalization,
    this.firstCardKey,
  });

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

    return PaginatedEventsList(
      eventProvider: eventProvider,
      personalization: personalization,
      firstCardKey: firstCardKey,
      onEventTap: (event, globalIndex) {
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
