import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/personalization_provider.dart';
import '../../theme/theme.dart';
import '../events/event_card.dart';

const int kEventsPerPage = 15;

/// Displays [kEventsPerPage] events at a time from [eventProvider.events].
/// Shows a count banner ("Showing 15 of 47 events") at the top and page
/// navigation controls at the bottom when there is more than one page.
///
/// [onEventTap] is called by the parent so navigation (go_router) stays
/// in the screen layer, not in this widget.
class PaginatedEventsList extends StatefulWidget {
  final EventProvider eventProvider;
  final PersonalizationProvider personalization;

  /// Called when a card is tapped. Parent handles routing + view tracking.
  final void Function(Event event, int globalIndex) onEventTap;

  const PaginatedEventsList({
    super.key,
    required this.eventProvider,
    required this.personalization,
    required this.onEventTap,
  });

  @override
  State<PaginatedEventsList> createState() => _PaginatedEventsListState();
}

class _PaginatedEventsListState extends State<PaginatedEventsList> {
  int _currentPage = 0;

  List<Event> get _all => widget.eventProvider.events;
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
      // List changed — reset to first page without animation.
      _currentPage = 0;
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
  }

  @override
  Widget build(BuildContext context) {
    final page = _pageEvents;
    final provider = widget.eventProvider;

    return Column(
      children: [
        // ── Count banner ──────────────────────────────────────────────────────
        _EventCountBanner(
          currentPage: _currentPage,
          pageSize: kEventsPerPage,
          total: _total,
        ),
        // ── Event cards ───────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
            itemCount: page.length,
            itemBuilder: (ctx, i) {
              final event = page[i];
              final globalIndex = _currentPage * kEventsPerPage + i;
              return EventCard(
                event: event,
                onTap: () => widget.onEventTap(event, globalIndex),
                onBookmark: () => provider.toggleBookmark(globalIndex),
                onInterested: () => provider.toggleInterested(globalIndex),
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
  final int total;

  const _EventCountBanner({
    required this.currentPage,
    required this.pageSize,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final start = currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, total);

    // "Showing 1–15 of 47 events"  or  "Showing all 12 events" when ≤15
    final label = total <= pageSize
        ? 'Showing all $total event${total == 1 ? '' : 's'}'
        : 'Showing $start–$end of $total events';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingXs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_rounded,
            size: AppTheme.iconSm,
            color: colors.primary,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
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
            label: 'Previous',
            onTap: onPrev,
          ),
          // ── Page indicator + dot row ──────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page ${currentPage + 1} of $totalPages',
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
            label: 'Next',
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
