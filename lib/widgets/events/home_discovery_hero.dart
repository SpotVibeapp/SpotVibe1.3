import 'package:flutter/material.dart';

import '../../data/event_time.dart';
import '../../data/pricing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';

/// Picks the one genuine listing that receives the prominent home placement.
///
/// A listing explicitly featured for the current week always wins. When there
/// is no paid/featured listing, the first event already ranked by the feed is
/// used instead. This deliberately never creates a placeholder event or
/// fabricates popularity data.
Event? selectDiscoveryHeroEvent(List<Event> events, {DateTime? now}) {
  for (final event in events) {
    if (isFeaturedInCurrentWeek(event.featuredWeekKey, now: now)) {
      return event;
    }
  }
  return events.isEmpty ? null : events.first;
}

/// A compact, image-led entry point for the normal unfiltered home feed.
///
/// It only renders a real [event] supplied by the feed. The event cover, date,
/// venue, and destination are all taken directly from that listing.
class HomeDiscoveryHero extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const HomeDiscoveryHero({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = categoryAccent(event.category);
    final isFeatured = event.isFeaturedThisWeek;
    final location = event.fullLocation.isEmpty ? event.location : event.fullLocation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingXs,
      ),
      child: Semantics(
        button: true,
        label: l10n.openEvent(event.title),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.26),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              side: BorderSide(color: accent.withValues(alpha: 0.72)),
            ),
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventCoverImage.fromEvent(
                      event,
                      placeholderColor: colors.surfaceContainerHighest,
                    ),
                    // The image stays visible, while the dark scrim keeps
                    // the genuine event information readable on every cover.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x75000000),
                            Color(0x1C000000),
                            Color(0xD9000000),
                          ],
                          stops: [0, 0.42, 1],
                        ),
                      ),
                    ),
                    // A subtle category-colored glow gives otherwise dark
                    // photos the same lively SpotVibe signature.
                    Positioned(
                      top: -44,
                      right: -30,
                      child: IgnorePointer(
                        child: Container(
                          width: 142,
                          height: 142,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroBadge(
                            icon: isFeatured
                                ? Icons.auto_awesome_rounded
                                : Icons.near_me_rounded,
                            label: isFeatured
                                ? l10n.featuredThisWeek
                                : l10n.homeNextUp,
                          ),
                          const Spacer(),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              shadows: const [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 7,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: AppTheme.iconSm,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Expanded(
                                child: Text(
                                  formatEventWhen(event.dateTime),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x99000000),
                                        blurRadius: 5,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.48),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: AppTheme.iconSm + 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: AppTheme.iconSm,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC12101B),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: AppTheme.iconSm),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
          ),
        ],
      ),
    );
  }
}

/// One-tap, reversible discovery shortcuts for the home feed.
///
/// Each chip maps to a real EventProvider filter. "Near you" uses the same
/// device-location action as the existing search header; it never assumes or
/// displays a location the user has not chosen to share.
class HomeQuickFilters extends StatelessWidget {
  final bool isTodaySelected;
  final bool isWeekendSelected;
  final bool isFreeSelected;
  final bool isNearMeSelected;
  final bool isRequestingLocation;
  final VoidCallback onTodayTap;
  final VoidCallback onWeekendTap;
  final VoidCallback onFreeTap;
  final VoidCallback? onNearMeTap;

  const HomeQuickFilters({
    super.key,
    required this.isTodaySelected,
    required this.isWeekendSelected,
    required this.isFreeSelected,
    required this.isNearMeSelected,
    required this.isRequestingLocation,
    required this.onTodayTap,
    required this.onWeekendTap,
    required this.onFreeTap,
    required this.onNearMeTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      container: true,
      label: l10n.quickFilters,
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            AppTheme.spacingXs,
          ),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _DiscoveryFilterChip(
                  key: const Key('home-quick-filter-today'),
                  icon: Icons.wb_sunny_rounded,
                  label: l10n.today,
                  isSelected: isTodaySelected,
                  onTap: onTodayTap,
                );
              case 1:
                return _DiscoveryFilterChip(
                  key: const Key('home-quick-filter-weekend'),
                  icon: Icons.weekend_rounded,
                  label: l10n.thisWeekend,
                  isSelected: isWeekendSelected,
                  onTap: onWeekendTap,
                );
              case 2:
                return _DiscoveryFilterChip(
                  key: const Key('home-quick-filter-free'),
                  icon: Icons.local_offer_rounded,
                  label: l10n.free,
                  isSelected: isFreeSelected,
                  onTap: onFreeTap,
                );
              default:
                return _DiscoveryFilterChip(
                  key: const Key('home-quick-filter-near-me'),
                  icon: isRequestingLocation
                      ? Icons.location_searching_rounded
                      : Icons.near_me_rounded,
                  label: l10n.nearYou,
                  isSelected: isNearMeSelected,
                  onTap: isRequestingLocation ? null : onNearMeTap,
                );
            }
          },
        ),
      ),
    );
  }
}

class _DiscoveryFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DiscoveryFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final foreground = isSelected ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: Material(
        color: isSelected ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: enabled ? 1 : AppTheme.opacityDisabled,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.72)
                      : colors.outlineVariant.withValues(alpha: 0.50),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: foreground, size: AppTheme.iconSm),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
