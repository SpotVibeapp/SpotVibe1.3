import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/moderation_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/rsvp_provider.dart';
import '../../services/ai_moderation_service.dart';
import '../../theme/theme.dart';
import '../common/app_avatar.dart';
import '../common/section_title.dart';
import '../common/user_action_sheet.dart';

class CommentSection extends StatelessWidget {
  /// Accent color for the section header bar (usually the event's category
  /// color). Defaults to the brand violet when not supplied.
  final Color accent;

  /// When true (admin/moderator), each comment gets a delete action.
  final bool canModerate;

  const CommentSection({
    super.key,
    this.accent = AppTheme.brandViolet,
    this.canModerate = false,
  });

  @override
  Widget build(BuildContext context) {
    final rsvp = context.watch<RsvpProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionTitle(title: l10n.comments, accent: accent),
            ),
            Text(
              '${rsvp.comments.length}',
              style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rsvp.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (rsvp.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: colors.onSurfaceVariant,
                          size: AppTheme.iconLg,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          l10n.noCommentsYet,
                          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...rsvp.comments.map((c) => _CommentBubble(
                      authorId: c.authorId,
                      authorName: c.authorName,
                      authorAvatar: c.authorAvatarUrl,
                      text: c.text,
                      time: _formatTime(context, c.createdAt),
                      isMe: c.authorId == auth.user?.id,
                      onDelete: canModerate
                          ? () => _deleteComment(context, c.id)
                          : null,
                      onUserTap: auth.isLoggedIn && c.authorId != auth.user?.id
                          ? () {
                              final follow = context.read<FollowProvider>();
                              final currentId = auth.user!.id;
                              UserActionSheet.show(
                                context,
                                userName: c.authorName,
                                isFollowing: follow.isFollowing(currentId, c.authorId),
                                onToggleFollow: () {
                                  final nowFollowing = follow.toggleFollow(currentId, c.authorId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(nowFollowing
                                          ? l10n.followingName(c.authorName)
                                          : l10n.unfollowedName(c.authorName)),
                                    ),
                                  );
                                },
                                onBlock: () {
                                  auth.blockUser(c.authorId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.userBlocked)),
                                  );
                                },
                                onReport: () {},
                              );
                            }
                          : null,
                    )),
              if (auth.isLoggedIn) _CommentInput(),
            ],
          ),
        ),
        if (!auth.isLoggedIn) ...[
          const SizedBox(height: AppTheme.spacingSm),
          OutlinedButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.logInToComment),
          ),
        ],
      ],
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return DateFormat('MMM d').format(dt);
  }

  /// Admin-only comment removal.
  Future<void> _deleteComment(BuildContext context, String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteComment),
        content: Text(l10n.adminDeleteCommentBody),
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
    final ok = await context.read<RsvpProvider>().deleteComment(commentId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.adminCommentRemoved : '…')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final String time;
  final bool isMe;
  final VoidCallback? onUserTap;
  final VoidCallback? onDelete;

  const _CommentBubble({
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.time,
    required this.isMe,
    this.onUserTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: AppAvatar(
              imageUrl: authorAvatar,
              size: AppTheme.avatarSm,
              fallbackName: authorName,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isMe ? AppLocalizations.of(context)!.you : authorName,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isMe ? colors.primary : colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      time,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(text, style: textTheme.bodySmall),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: AppTheme.iconSm),
              color: colors.error,
              tooltip: AppLocalizations.of(context)!.adminDeleteComment,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CommentInput extends StatefulWidget {
  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _controller = TextEditingController();
  bool _isChecking = false;
  ModerationResult? _moderationResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;

    setState(() {
      _isChecking = true;
      _moderationResult = null;
    });

    final modService = context.read<AiModerationService>();
    final result = await modService.moderateText(t);

    if (!mounted) return;

    if (result.isRejected) {
      setState(() {
        _isChecking = false;
        _moderationResult = result;
      });
      return;
    }

    // Flagged content: post with a warning shown briefly
    if (result.isFlagged) {
      setState(() => _moderationResult = result);
    }

    final auth = context.read<AuthProvider>();
    final rsvp = context.read<RsvpProvider>();
    await rsvp.addComment(
      text: t,
      authorName: auth.user!.displayName,
      authorAvatar: auth.user!.avatarUrl,
    );

    if (!mounted) return;
    _controller.clear();
    setState(() {
      _isChecking = false;
      // Clear flag warning after posting
      if (_moderationResult?.isFlagged ?? false) _moderationResult = null;
    });
  }

  void _dismissWarning() => setState(() => _moderationResult = null);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final isRejected = _moderationResult?.isRejected ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Moderation feedback banner ──────────────────────────────────────
        if (_moderationResult != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.fromLTRB(
              AppTheme.spacingSm,
              AppTheme.spacingSm,
              AppTheme.spacingSm,
              0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: isRejected
                  ? colors.errorContainer
                  : colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isRejected ? Icons.block_rounded : Icons.warning_amber_rounded,
                  size: AppTheme.iconSm,
                  color: isRejected
                      ? colors.onErrorContainer
                      : colors.onTertiaryContainer,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRejected
                            ? l10n.detectedLabel(_moderationResult!.category ?? l10n.content)
                            : l10n.warningLabel(_moderationResult!.category ?? l10n.content),
                        style: text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isRejected
                              ? colors.onErrorContainer
                              : colors.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _moderationResult!.reason ?? l10n.reviewComment,
                        style: text.labelSmall?.copyWith(
                          color: isRejected
                              ? colors.onErrorContainer
                              : colors.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRejected)
                  GestureDetector(
                    onTap: _dismissWarning,
                    child: Icon(
                      Icons.close_rounded,
                      size: AppTheme.iconSm,
                      color: colors.onErrorContainer,
                    ),
                  ),
              ],
            ),
          ),
        ],
        // ── Input row ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _submit(),
                  textInputAction: TextInputAction.send,
                  enabled: !_isChecking,
                  decoration: InputDecoration(
                    hintText: l10n.addCommentHint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      borderSide: BorderSide(
                        color: isRejected ? colors.error : colors.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      borderSide: BorderSide(
                        color: isRejected ? colors.error : colors.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      borderSide: BorderSide(
                        color: isRejected ? colors.error : colors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _isChecking
                  ? const SizedBox(
                      width: AppTheme.iconXl,
                      height: AppTheme.iconXl,
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingXs),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filled(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            isRejected ? colors.errorContainer : colors.primary,
                        foregroundColor:
                            isRejected ? colors.onErrorContainer : colors.onPrimary,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
