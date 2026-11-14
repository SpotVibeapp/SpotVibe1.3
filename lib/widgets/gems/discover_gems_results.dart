import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/event_provider.dart';
import '../../providers/gem_provider.dart';
import '../../theme/theme.dart';
import 'gem_cover.dart';

/// Hidden Gems that match the Discover search, fetched from real gem docs.
class DiscoverGemsResults extends StatelessWidget {
  const DiscoverGemsResults({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = context.watch<EventProvider>().searchQuery.trim();
    if (query.isEmpty) return const SizedBox.shrink();
    final gems = context.watch<GemProvider>().gemsMatching(query);
    if (gems.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Text(
              l10n.gemsDiscoverSection,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              itemCount: gems.take(8).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final gem = gems[index];
                return SizedBox(
                  width: 160,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/gem', extra: gem),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GemCover(gem: gem, height: 80),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              gem.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
