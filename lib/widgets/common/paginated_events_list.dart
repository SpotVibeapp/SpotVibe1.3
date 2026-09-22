import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/personalization_provider.dart';
import '../../theme/theme.dart';
import '../events/event_card.dart';
import 'jambase_attribution.dart';

const int kEventsPerPage = 15;

/// Displays [kEventsPerPage] events at a time from [eventProvider.events].
/// Shows a count banner ("Showing 15 of 47 events") and optional
/// [feedHeader] content before the cards, plus page navigation controls when
/// there is more than one page.
///
/// [onEventTap] is called by the parent so navigation (go_router) stays
/// in the screen layer, not in this widget.
class PaginatedEventsList extends StatefulWidget {
  final EventProvider eventProvider;
  final PersonalizationProvider personalization;

  /// Optional scrollable content shown before the feed section heading. This
  /// lets the home page have a visual discovery moment without making its
  /// search controls or pagination fixed and crowded on smaller phones.
  final List<Widget> feedHeader;

  /// Optional title shown above the accurate feed-count label.
  final String? sectionTitle;

  /// Real events already displayed in a prominent header can be omitted from
  /// the card list below it, so people are not shown the exact same listings
  /// twice in a row.
  final Set<String> excludedEventIds;

  /// Attached to the first event card so the guided tour can spotlight it.
  final GlobalKey? firstCardKey;

  /// Called when a card is tapped. Parent handles routing + view tracking.
  final void Function(Event event, int globalIndex) onEventTap;

  const PaginatedEventsList({
    super.key,
    required this.eventProvider,
    required this.personalization,
    required this.onEventTap,
    this.feedHeader = const [],
    this.sectionTitle,
    this.excludedEventIds = const <String>{},
    this.firstCardKey,
  });

  @override
  State<PaginatedEventsList> createState() => _PaginatedEventsListState();
}

class _PaginatedEventsListState extends State<PaginatedEventsList> {
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Return the feed to the top so a new page always starts at its first card
  /// instead of leaving the reader stranded mid-list from the previous page.
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  List<Event> get _all {
    final excluded = widget.excludedEventIds;
    if (excluded.isEmpty) return widget.eventProvider.events;
    return widget.eventProvider.events
        .where((event) => !excluded.contains(event.id))
        .toList(growable: false);
  }

  int get _total => _all.length;
  int get _totalPages => (_total / kEventsPerPage).ceil().clamp(1, 99999);

  List<Event> get _pageEvents {
    final start = _currentPage * kEventsPerPage;
    final end = (start + kEventsPerPage).clamp(0, _total);
    return _all.sublist(start, end);
  }

  /// Track previous list identity to auto-reset page on filter/search change.
  List<Event>? _prevSnapshot;

  @override
  void didUpdateWidget(PaginatedEventsList old) {
    super.didUpdateWidget(old);
    if (!_sameList(_all, _prevSnapshot)) {
      // List changed (new search / filter / refresh) — reset to first page and
      // return the feed to the top after this frame lays out the new content.
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
    _prevSnapshot = List.of(_all);
  }

  static bool _sameList(List<Event> a, List<Event>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _go(int page) {
    setState(() => _currentPage = page.clamp(0, _totalPages - 1));
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pageEvents;
    final provider = widget.eventProvider;

    // The discovery header (showcase carousel, quick filters) belongs to the
    // first page only — repeating it atop pages 2, 3, … made the feed feel like
    // it kept reloading. Later pages start straight at the count banner.
    final headerCount = _currentPage == 0 ? widget.feedHeader.length : 0;
    // Licence condition: any page showing a JamBase row ends with a
    // "Powered by JamBase" link. Empty for pages without one.
    final showAttribution = JamBaseAttribution.needed(page);

    return Column(
      children: [
        // ── Scrollable discovery header, feed heading, and event cards ────────
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
            itemCount: headerCount + 1 + page.length + (showAttribution ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i < headerCount) return widget.feedHeader[i];
              if (i == headerCount + 1 + page.length) {
                return JamBaseAttribution(events: page);
              }

              if (i == headerCount) {
                return _EventCountBanner(
                  currentPage: _currentPage,
                  pageSize: kEventsPerPage,
                  total: provider.events.length,
                  // Events shown outside the paginated list (the discovery
                  // hero) still count toward the real total, so add them back
                  // in for an accurate "of N" figure and a continuous range.
                  heroLead: provider.events.length - _total,
                  sectionTitle: widget.sectionTitle,
                );
              }

              final eventIndex = i - headerCount - 1;
              final event = page[eventIndex];
              // Cards may omit the event shown in the home hero, so use the
              // provider's actual index rather than the visible-list offset.
              final providerIndex = provider.indexOfEvent(event.id);
              return EventCard(
                key: _currentPage == 0 && eventIndex == 0
                    ? widget.firstCardKey
                    : null,
                event: event,
                onTap: () => widget.onEventTap(event, providerIndex),
                onBookmark: () => provider.toggleBookmark(providerIndex),
                onInterested: () => provider.toggleInterested(providerIndex),
                distanceMiles: provider.distanceFor(event),
              );
            },
          ),
        ),
        // ── Page navigation ───────────────────────────────────────────────────
        if (_totalPages > 1)
          _PaginationBar(
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPrev: _currentPage > 0 ? () => _go(_currentPage - 1) : null,
            onNext: _currentPage < _totalPages - 1
                ? () => _go(_currentPage + 1)
                : null,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count banner
// ─────────────────────────────────────────────────────────────────────────────

class _EventCountBanner extends StatelessWidget {
  final int currentPage;
  final int pageSize;

  /// True total across the whole feed, including any events rendered outside
  /// the paginated list (e.g. the discovery hero).
  final int total;

  /// How many leading events are shown above the list (the hero) and therefore
  /// are NOT part of the paginated slice but still count toward [total].
  final int heroLead;
  final String? sectionTitle;

  const _EventCountBanner({
    required this.currentPage,
    required this.pageSize,
    required this.total,
    this.heroLead = 0,
    this.sectionTitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    // The paginated list holds everything except the hero lead.
    final listTotal = (total - heroLead).clamp(0, total);

    // Numbering runs continuously across the hero and the list. The hero
    // occupies the first [heroLead] positions (only visible on page 0).
    final listStart = currentPage * pageSize;
    final listEnd = ((currentPage + 1) * pageSize).clamp(0, listTotal);
    final start = currentPage == 0 ? 1 : heroLead + listStart + 1;
    final end = heroLead + listEnd;

    // "Showing 1–15 of 47 events"  or  "Showing all 12 events" on a single page
    final label = listTotal <= pageSize
        ? l10n.showingAll(total)
        : l10n.showingRange(start, end, total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingXs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sectionTitle ?? l10n.homeHappeningNearYou,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: AppTheme.iconSm,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination bar
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant,
            width: AppTheme.borderDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Prev button ───────────────────────────────────────────────────
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: l10n.previous,
            onTap: onPrev,
          ),
          // ── Page indicator + dot row ──────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.pageXOfY(currentPage + 1, totalPages),
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _PageDots(
                  currentPage: currentPage,
                  totalPages: totalPages,
                ),
              ],
            ),
          ),
          // ── Next button ───────────────────────────────────────────────────
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: l10n.next,
            iconRight: true,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool iconRight;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.iconRight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final enabled = onTap != null;
    final color = enabled ? colors.primary : colors.onSurfaceVariant.withValues(alpha: AppTheme.opacityDisabled);

    final iconWidget = Icon(icon, size: AppTheme.iconMd, color: color);
    final labelWidget = Text(
      label,
      style: text.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconRight
              ? [labelWidget, const SizedBox(width: 2), iconWidget]
              : [iconWidget, const SizedBox(width: 2), labelWidget],
        ),
      ),
    );
  }
}

/// A row of up to 7 dot indicators; shows condensed version for larger page counts.
class _PageDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _PageDots({required this.currentPage, required this.totalPages});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Only render dots when ≤7 pages; otherwise skip (page label is enough).
    if (totalPages > 7) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPages, (i) {
        final active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.outlineVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        );
      }),
    );
  }
}
