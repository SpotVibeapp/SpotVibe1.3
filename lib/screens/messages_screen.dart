import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/event_message.dart';
import '../providers/auth_provider.dart';
import '../services/event_messaging_service.dart';
import '../theme/theme.dart';
import 'direct_conversation_screen.dart';

/// The Messages inbox: every 1:1 host/attendee conversation the signed-in
/// user is part of, newest first, with unread badges. Real-time.
class MessagesScreen extends StatelessWidget {
  final EventMessagingService? service;

  const MessagesScreen({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.id ?? '';
    final signedIn = uid.isNotEmpty && auth.user?.isGuest != true;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.messagesTitle)),
      body: signedIn
          ? MessagesInboxView(
              uid: uid,
              service: service ?? EventMessagingService(),
              onOpen: (thread) => openDirectConversation(
                context,
                eventId: thread.eventId,
                hostId: thread.hostId,
                attendeeId: thread.attendeeId,
                eventTitle: thread.eventTitle,
                otherName: thread.nameOf(thread.otherParticipant(uid)),
                service: service,
              ),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.messagesSignIn),
                  const SizedBox(height: AppTheme.spacingMd),
                  FilledButton(
                    onPressed: () => context.push('/login'),
                    child: Text(l10n.signIn),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Inbox list. Separate from [MessagesScreen] so it can be tested without
/// providers or Firebase.
class MessagesInboxView extends StatefulWidget {
  final String uid;
  final EventMessagingService service;
  final ValueChanged<EventDirectThread> onOpen;

  const MessagesInboxView({
    super.key,
    required this.uid,
    required this.service,
    required this.onOpen,
  });

  @override
  State<MessagesInboxView> createState() => _MessagesInboxViewState();
}

class _MessagesInboxViewState extends State<MessagesInboxView> {
  StreamSubscription<List<EventDirectThread>>? _threadsSub;
  StreamSubscription<Set<String>>? _blockedSub;
  List<EventDirectThread>? _threads;
  Set<String> _blocked = const {};
  Object? _error;

  @override
  void initState() {
    super.initState();
    _threadsSub = widget.service.watchInbox(widget.uid).listen(
          (t) => setState(() {
            _threads = t;
            _error = null;
          }),
          onError: (Object e) => setState(() => _error = e),
        );
    _blockedSub = widget.service.watchBlockedIds(widget.uid).listen(
          (b) => setState(() => _blocked = b),
          onError: (Object _) {},
        );
  }

  @override
  void dispose() {
    _threadsSub?.cancel();
    _blockedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_error != null && _threads == null) {
      return Center(child: Text(l10n.messagesLoadFailed));
    }
    final threads = _threads;
    if (threads == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final visible = threads
        .where((t) => !_blocked.contains(t.otherParticipant(widget.uid)))
        .toList();
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_chat_unread_outlined,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(l10n.messagesEmpty, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => ConversationTile(
        key: ValueKey('conv_${visible[i].id}'),
        thread: visible[i],
        uid: widget.uid,
        onTap: () => widget.onOpen(visible[i]),
      ),
    );
  }
}

/// One row in the inbox.
class ConversationTile extends StatelessWidget {
  final EventDirectThread thread;
  final String uid;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.thread,
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final otherId = thread.otherParticipant(uid);
    final stored = thread.nameOf(otherId);
    final role = thread.isHost(uid) ? l10n.messagesRoleAttendee : l10n.messagesRoleHost;
    final name = stored.isNotEmpty ? stored : role;
    final unread = thread.unreadFor(uid);
    final preview = thread.lastMessageIsMine(uid)
        ? l10n.messagesYouPrefix(thread.lastPreview)
        : thread.lastPreview;
    final subtitle = thread.eventTitle.isEmpty ? preview : '${thread.eventTitle} · $preview';
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase()),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: unread > 0 ? const TextStyle(fontWeight: FontWeight.w700) : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(stored.isNotEmpty ? role : '', style: theme.textTheme.labelSmall),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: unread > 0 ? TextStyle(color: theme.colorScheme.onSurface) : null,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (thread.lastMessageAt != null)
            Text(_when(context, thread.lastMessageAt!), style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          if (unread > 0)
            Badge(
              key: const Key('unreadBadge'),
              label: Text(DirectMessagePolicy.unreadLabel(unread)),
            ),
        ],
      ),
    );
  }

  static String _when(BuildContext context, DateTime at) {
    final loc = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final sameDay = now.year == at.year && now.month == at.month && now.day == at.day;
    return sameDay
        ? loc.formatTimeOfDay(TimeOfDay.fromDateTime(at))
        : loc.formatShortMonthDay(at);
  }
}

/// Unread total for a badge (profile tile). Hidden at zero.
class MessagesUnreadBadge extends StatefulWidget {
  final String uid;
  final EventMessagingService service;
  final Widget child;

  const MessagesUnreadBadge({
    super.key,
    required this.uid,
    required this.service,
    required this.child,
  });

  @override
  State<MessagesUnreadBadge> createState() => _MessagesUnreadBadgeState();
}

class _MessagesUnreadBadgeState extends State<MessagesUnreadBadge> {
  Stream<int>? _stream;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(MessagesUnreadBadge old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid || old.service != widget.service) _subscribe();
  }

  void _subscribe() {
    _stream = widget.uid.isEmpty ? null : widget.service.watchTotalUnread(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return widget.child;
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final n = snap.hasError ? 0 : (snap.data ?? 0);
        return Badge(
          key: const Key('messagesTotalBadge'),
          isLabelVisible: n > 0,
          label: Text(DirectMessagePolicy.unreadLabel(n)),
          child: widget.child,
        );
      },
    );
  }
}
