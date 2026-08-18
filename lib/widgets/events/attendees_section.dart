import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/rsvp_provider.dart';
import '../../theme/theme.dart';
import '../common/app_avatar.dart';
import '../common/section_title.dart';

class AttendeesSection extends StatelessWidget {
  /// Accent color for the section header bar (usually the event's category
  /// color). Defaults to the brand violet when not supplied.
  final Color accent;

  const AttendeesSection({super.key, this.accent = AppTheme.brandViolet});

  @override
  Widget build(BuildContext context) {
    final rsvp = context.watch<RsvpProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    if (rsvp.totalRsvpCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: l10n.whosGoing, accent: accent),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: AppTheme.iconLg, color: colors.onSurfaceVariant),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  l10n.noRsvpsYet,
                  style: text.titleSmall,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.beFirstToGo,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final publicList = rsvp.publicAttendees;
    final privateCount = rsvp.totalRsvpCount - publicList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.whosGoing, accent: accent),
        const SizedBox(height: AppTheme.spacingSm),
        _SocialProofHeader(
          publicList: publicList,
          totalCount: rsvp.totalRsvpCount,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        // Full grid below
        if (publicList.isEmpty)
          Text(
            l10n.attendeesPrivate,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          )
        else ...[
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingMd,
            children: [
              ...publicList.take(12).map((attendee) => _AttendeeTile(attendee: attendee)),
              if (privateCount > 0)
                _PrivateCountTile(count: privateCount),
            ],
          ),
        ],
      ],
    );
  }
}

// Overlapping avatar stack with "X people are going" headline.
class _SocialProofHeader extends StatelessWidget {
  final List<dynamic> publicList;
  final int totalCount;

  const _SocialProofHeader({
    required this.publicList,
    required this.totalCount,
  });

  static const double _avatarSize = 36.0;
  static const double _overlap = 12.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final stackList = publicList.take(5).toList();
    final extraCount = totalCount - stackList.length;
    // Width of the entire stack: first avatar full width + each additional shifted left by _overlap
    final stackWidth = _avatarSize +
        (stackList.length - 1).clamp(0, 4) * (_avatarSize - _overlap) +
        (extraCount > 0 ? (_avatarSize - _overlap) : 0);

    return Row(
      children: [
        // Overlapping avatar stack
        SizedBox(
          width: stackWidth.clamp(0, double.infinity),
          height: _avatarSize,
          child: Stack(
            children: [
              ...List.generate(stackList.length, (i) {
                return Positioned(
                  left: i * (_avatarSize - _overlap),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surface,
                        width: AppTheme.borderSelected,
                      ),
                    ),
                    child: AppAvatar(
                      imageUrl: stackList[i].avatarUrl as String,
                      size: _avatarSize,
                      fallbackName: stackList[i].userName as String,
                    ),
                  ),
                );
              }),
              if (extraCount > 0)
                Positioned(
                  left: stackList.length * (_avatarSize - _overlap),
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryContainer,
                      border: Border.all(
                        color: colors.surface,
                        width: AppTheme.borderSelected,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+$extraCount',
                        style: text.labelSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.peopleGoing(totalCount),
                style: text.titleSmall?.copyWith(color: colors.onSurface),
              ),
              Text(
                l10n.bePartOfExperience,
                style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendeeTile extends StatelessWidget {
  final dynamic attendee;
  const _AttendeeTile({required this.attendee});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          AppAvatar(
            imageUrl: attendee.avatarUrl as String,
            size: AppTheme.avatarMd,
            fallbackName: attendee.userName as String,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            attendee.userName as String,
            style: text.labelSmall?.copyWith(color: colors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PrivateCountTile extends StatelessWidget {
  final int count;
  const _PrivateCountTile({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: AppTheme.avatarMd,
            height: AppTheme.avatarMd,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(
              Icons.lock_rounded,
              size: AppTheme.iconSm,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            AppLocalizations.of(context)!.privateCount(count),
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
