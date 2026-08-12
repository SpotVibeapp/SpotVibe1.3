import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/subscription_provider.dart';
import '../theme/theme.dart';

/// Shown when a venue owner taps "Claim this page" on an auto-generated event.
///
/// • Non-subscribers see a Premium sales page explaining the venue control tier.
/// • Existing Pro subscribers see an ownership verification prompt.
class VenueClaimScreen extends StatelessWidget {
  final Event event;
  const VenueClaimScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    return sub.isSubscribed
        ? _VerifyOwnershipView(event: event)
        : _PremiumSalesView(event: event);
  }
}

// ── Premium Sales Page ─────────────────────────────────────────────────────────

class _PremiumSalesView extends StatelessWidget {
  final Event event;
  const _PremiumSalesView({required this.event});

  static const _perks = [
    (Icons.edit_rounded, 'Edit Event Details', 'Update name, description, hours, photos, and more in real time'),
    (Icons.local_offer_rounded, 'Promote Your Specials', 'Pin drink deals, happy hours, and ticketed nights to the top'),
    (Icons.bar_chart_rounded, 'Audience Insights', "See RSVP trends, who's attending, and peak interest days"),
    (Icons.chat_bubble_rounded, 'Respond to Comments', 'Engage directly with attendees and answer questions publicly'),
    (Icons.verified_rounded, 'Verified Venue Badge', 'Display a blue checkmark so fans know this is the official page'),
    (Icons.notifications_active_rounded, 'Push Announcements', 'Notify RSVPs instantly about last-minute changes or specials'),
    (Icons.photo_library_rounded, 'Rich Media Gallery', 'Add a full photo gallery and video to attract more guests'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          _ClaimHeader(appColors: appColors, eventTitle: event.title),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.spacingLg),
                _VenueEventCard(event: event, colors: colors, text: text),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  'Take control of your venue page',
                  style: text.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'SpotVibe automatically generates pages for local venues and events. '
                  'As the venue owner, becoming a SpotVibe Premium member gives you '
                  'full control over this listing — edit details, showcase specials, '
                  'and connect directly with your guests.',
                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                _PerksList(appColors: appColors, colors: colors, text: text),
                const SizedBox(height: AppTheme.spacingLg),
                _PremiumCta(appColors: appColors, text: text),
                const SizedBox(height: AppTheme.spacingSm),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Not now',
                      style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
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

class _ClaimHeader extends StatelessWidget {
  final AppColorsExtension appColors;
  final String eventTitle;
  const _ClaimHeader({required this.appColors, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7),
                  appColors.proGold,
                  appColors.proGoldLight,
                ],
                stops: const [0.0, 0.65, 1.0],
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: AppTheme.iconLg,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const Text(
                    'Claim Your Venue',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                    child: Text(
                      'Powered by SpotVibe Premium',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Venue Event Card ───────────────────────────────────────────────────────────

class _VenueEventCard extends StatelessWidget {
  final Event event;
  final ColorScheme colors;
  final TextTheme text;
  const _VenueEventCard({
    required this.event,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: AppTheme.iconMd,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.location,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Perks List ─────────────────────────────────────────────────────────────────

class _PerksList extends StatelessWidget {
  final AppColorsExtension appColors;
  final ColorScheme colors;
  final TextTheme text;
  const _PerksList({
    required this.appColors,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: List.generate(_PremiumSalesView._perks.length, (i) {
          final (icon, title, subtitle) = _PremiumSalesView._perks[i];
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
                            appColors.proGold.withValues(alpha: 0.2),
                            appColors.proGoldLight.withValues(alpha: 0.15),
                          ],
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
                          Text(
                            title,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(subtitle, style: text.labelSmall),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: appColors.proGold,
                      size: AppTheme.iconMd,
                    ),
                  ],
                ),
              ),
              if (i < _PremiumSalesView._perks.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.2),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Premium CTA Button ─────────────────────────────────────────────────────────

class _PremiumCta extends StatelessWidget {
  final AppColorsExtension appColors;
  final TextTheme text;
  const _PremiumCta({required this.appColors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.proGold, appColors.proGoldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: appColors.proGold.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            // Close this screen and open the paywall.
            context.pop();
            context.push('/paywall');
          },
          child: SizedBox(
            height: AppTheme.buttonHeight + 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: AppTheme.iconMd,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Unlock Premium & Claim Page',
                  style: text.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
}

// ── Ownership Verification View (existing Premium members) ─────────────────────

class _VerifyOwnershipView extends StatefulWidget {
  final Event event;
  const _VerifyOwnershipView({required this.event});

  @override
  State<_VerifyOwnershipView> createState() => _VerifyOwnershipViewState();
}

class _VerifyOwnershipViewState extends State<_VerifyOwnershipView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    if (_submitted) {
      return _SubmittedConfirmation(
        eventTitle: widget.event.title,
        appColors: appColors,
        text: text,
        colors: colors,
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verify Ownership'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pro badge row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appColors.proGold.withValues(alpha: 0.15),
                      appColors.proGoldLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: appColors.proGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: appColors.proGold,
                      size: AppTheme.iconMd,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'You\'re a SpotVibe Premium member. Submit your details and we\'ll verify your ownership within 2 business days.',
                        style: text.labelMedium?.copyWith(
                          color: appColors.proGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Event being claimed
              Text('Claiming page for', style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppTheme.spacingXs),
              Text(widget.event.title, style: text.titleMedium),
              Text(widget.event.location, style: text.bodySmall),
              const SizedBox(height: AppTheme.spacingLg),
              Text('Your Details', style: text.titleSmall),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name *',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Business email *',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your email';
                  if (!v.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Your role (e.g. Owner, GM) *',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your role' : null,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'By submitting, you confirm that you are an authorized representative of this venue. '
                'False claims may result in account suspension.',
                style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // Submit button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [appColors.proGold, appColors.proGoldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: appColors.proGold.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    onTap: _submit,
                    child: SizedBox(
                      height: AppTheme.buttonHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.white, size: AppTheme.iconMd),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            'Submit Ownership Request',
                            style: text.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Submission Confirmation ────────────────────────────────────────────────────

class _SubmittedConfirmation extends StatelessWidget {
  final String eventTitle;
  final AppColorsExtension appColors;
  final TextTheme text;
  final ColorScheme colors;

  const _SubmittedConfirmation({
    required this.eventTitle,
    required this.appColors,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [appColors.proGold, appColors.proGoldLight],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: appColors.proGold.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.white,
                  size: AppTheme.iconXl,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Request Submitted! 🎉',
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'We\'ve received your ownership request for "$eventTitle". '
                'Our team will review your details and reach out within 2 business days.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
