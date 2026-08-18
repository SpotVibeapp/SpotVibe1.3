import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/event_time.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';
import '../common/source_badge.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onInterested;
  /// When non-null, shows a "X.X mi" distance chip next to the location row.
  final double? distanceMiles;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onBookmark,
    required this.onInterested,
    this.distanceMiles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventImage(event: event, appColors: appColors),
            _EventDetails(
              event: event,
              onBookmark: onBookmark,
              onInterested: onInterested,
              distanceMiles: distanceMiles,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final Event event;
  final AppColorsExtension appColors;

  const _EventImage({required this.event, required this.appColors});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final catColor = categoryAccent(event.category);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: event.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: appColors.shimmer),
              errorWidget: (_, __, ___) => EventImagePlaceholder(category: event.category, height: 180),
            ),
            // Category-tinted scrim fading up from the bottom of the photo.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 46,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        catColor.withValues(alpha: 0.55),
                        catColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppTheme.spacingSm,
              left: AppTheme.spacingSm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: catColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  formatEventDayChip(event.dateTime),
                  style: text.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppTheme.spacingSm,
              right: AppTheme.spacingSm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: event.isFree ? appColors.eventCostBadge : colors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  event.costLabel,
                  style: text.labelMedium?.copyWith(
                    color: event.isFree ? colors.surface : colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (event.isFeaturedThisWeek)
              Positioned(
                bottom: AppTheme.spacingSm,
                right: AppTheme.spacingSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [appColors.proGold, appColors.proGoldLight]),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    l10n.featured,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            if (SourceBadge.isHonest(event.source))
              Positioned(
                bottom: AppTheme.spacingSm,
                left: AppTheme.spacingSm,
                child: SourceBadge(source: event.source),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventDetails extends StatelessWidget {
  final Event event;
  final VoidCallback onBookmark;
  final VoidCallback onInterested;
  final double? distanceMiles;

  const _EventDetails({
    required this.event,
    required this.onBookmark,
    required this.onInterested,
    this.distanceMiles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;
    final catColor = categoryAccent(event.category);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    event.category,
                    style: text.labelSmall?.copyWith(
                      color: catColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: AppTheme.iconSm, color: appColors.subtleText),
              const SizedBox(width: AppTheme.spacingXs),
              Flexible(
                child: Text(
                  formatEventWhen(event.dateTime),
                  style: text.labelSmall?.copyWith(color: appColors.subtleText),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            event.title,
            style: text.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: AppTheme.iconSm, color: appColors.subtleText),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  event.location,
                  style: text.bodySmall?.copyWith(color: appColors.subtleText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (distanceMiles != null) ...[
                const SizedBox(width: AppTheme.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded,
                          size: 10, color: colors.onPrimaryContainer),
                      const SizedBox(width: 2),
                      Text(
                        distanceMiles! < 0.1
                            ? l10n.underTenthMi
                            : l10n.miShort(distanceMiles!.toStringAsFixed(1)),
                        style: text.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              _ActionChip(
                icon: event.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: '${event.bookmarkedCount}',
                isActive: event.isBookmarked,
                activeColor: catColor,
                onTap: onBookmark,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _ActionChip(
                icon: event.isInterested ? Icons.star_rounded : Icons.star_border_rounded,
                label: '${event.interestedCount}',
                isActive: event.isInterested,
                activeColor: catColor,
                onTap: onInterested,
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.byOrganizer(event.organizerName),
                  style: text.labelSmall?.copyWith(color: appColors.subtleText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  /// Tint applied to the chip when active (the event's category color).
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.45)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppTheme.iconSm,
              color: isActive ? activeColor : colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: isActive ? activeColor : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
