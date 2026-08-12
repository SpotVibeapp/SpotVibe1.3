import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/notification_item.dart';
import '../providers/notification_provider.dart';
import '../theme/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: text.titleLarge),
        centerTitle: false,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: notifProvider.markAllRead,
              child: Text('Mark all read',
                  style: text.labelMedium?.copyWith(color: colors.primary)),
            ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: colors.onSurfaceVariant),
            tooltip: 'Notification preferences',
            onPressed: () => context.push('/notification-preferences'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: text.labelLarge,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          tabs: [
            _TabLabel('All', _badge(notifProvider.all)),
            _TabLabel('Reminders', _badge(notifProvider.reminders)),
            _TabLabel('Events', _badge(notifProvider.newEvents)),
            _TabLabel('Social', _badge(notifProvider.social)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _NotificationListView(
              items: notifProvider.all,
              appColors: appColors,
              onTap: (item) => _handleTap(context, notifProvider, item),
              onDismiss: (item) => notifProvider.remove(item.id)),
          _NotificationListView(
              items: notifProvider.reminders,
              appColors: appColors,
              onTap: (item) => _handleTap(context, notifProvider, item),
              onDismiss: (item) => notifProvider.remove(item.id)),
          _NotificationListView(
              items: notifProvider.newEvents,
              appColors: appColors,
              onTap: (item) => _handleTap(context, notifProvider, item),
              onDismiss: (item) => notifProvider.remove(item.id)),
          _NotificationListView(
              items: notifProvider.social,
              appColors: appColors,
              onTap: (item) => _handleTap(context, notifProvider, item),
              onDismiss: (item) => notifProvider.remove(item.id)),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, NotificationProvider provider,
      NotificationItem item) {
    provider.markRead(item.id);
    if (item.routePath != null) {
      context.push(item.routePath!);
    }
  }

  int _badge(List<NotificationItem> items) =>
      items.where((n) => n.isUnread).length;
}

// ── Tab label with optional unread badge ────────────────────────────────────

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.label, this.unread);

  final String label;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (unread > 0) ...[
            const SizedBox(width: AppTheme.spacingXs),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXs + 2,
                  vertical: 1),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Scrollable notification list ─────────────────────────────────────────────

class _NotificationListView extends StatelessWidget {
  const _NotificationListView({
    required this.items,
    required this.appColors,
    required this.onTap,
    required this.onDismiss,
  });

  final List<NotificationItem> items;
  final AppColorsExtension appColors;
  final void Function(NotificationItem) onTap;
  final void Function(NotificationItem) onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: AppTheme.iconLg * 1.5,
                color: colors.onSurfaceVariant),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Nothing here yet',
                style: text.titleMedium
                    ?.copyWith(color: colors.onSurface)),
            const SizedBox(height: AppTheme.spacingSm),
            Text("You're all caught up!",
                style: text.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 72, color: colors.outlineVariant),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding:
                const EdgeInsets.only(right: AppTheme.spacingMd),
            color: appColors.danger.withValues(
                alpha: AppTheme.opacityOverlay),
            child: Icon(Icons.delete_outline_rounded,
                color: colors.onError),
          ),
          onDismissed: (_) => onDismiss(item),
          child: _NotificationTile(
            item: item,
            appColors: appColors,
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }
}

// ── Single notification tile ─────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.appColors,
    required this.onTap,
  });

  final NotificationItem item;
  final AppColorsExtension appColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final iconCol = item.iconColor(colors,
        teal: appColors.creatorTeal, gold: appColors.proGold);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isUnread
            ? colors.primaryContainer
                .withValues(alpha: AppTheme.opacityHint * 0.25)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon avatar
            Container(
              width: AppTheme.avatarMd,
              height: AppTheme.avatarMd,
              decoration: BoxDecoration(
                color: iconCol.withValues(
                    alpha: AppTheme.opacityHint * 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: iconCol,
                  size: AppTheme.iconMd),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: item.isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.subtitle}  ·  ${NotificationItem.relativeTime(item.createdAt)}',
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.isUnread) ...[
              const SizedBox(width: AppTheme.spacingSm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
