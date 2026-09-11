import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/gem.dart';
import '../services/maps_service.dart';
import '../theme/theme.dart';
import '../widgets/gems/gem_cover.dart';

/// Detail page for a single hidden gem. Shows the place, a description, any
/// source-provided details (hours, fees, access), and actions to get directions
/// or open its website.
class GemDetailScreen extends StatelessWidget {
  final Gem gem;
  const GemDetailScreen({super.key, required this.gem});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GemCover(gem: gem, height: 220),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(gem.category.icon, size: 18, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        gem.category.label,
                        style: text.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    gem.name,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (gem.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_rounded,
                            size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gem.address,
                            style: text.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    gem.description?.isNotEmpty == true
                        ? gem.description!
                        : gem.summary,
                    style: text.bodyLarge,
                  ),
                  if (gem.details.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      l10n.gemsGoodToKnow,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    ...gem.details.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                e.key,
                                style: text.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant),
                              ),
                            ),
                            Expanded(
                              child: Text(e.value, style: text.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingLg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => MapsService.openDirectionsToCoords(
                            gem.latitude,
                            gem.longitude,
                            label: gem.name,
                          ),
                          icon: const Icon(Icons.directions_rounded),
                          label: Text(l10n.gemsDirections),
                        ),
                      ),
                      if (gem.website != null) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _open(gem.website!),
                            icon: const Icon(Icons.public_rounded),
                            label: Text(l10n.gemsWebsite),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    l10n.gemsAttribution,
                    style: text.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
