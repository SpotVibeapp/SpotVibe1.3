import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/gem.dart';
import '../providers/auth_provider.dart';
import '../providers/gem_provider.dart';
import '../services/location_service.dart';
import '../theme/theme.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/gems/gem_cover.dart';

/// Hidden Gems tab — a browsable directory of overlooked local *places*
/// (trails, parks, viewpoints, pools, museums, murals, historic sites and
/// quirky attractions). National by design: it geocodes any typed city and
/// pulls gems from OpenStreetMap, so no per-city curation is ever required.
class GemsScreen extends StatefulWidget {
  const GemsScreen({super.key});

  @override
  State<GemsScreen> createState() => _GemsScreenState();
}

class _GemsScreenState extends State<GemsScreen> {
  final _searchController = TextEditingController();
  final _locationService = LocationService();
  bool _bootstrapped = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped || !mounted) return;
    _bootstrapped = true;
    final provider = context.read<GemProvider>();
    if (provider.hasLocation) return;

    final coords = await _locationService.getCurrentLocation(
      requestPermission: false,
    );
    if (!mounted) return;
    if (coords != null) {
      await provider.loadForCoordinates(
        lat: coords.lat,
        lng: coords.lng,
        label: AppLocalizations.of(context)!.nearYou,
      );
    } else {
      // No location permission yet — show the newest community gems anywhere.
      await provider.loadAll();
    }
  }

  void _addGem() {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gemsSignInToAdd)),
      );
      return;
    }
    context.push('/gems/add').then((added) {
      if (added == true && mounted) {
        context.read<GemProvider>().refresh();
      }
    });
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<GemProvider>();
    setState(() => _locating = true);
    final coords =
        await _locationService.getCurrentLocation(requestPermission: true);
    if (!mounted) return;
    setState(() => _locating = false);
    if (coords != null) {
      _searchController.clear();
      await provider.loadForCoordinates(
        lat: coords.lat,
        lng: coords.lng,
        label: l10n.nearYou,
      );
    } else {
      final permanentlyDenied = await _locationService.isPermanentlyDenied();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.couldNotGetLocation),
          action: permanentlyDenied
              ? SnackBarAction(
                  label: l10n.openSettings,
                  onPressed: _locationService.openAppSettings,
                )
              : null,
        ),
      );
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final provider = context.read<GemProvider>();
    final ok = await provider.loadForQuery(trimmed);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t find "$trimmed". Try a larger nearby city.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final provider = context.watch<GemProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGem,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(l10n.gemsAddButton),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacingMd,
                  AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingXs),
              child: Row(
                children: [
                  Icon(Icons.diamond_rounded, color: colors.primary, size: 26),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.gemsTitle,
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          l10n.gemsSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingXs),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: l10n.gemsSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  IconButton.filledTonal(
                    onPressed: _locating ? null : _useMyLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    tooltip: l10n.gemsUseMyLocation,
                  ),
                ],
              ),
            ),
            if (provider.areaLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: AppTheme.iconSm, color: colors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.gemsShowingIn(provider.areaLabel),
                        style: text.labelSmall?.copyWith(color: colors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (provider.availableCategories.isNotEmpty)
              _GemCategoryChips(provider: provider),
            Expanded(child: _body(context, provider, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _body(
      BuildContext context, GemProvider provider, AppLocalizations l10n) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final gems = provider.gems;
    if (gems.isEmpty) {
      return EmptyStateView(
        variant: EmptyStateVariant.noEventsNearby,
        icon: Icons.travel_explore_rounded,
        title: l10n.gemsEmptyTitle,
        subtitle: l10n.gemsEmptySubtitle,
        actionLabel: l10n.gemsUseMyLocation,
        onAction: _useMyLocation,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppTheme.spacingMd, AppTheme.spacingSm,
            AppTheme.spacingMd, AppTheme.spacingLg),
        itemCount: gems.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSm),
        itemBuilder: (context, index) {
          if (index == gems.length) {
            return Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: Text(
                l10n.gemsAttribution,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          }
          return _GemCard(gem: gems[index]);
        },
      ),
    );
  }
}

class _GemCategoryChips extends StatelessWidget {
  final GemProvider provider;
  const _GemCategoryChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cats = provider.availableCategories;
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: ChoiceChip(
              label: Text(l10n.gemsAllCategories),
              selected: provider.categoryFilter == null,
              onSelected: (_) => provider.selectCategory(null),
            ),
          ),
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: ChoiceChip(
                avatar: Icon(c.icon, size: 16),
                label: Text(c.label),
                selected: provider.categoryFilter == c,
                onSelected: (_) => provider.selectCategory(
                    provider.categoryFilter == c ? null : c),
              ),
            ),
        ],
      ),
    );
  }
}

class _GemCard extends StatelessWidget {
  final Gem gem;
  const _GemCard({required this.gem});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/gem', extra: gem),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GemCover(gem: gem, height: 130),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gem.name,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gem.summary,
                    style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (gem.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_rounded,
                            size: 14, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gem.address,
                            style: text.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
