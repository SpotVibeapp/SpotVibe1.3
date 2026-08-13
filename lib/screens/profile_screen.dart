import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme.dart';
import '../widgets/common/app_avatar.dart';
import '../widgets/common/follow_stats_row.dart';
import '../widgets/common/pro_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;
    final user = auth.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ── Guest Profile ────────────────────────────────────────────────────────
    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppTheme.avatarLg,
                  height: AppTheme.avatarLg,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: AppTheme.iconXl,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Browsing as Guest', style: text.headlineSmall),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Create an account to RSVP, leave comments, create events, and connect with others.',
                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                FilledButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In or Create Account'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _SettingsTile(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  onTap: () => context.push('/map'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
                _SettingsTile(
                  icon: themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                  onTap: null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final follow = context.watch<FollowProvider>();
    final followers = follow.followerCount(user.id);
    final following = follow.followingCount(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            AppAvatar(imageUrl: user.avatarUrl, size: AppTheme.avatarLg, fallbackName: user.displayName),
            const SizedBox(height: AppTheme.spacingMd),
            Text(user.displayName, style: text.headlineSmall),
            const SizedBox(height: AppTheme.spacingXs),
            Text(user.email, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Follower / Following stats ─────────────────────────────────
            FollowStatsRow(
              followerCount: followers,
              followingCount: following,
            ),
            const SizedBox(height: AppTheme.spacingXl),

            _ProTile(isSubscribed: sub.isSubscribed, appColors: appColors, text: text),
            _SettingsTile(
              icon: Icons.event_rounded,
              label: 'My Events',
              onTap: () => context.push('/my-events'),
            ),
            _SettingsTile(
              icon: Icons.map_outlined,
              label: 'Map',
              onTap: () => context.push('/map'),
            ),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => context.push('/notifications'),
            ),
            _SettingsTile(
              icon: themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              label: 'Dark Mode',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
            _SettingsTile(icon: Icons.bookmark_rounded, label: 'Saved Events', onTap: () => context.push('/saved-events')),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProTile extends StatelessWidget {
  final bool isSubscribed;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _ProTile({required this.isSubscribed, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [appColors.proGold.withValues(alpha: 0.15), appColors.proGoldLight.withValues(alpha: 0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: appColors.proGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [appColors.proGold, appColors.proGoldLight]),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: AppTheme.iconMd, color: Colors.white),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('SpotVibe Premium', style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: AppTheme.spacingSm),
                      if (isSubscribed) const ProBadge(),
                    ],
                  ),
                  Text(
                    isSubscribed
                        ? 'Active — \$15/month'
                        : '\$15/month · recurring events, claims, analytics',
                    style: text.labelSmall?.copyWith(color: appColors.proGold),
                  ),
                ],
              ),
            ),
            Icon(
              isSubscribed ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: appColors.proGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.label, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(icon, size: AppTheme.iconMd, color: colors.primary),
      ),
      title: Text(label, style: text.bodyLarge),
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant) : null),
      onTap: onTap,
    );
  }
}
