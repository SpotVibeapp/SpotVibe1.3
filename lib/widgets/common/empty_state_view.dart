import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// The visual variant of the empty state — drives icon, gradient bg, and tone.
enum EmptyStateVariant {
  /// Generic "no results" — primary purple tone.
  generic,

  /// Events are filtered too strictly — purple/secondary tone with target icon.
  filtersTooStrict,

  /// No events found nearby by location/area — amber/warning tone.
  noEventsNearby,

  /// Location permission absent or GPS unavailable — amber/orange tone.
  noLocation,

  /// API / network error — error red tone.
  apiError,

  /// No saved/bookmarked events yet — teal tone.
  noSavedEvents,
}

class EmptyStateView extends StatefulWidget {
  final EmptyStateVariant variant;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EmptyStateView({
    super.key,
    this.variant = EmptyStateVariant.generic,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  State<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends State<EmptyStateView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the two gradient colours for the icon container background.
  List<Color> _gradientColors(ColorScheme colors, AppColorsExtension appColors) {
    switch (widget.variant) {
      case EmptyStateVariant.filtersTooStrict:
        return [colors.primaryContainer, colors.secondaryContainer];
      case EmptyStateVariant.noEventsNearby:
        return [
          appColors.warning.withValues(alpha: AppTheme.opacityHint),
          colors.tertiaryContainer,
        ];
      case EmptyStateVariant.noLocation:
        return [
          appColors.warning.withValues(alpha: AppTheme.opacityHint),
          appColors.warning.withValues(alpha: 0.2),
        ];
      case EmptyStateVariant.apiError:
        return [
          colors.errorContainer,
          colors.errorContainer.withValues(alpha: AppTheme.opacityHint),
        ];
      case EmptyStateVariant.noSavedEvents:
        return [
          appColors.creatorTeal.withValues(alpha: 0.18),
          appColors.creatorTealLight.withValues(alpha: 0.10),
        ];
      case EmptyStateVariant.generic:
        return [colors.primaryContainer, colors.surfaceContainerHighest];
    }
  }

  Color _iconColor(ColorScheme colors, AppColorsExtension appColors) {
    switch (widget.variant) {
      case EmptyStateVariant.filtersTooStrict:
        return colors.primary;
      case EmptyStateVariant.noEventsNearby:
        return appColors.warning;
      case EmptyStateVariant.noLocation:
        return appColors.warning;
      case EmptyStateVariant.apiError:
        return colors.error;
      case EmptyStateVariant.noSavedEvents:
        return appColors.creatorTeal;
      case EmptyStateVariant.generic:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    final gradients = _gradientColors(colors, appColors);
    final iconColor = _iconColor(colors, appColors);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon container with gradient background ──────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradients,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradients.first.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 44, color: iconColor),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Title ────────────────────────────────────────────────────
                Text(
                  widget.title,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // ── Subtitle ─────────────────────────────────────────────────
                Text(
                  widget.subtitle,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // ── Primary CTA ───────────────────────────────────────────────
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  FilledButton.icon(
                    onPressed: widget.onAction,
                    icon: Icon(_ctaIcon, size: AppTheme.iconSm),
                    label: Text(widget.actionLabel!),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, AppTheme.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                    ),
                  ),
                ],

                // ── Secondary CTA ─────────────────────────────────────────────
                if (widget.secondaryActionLabel != null &&
                    widget.onSecondaryAction != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  TextButton(
                    onPressed: widget.onSecondaryAction,
                    child: Text(widget.secondaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _ctaIcon {
    switch (widget.variant) {
      case EmptyStateVariant.filtersTooStrict:
        return Icons.filter_alt_off_rounded;
      case EmptyStateVariant.noEventsNearby:
        return Icons.radar_rounded;
      case EmptyStateVariant.noLocation:
        return Icons.my_location_rounded;
      case EmptyStateVariant.apiError:
        return Icons.refresh_rounded;
      case EmptyStateVariant.noSavedEvents:
        return Icons.explore_rounded;
      case EmptyStateVariant.generic:
        return Icons.search_rounded;
    }
  }
}
