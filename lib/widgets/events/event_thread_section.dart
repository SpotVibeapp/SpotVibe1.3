import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rsvp_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/event_messaging_service.dart';
import '../../theme/theme.dart';
import '../billing/soft_paywall_sheet.dart';
import '../common/section_title.dart';

/// Private event thread for the host and RSVP'd attendees.
class EventThreadSection extends StatelessWidget {
  final String eventId;
  final String creatorId;
  final Color accent;

  const EventThreadSection({
    super.key,
    required this.eventId,
    required this.creatorId,
    required this.accent,
  });

  bool _canJoin(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final rsvp = context.read<RsvpProvider>();
    final uid = auth.user?.id;
    if (uid == null || uid.isEmpty) return false;
    if (auth.isAdmin) return true;
    if (creatorId == uid) return true;
    return rsvp.hasRsvp;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canJoin = _canJoin(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.eventThreadTitle, accent: accent),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          l10n.eventThreadHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        StreamBuilder<int>(
          stream: () {
            final uid = context.read<AuthProvider>().user?.id ?? '';
            if (uid.isEmpty || !canJoin) return null;
            return EventMessagingService().watchUnreadCount(eventId: eventId, uid: uid);
          }(),
          builder: (context, snap) {
            final unread = snap.data ?? 0;
            return FilledButton.tonalIcon(
              onPressed: canJoin
                  ? () => _openThread(context)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.eventThreadRsvpRequired)),
                      ),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: const Icon(Icons.forum_outlined),
              ),
              label: Text(l10n.eventThreadOpen),
            );
          },
        ),
      ],
    );
  }

  void _openThread(BuildContext context) {
    final service = EventMessagingService();
    final auth = context.read<AuthProvider>();
    final premium = context.read<SubscriptionProvider>().isSubscribed;
    final isHost = creatorId == auth.user?.id || auth.isAdmin;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EventThreadSheet(
        eventId: eventId,
        creatorId: creatorId,
        service: service,
        isHost: isHost,
        isPremium: premium,
        uid: auth.user?.id ?? '',
        authorName: auth.user?.displayName ?? '',
      ),
    );
  }
}

class _EventThreadSheet extends StatefulWidget {
  final String eventId;
  final String creatorId;
  final EventMessagingService service;
  final bool isHost;
  final bool isPremium;
  final String uid;
  final String authorName;

  const _EventThreadSheet({
    required this.eventId,
    required this.creatorId,
    required this.service,
    required this.isHost,
    required this.isPremium,
    required this.uid,
    required this.authorName,
  });

  @override
  State<_EventThreadSheet> createState() => _EventThreadSheetState();
}

class _EventThreadSheetState extends State<_EventThreadSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _optOutDms = false;
  Map<String, int> _receipts = const {};

  @override
  void initState() {
    super.initState();
    widget.service.getMute(widget.eventId, widget.uid).then((mute) {
      if (mounted) setState(() => _optOutDms = mute?['optOutDms'] == true);
    });
    widget.service.markRead(eventId: widget.eventId).ignore();
    widget.service.watchReceipts(widget.eventId).listen((r) {
      if (mounted) setState(() => _receipts = r);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.service.sendThreadMessage(
        eventId: widget.eventId,
        text: text,
        authorName: widget.authorName,
      );
      _controller.clear();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.eventThreadSendFailed)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleOptOut() async {
    final next = !_optOutDms;
    await widget.service.setMute(
      eventId: widget.eventId,
      muted: false,
      optOutDms: next,
    );
    if (mounted) setState(() => _optOutDms = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingMd,
          right: AppTheme.spacingMd,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingMd,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.eventThreadTitle, style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: _toggleOptOut,
                  child: Text(_optOutDms ? l10n.eventThreadAllowDms : l10n.eventThreadOptOutDms),
                ),
              ],
            ),
            if (!widget.isHost && widget.creatorId.isNotEmpty)
              StreamBuilder<EventDirectThread?>(
                stream: widget.service.watchDirectThreadMeta(
                  widget.service.directThreadId(
                    eventId: widget.eventId,
                    hostId: widget.creatorId,
                    attendeeId: widget.uid,
                  ),
                ),
                builder: (context, snap) {
                  final thread = snap.data;
                  if (thread == null) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: Text(l10n.eventThreadHostMessage),
                    subtitle: Text(
                      thread.lastPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDirectThread(thread),
                  );
                },
              ),
            const SizedBox(height: AppTheme.spacingSm),
            Expanded(
              child: StreamBuilder<List<EventMessage>>(
                stream: widget.service.watchThread(widget.eventId),
                builder: (context, snap) {
                  final messages = snap.data ?? const <EventMessage>[];
                  if (messages.isEmpty) {
                    return Center(child: Text(l10n.eventThreadEmpty));
                  }
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final mine = m.authorId == widget.uid;
                      final readBy = _receipts.entries
                          .where((e) => e.key != m.authorId && e.value >= m.createdAt.millisecondsSinceEpoch)
                          .length;
                      return ListTile(
                        dense: true,
                        title: Text(m.authorName.isEmpty ? l10n.eventThreadMember : m.authorName),
                        subtitle: Text(m.text),
                        trailing: widget.isHost
                            ? IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _messageActions(m),
                              )
                            : (readBy > 0 && widget.isPremium
                                ? Text(l10n.eventThreadReadCount(readBy),
                                    style: Theme.of(context).textTheme.labelSmall)
                                : null),
                        tileColor: mine
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: l10n.eventThreadHint,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _messageActions(EventMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.eventThreadRemove),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.eventThreadReport),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
            if (widget.isHost && message.authorId != widget.uid)
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text(l10n.eventThreadBlock),
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
            if (widget.isHost && message.authorId != widget.uid)
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(l10n.eventThreadDirectMessage),
                onTap: () => Navigator.pop(ctx, 'dm'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      await widget.service.removeMessage(eventId: widget.eventId, messageId: message.id);
    } else if (action == 'report') {
      await context.read<AuthProvider>().reportContent(
            contentType: 'event_thread_message',
            contentId: message.id,
            reportedUserId: message.authorId,
            reason: 'Reported event thread message',
          );
    } else if (action == 'block') {
      await context.read<AuthProvider>().blockUser(message.authorId);
    } else if (action == 'dm') {
      if (!widget.isPremium) {
        await showSoftPaywallSheet(
          context,
          title: l10n.eventThreadDmPremiumTitle,
          body: l10n.eventThreadDmPremiumBody,
        );
        return;
      }
      await _composeDirectMessage(message.authorId);
    }
  }

  Future<void> _composeDirectMessage(String attendeeId) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventThreadDirectMessage),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(hintText: l10n.eventThreadHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.eventThreadSend),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (sent != true || text.isEmpty) return;
    try {
      await widget.service.sendDirectMessage(
        eventId: widget.eventId,
        attendeeId: attendeeId,
        text: text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eventThreadDmSent)));
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? l10n.eventThreadSendFailed)),
        );
      }
    }
  }

  Future<void> _openDirectThread(EventDirectThread thread) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppTheme.spacingMd,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.6,
            child: Column(
              children: [
                Text(l10n.eventThreadHostMessage, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacingSm),
                Expanded(
                  child: StreamBuilder<List<EventMessage>>(
                    stream: widget.service.watchDirectMessages(thread.id),
                    builder: (context, snap) {
                      final messages = snap.data ?? const <EventMessage>[];
                      if (messages.isEmpty) {
                        return Center(child: Text(l10n.eventThreadDmEmpty));
                      }
                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          return ListTile(
                            dense: true,
                            title: Text(m.authorId == widget.uid ? widget.authorName : l10n.eventThreadHostMessage),
                            subtitle: Text(m.text),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: l10n.eventThreadHint,
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await widget.service.sendDirectMessage(
                            eventId: widget.eventId,
                            attendeeId: thread.attendeeId,
                            text: text,
                          );
                          controller.clear();
                        } on FirebaseFunctionsException catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.message ?? l10n.eventThreadSendFailed)),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
  }
}
