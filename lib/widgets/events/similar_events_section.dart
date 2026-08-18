import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../theme/theme.dart';
import '../common/event_image_placeholder.dart';

class SimilarEventsSection extends StatelessWidget {
  final Event currentEvent;
  const SimilarEventsSection({super.key, required this.currentEvent});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final similar = eventProvider.events
        .where((e) =>
            e.id != currentEvent.id &&
            e.category.toLowerCase() == currentEvent.category.toLowerCase())
        .take(8)
        .toList();

    if (similar.isEmpty) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.moreLikeThis, style: text.titleMedium)),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.seeAll),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
            itemBuilder: (context, index) {
              final event = similar[index];
              final idx = eventProvider.indexOfEvent(event.id);
              return _SimilarEventCard(event: event, eventIndex: idx);
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarEventCard extends StatelessWidget {
  final Event event;
  final int eventIndex;
  const _SimilarEventCard({required this.event, required this.eventIndex});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: event),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 100,
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(color: appColors.shimmer),
                errorWidget: (_, __, ___) =>
                    EventImagePlaceholder(category: event.category),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d').format(event.dateTime),
                          style: text.labelSmall?.copyWith(color: colors.primary),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: event.isFree
                                ? appColors.eventCostBadge.withValues(alpha: 0.15)
                                : colors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            event.costLabel,
                            style: text.labelSmall?.copyWith(
                              color: event.isFree
                                  ? appColors.eventCostBadge
                                  : colors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
