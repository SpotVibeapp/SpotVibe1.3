import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_event.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';

class UserEventCard extends StatelessWidget {
  final UserCreatedEvent event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserEventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;
    final dateStr = DateFormat('EEE, MMM d · h:mm a').format(event.dateTime);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or gradient accent bar
            if (event.imageUrl.isNotEmpty)
              _UserEventThumbnail(event: event, appColors: appColors, colors: colors)
            else
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: event.isPremiumListing
                        ? [appColors.proGold, appColors.proGoldLight]
                        : [colors.primary, colors.tertiary],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: text.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.isPremiumListing) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        _FeaturedBadge(appColors: appColors),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: AppTheme.iconSm, color: colors.primary),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(dateStr, style: text.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: AppTheme.iconSm, color: colors.onSurfaceVariant),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(
                          event.fullLocation.isNotEmpty ? event.fullLocation : event.address,
                          style: text.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline_rounded,
                        label: '${event.interestedCount} interested',
                        colors: colors,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      _StatChip(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        colors: colors,
                      ),
                      const Spacer(),
                      // Admin action buttons
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        iconSize: AppTheme.iconSm,
                        tooltip: 'Edit event',
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primaryContainer.withValues(alpha: 0.6),
                          foregroundColor: colors.primary,
                          padding: const EdgeInsets.all(AppTheme.spacingXs),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        iconSize: AppTheme.iconSm,
                        tooltip: 'Delete event',
                        style: IconButton.styleFrom(
                          backgroundColor: colors.errorContainer.withValues(alpha: 0.6),
                          foregroundColor: colors.error,
                          padding: const EdgeInsets.all(AppTheme.spacingXs),
                          minimumSize: const Size(32, 32),
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
    );
  }
}

class _UserEventThumbnail extends StatelessWidget {
  final UserCreatedEvent event;
  final AppColorsExtension appColors;
  final ColorScheme colors;

  const _UserEventThumbnail({
    required this.event,
    required this.appColors,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: event.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: appColors.shimmer),
              errorWidget: (_, __, ___) =>
                  EventImagePlaceholder(category: event.category, height: 160),
            ),
            // Bottom gradient scrim so badges remain readable
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Cost badge — top right
            Positioned(
              top: AppTheme.spacingSm,
              right: AppTheme.spacingSm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: event.cost == null || event.cost == 0
                      ? appColors.eventCostBadge
                      : colors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  event.cost == null || event.cost == 0
                      ? 'Free'
                      : '\$${event.cost!.toStringAsFixed(2)}',
                  style: text.labelSmall?.copyWith(
                    color: event.cost == null || event.cost == 0
                        ? colors.surface
                        : colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Featured badge — top left (Pro events only)
            if (event.isPremiumListing)
              Positioned(
                top: AppTheme.spacingSm,
                left: AppTheme.spacingSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [appColors.proGold, appColors.proGoldLight]),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  final AppColorsExtension appColors;
  const _FeaturedBadge({required this.appColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [appColors.proGold, appColors.proGoldLight]),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: const Text(
        'FEATURED',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;

  const _StatChip({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
