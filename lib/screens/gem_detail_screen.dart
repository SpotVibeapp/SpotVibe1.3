import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/gem.dart';
import '../providers/auth_provider.dart';
import '../services/gem_service.dart';
import '../services/maps_service.dart';
import '../theme/theme.dart';
import '../widgets/gems/gem_cover.dart';

/// Detail page for a single community hidden gem. Shows the place, its
/// description, who added it, directions, and community interaction — likes and
/// comments (both signed-in only, both moderated).
class GemDetailScreen extends StatefulWidget {
  final Gem gem;
  const GemDetailScreen({super.key, required this.gem});

  @override
  State<GemDetailScreen> createState() => _GemDetailScreenState();
}

class _GemDetailScreenState extends State<GemDetailScreen> {
  late Gem _gem;
  final _commentController = TextEditingController();
  List<GemComment> _comments = const [];
  bool _loadingComments = true;
  bool _posting = false;
  bool _likeBusy = false;

  @override
  void initState() {
    super.initState();
    _gem = widget.gem;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  GemService get _service => context.read<GemService>();
  AuthProvider get _auth => context.read<AuthProvider>();

  bool get _canInteract =>
      _auth.isLoggedIn && !_auth.isGuest && (_auth.user?.id.isNotEmpty ?? false);

  Future<void> _load() async {
    final viewerId = _auth.user?.id;
    try {
      final fresh = await _service.getGemById(_gem.id, viewerId: viewerId);
      final comments = await _service.getComments(_gem.id);
      if (!mounted) return;
      setState(() {
        if (fresh != null) _gem = fresh;
        _comments = comments;
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canInteract) {
      _snack(l10n.gemsSignInToInteract);
      return;
    }
    if (_likeBusy) return;
    setState(() => _likeBusy = true);
    // Optimistic update.
    final wasLiked = _gem.likedByMe;
    setState(() {
      _gem = _gem.copyWith(
        likedByMe: !wasLiked,
        likeCount: (_gem.likeCount + (wasLiked ? -1 : 1)).clamp(0, 1 << 30),
      );
    });
    try {
      await _service.toggleLike(_gem.id, _auth.user!.id);
    } catch (_) {
      if (!mounted) return;
      // Revert on failure.
      setState(() {
        _gem = _gem.copyWith(
          likedByMe: wasLiked,
          likeCount: (_gem.likeCount + (wasLiked ? 1 : -1)).clamp(0, 1 << 30),
        );
      });
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _postComment() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canInteract) {
      _snack(l10n.gemsSignInToInteract);
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final result = await _service.addComment(
        gemId: _gem.id,
        authorId: _auth.user!.id,
        authorName: _auth.user!.displayName,
        authorAvatarUrl: _auth.user!.avatarUrl,
        text: text,
      );
      if (!mounted) return;
      if (result.isRejected) {
        _snack(l10n.gemCommentRejected);
      } else if (result.value != null) {
        setState(() {
          _comments = [result.value!, ..._comments];
          _gem = _gem.copyWith(commentCount: _gem.commentCount + 1);
        });
        _commentController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (_) {
      if (mounted) _snack(l10n.gemCommentError);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GemCover(gem: _gem, height: 220),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_gem.category.icon, size: 18, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _gem.category.label,
                        style: text.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    _gem.name,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (_gem.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_rounded,
                            size: 16, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _gem.address,
                            style: text.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    l10n.gemAddedBy(_gem.creatorName),
                    style:
                        text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    _gem.description.isNotEmpty ? _gem.description : _gem.summary,
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildLikeRow(l10n, colors, text),
                  const SizedBox(height: AppTheme.spacingMd),
                  FilledButton.icon(
                    onPressed: () => MapsService.openDirectionsToCoords(
                      _gem.latitude,
                      _gem.longitude,
                      label: _gem.name,
                    ),
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(l10n.gemsDirections),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    l10n.gemComments(_gem.commentCount),
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _buildCommentComposer(l10n, colors),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildComments(l10n, colors, text),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    l10n.gemsAttribution,
                    style: text.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeRow(
      AppLocalizations l10n, ColorScheme colors, TextTheme text) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: _toggleLike,
          icon: Icon(
            _gem.likedByMe
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _gem.likedByMe ? colors.error : null,
          ),
          tooltip: l10n.gemLikes(_gem.likeCount),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          l10n.gemLikes(_gem.likeCount),
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCommentComposer(AppLocalizations l10n, ColorScheme colors) {
    if (!_canInteract) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                l10n.gemsSignInToInteract,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            minLines: 1,
            maxLines: 4,
            maxLength: 2000,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l10n.gemCommentHint,
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        FilledButton(
          onPressed: _posting ? null : _postComment,
          child: _posting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.gemCommentPost),
        ),
      ],
    );
  }

  Widget _buildComments(
      AppLocalizations l10n, ColorScheme colors, TextTheme text) {
    if (_loadingComments) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        child: Text(
          l10n.gemCommentEmpty,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }
    return Column(
      children: [
        for (final c in _comments)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage: c.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(c.authorAvatarUrl)
                      : null,
                  child: c.authorAvatarUrl.isEmpty
                      ? Text(
                          c.authorName.isNotEmpty
                              ? c.authorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: colors.onPrimaryContainer),
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.authorName,
                        style: text.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(c.text, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
