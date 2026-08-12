import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Bottom sheet shown when a user taps another user's avatar or name.
///
/// The Follow button is stateful — it reads [isFollowing] to show the correct
/// label and icon, and calls [onToggleFollow] which returns the new state so
/// the caller can update its own provider.
class UserActionSheet extends StatelessWidget {
  final String userName;

  /// Whether the current user already follows [userName].
  final bool isFollowing;

  /// Called when the follow/unfollow tile is tapped.
  final VoidCallback onToggleFollow;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const UserActionSheet({
    super.key,
    required this.userName,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onBlock,
    required this.onReport,
  });

  /// Convenience helper to open the sheet without managing a route.
  static Future<void> show(
    BuildContext context, {
    required String userName,
    required bool isFollowing,
    required VoidCallback onToggleFollow,
    required VoidCallback onBlock,
    required VoidCallback onReport,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (_) => UserActionSheet(
        userName: userName,
        isFollowing: isFollowing,
        onToggleFollow: onToggleFollow,
        onBlock: onBlock,
        onReport: onReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(userName, style: text.titleMedium),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Follow / Unfollow ────────────────────────────────────────────
            _ActionTile(
              icon: isFollowing
                  ? Icons.person_remove_rounded
                  : Icons.person_add_rounded,
              label: isFollowing ? 'Unfollow' : 'Follow',
              color: isFollowing ? colors.onSurfaceVariant : colors.primary,
              onTap: () {
                Navigator.pop(context);
                onToggleFollow();
              },
            ),

            const Divider(),

            // ── Block ────────────────────────────────────────────────────────
            _ActionTile(
              icon: Icons.block_rounded,
              label: 'Block User',
              color: appColors.warning,
              onTap: () {
                Navigator.pop(context);
                onBlock();
              },
            ),

            // ── Report ───────────────────────────────────────────────────────
            _ActionTile(
              icon: Icons.flag_rounded,
              label: 'Report User',
              color: appColors.danger,
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: text.bodyLarge?.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
