import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../services/deep_link_service.dart';
import '../services/permission_service.dart';
import '../theme/theme.dart';
import '../widgets/common/spotvibe_logo.dart';

/// Shown once on first launch to request location and notification permissions.
/// After the user grants or skips both, they are sent to the main app.
class PermissionPromptScreen extends StatefulWidget {
  final PermissionService permissionService;

  const PermissionPromptScreen({
    super.key,
    required this.permissionService,
  });

  @override
  State<PermissionPromptScreen> createState() => _PermissionPromptScreenState();
}

class _PermissionPromptScreenState extends State<PermissionPromptScreen> {
  bool _locationGranted = false;
  bool _notifGranted = false;
  bool _locationLoading = false;
  bool _notifLoading = false;
  bool _locationDone = false;
  bool _notifDone = false;

  Future<void> _requestLocation() async {
    if (_locationLoading || _locationDone) return;
    setState(() => _locationLoading = true);
    final granted = await widget.permissionService.requestLocation();
    if (mounted) {
      setState(() {
        _locationGranted = granted;
        _locationLoading = false;
        _locationDone = true;
      });
    }
  }

  Future<void> _requestNotifs() async {
    if (_notifLoading || _notifDone) return;
    setState(() => _notifLoading = true);
    final granted = await widget.permissionService.requestNotifications();
    if (mounted) {
      setState(() {
        _notifGranted = granted;
        _notifLoading = false;
        _notifDone = true;
      });
    }
  }

  Future<void> _finish() async {
    await widget.permissionService.markAsked();
    if (!mounted) return;
    // If the user arrived via a deep link on their very first install, a
    // pending path was saved before they were sent here.  Restore it so they
    // land on the event they originally tapped rather than the home feed.
    final pending = await DeepLinkService.consumePendingLink();
    if (mounted) context.go(pending ?? '/');
  }

  bool get _canFinish => _locationDone || _notifDone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header gradient banner ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingXl,
                AppTheme.spacingLg,
                AppTheme.spacingLg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.tertiary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SpotVibeLogo(size: 56),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    l10n.setupTitle,
                    style: text.headlineSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    l10n.setupBody,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            // ── Permission cards ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spacingSm),

                    // Location card
                    _PermissionCard(
                      icon: Icons.location_on_rounded,
                      iconColor: colors.primary,
                      title: l10n.location,
                      description: l10n.locationCardDesc,
                      granted: _locationGranted,
                      done: _locationDone,
                      loading: _locationLoading,
                      onAllow: _requestLocation,
                    ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // Notifications card
                    _PermissionCard(
                      icon: Icons.notifications_rounded,
                      iconColor: colors.tertiary,
                      title: l10n.notifications,
                      description: l10n.notifCardDesc,
                      granted: _notifGranted,
                      done: _notifDone,
                      loading: _notifLoading,
                      onAllow: _requestNotifs,
                    ),

                    const SizedBox(height: AppTheme.spacingXl),

                    // Continue / Skip button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canFinish ? _finish : null,
                        child: Text(l10n.continueBtn),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingSm),

                    // Skip all
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.skipForNow,
                        style: text.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // Fine-print
                    Text(
                      l10n.changeSettingsAnytime,
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(
                            alpha: AppTheme.opacityHint),
                      ),
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

// ── Permission card widget ─────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool granted;
  final bool done;
  final bool loading;
  final VoidCallback onAllow;

  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.granted,
    required this.done,
    required this.loading,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: done && granted
            ? colors.primaryContainer.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: done && granted
              ? colors.primary.withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.4),
          width: done && granted ? AppTheme.borderSelected : AppTheme.borderDefault,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done && granted
                  ? colors.primaryContainer
                  : iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: done && granted
                ? Icon(Icons.check_rounded,
                    color: colors.onPrimaryContainer, size: AppTheme.iconMd)
                : Icon(icon, color: iconColor, size: AppTheme.iconMd),
          ),

          const SizedBox(width: AppTheme.spacingMd),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (done && !granted) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.denied,
                          style: text.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                    if (done && granted) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.allowed,
                          style: text.labelSmall?.copyWith(
                              color: colors.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(description,
                    style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant)),
                if (!done) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: loading ? null : onAllow,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        side: BorderSide(color: iconColor.withValues(alpha: 0.6)),
                        foregroundColor: iconColor,
                      ),
                      child: loading
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: iconColor),
                            )
                          : Text(AppLocalizations.of(context)!.allow),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
