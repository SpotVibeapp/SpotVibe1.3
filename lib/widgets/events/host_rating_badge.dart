import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event_review.dart';
import '../../services/event_review_service.dart';
import '../../theme/theme.dart';

class HostRatingBadge extends StatelessWidget {
  final String hostId;
  final EventReviewService? service;

  const HostRatingBadge({super.key, required this.hostId, this.service});

  @override
  Widget build(BuildContext context) {
    if (hostId.isEmpty) return const SizedBox.shrink();
    final svc = service ?? EventReviewService();
    return StreamBuilder<ReviewStats>(
      stream: svc.watchHostStats(hostId),
      builder: (context, snap) {
        final stats = snap.data;
        if (stats == null || !stats.hasRating) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                l10n.eventReviewHostRating(stats.avgStars.toStringAsFixed(1), stats.count),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class GemRatingBadge extends StatelessWidget {
  final String gemId;
  final EventReviewService? service;

  const GemRatingBadge({super.key, required this.gemId, this.service});

  @override
  Widget build(BuildContext context) {
    if (gemId.isEmpty) return const SizedBox.shrink();
    final svc = service ?? EventReviewService();
    return StreamBuilder<ReviewStats>(
      stream: svc.watchGemStats(gemId),
      builder: (context, snap) {
        final stats = snap.data;
        if (stats == null || !stats.hasRating) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingXs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 2),
              Text(
                l10n.eventReviewHostRating(stats.avgStars.toStringAsFixed(1), stats.count),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
