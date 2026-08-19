import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/partner_promo_code.dart';
import '../providers/auth_provider.dart';
import '../providers/partner_promo_provider.dart';
import '../theme/theme.dart';

/// Admin-only inventory and issuance screen for App Store / Google Play offer
/// codes. It never creates a home-grown Premium unlock code: administrators
/// stock codes generated in the relevant storefront, then issue one code to one
/// business partner from this tab.
class AdminPartnerPromoCodesTab extends StatelessWidget {
  const AdminPartnerPromoCodesTab({
    super.key,
    required this.provider,
  });

  final PartnerPromoProvider provider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final available = provider.availableCodes;
    final issued = provider.issuedCodes;
    final revoked = provider.codes.where((code) => code.isRevoked).toList();

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          _StoreCodeNotice(colors: colors, text: text),
          const SizedBox(height: AppTheme.spacingMd),
          FilledButton.icon(
            onPressed: provider.busy ? null : () => _showStockCodeDialog(context),
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Add store-issued code'),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _ErrorBanner(
              message: provider.error!,
              onDismiss: provider.clearError,
            ),
          ],
          const SizedBox(height: AppTheme.spacingXl),
          _SectionHeader(
            title: 'Ready to issue',
            count: available.length,
            subtitle: 'Each code can be assigned to one partner only.',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (available.isEmpty)
            _EmptyCodesState(
              icon: Icons.inventory_2_outlined,
              title: 'No codes in inventory',
              body: 'Create a one-time offer-code batch in App Store Connect or Google Play Console, then add each code here before you meet a partner.',
            )
          else
            ...available.map(
              (code) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: _PartnerCodeCard(
                  code: code,
                  busy: provider.busy,
                  onCopy: () => _copyCode(context, code.code),
                  onIssue: () => _showIssueDialog(context, code),
                  onRevoke: () => _confirmRevoke(context, code),
                ),
              ),
            ),
          const SizedBox(height: AppTheme.spacingXl),
          _SectionHeader(
            title: 'Issued partners',
            count: issued.length,
            subtitle: 'Issued codes stay assigned and cannot be handed to another partner.',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (issued.isEmpty)
            const _EmptyCodesState(
              icon: Icons.handshake_outlined,
              title: 'Nothing issued yet',
              body: 'Assign an available code when you are ready to give a partner their store offer.',
            )
          else
            ...issued.map(
              (code) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: _PartnerCodeCard(
                  code: code,
                  busy: provider.busy,
                  onCopy: () => _copyCode(context, code.code),
                  onIssue: null,
                  onRevoke: () => _confirmRevoke(context, code),
                ),
              ),
            ),
          if (revoked.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXl),
            _SectionHeader(
              title: 'Revoked',
              count: revoked.length,
              subtitle: 'Revoke it in the matching storefront too if it has not been redeemed.',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...revoked.map(
              (code) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: _PartnerCodeCard(
                  code: code,
                  busy: provider.busy,
                  onCopy: () => _copyCode(context, code.code),
                  onIssue: null,
                  onRevoke: null,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Future<void> _showStockCodeDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final adminUid = auth.user?.id;
    if (adminUid == null) return;

    final codeController = TextEditingController();
    final offerController = TextEditingController(text: 'Partner Premium');
    final durationController = TextEditingController();
    var platform = PartnerPromoPlatform.android;
    var saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add store-issued code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste a one-time code already created in App Store Connect or Google Play Console. The offer and duration below are for your admin records; the storefront controls the real billing terms.',
                ),
                const SizedBox(height: AppTheme.spacingMd),
                DropdownButtonFormField<PartnerPromoPlatform>(
                  initialValue: platform,
                  decoration: const InputDecoration(labelText: 'Store'),
                  items: PartnerPromoPlatform.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item == PartnerPromoPlatform.android
                              ? 'Google Play / Android'
                              : 'App Store / iPhone'),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null) setDialogState(() => platform = value);
                        },
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextField(
                  controller: codeController,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Store-issued one-time code',
                    hintText: 'Paste code exactly as generated',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextField(
                  controller: offerController,
                  decoration: const InputDecoration(
                    labelText: 'Offer label',
                    hintText: 'Example: Partner Premium',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Store offer duration / terms',
                    hintText: 'Example: 90-day free period',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      final created = await provider.stockStoreCode(
                        code: codeController.text,
                        platform: platform,
                        offerLabel: offerController.text,
                        durationLabel: durationController.text,
                        adminUid: adminUid,
                      );
                      if (!dialogContext.mounted) return;
                      if (created == null) {
                        setDialogState(() {
                          saving = false;
                          error = provider.error ?? 'Could not add the code.';
                        });
                        return;
                      }
                      Navigator.pop(dialogContext);
                    },
              child: Text(saving ? 'Adding…' : 'Add to inventory'),
            ),
          ],
        ),
      ),
    );

    codeController.dispose();
    offerController.dispose();
    durationController.dispose();
  }

  Future<void> _showIssueDialog(BuildContext context, PartnerPromoCode code) async {
    final auth = context.read<AuthProvider>();
    final adminUid = auth.user?.id;
    if (adminUid == null) return;

    final partnerController = TextEditingController();
    final emailController = TextEditingController();
    var saving = false;
    String? error;

    final issued = await showDialog<PartnerPromoCode>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Issue partner code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code.offerLabel, style: Theme.of(dialogContext).textTheme.titleSmall),
                Text('${code.platformLabel} · ${code.durationLabel}'),
                const SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: partnerController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Partner or business name',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Partner email (optional)',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      final result = await provider.issueCode(
                        codeId: code.id,
                        partnerName: partnerController.text,
                        partnerEmail: emailController.text,
                        adminUid: adminUid,
                      );
                      if (!dialogContext.mounted) return;
                      if (result == null) {
                        setDialogState(() {
                          saving = false;
                          error = provider.error ?? 'Could not issue the code.';
                        });
                        return;
                      }
                      Navigator.pop(dialogContext, result);
                    },
              icon: const Icon(Icons.send_rounded),
              label: Text(saving ? 'Issuing…' : 'Issue code'),
            ),
          ],
        ),
      ),
    );

    partnerController.dispose();
    emailController.dispose();

    if (issued != null && context.mounted) {
      await _showIssuedCodeDialog(context, issued);
    }
  }

  Future<void> _showIssuedCodeDialog(BuildContext context, PartnerPromoCode code) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Code ready to share'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(code.partnerName ?? 'Partner', style: Theme.of(dialogContext).textTheme.titleSmall),
            Text('${code.platformLabel} · ${code.durationLabel}'),
            const SizedBox(height: AppTheme.spacingMd),
            SelectableText(
              code.code,
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            const Text(
              'Give this code only to the assigned partner. They redeem it through the matching store purchase flow.',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _copyCode(dialogContext, code.code),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy code'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, PartnerPromoCode code) async {
    final auth = context.read<AuthProvider>();
    final adminUid = auth.user?.id;
    if (adminUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke this inventory record?'),
        content: Text(
          'This marks ${code.code} as revoked in SpotVibe so it cannot be issued again. You must also deactivate it in ${code.platformLabel} if the store still allows redemption.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await provider.revokeCode(codeId: code.id, adminUid: adminUid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Partner code revoked.' : provider.error ?? 'Could not revoke code.')),
    );
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store code copied.')),
    );
  }
}

class _StoreCodeNotice extends StatelessWidget {
  const _StoreCodeNotice({required this.colors, required this.text});

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, color: colors.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store-issued partner offers only',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Create the one-time code and its free-access terms in App Store Connect or Google Play Console first. This dashboard safely inventories and assigns that code to one partner; it does not create a custom Premium unlock.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.subtitle,
  });

  final String title;
  final int count;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Text('$count', style: text.labelSmall),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _EmptyCodesState extends StatelessWidget {
  const _EmptyCodesState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, size: AppTheme.iconLg, color: colors.onSurfaceVariant),
          const SizedBox(height: AppTheme.spacingSm),
          Text(title, style: text.titleSmall),
          const SizedBox(height: 2),
          Text(
            body,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, color: colors.onErrorContainer),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

class _PartnerCodeCard extends StatelessWidget {
  const _PartnerCodeCard({
    required this.code,
    required this.busy,
    required this.onCopy,
    required this.onIssue,
    required this.onRevoke,
  });

  final PartnerPromoCode code;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback? onIssue;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final statusColor = switch (code.status) {
      PartnerPromoStatus.available => colors.primary,
      PartnerPromoStatus.issued => colors.tertiary,
      PartnerPromoStatus.revoked => colors.error,
    };
    final issuedAt = code.issuedAt;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code.code,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy store code',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  code.statusLabel,
                  style: text.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(code.offerLabel, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(
            '${code.platformLabel} · ${code.durationLabel}',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (code.isIssued) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Issued to ${code.partnerName ?? 'partner'}${(code.partnerEmail?.isNotEmpty ?? false) ? ' · ${code.partnerEmail}' : ''}',
              style: text.bodySmall,
            ),
            if (issuedAt != null)
              Text(
                DateFormat('MMM d, yyyy · h:mm a').format(issuedAt),
                style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
          if (code.isRevoked) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Also deactivate this code in ${code.platformLabel} if it is still redeemable there.',
              style: text.bodySmall?.copyWith(color: colors.error),
            ),
          ],
          if (onIssue != null || onRevoke != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRevoke != null)
                  TextButton(
                    onPressed: busy ? null : onRevoke,
                    child: Text('Revoke', style: TextStyle(color: colors.error)),
                  ),
                if (onIssue != null) ...[
                  const SizedBox(width: AppTheme.spacingSm),
                  FilledButton.icon(
                    onPressed: busy ? null : onIssue,
                    icon: const Icon(Icons.send_rounded, size: AppTheme.iconSm),
                    label: const Text('Issue'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
