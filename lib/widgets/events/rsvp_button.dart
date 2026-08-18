import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rsvp_provider.dart';
import '../../theme/theme.dart';

/// Full-width RSVP button with an inline privacy toggle.
/// Shows an RSVP action sheet when the user is not yet RSVP'd.
class RsvpButton extends StatelessWidget {
  const RsvpButton({super.key});

  @override
  Widget build(BuildContext context) {
    final rsvp = context.watch<RsvpProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (!auth.isLoggedIn || auth.isGuest) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/login'),
          icon: const Icon(Icons.login_rounded),
          label: Text(AppLocalizations.of(context)!.logInToRsvp),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    if (rsvp.hasRsvp) {
      return _AttendingTile(rsvp: rsvp, colors: colors, text: text);
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: rsvp.isSubmitting
            ? null
            : () => _showRsvpSheet(context, rsvp, auth),
        icon: rsvp.isSubmitting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : const Icon(Icons.event_available_rounded),
        label: Text(AppLocalizations.of(context)!.rsvpToThisEvent),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showRsvpSheet(
    BuildContext context,
    RsvpProvider rsvp,
    AuthProvider auth,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (_) => _RsvpSheet(rsvp: rsvp, auth: auth),
    );
  }
}

class _AttendingTile extends StatelessWidget {
  final RsvpProvider rsvp;
  final ColorScheme colors;
  final TextTheme text;

  const _AttendingTile({
    required this.rsvp,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.primary, size: AppTheme.iconMd),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.youAreAttending,
                  style: text.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  rsvp.myRsvpIsPrivate ? l10n.privateRsvp : l10n.publicRsvp,
                  style: text.labelSmall?.copyWith(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: rsvp.isSubmitting ? null : () => rsvp.cancelRsvp(),
            child: Text(
              l10n.cancelRsvp,
              style: text.labelMedium?.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _RsvpSheet extends StatefulWidget {
  final RsvpProvider rsvp;
  final AuthProvider auth;

  const _RsvpSheet({required this.rsvp, required this.auth});

  @override
  State<_RsvpSheet> createState() => _RsvpSheetState();
}

class _RsvpSheetState extends State<_RsvpSheet> {
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(l10n.rsvpToThisEvent, style: text.titleLarge),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              l10n.rsvpSubtitle,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // Privacy toggle
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: SwitchListTile(
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
                title: Text(l10n.keepPrivate, style: text.bodyMedium),
                subtitle: Text(
                  _isPrivate
                      ? l10n.onlyCountVisible
                      : l10n.nameWillAppear,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                secondary: Icon(
                  _isPrivate ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: _isPrivate ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final user = widget.auth.user!;
                  Navigator.pop(context);
                  await widget.rsvp.rsvp(
                    userName: user.displayName,
                    avatarUrl: user.avatarUrl,
                    isPrivate: _isPrivate,
                  );
                },
                icon: const Icon(Icons.event_available_rounded),
                label: Text(l10n.confirmRsvp),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
