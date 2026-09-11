import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/gem.dart';
import '../providers/auth_provider.dart';
import '../services/gem_service.dart';
import '../theme/theme.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/gems/gem_cover.dart';

/// Lists the hidden gems the signed-in user has submitted, so they can find
/// and edit or delete their own contributions in one place.
class MyGemsScreen extends StatefulWidget {
  const MyGemsScreen({super.key});

  @override
  State<MyGemsScreen> createState() => _MyGemsScreenState();
}

class _MyGemsScreenState extends State<MyGemsScreen> {
  List<Gem> _gems = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  GemService get _service => context.read<GemService>();
  AuthProvider get _auth => context.read<AuthProvider>();

  Future<void> _load() async {
    final uid = _auth.user?.id;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final gems = await _service.getGemsForUser(uid);
      if (!mounted) return;
      setState(() {
        _gems = gems;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myGemsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _gems.isEmpty
              ? EmptyStateView(
                  icon: Icons.diamond_outlined,
                  title: l10n.myGemsEmptyTitle,
                  subtitle: l10n.myGemsEmptySubtitle,
                  actionLabel: l10n.gemsAddButton,
                  onAction: () => _openAdd(),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: _gems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, index) {
                      final gem = _gems[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingXs,
                          ),
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              child: GemCover(gem: gem, height: 56),
                            ),
                          ),
                          title: Text(
                            gem.name,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            gem.address.isNotEmpty ? gem.address : gem.summary,
                            style: text.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openGem(gem),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _gems.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.gemsAddButton),
            ),
    );
  }

  Future<void> _openGem(Gem gem) async {
    final changed = await context.push('/gem', extra: gem);
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _openAdd() async {
    final added = await context.push('/gems/add');
    if (added == true && mounted) {
      await _load();
    }
  }
}
