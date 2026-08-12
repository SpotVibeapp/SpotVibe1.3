import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

/// Paywall shown to event creators who want the $9.99/month Creator Pro tier.
/// This screen is purely UI — no RevenueCat integration yet since the
/// Creator Pro entitlement needs to be configured server-side first.
class CreatorProPaywallScreen extends StatefulWidget {
  const CreatorProPaywallScreen({super.key});

  @override
  State<CreatorProPaywallScreen> createState() => _CreatorProPaywallScreenState();
}

class _CreatorProPaywallScreenState extends State<CreatorProPaywallScreen> {
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Show success — wire to RevenueCat when Creator Pro entitlement is live
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎨 Welcome to Creator Pro! Your first event is ready to go.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop(true); // return true = subscribed
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _CreatorProHeader(appColors: appColors, onClose: () => context.pop(false))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.spacingLg),
                _PriceChip(appColors: appColors, text: text, colors: colors),
                const SizedBox(height: AppTheme.spacingLg),
                _CreatorFeatureList(colors: colors, appColors: appColors, text: text),
                const SizedBox(height: AppTheme.spacingLg),
                _FreeVsProComparison(colors: colors, appColors: appColors, text: text),
                const SizedBox(height: AppTheme.spacingLg),
                _SubscribeButton(appColors: appColors, isLoading: _isLoading, onTap: _handleSubscribe),
                const SizedBox(height: AppTheme.spacingSm),
                Center(
                  child: Text(
                    'Cancel anytime · No hidden fees',
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _CreatorProHeader extends StatelessWidget {
  final AppColorsExtension appColors;
  final VoidCallback onClose;
  const _CreatorProHeader({required this.appColors, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appColors.creatorTeal, appColors.creatorTealLight, const Color(0xFF6C5CE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Creator ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                const Text(
                  'Grow your audience. Run recurring events.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onClose,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Price Chip ─────────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  final AppColorsExtension appColors;
  final TextTheme text;
  final ColorScheme colors;
  const _PriceChip({required this.appColors, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.creatorTeal.withValues(alpha: 0.12), appColors.creatorTealLight.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: appColors.creatorTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\$9.99',
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: appColors.creatorTeal,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            '/ month',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: AppTheme.spacingXs),
            decoration: BoxDecoration(
              color: appColors.creatorTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Text(
              'MOST POPULAR',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: appColors.creatorTeal,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature List ───────────────────────────────────────────────────────────────

class _CreatorFeatureList extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _CreatorFeatureList({required this.colors, required this.appColors, required this.text});

  static const _features = [
    (Icons.repeat_rounded, 'Recurring Events', 'Post once — auto-repeats weekly or monthly'),
    (Icons.star_rounded, 'Featured Placement', 'Top of category feed 1× per week'),
    (Icons.bar_chart_rounded, 'Analytics Dashboard', 'Views, saves & click-throughs per event'),
    (Icons.palette_rounded, 'Custom Branding', 'Your logo and accent color on every page'),
    (Icons.phone_rounded, 'Contact Button', 'Phone, website & social links on event page'),
    (Icons.block_rounded, 'No Ads on Your Pages', 'Clean, distraction-free event pages'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: List.generate(_features.length, (i) {
          final (icon, title, subtitle) = _features[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm + 2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            appColors.creatorTeal.withValues(alpha: 0.2),
                            appColors.creatorTealLight.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(icon, size: AppTheme.iconSm + 4, color: appColors.creatorTeal),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(subtitle, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: appColors.creatorTeal, size: AppTheme.iconMd),
                  ],
                ),
              ),
              if (i < _features.length - 1)
                Divider(height: 1, thickness: 1, color: colors.outlineVariant.withValues(alpha: 0.2)),
            ],
          );
        }),
      ),
    );
  }
}

// ── Free vs Pro Comparison ─────────────────────────────────────────────────────

class _FreeVsProComparison extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _FreeVsProComparison({required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Text('What you get', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
          _ComparisonRow(label: 'One-time events', free: true, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Basic event page', free: true, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Public feed listing', free: true, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Recurring events', free: false, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Featured placement', free: false, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Analytics dashboard', free: false, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Custom branding', free: false, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'Contact button', free: false, pro: true, appColors: appColors, text: text, colors: colors),
          _ComparisonRow(label: 'No ads on pages', free: false, pro: true, appColors: appColors, text: text, colors: colors, isLast: true),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final bool free;
  final bool pro;
  final AppColorsExtension appColors;
  final TextTheme text;
  final ColorScheme colors;
  final bool isLast;

  const _ComparisonRow({
    required this.label,
    required this.free,
    required this.pro,
    required this.appColors,
    required this.text,
    required this.colors,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodySmall)),
              SizedBox(
                width: 56,
                child: Center(child: _indicator(free, colors, appColors)),
              ),
              SizedBox(
                width: 56,
                child: Center(child: _indicator(pro, colors, appColors)),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _indicator(bool value, ColorScheme colors, AppColorsExtension appColors) {
    return value
        ? Icon(Icons.check_rounded, size: AppTheme.iconSm, color: appColors.creatorTeal)
        : Icon(Icons.remove_rounded, size: AppTheme.iconSm, color: colors.onSurfaceVariant.withValues(alpha: AppTheme.opacityDisabled));
  }
}

// ── Subscribe Button ───────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  final AppColorsExtension appColors;
  final bool isLoading;
  final VoidCallback onTap;
  const _SubscribeButton({required this.appColors, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.creatorTeal, appColors.creatorTealLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: appColors.creatorTeal.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: isLoading ? null : onTap,
          child: Container(
            height: AppTheme.buttonHeight + 6,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                      SizedBox(width: AppTheme.spacingSm),
                      Text(
                        'Start Creator Pro — \$9.99/mo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
