import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/event_message.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/event_messaging_service.dart';
import '../theme/theme.dart';
import '../widgets/billing/soft_paywall_sheet.dart';

/// Opens the 1:1 conversation between an event host and one attendee.
///
/// Works for a conversation that does not exist yet: the first send creates
/// it (attendees for free; hosts need Premium to start one).
Future<void> openDirectConversation(
  BuildContext context, {
  required String eventId,
  required String hostId,
  required String attendeeId,
  String eventTitle = '',
  String otherName = '',
  EventMessagingService? service,
}) {
  final auth = context.read<AuthProvider>();
  final premium = context.read<SubscriptionProvider>().isSubscribed;
  final uid = auth.user?.id ?? '';
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DirectConversationScreen(
        eventId: eventId,
        hostId: hostId,
        attendeeId: attendeeId,
        uid: uid,
        isPremium: premium,
        eventTitle: eventTitle,
        otherName: otherName,
        service: service ?? EventMessagingService(),
        onReport: ({required contentType, required contentId, required reportedUserId}) =>
            auth.reportContent(
          contentType: contentType,
          contentId: contentId,
          reportedUserId: reportedUserId,
          reason: 'Reported private message',
        ),
        onBlock: auth.blockUser,
      ),
    ),
  );
}

typedef DirectReportCallback = Future<void> Function({
  required String contentType,
  required String contentId,
  required String reportedUserId,
});

class DirectConversationScreen extends StatefulWidget {
  final String eventId;
  final String hostId;
  final String attendeeId;
  final String uid;
  final bool isPremium;
  final String eventTitle;
  final String otherName;
  final EventMessagingService service;
  final DirectReportCallback onReport;
  final Future<void> Function(String userId) onBlock;

  /// Shown when a host without Premium tries to start a conversation.
  final Future<void> Function(BuildContext context)? onPremiumRequired;

  const DirectConversationScreen({
    super.key,
    required this.eventId,
    required this.hostId,
    required this.attendeeId,
    required this.uid,
    required this.isPremium,
    required this.service,
    required this.onReport,
    required this.onBlock,
    this.eventTitle = '',
    this.otherName = '',
    this.onPremiumRequired,
  });

  @override
  State<DirectConversationScreen> createState() => _DirectConversationScreenState();
}

class _DirectConversationScreenState extends State<DirectConversationScreen> {
  final _controller = TextEditingController();
  late final String _threadId;
  late final Stream<EventDirectThread?> _threadStream;
  Stream<List<EventMessage>>? _messagesStream;
  bool _sending = false;
  DateTime? _lastMarkedAt;

  bool get _isHost => widget.uid.isNotEmpty && widget.uid == widget.hostId;
  String get _otherId => _isHost ? widget.attendeeId : widget.hostId;

  @override
  void initState() {
    super.initState();
    _threadId = widget.service.directThreadId(
      eventId: widget.eventId,
      hostId: widget.hostId,
      attendeeId: widget.attendeeId,
    );
    _threadStream = widget.service.watchDirectThreadMeta(_threadId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeMarkRead(EventDirectThread thread) {
    if (thread.unreadFor(widget.uid) <= 0) return;
    final at = thread.lastMessageAt;
    if (at != null && _lastMarkedAt == at) return;
    _lastMarkedAt = at;
    widget.service.markDirectRead(thread.id).catchError((Object e) {
      debugPrint('markDirectRead failed: $e');
    });
  }

  Future<void> _premiumRequired() async {
    final custom = widget.onPremiumRequired;
    if (custom != null) {
      await custom(context);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    await showSoftPaywallSheet(
      context,
      title: l10n.eventThreadDmPremiumTitle,
      body: l10n.eventThreadDmPremiumBody,
    );
  }

  Future<void> _send({required bool threadExists}) async {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > DirectMessagePolicy.maxLength) {
      _snack(l10n.messagesTooLong);
      return;
    }
    if (_isHost &&
        DirectMessagePolicy.hostNeedsPremium(
          threadExists: threadExists,
          isPremium: widget.isPremium,
        )) {
      await _premiumRequired();
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.sendDirectMessage(
        eventId: widget.eventId,
        attendeeId: widget.attendeeId,
        text: text,
      );
      _controller.clear();
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      if (details is Map && details['reason'] == 'premium-required') {
        if (mounted) await _premiumRequired();
      } else {
        _snack(e.message ?? l10n.eventThreadSendFailed);
      }
    } catch (_) {
      _snack(l10n.eventThreadSendFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _report({String? messageId}) async {
    final l10n = AppLocalizations.of(context)!;
    await widget.onReport(
      contentType: messageId == null ? 'direct_conversation' : 'direct_message',
      contentId: messageId == null ? _threadId : '$_threadId/$messageId',
      reportedUserId: _otherId,
    );
    _snack(l10n.messagesReported);
  }

  Future<void> _block() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.messagesBlockConfirmTitle),
        content: Text(l10n.messagesBlockConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.messagesBlock)),
        ],
      ),
    );
    if (ok != true) return;
    await widget.onBlock(_otherId);
    if (!mounted) return;
    _snack(l10n.messagesBlocked);
    Navigator.of(context).maybePop();
  }

  String _otherLabel(AppLocalizations l10n, EventDirectThread? thread) {
    final stored = thread?.nameOf(_otherId) ?? '';
    if (stored.isNotEmpty) return stored;
    if (widget.otherName.trim().isNotEmpty) return widget.otherName.trim();
    return _isHost ? l10n.messagesRoleAttendee : l10n.messagesRoleHost;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<EventDirectThread?>(
      stream: _threadStream,
      builder: (context, threadSnap) {
        final thread = threadSnap.data;
        if (thread != null) {
          _messagesStream ??= widget.service.watchDirectMessages(thread.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeMarkRead(thread);
          });
        }
        final title = _otherLabel(l10n, thread);
        final eventTitle = (thread?.eventTitle.isNotEmpty ?? false)
            ? thread!.eventTitle
            : widget.eventTitle;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (eventTitle.isNotEmpty)
                  Text(
                    l10n.messagesAboutEvent(eventTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                key: const Key('conversationMenu'),
                onSelected: (v) {
                  if (v == 'report') _report();
                  if (v == 'block') _block();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'report', child: Text(l10n.messagesReportConversation)),
                  PopupMenuItem(value: 'block', child: Text(l10n.messagesBlockUser)),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: threadSnap.hasError
                      ? Center(child: Text(l10n.messagesLoadFailed))
                      : thread == null
                          ? _EmptyConversation(
                              text: _isHost
                                  ? l10n.messagesHostStartHint
                                  : l10n.messagesNewConversationHint,
                            )
                          : _MessageList(
                              stream: _messagesStream!,
                              uid: widget.uid,
                              onLongPress: (m) => _messageActions(m),
                            ),
                ),
                _Composer(
                  controller: _controller,
                  sending: _sending,
                  onSend: () => _send(threadExists: thread != null),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _messageActions(EventMessage m) async {
    if (m.authorId == widget.uid) return;
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.messagesReportMessage),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: Text(l10n.messagesBlockUser),
              onTap: () => Navigator.pop(ctx, 'block'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'report') await _report(messageId: m.id);
    if (action == 'block') await _block();
  }
}

class _EmptyConversation extends StatelessWidget {
  final String text;
  const _EmptyConversation({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppTheme.spacingMd),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final Stream<List<EventMessage>> stream;
  final String uid;
  final ValueChanged<EventMessage> onLongPress;

  const _MessageList({required this.stream, required this.uid, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<EventMessage>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(l10n.messagesLoadFailed));
        final messages = snap.data ?? const <EventMessage>[];
        if (messages.isEmpty) {
          return Center(child: Text(l10n.eventThreadDmEmpty));
        }
        // Newest at the bottom, list anchored to the bottom.
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final m = messages[messages.length - 1 - i];
            return MessageBubble(
              key: ValueKey('dm_${m.id}'),
              message: m,
              mine: m.authorId == uid,
              onLongPress: () => onLongPress(m),
            );
          },
        );
      },
    );
  }
}

/// One chat bubble. Mine on the right in the primary color.
class MessageBubble extends StatelessWidget {
  final EventMessage message;
  final bool mine;
  final VoidCallback? onLongPress;

  const MessageBubble({super.key, required this.message, required this.mine, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(message.createdAt));
    final bg = mine ? colors.primary : colors.surfaceContainerHighest;
    final fg = mine ? colors.onPrimary : colors.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.text, style: TextStyle(color: fg)),
              const SizedBox(height: 2),
              Text(
                time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('dmComposer'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: DirectMessagePolicy.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.eventThreadHint, counterText: ''),
            ),
          ),
          IconButton(
            key: const Key('dmSend'),
            tooltip: l10n.eventThreadSend,
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
