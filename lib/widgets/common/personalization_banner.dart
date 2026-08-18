import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// Subtle animated banner shown above the event feed when personalization is
/// active. Displays the user's top interest categories and opens an
/// explanation sheet on tap.
class PersonalizationBanner extends StatefulWidget {
  final List<String> topCategories;
  final VoidCallback? onReset;

  const PersonalizationBanner({
    super.key,
    required this.topCategories,
    this.onReset,
  });

  @override
  State<PersonalizationBanner> createState() => _PersonalizationBannerState();
}

class _PersonalizationBannerState extends State<PersonalizationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showExplanation(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: colors.primary, size: AppTheme.iconMd),
                const SizedBox(width: AppTheme.spacingSm),
                Text(l10n.whyAmISeeing,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.personalizationBody,
              style: text.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (widget.topCategories.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(l10n.topInterests,
                  style: text.labelLarge
                      ?.copyWith(color: colors.onSurface)),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingSm,
                children: widget.topCategories
                    .map((cat) => Chip(
                          label: Text(cat),
                          backgroundColor: colors.primaryContainer,
                          labelStyle: text.labelMedium?.copyWith(
                              color: colors.onPrimaryContainer),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
            if (widget.onReset != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReset!();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.resetMyPreferences),
                ),
              ),
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.gotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final cats = widget.topCategories;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: () => _showExplanation(context),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.2),
                width: AppTheme.borderDefault,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: AppTheme.iconSm, color: colors.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: cats.isEmpty
                      ? Text(
                          l10n.personalizingFeed,
                          style: text.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        )
                      : RichText(
                          text: TextSpan(
                            style: text.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                            children: [
                              TextSpan(text: l10n.showingMore),
                              TextSpan(
                                text: cats.take(2).join(' & '),
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: l10n.forYou),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Icon(Icons.info_outline_rounded,
                    size: AppTheme.iconSm,
                    color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
