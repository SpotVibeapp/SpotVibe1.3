import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/theme.dart';

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

    // Show success state when already subscribed
    if (sub.isSubscribed) {
      return _AlreadySubscribedView(onClose: () => Navigator.of(context).pop());
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PaywallHeader(appColors: appColors)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.spacingLg),
                _PlanToggle(sub: sub, appColors: appColors),
                const SizedBox(height: AppTheme.spacingMd),
                _PriceDisplay(sub: sub, text: text, appColors: appColors),
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

// ── Header ─────────────────────────────────────────────────────────────────────

class _PaywallHeader extends StatelessWidget {
  final AppColorsExtension appColors;
  const _PaywallHeader({required this.appColors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SpotVibe ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                const Text(
                  'Discover every event, everywhere',
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Plan Toggle ────────────────────────────────────────────────────────────────

class _PlanToggle extends StatelessWidget {
  final SubscriptionProvider sub;
  final AppColorsExtension appColors;
  const _PlanToggle({required this.sub, required this.appColors});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _PlanTab(
            label: 'Monthly',
            isSelected: sub.selectedPlanIndex == 0,
            onTap: () => sub.selectPlan(0),
            appColors: appColors,
          ),
          _PlanTab(
            label: 'Annual',
            isSelected: sub.selectedPlanIndex == 1,
            onTap: () => sub.selectPlan(1),
            appColors: appColors,
            savingsBadge: 'SAVE 40%',
          ),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorsExtension appColors;
  final String? savingsBadge;

  const _PlanTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.appColors,
    this.savingsBadge,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [appColors.proGold, appColors.proGoldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: isSelected
                ? [BoxShadow(color: appColors.proGold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: text.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (savingsBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.3) : appColors.proGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Text(
                    savingsBadge!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : appColors.proGold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price Display ──────────────────────────────────────────────────────────────

class _PriceDisplay extends StatelessWidget {
  final SubscriptionProvider sub;
  final TextTheme text;
  final AppColorsExtension appColors;
  const _PriceDisplay({required this.sub, required this.text, required this.appColors});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAnnual = sub.selectedPlanIndex == 1;
    final package = sub.selectedPackage;

    String priceLabel;
    String subLabel;

    if (package != null) {
      final priceString = package.storeProduct.priceString;
      priceLabel = priceString;
      subLabel = isAnnual ? 'per year · billed annually' : 'per month · cancel anytime';
    } else if (sub.isPurchasing) {
      priceLabel = '—';
      subLabel = 'Loading plans…';
    } else {
      // No products configured yet — show illustrative prices
      priceLabel = isAnnual ? '\$39.99' : '\$5.99';
      subLabel = isAnnual
          ? 'per year · billed annually (≈ \$3.33/mo)'
          : 'per month · cancel anytime';
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            priceLabel,
            key: ValueKey(priceLabel),
            style: text.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: appColors.proGold,
              fontSize: 40,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(subLabel, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

// ── Feature List ───────────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  final ColorScheme colors;
  final AppColorsExtension appColors;
  final TextTheme text;
  const _FeatureList({required this.colors, required this.appColors, required this.text});

  static const _features = [
    (Icons.explore_rounded, 'Priority Event Discovery', 'See events before anyone else in your area'),
    (Icons.bookmark_rounded, 'Unlimited Bookmarks', 'Save as many events as you want, forever'),
    (Icons.search_rounded, 'Advanced Search Filters', 'Filter by radius, source, cost, and date'),
    (Icons.chat_bubble_rounded, 'Exclusive Chat Features', 'React, reply, and pin messages in event chats'),
    (Icons.notifications_active_rounded, 'Early Access Alerts', 'Get notified before events sell out'),
    (Icons.block_rounded, 'Ad-Free Experience', 'No ads, no interruptions — just pure events'),
    (Icons.workspace_premium_rounded, 'Pro Badge on Profile', 'Stand out with a golden PRO badge'),
    (Icons.download_rounded, 'Offline Event Access', 'Save event details for offline viewing'),
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
                          colors: [appColors.proGold.withValues(alpha: 0.2), appColors.proGoldLight.withValues(alpha: 0.15)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(icon, size: AppTheme.iconSm + 4, color: appColors.proGold),
                    ),
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
                    Icon(Icons.check_circle_rounded, color: appColors.proGold, size: AppTheme.iconMd),
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

// ── Purchase Button ────────────────────────────────────────────────────────────

class _PurchaseButton extends StatelessWidget {
  final SubscriptionProvider sub;
  final AppColorsExtension appColors;
  const _PurchaseButton({required this.sub, required this.appColors});

  @override
  Widget build(BuildContext context) {
    final isAnnual = sub.selectedPlanIndex == 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.proGold, appColors.proGoldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(color: appColors.proGold.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: sub.isPurchasing ? null : () => _handlePurchase(context),
          child: Container(
            height: AppTheme.buttonHeight + 6,
            alignment: Alignment.center,
            child: sub.isPurchasing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        isAnnual ? 'Start Annual Plan' : 'Start Monthly Plan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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
          content: Text('🎉 Welcome to SpotVibe Pro!'),
          backgroundColor: Color(0xFFE8A838),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else if (sub.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sub.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      sub.clearError();
    }
  }
}

// ── Restore Button ─────────────────────────────────────────────────────────────

class _RestoreButton extends StatelessWidget {
  final SubscriptionProvider sub;
  final ColorScheme colors;
  final TextTheme text;
  const _RestoreButton({required this.sub, required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: sub.isPurchasing ? null : () => _handleRestore(context),
      child: Text(
        'Restore Purchases',
        style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    final restored = await sub.restorePurchases();
    if (!context.mounted) return;
    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Subscription restored successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
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

// ── Terms Row ─────────────────────────────────────────────────────────────────

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
              text: 'Terms of Service',
              style: linkStyle,
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Already Subscribed ────────────────────────────────────────────────────────

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
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [appColors.proGold, appColors.proGoldLight],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: appColors.proGold.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text("You're already Pro! 🎉", style: text.headlineSmall),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                "You have full access to all SpotVibe Pro features. Enjoy discovering events your way!",
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
