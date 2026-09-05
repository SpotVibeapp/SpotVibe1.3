import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/notification_preferences_provider.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../theme/theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _sendingTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationPreferencesProvider>().load();
    });
  }

  Future<void> _sendTestNotification() async {
    if (_sendingTest) return;

    final permissionService = context.read<PermissionService>();
    final notificationService = context.read<NotificationService>();
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sendingTest = true);

    var allowed = await permissionService.isNotificationGranted();
    if (!allowed) {
      allowed = await permissionService.requestNotifications();
    }

    var sent = false;
    if (allowed) {
      sent = await notificationService.sendTestNotification(
        title: l10n.notificationTestAlertTitle,
        body: l10n.notificationTestAlertBody,
      );
    }

    if (!mounted) return;
    setState(() => _sendingTest = false);

    final messenger = ScaffoldMessenger.of(context);
    if (!allowed) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.notificationPermissionNeeded),
          action: SnackBarAction(
            label: l10n.openSettings,
            onPressed: () {
              unawaited(permissionService.openDeviceSettings());
            },
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sent ? l10n.notificationTestSent : l10n.notificationTestFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<NotificationPreferencesProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Notification Preferences', style: text.titleLarge),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.outlineVariant),
        ),
      ),
      body: prefs.isLoaded
          ? _PrefsBody(
              prefs: prefs,
              isSendingTest: _sendingTest,
              onSendTest: _sendTestNotification,
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _PrefsBody extends StatelessWidget {
  const _PrefsBody({
    required this.prefs,
    required this.isSendingTest,
    required this.onSendTest,
  });

  final NotificationPreferencesProvider prefs;
  final bool isSendingTest;
  final VoidCallback onSendTest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: colors.primary.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: colors.primary),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        l10n.notificationTestTitle,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.notificationTestBody,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                FilledButton.tonalIcon(
                  onPressed: isSendingTest ? null : onSendTest,
                  icon: isSendingTest
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(l10n.sendTestNotification),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // ── A. Event Reminders ─────────────────────────────────────────────
        _SectionHeader(icon: Icons.alarm_rounded, label: 'Event Reminders', color: colors.tertiary),
        _PrefTile(
          title: 'Event reminders',
          subtitle: '1 hour before, day-of at 3 PM, and 24 hours before',
          value: prefs.eventReminders,
          onChanged: prefs.toggleEventReminders,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Divider(
          indent: AppTheme.spacingMd,
          endIndent: AppTheme.spacingMd,
          color: colors.outlineVariant,
        ),

        // ── B. New Events (Discover) ───────────────────────────────────────
        _SectionHeader(
          icon: Icons.celebration_rounded,
          label: 'New Events Near You',
          color: colors.primary,
        ),
        _PrefTile(
          title: 'Weekly digest',
          subtitle: 'Every Friday morning — a curated list of upcoming events',
          value: prefs.weeklyDigest,
          onChanged: prefs.toggleWeeklyDigest,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alert categories', style: text.titleSmall?.copyWith(color: colors.onSurface)),
              GestureDetector(
                onTap: prefs.enableAllCategories,
                child: Text(
                  'Enable all',
                  style: text.labelMedium?.copyWith(
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children:
                kNotificationCategories.map((cat) {
                  final enabled = prefs.isCategoryEnabled(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: enabled,
                    onSelected: (v) => prefs.toggleCategory(cat, v),
                    selectedColor: colors.primaryContainer,
                    checkmarkColor: colors.onPrimaryContainer,
                    labelStyle: text.labelMedium?.copyWith(
                      color: enabled ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                      fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: enabled ? colors.primary : colors.outlineVariant,
                      width: enabled ? AppTheme.borderSelected : AppTheme.borderDefault,
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Divider(
          indent: AppTheme.spacingMd,
          endIndent: AppTheme.spacingMd,
          color: colors.outlineVariant,
        ),

        // ── C. Social ─────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.people_rounded, label: 'Social', color: const Color(0xFFE84393)),
        _PrefTile(
          title: 'Comments on my events',
          subtitle: 'Get notified when someone comments on your event',
          value: prefs.socialComments,
          onChanged: prefs.toggleSocialComments,
        ),
        _PrefTile(
          title: 'Friends going to events',
          subtitle: 'When a friend RSVPs to an event you might like',
          value: prefs.socialFriendRsvp,
          onChanged: prefs.toggleSocialFriendRsvp,
        ),
        _PrefTile(
          title: 'Friend requests',
          subtitle: 'When someone sends you a friend request',
          value: prefs.socialFriendRequests,
          onChanged: prefs.toggleSocialFriendRequests,
        ),
        const SizedBox(height: AppTheme.spacingXl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Text(
            'Push notifications are delivered via your device. You can also manage '
            'notifications in your device Settings → SpotVibe.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: AppTheme.avatarSm,
            height: AppTheme.avatarSm,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppTheme.opacityHint * 0.4),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: AppTheme.iconSm + 2),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(label, style: text.titleSmall?.copyWith(color: colors.onSurface)),
        ],
      ),
    );
  }
}

// ── Toggle preference tile ────────────────────────────────────────────────────

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      title: Text(
        title,
        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colors.onSurface),
      ),
      subtitle: Text(subtitle, style: text.bodySmall),
      value: value,
      onChanged: onChanged,
      activeTrackColor: colors.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
    );
  }
}
