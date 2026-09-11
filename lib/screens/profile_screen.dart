import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/tour_service.dart';
import '../providers/follow_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/user_event_repository.dart';
import '../services/user_event_service.dart';
import '../theme/theme.dart';
import '../widgets/common/editable_avatar.dart';
import '../widgets/common/app_icon_mark.dart';
import '../widgets/common/follow_stats_row.dart';
import '../widgets/common/guided_tour.dart';
import '../widgets/common/pro_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Guided-tour target keys (static so they stay stable across rebuilds).
  static final GlobalKey _tourKeyPremium = GlobalKey();
  static final GlobalKey _tourKeyLanguage = GlobalKey();
  static final GlobalKey _tourKeyMyEvents = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
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
        appBar: AppBar(
          title: Text(l10n.profile),
          leading: const Padding(
            padding: EdgeInsets.all(8),
            child: AppIconMark(size: 30, glow: false),
          ),
        ),
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
                Text(l10n.browsingAsGuest, style: text.headlineSmall),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.guestPrompt,
                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                FilledButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.signInOrCreate),
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _SettingsTile(
                  icon: Icons.map_outlined,
                  label: l10n.map,
                  onTap: () => context.push('/map'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: l10n.notificationsSettings,
                  onTap: () => context.push('/notifications'),
                ),
                _SettingsTile(
                  icon:
                      themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  label: l10n.darkMode,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                  onTap: null,
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  label: l10n.language,
                  trailing: Text(_currentLanguageLabel(context)),
                  onTap: () => _showLanguageDialog(context),
                ),
                _SettingsTile(
                  icon: Icons.explore_rounded,
                  label: l10n.takeTheTour,
                  onTap: () => _replayTour(context),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: l10n.privacyPolicy,
                  onTap: () => context.push('/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.gavel_rounded,
                  label: l10n.termsOfUse,
                  onTap: () => context.push('/terms'),
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
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: AppIconMark(size: 30, glow: false),
        ),
        actions: [
          IconButton(
            tooltip: l10n.editProfile,
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      // Explicitly keep the last Profile action above Android's system
      // navigation/gesture area. On devices with three-button navigation this
      // prevents the Sign out button from ending underneath the system bar.
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              children: [
                EditableAvatar(
                  imageUrl: user.avatarUrl,
                  fallbackName: user.displayName,
                  size: AppTheme.avatarLg,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Tap to change photo',
                  style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(user.displayName, style: text.headlineSmall),
                const SizedBox(height: AppTheme.spacingXs),
                Text(user.email, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppTheme.spacingSm),
                OutlinedButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.editProfile),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Follower / Following stats ─────────────────────────────────
                FollowStatsRow(followerCount: followers, followingCount: following),
                const SizedBox(height: AppTheme.spacingXl),

                KeyedSubtree(
                  key: _tourKeyPremium,
                  child: auth.isAdmin
                      ? _AdminAccessTile(text: text)
                      : _ProTile(sub: sub, appColors: appColors, text: text),
                ),
                KeyedSubtree(
                  key: _tourKeyMyEvents,
                  child: _SettingsTile(
                    icon: Icons.event_rounded,
                    label: l10n.myEvents,
                    onTap: () => context.push('/my-events'),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.diamond_outlined,
                  label: l10n.myGemsTitle,
                  onTap: () => context.push('/my-gems'),
                ),
                _SettingsTile(
                  icon: Icons.map_outlined,
                  label: l10n.map,
                  onTap: () => context.push('/map'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: l10n.notificationsSettings,
                  onTap: () => context.push('/notifications'),
                ),
                _SettingsTile(
                  icon:
                      themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  label: l10n.darkMode,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.bookmark_rounded,
                  label: l10n.savedEvents,
                  onTap: () => context.push('/saved-events'),
                ),
                KeyedSubtree(
                  key: _tourKeyLanguage,
                  child: _SettingsTile(
                    icon: Icons.language_rounded,
                    label: l10n.language,
                    trailing: Text(_currentLanguageLabel(context)),
                    onTap: () => _showLanguageDialog(context),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.explore_rounded,
                  label: l10n.takeTheTour,
                  onTap: () => _replayTour(context),
                ),
                if (auth.isAdmin)
                  _SettingsTile(
                    icon: Icons.shield_rounded,
                    label: l10n.adminDashboard,
                    onTap: () => context.push('/admin'),
                  ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: l10n.privacyPolicy,
                  onTap: () => context.push('/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.gavel_rounded,
                  label: l10n.termsOfUse,
                  onTap: () => context.push('/terms'),
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  label: l10n.deleteAccount,
                  onTap: () => _confirmDeleteAccount(context),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.signOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                  ),
                ),
              ],
            ),
          ),
          GuidedTour(
            tourId: 'profile',
            steps: [
              TourStep(
                targetKey: _tourKeyPremium,
                title: auth.isAdmin
                    ? l10n.adminAccountAccess
                    : l10n.tourProfile1Title,
                description: auth.isAdmin
                    ? l10n.adminAccountAccessBody
                    : l10n.tourProfile1Body,
              ),
              TourStep(
                targetKey: _tourKeyLanguage,
                title: l10n.tourProfile2Title,
                description: l10n.tourProfile2Body,
              ),
              TourStep(
                targetKey: _tourKeyMyEvents,
                title: l10n.tourProfile3Title,
                description: l10n.tourProfile3Body,
              ),
            ],
            ),
          ],
        ),
      ),
    );
  }

  /// Lets a signed-in person update only their own public organizer name.
  /// Account email, roles, and other users are intentionally not editable here.
  Future<void> _editProfile(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || user.isGuest) return;
    final l10n = AppLocalizations.of(context)!;

    final draft = await showDialog<_ProfileEditDraft>(
      context: context,
      builder: (_) => _EditProfileDialog(initialName: user.displayName),
    );
    if (draft == null || !context.mounted) return;

    final eventService = UserEventService(
      repository: context.read<UserEventRepository>(),
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await auth.updateDisplayName(draft.displayName);
      if (draft.updateExistingEvents) {
        await eventService.updateOrganizerNameForCreator(
          updated.id,
          updated.displayName,
        );
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated)),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  /// Resets all tour "seen" flags and returns home so the tour replays.
  Future<void> _replayTour(BuildContext context) async {
    await TourService.resetAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.tourRestarted)));
    context.go('/');
  }

  /// Shows the account-deletion confirmation and performs the deletion.
  /// Returns the password entered (may be empty) so email accounts can
  /// re-authenticate before the destructive operation.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.deleteAccount(password: password.isEmpty ? null : password);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountDeletedMsg), behavior: SnackBarBehavior.floating),
      );
      if (context.mounted) context.go('/');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Returns the localized label for the currently selected language.
  String _currentLanguageLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (context.read<LocaleProvider>().currentCode) {
      case 'en':
        return l10n.english;
      case 'es':
        return l10n.spanish;
      default:
        return l10n.languageSystemDefault;
    }
  }

  /// Shows a dialog to pick System / English / Español.
  Future<void> _showLanguageDialog(BuildContext context) async {
    final provider = context.read<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    final current = provider.currentCode;

    String? choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return SimpleDialog(
          title: Text(l10n.language),
          children: [
            for (final option in [
              ('system', l10n.languageSystemDefault),
              ('en', l10n.english),
              ('es', l10n.spanish),
            ])
              ListTile(
                leading: Icon(
                  option.$1 == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: option.$1 == current ? colors.primary : colors.onSurfaceVariant,
                ),
                title: Text(option.$2),
                onTap: () => Navigator.pop(dialogContext, option.$1),
              ),
          ],
        );
      },
    );

    if (choice != null) await provider.setCode(choice);
  }
}

class _ProfileEditDraft {
  final String displayName;
  final bool updateExistingEvents;

  const _ProfileEditDraft({
    required this.displayName,
    required this.updateExistingEvents,
  });
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;

  const _EditProfileDialog({required this.initialName});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  bool _updateExistingEvents = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.profileNameRequired);
      return;
    }
    if (name.length > 100) {
      setState(() => _error = l10n.profileNameTooLong);
      return;
    }
    Navigator.pop(
      context,
      _ProfileEditDraft(
        displayName: name,
        updateExistingEvents: _updateExistingEvents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.editProfile),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileNameHelp),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l10n.profileNameLabel,
                hintText: l10n.profileNameHint,
                errorText: _error,
                prefixIcon: const Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            CheckboxListTile(
              value: _updateExistingEvents,
              onChanged: (value) =>
                  setState(() => _updateExistingEvents = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.updateExistingEventNames),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountBody, style: text.bodyMedium),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.passwordEmailAccounts,
              hintText: l10n.optional,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

class _ProTile extends StatelessWidget {
  final SubscriptionProvider sub;
  final AppColorsExtension appColors;
  final TextTheme text;

  const _ProTile({required this.sub, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              appColors.proGold.withValues(alpha: 0.15),
              appColors.proGoldLight.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: appColors.proGold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: appColors.proGold.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                gradient: AppTheme.proGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                boxShadow: [
                  BoxShadow(
                    color: appColors.proGold.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: AppTheme.iconMd,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SpotVibe Premium',
                        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      if (sub.isSubscribed) const ProBadge(),
                    ],
                  ),
                  Text(
                    sub.isSubscribed
                        ? (sub.isInTrial
                            ? l10n.trialActiveLabel(sub.displayPriceLabel)
                            : l10n.activeLabel(sub.displayPriceLabel))
                        : '${sub.displayPriceLabel} ${l10n.afterTrial(l10n.trialLabel)}',
                    style: text.labelSmall?.copyWith(color: appColors.proGold),
                  ),
                ],
              ),
            ),
            Icon(
              sub.isSubscribed ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: appColors.proGold,
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the store subscription promo for administrators. Admin access is
/// role-based and must never imply a store purchase or send the admin to a
/// paywall.
class _AdminAccessTile extends StatelessWidget {
  final TextTheme text;

  const _AdminAccessTile({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.brandViolet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.brandViolet.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.brandViolet.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: AppTheme.iconMd,
              color: AppTheme.brandViolet,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminAccountAccess,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  l10n.adminAccountAccessBody,
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: AppTheme.brandViolet,
          ),
        ],
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
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }
}
