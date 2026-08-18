import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/event_claim.dart';
import '../models/user_report.dart';
import '../providers/moderation_provider.dart';
import '../theme/category_colors.dart';
import '../theme/theme.dart';

/// Admin-only moderation screen: review user reports, remove harmful events,
/// moderate venue claims, and ban users. Reached from Profile when the
/// signed-in user is an administrator.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModerationProvider>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final mod = context.watch<ModerationProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminDashboard),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.flag_rounded),
                text: l10n.adminReports,
              ),
              Tab(
                icon: const Icon(Icons.event_rounded),
                text: l10n.adminEvents,
              ),
              Tab(
                icon: const Icon(Icons.store_rounded),
                text: l10n.adminClaims,
              ),
            ],
          ),
        ),
        body: mod.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _ReportsTab(provider: mod),
                  _EventsTab(provider: mod, search: _search),
                  _ClaimsTab(provider: mod),
                ],
              ),
        backgroundColor: colors.surface,
      ),
    );
  }
}

// ── Reports tab ───────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  final ModerationProvider provider;

  const _ReportsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final reports = provider.reports;
    final banned = provider.bannedUserIds;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        if (reports.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
            child: Column(
              children: [
                Icon(Icons.verified_rounded, size: 56, color: colors.primary),
                const SizedBox(height: AppTheme.spacingMd),
                Text(l10n.adminNoReports, style: text.bodyLarge),
              ],
            ),
          )
        else
          ...reports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: _ReportCard(
                report: report,
                onResolve: () => _resolve(context, report),
                onBan: () => _ban(context, report),
              ),
            ),
          ),

        const SizedBox(height: AppTheme.spacingLg),
        Text(l10n.adminBannedUsers,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppTheme.spacingSm),
        if (banned.isEmpty)
          Text(l10n.adminNoBanned,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant))
        else
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: banned.map((uid) {
              return Chip(
                avatar: const Icon(Icons.block_rounded, size: AppTheme.iconSm),
                label: Text(uid),
                onDeleted: provider.busy ? null : () => _unban(context, uid),
                deleteIcon: const Icon(Icons.close_rounded, size: AppTheme.iconSm),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _resolve(BuildContext context, UserReport report) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await provider.resolveReport(report.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.adminReportResolved : '…')),
    );
  }

  Future<void> _ban(BuildContext context, UserReport report) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminBanConfirmTitle),
        content: Text(l10n.adminBanConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminBanUser),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await provider.banUser(report.reportedUserId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.adminUserBanned : '…')),
    );
    // A banned report can be auto-resolved.
    await provider.resolveReport(report.id);
  }

  Future<void> _unban(BuildContext context, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await provider.unbanUser(uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.adminUserUnbanned : '…')),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final UserReport report;
  final VoidCallback onResolve;
  final VoidCallback onBan;

  const _ReportCard({
    required this.report,
    required this.onResolve,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: AppTheme.iconMd, color: colors.error),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  l10n.adminReason(report.reason.isEmpty ? '—' : report.reason),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            l10n.adminReportedUser(report.reportedUserId),
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            l10n.adminReportedBy(report.reportedById),
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            DateFormat('MMM d, yyyy · h:mm a').format(report.createdAt),
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onBan,
                child: Text(l10n.adminBanUser),
              ),
              TextButton(
                onPressed: onResolve,
                child: Text(l10n.adminResolve),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Claims tab ────────────────────────────────────────────────────────────────

class _ClaimsTab extends StatelessWidget {
  final ModerationProvider provider;

  const _ClaimsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final claims = provider.claims;

    if (claims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_rounded, size: 56, color: colors.primary),
            const SizedBox(height: AppTheme.spacingMd),
            Text(l10n.adminNoClaims, style: text.bodyLarge),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: claims.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, index) => _ClaimCard(
        claim: claims[index],
        busy: provider.busy,
        onApprove: () => _decide(context, claims[index], approve: true),
        onReject: () => _decide(context, claims[index], approve: false),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    EventClaim claim, {
    required bool approve,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = approve
        ? await provider.approveClaim(claim.id)
        : await provider.rejectClaim(claim.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (approve ? l10n.adminClaimApproved : l10n.adminClaimRejected)
            : '…'),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final EventClaim claim;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ClaimCard({
    required this.claim,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  String _statusLabel(AppLocalizations l10n) {
    switch (claim.status) {
      case ClaimStatus.pending:
        return l10n.adminPending;
      case ClaimStatus.approved:
        return l10n.adminApproved;
      case ClaimStatus.rejected:
        return l10n.adminRejected;
    }
  }

  Color _statusColor(ColorScheme colors) {
    switch (claim.status) {
      case ClaimStatus.pending:
        return colors.tertiary;
      case ClaimStatus.approved:
        return const Color(0xFF00B894);
      case ClaimStatus.rejected:
        return colors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pending = claim.status == ClaimStatus.pending;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.eventTitle,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(colors).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  _statusLabel(l10n),
                  style: text.labelSmall?.copyWith(
                    color: _statusColor(colors),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            '${claim.fullName} · ${claim.email}',
            style: text.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${_roleLabel(l10n, claim.role)} · ${claim.organization}',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (claim.statement.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              claim.statement,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (pending) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onReject,
                  child: Text(l10n.adminReject,
                      style: TextStyle(color: colors.error)),
                ),
                FilledButton(
                  onPressed: busy ? null : onApprove,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(l10n.adminApprove),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, ClaimRole role) {
    switch (role) {
      case ClaimRole.owner:
        return l10n.claimRoleOwner;
      case ClaimRole.promoter:
        return l10n.claimRolePromoter;
      case ClaimRole.bookingAgent:
        return l10n.claimRoleBookingAgent;
      case ClaimRole.marketing:
        return l10n.claimRoleMarketing;
      case ClaimRole.other:
        return l10n.claimRoleOther;
    }
  }
}

// ── Events tab ────────────────────────────────────────────────────────────────

class _EventsTab extends StatefulWidget {
  final ModerationProvider provider;
  final TextEditingController search;

  const _EventsTab({required this.provider, required this.search});

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  @override
  void initState() {
    super.initState();
    widget.search.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.search.removeListener(_onSearch);
    super.dispose();
  }

  void _onSearch() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final provider = widget.provider;

    final query = widget.search.text.toLowerCase().trim();
    final events = query.isEmpty
        ? provider.events
        : provider.events
            .where((e) =>
                e.title.toLowerCase().contains(query) ||
                e.location.toLowerCase().contains(query) ||
                e.organizerName.toLowerCase().contains(query))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: TextField(
            controller: widget.search,
            decoration: InputDecoration(
              hintText: l10n.adminSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    l10n.adminNoEvents,
                    style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingMd),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _EventRow(
                      event: event,
                      busy: provider.busy,
                      onOpen: () => context.push('/event/${event.id}', extra: event),
                      onRemove: () => _remove(context, event),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _remove(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminRemoveEventTitle),
        content: Text(l10n.adminRemoveEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await provider.deleteEvent(event.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.adminEventRemoved : '…')),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Event event;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _EventRow({
    required this.event,
    required this.busy,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final catColor = categoryAccent(event.category);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${event.organizerName} · ${event.location}',
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: busy ? null : onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: colors.error,
            tooltip: l10n.adminRemoveEvent,
          ),
        ],
      ),
    );
  }
}
