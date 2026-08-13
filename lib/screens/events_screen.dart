import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/personalization_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';
import '../widgets/common/category_chips.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/event_card_skeleton.dart';
import '../widgets/common/paginated_events_list.dart';
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
        const SnackBar(content: Text('Could not get your location. Please allow location access.')),
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
    final activeFilters = eventProvider.activeFilterCount;
    final hasAreaQuery = eventProvider.areaQuery.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingMd),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Row(
                children: [
                  Text('SpotVibe', style: text.headlineMedium?.copyWith(color: colors.primary)),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
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
                        tooltip: 'Filters',
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
            const SizedBox(height: AppTheme.spacingSm),
            SearchHeader(
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
              ),
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
                'Showing events in "$areaQuery"',
                style: text.labelSmall?.copyWith(color: colors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Text(
                'Clear',
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
              '$count result${count == 1 ? '' : 's'} for "$query"',
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
                    sortingByDistance ? 'Nearest first' : 'By date',
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

  const _EventsList({
    required this.eventProvider,
    required this.areaQuery,
    required this.personalization,
  });

  @override
  Widget build(BuildContext context) {
    if (eventProvider.isLoading) {
      return const EventFeedSkeleton();
    }

    if (eventProvider.error != null) {
      return EmptyStateView(
        variant: EmptyStateVariant.apiError,
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load events',
        subtitle:
            'Check your connection and try again. Your saved events are still available.',
        actionLabel: 'Try Again',
        onAction: eventProvider.loadEvents,
        secondaryActionLabel: 'View Saved Events',
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
          title: 'No matches for these filters',
          subtitle:
              'Try broadening your search — adjust the date, price, or category filters to see more events.',
          actionLabel: 'Clear Filters',
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
          title: 'No events near "$areaQuery"',
          subtitle:
              'Try a different city, zip code, or increase your search radius in the filter options.',
          actionLabel: 'Increase Radius',
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
          secondaryActionLabel: 'Clear Location',
          onSecondaryAction: () => eventProvider.searchArea(''),
        );
      }

      if (!hasLocation) {
        return EmptyStateView(
          variant: EmptyStateVariant.noLocation,
          icon: Icons.location_searching_rounded,
          title: 'Location needed',
          subtitle:
              'Enable location so SpotVibe can find events happening near you right now.',
          actionLabel: 'Enable Location',
          onAction: () => context
              .findAncestorStateOfType<_EventsScreenState>()
              ?._requestUserLocation(),
          secondaryActionLabel: 'Browse All Events',
          onSecondaryAction: () => eventProvider.selectCategory('All'),
        );
      }

      return EmptyStateView(
        variant: EmptyStateVariant.generic,
        icon: Icons.event_busy_rounded,
        title: 'No events found nearby',
        subtitle:
            'Try increasing your search radius or check back later — new events are added every day.',
        actionLabel: 'Increase Radius',
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
      onEventTap: (event, globalIndex) {
        personalization.recordView(event);
        context.push('/event/${event.id}', extra: event);
      },
    );
  }
}
