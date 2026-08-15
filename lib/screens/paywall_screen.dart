import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/pricing.dart';
import '../providers/subscription_provider.dart';
import '../theme/theme.dart';

/// Launch paywall: 7-day trial, then store-billed $12.99/month
/// (or $9.99 founding SKU while slots remain).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final text = Theme.of(context).textTheme;

    if (sub.isSubscribed) {
      return _AlreadySubscribedView(onClose: () => Navigator.of(context).pop(true));
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(appColors: appColors)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.spacingLg),
                _PriceBlock(sub: sub, text: text, appColors: appColors),
                const SizedBox(height: AppTheme.spacingLg),
                _FreeVsPremium(sub: sub, colors: colors, appColors: appColors, text: text),
                const SizedBox(height: AppTheme.spacingLg),
                _FeatureList(colors: colors, appColors: appColors, text: text),
                const SizedBox(height: AppTheme.spacingLg),
                _PurchaseButton(sub: sub, appColors: appColors),
                const SizedBox(height: AppTheme.spacingMd),
                _RestoreButton(sub: sub, colors: colors, text: text),
                const SizedBox(height: AppTheme.spacingSm),
                _TermsRow(colors: colors, text: text),
                const SizedBox(height: AppTheme.spacingXl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppColorsExtension appColors;
  const _Header({required this.appColors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appColors.proGold, appColors.proGoldLight, const Color(0xFF6C5CE7)],
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
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                const Text(
                  kPremiumPlanName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                const Text(
                  'For promoters, venues, and organizers',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
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
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final SubscriptionProvider sub;
  final TextTheme text;
  final AppColorsExtension appColors;
  const _PriceBlock({required this.sub, required this.text, required this.appColors});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final package = sub.selectedPackage;
    final price = package?.storeProduct.priceString ?? sub.displayPriceLabel;

    return Column(
      children: [
        Text(
          kPremiumTrialLabel,
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: appColors.proGold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'then $price',
          style: text.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: appColors.proGold,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub.billingFinePrint,
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        if (sub.offerFoundingPrice && !sub.isFoundingMember) ...[
          const SizedBox(height: 8),
          Text(
            'Founding venues lock ${kFoundingMonthlyLabel} — ${sub.foundingSlotsRemaining} of $kFoundingMemberLimit left',
            style: text.labelSmall?.copyWith(
              color: appColors.proGold,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _FreeVsPremium extends StatelessWidget {
  final SubscriptionProvider sub;
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _FreeVsPremium({
    required this.sub,
    required this.colors,
    required this.appColors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Free — \$0', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppTheme.spacingSm),
          ...kFreePlanPerks.map(
            (perk) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(perk, style: text.bodySmall)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Premium — ${sub.displayPriceLabel}',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: appColors.proGold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Everything in Free, plus the tools below.',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _FeatureList({required this.colors, required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: List.generate(kPremiumPlanPerks.length, (i) {
          final (title, subtitle) = kPremiumPlanPerks[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm + 2,
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: appColors.proGold, size: AppTheme.iconMd),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(subtitle, style: text.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < kPremiumPlanPerks.length - 1)
                Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.2)),
            ],
          );
        }),
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final SubscriptionProvider sub;
  final AppColorsExtension appColors;
  const _PurchaseButton({required this.sub, required this.appColors});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: sub.isPurchasing ? null : () => _handlePurchase(context),
        child: Ink(
          height: AppTheme.buttonHeight + 6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appColors.proGold, appColors.proGoldLight],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Center(
            child: sub.isPurchasing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    sub.subscribeCtaLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    final success = await sub.purchaseSelected();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to SpotVibe Premium.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (sub.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sub.errorMessage!), behavior: SnackBarBehavior.floating),
      );
      sub.clearError();
    }
  }
}

class _RestoreButton extends StatelessWidget {
  final SubscriptionProvider sub;
  final ColorScheme colors;
  final TextTheme text;
  const _RestoreButton({required this.sub, required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: sub.isPurchasing ? null : () => _handleRestore(context),
      child: Text('Restore Purchases', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
    );
  }

  Future<void> _handleRestore(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    final restored = await sub.restorePurchases();
    if (!context.mounted) return;
    if (restored) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sub.errorMessage ?? 'No subscription found to restore.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      sub.clearError();
    }
  }
}

class _TermsRow extends StatelessWidget {
  final ColorScheme colors;
  final TextTheme text;
  const _TermsRow({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    final style = text.labelSmall?.copyWith(color: colors.onSurfaceVariant);
    final linkStyle = text.labelSmall?.copyWith(
      color: colors.primary,
      decoration: TextDecoration.underline,
    );
    return Center(
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'By subscribing you agree to our '),
            TextSpan(
              text: 'Terms of Use',
              style: linkStyle,
              recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy'),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AlreadySubscribedView extends StatelessWidget {
  final VoidCallback onClose;
  const _AlreadySubscribedView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 72, color: appColors.proGold),
              const SizedBox(height: AppTheme.spacingLg),
              Text('You\'re on Premium', style: text.headlineSmall),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Recurring events, analytics, branding, and verified claims are unlocked.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton(onPressed: onClose, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
