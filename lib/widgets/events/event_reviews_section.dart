import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/event_time.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event_review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rsvp_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/event_review_service.dart';
import '../../theme/theme.dart';
import '../billing/soft_paywall_sheet.dart';
import '../common/section_title.dart';

/// Star reviews for an event: only RSVP'd attendees, only after it ends.
class EventReviewsSection extends StatelessWidget {
  final String eventId;
  final String creatorId;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final Color accent;
  final bool showComposer;

  const EventReviewsSection({
    super.key,
    required this.eventId,
    required this.creatorId,
    required this.dateTime,
    required this.endDateTime,
    required this.accent,
    this.showComposer = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = EventReviewService();
    final auth = context.watch<AuthProvider>();
    final rsvp = context.watch<RsvpProvider>();
    final uid = auth.user?.id ?? '';
    final ended = isEventEnded(dateTime, endDateTime);
    final canReview = showComposer &&
        uid.isNotEmpty &&
        ended &&
        (rsvp.hasRsvp || auth.isAdmin);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.eventReviewTitle, accent: accent),
        const SizedBox(height: AppTheme.spacingSm),
        Text(l10n.eventReviewHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppTheme.spacingSm),
        StreamBuilder<ReviewStats>(
          stream: service.watchEventStats(eventId),
          builder: (context, snap) {
            final stats = snap.data;
            if (stats == null || !stats.hasRating) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(
                l10n.eventReviewHostRating(stats.avgStars.toStringAsFixed(1), stats.count),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          },
        ),
        if (canReview)
          _ReviewComposer(
            eventId: eventId,
            service: service,
            authorName: auth.user?.displayName ?? '',
            uid: uid,
          )
        else if (showComposer && uid.isNotEmpty && !ended)
          Text(l10n.eventReviewNotEnded, style: Theme.of(context).textTheme.bodySmall)
        else if (showComposer && uid.isNotEmpty && !rsvp.hasRsvp)
          Text(l10n.eventReviewRsvpRequired, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppTheme.spacingSm),
        StreamBuilder<List<EventReview>>(
          stream: service.watchEventReviews(eventId),
          builder: (context, snap) {
            final reviews = snap.data ?? const <EventReview>[];
            if (reviews.isEmpty) {
              return Text(l10n.eventReviewEmpty, style: Theme.of(context).textTheme.bodySmall);
            }
            final isHost = creatorId == uid || auth.isAdmin;
            final isPremium = context.watch<SubscriptionProvider>().isSubscribed;
            return Column(
              children: [
                for (final review in reviews)
                  _ReviewTile(
                    review: review,
                    service: service,
                    isHost: isHost,
                    isPremium: isPremium,
                    isMine: review.authorId == uid,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewComposer extends StatefulWidget {
  final String eventId;
  final EventReviewService service;
  final String authorName;
  final String uid;

  const _ReviewComposer({
    required this.eventId,
    required this.service,
    required this.authorName,
    required this.uid,
  });

  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<_ReviewComposer> {
  int _stars = 0;
  final _note = TextEditingController();
  bool _sending = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    widget.service.watchEventReviews(widget.eventId).listen((reviews) {
      if (!mounted || _hydrated) return;
      EventReview? mine;
      for (final r in reviews) {
        if (r.authorId == widget.uid) mine = r;
      }
      if (mine != null) {
        setState(() {
          _stars = mine!.stars;
          if (_note.text.isEmpty) _note.text = mine.note;
          _hydrated = true;
        });
      } else {
        _hydrated = true;
      }
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars < 1 || _sending) return;
    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.service.submitReview(
        eventId: widget.eventId,
        stars: _stars,
        authorName: widget.authorName,
        note: _note.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventReviewSubmitted)),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? l10n.eventReviewFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_hydrated && _stars > 0 ? l10n.eventReviewEdit : l10n.eventReviewCta,
            style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _stars = i),
                icon: Icon(
                  i <= _stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        TextField(
          controller: _note,
          minLines: 1,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(hintText: l10n.eventReviewNoteHint),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _stars < 1 || _sending ? null : _submit,
            child: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.eventReviewSubmit),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final EventReview review;
  final EventReviewService service;
  final bool isHost;
  final bool isPremium;
  final bool isMine;

  const _ReviewTile({
    required this.review,
    required this.service,
    required this.isHost,
    required this.isPremium,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.authorName.isEmpty ? l10n.eventThreadMember : review.authorName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= review.stars ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                if (!isMine)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    tooltip: l10n.eventReviewReport,
                    onPressed: () => context.read<AuthProvider>().reportContent(
                          contentType: 'event_review',
                          contentId: '${review.eventId}_${review.id}',
                          reportedUserId: review.authorId,
                          reason: 'Reported event review',
                        ),
                  ),
              ],
            ),
            if (review.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(review.note),
            ],
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingXs),
              Text(l10n.eventReviewHostReply(review.reply!),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (isHost)
              TextButton(
                onPressed: () async {
                  if (!isPremium) {
                    await showSoftPaywallSheet(
                      context,
                      title: l10n.eventReviewReplyPremiumTitle,
                      body: l10n.eventReviewReplyPremiumBody,
                    );
                    return;
                  }
                  final controller = TextEditingController(text: review.reply ?? '');
                  final send = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.eventReviewReply),
                      content: TextField(
                        controller: controller,
                        maxLines: 4,
                        maxLength: 300,
                        decoration: InputDecoration(hintText: l10n.eventReviewReplyHint),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.eventReviewSubmit)),
                      ],
                    ),
                  );
                  final text = controller.text.trim();
                  controller.dispose();
                  if (send != true || text.isEmpty) return;
                  try {
                    await service.replyToReview(
                      eventId: review.eventId.isEmpty ? review.id : review.eventId,
                      reviewerId: review.authorId,
                      reply: text,
                    );
                  } on FirebaseFunctionsException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? l10n.eventReviewFailed)),
                      );
                    }
                  }
                },
                child: Text(l10n.eventReviewReply),
              ),
          ],
        ),
      ),
    );
  }
}

class GemEventReviewsSection extends StatelessWidget {
  final String gemId;
  final Color accent;

  const GemEventReviewsSection({super.key, required this.gemId, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = EventReviewService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.eventReviewTitle, accent: accent),
        const SizedBox(height: AppTheme.spacingSm),
        Text(l10n.eventReviewGemHelp, style: Theme.of(context).textTheme.bodySmall),
        GemRatingFromService(gemId: gemId, service: service),
        const SizedBox(height: AppTheme.spacingSm),
        StreamBuilder<List<EventReview>>(
          stream: service.watchGemEventReviews(gemId),
          builder: (context, snap) {
            final reviews = snap.data ?? const <EventReview>[];
            if (reviews.isEmpty) {
              return Text(l10n.eventReviewEmpty, style: Theme.of(context).textTheme.bodySmall);
            }
            return Column(
              children: [
                for (final review in reviews)
                  _ReviewTile(
                    review: review,
                    service: service,
                    isHost: false,
                    isPremium: false,
                    isMine: false,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class GemRatingFromService extends StatelessWidget {
  final String gemId;
  final EventReviewService service;
  const GemRatingFromService({super.key, required this.gemId, required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<ReviewStats>(
      stream: service.watchGemStats(gemId),
      builder: (context, snap) {
        final stats = snap.data;
        if (stats == null || !stats.hasRating) return const SizedBox.shrink();
        return Text(l10n.eventReviewHostRating(stats.avgStars.toStringAsFixed(1), stats.count));
      },
    );
  }
}

/// Premium analytics: the host's reviews across events, with reply actions.
class HostReviewsPanel extends StatelessWidget {
  final String hostId;
  final bool isPremium;

  const HostReviewsPanel({super.key, required this.hostId, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = EventReviewService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.eventReviewTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingXs),
        StreamBuilder<ReviewStats>(
          stream: service.watchHostStats(hostId),
          builder: (context, snap) {
            final stats = snap.data;
            if (stats == null || !stats.hasRating) {
              return Text(l10n.eventReviewEmpty, style: Theme.of(context).textTheme.bodySmall);
            }
            return Text(l10n.eventReviewHostRating(stats.avgStars.toStringAsFixed(1), stats.count));
          },
        ),
        const SizedBox(height: AppTheme.spacingSm),
        StreamBuilder<List<EventReview>>(
          stream: service.watchHostReviews(hostId),
          builder: (context, snap) {
            final reviews = snap.data ?? const <EventReview>[];
            if (reviews.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                for (final review in reviews.take(20))
                  _ReviewTile(
                    review: review,
                    service: service,
                    isHost: true,
                    isPremium: isPremium,
                    isMine: false,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
