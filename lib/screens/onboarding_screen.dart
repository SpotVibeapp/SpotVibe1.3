import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../repositories/onboarding_repository.dart';
import '../services/deep_link_service.dart';
import '../services/permission_service.dart';
import '../theme/theme.dart';
import '../widgets/common/spotvibe_logo.dart';

// ── Interest category data ─────────────────────────────────────────────────────

/// Maps an English interest key (stored as data) to its localized label.
String _interestLabel(BuildContext context, String key) {
  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'Music':
      return l10n.interestMusic;
    case 'Sports':
      return l10n.interestSports;
    case 'Food & Drink':
      return l10n.interestFoodDrink;
    case 'Arts':
      return l10n.interestArts;
    case 'Nightlife':
      return l10n.interestNightlife;
    case 'Comedy':
      return l10n.interestComedy;
    case 'Community':
      return l10n.interestCommunity;
    case 'Tech':
      return l10n.interestTech;
    case 'Fitness':
      return l10n.interestFitness;
    case 'Family':
      return l10n.interestFamily;
    case 'Outdoor':
      return l10n.interestOutdoor;
    case 'Film':
      return l10n.interestFilm;
    default:
      return key;
  }
}

class _InterestOption {
  final String label;
  final IconData icon;
  const _InterestOption(this.label, this.icon);
}

const List<_InterestOption> _kInterests = [
  _InterestOption('Music', Icons.music_note_rounded),
  _InterestOption('Sports', Icons.sports_soccer_rounded),
  _InterestOption('Food & Drink', Icons.restaurant_rounded),
  _InterestOption('Arts', Icons.palette_rounded),
  _InterestOption('Nightlife', Icons.nightlife_rounded),
  _InterestOption('Comedy', Icons.sentiment_very_satisfied_rounded),
  _InterestOption('Community', Icons.people_rounded),
  _InterestOption('Tech', Icons.computer_rounded),
  _InterestOption('Fitness', Icons.fitness_center_rounded),
  _InterestOption('Family', Icons.child_care_rounded),
  _InterestOption('Outdoor', Icons.park_rounded),
  _InterestOption('Film', Icons.movie_rounded),
];

// ── Main onboarding screen ─────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final PermissionService permissionService;
  final OnboardingRepository onboardingRepository;

  const OnboardingScreen({
    super.key,
    required this.permissionService,
    required this.onboardingRepository,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  // Permission step state
  bool _locationGranted = false;
  bool _locationDone = false;
  bool _locationLoading = false;
  bool _notifGranted = false;
  bool _notifDone = false;
  bool _notifLoading = false;

  // Interests step state
  final Set<String> _selectedInterests = {};

  // Welcome page animation
  late final AnimationController _heroController;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heroScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeIn);
    _heroController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ───────────────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    await widget.onboardingRepository.saveInterests(_selectedInterests.toList());
    await widget.onboardingRepository.markDone();
    await widget.permissionService.markAsked();
    if (!mounted) return;
    final pending = await DeepLinkService.consumePendingLink();
    if (mounted) context.go(pending ?? '/');
  }

  // ── Permission helpers ───────────────────────────────────────────────────────

  Future<void> _requestLocation() async {
    if (_locationLoading || _locationDone) return;
    setState(() => _locationLoading = true);
    final granted = await widget.permissionService.requestLocation();
    if (mounted) {
      setState(() {
        _locationGranted = granted;
        _locationLoading = false;
        _locationDone = true;
      });
    }
  }

  Future<void> _requestNotifs() async {
    if (_notifLoading || _notifDone) return;
    setState(() => _notifLoading = true);
    final granted = await widget.permissionService.requestNotifications();
    if (mounted) {
      setState(() {
        _notifGranted = granted;
        _notifLoading = false;
        _notifDone = true;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(
                    heroScale: _heroScale,
                    heroFade: _heroFade,
                  ),
                  _PermissionsPage(
                    locationGranted: _locationGranted,
                    locationDone: _locationDone,
                    locationLoading: _locationLoading,
                    notifGranted: _notifGranted,
                    notifDone: _notifDone,
                    notifLoading: _notifLoading,
                    onRequestLocation: _requestLocation,
                    onRequestNotifs: _requestNotifs,
                  ),
                  _InterestsPage(
                    selected: _selectedInterests,
                    onToggle: (label) => setState(() {
                      if (_selectedInterests.contains(label)) {
                        _selectedInterests.remove(label);
                      } else {
                        _selectedInterests.add(label);
                      }
                    }),
                  ),
                  const _ReadyPage(),
                ],
              ),
            ),

            // Bottom navigation area
            _OnboardingFooter(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onNext: _nextPage,
              onSkip: _currentPage == _totalPages - 1 ? null : _finish,
              onFinish: _currentPage == _totalPages - 1 ? _finish : null,
              isLastPage: _currentPage == _totalPages - 1,
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final Animation<double> heroScale;
  final Animation<double> heroFade;

  const _WelcomePage({required this.heroScale, required this.heroFade});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: heroFade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingXl,
          AppTheme.spacingLg,
          AppTheme.spacingMd,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingXl),

            // Hero graphic with a slowly breathing brand-colored aura
            ScaleTransition(
              scale: heroScale,
              child: const _WelcomeHero(),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            Text(
              l10n.discoverTitle,
              textAlign: TextAlign.center,
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Text(
              l10n.discoverBody,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.55,
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Feature pills row
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: [
                _FeaturePill(
                    icon: Icons.location_on_rounded, label: l10n.nearYou),
                _FeaturePill(
                    icon: Icons.tune_rounded, label: l10n.personalised),
                _FeaturePill(
                    icon: Icons.group_rounded, label: l10n.social),
                _FeaturePill(
                    icon: Icons.notifications_active_rounded,
                    label: l10n.reminders),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
            color: colors.primary.withValues(alpha: 0.18),
            width: AppTheme.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTheme.iconSm, color: colors.primary),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Permissions ────────────────────────────────────────────────────────

class _PermissionsPage extends StatelessWidget {
  final bool locationGranted;
  final bool locationDone;
  final bool locationLoading;
  final bool notifGranted;
  final bool notifDone;
  final bool notifLoading;
  final VoidCallback onRequestLocation;
  final VoidCallback onRequestNotifs;

  const _PermissionsPage({
    required this.locationGranted,
    required this.locationDone,
    required this.locationLoading,
    required this.notifGranted,
    required this.notifDone,
    required this.notifLoading,
    required this.onRequestLocation,
    required this.onRequestNotifs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingMd),

          // Section header
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(Icons.lock_open_rounded,
                size: AppTheme.iconMd, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            l10n.quickPermsTitle,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            l10n.quickPermsBody,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Location card
          _OnboardingPermCard(
            icon: Icons.location_on_rounded,
            iconColor: colors.primary,
            title: l10n.location,
            description: l10n.locationDesc,
            granted: locationGranted,
            done: locationDone,
            loading: locationLoading,
            onAllow: onRequestLocation,
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Notifications card
          _OnboardingPermCard(
            icon: Icons.notifications_rounded,
            iconColor: colors.tertiary,
            title: l10n.notifications,
            description: l10n.notifDesc,
            granted: notifGranted,
            done: notifDone,
            loading: notifLoading,
            onAllow: onRequestNotifs,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPermCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool granted;
  final bool done;
  final bool loading;
  final VoidCallback onAllow;

  const _OnboardingPermCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.granted,
    required this.done,
    required this.loading,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: done && granted
            ? colors.primaryContainer.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: done && granted
              ? colors.primary.withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.4),
          width:
              done && granted ? AppTheme.borderSelected : AppTheme.borderDefault,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done && granted
                  ? colors.primaryContainer
                  : iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: done && granted
                ? Icon(Icons.check_rounded,
                    color: colors.onPrimaryContainer, size: AppTheme.iconMd)
                : Icon(icon, color: iconColor, size: AppTheme.iconMd),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: granted
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          granted
                              ? AppLocalizations.of(context)!.allowed
                              : AppLocalizations.of(context)!.denied,
                          style: text.labelSmall?.copyWith(
                            color: granted
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(description,
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
                if (!done) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: loading ? null : onAllow,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        side: BorderSide(color: iconColor.withValues(alpha: 0.6)),
                        foregroundColor: iconColor,
                      ),
                      child: loading
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: iconColor),
                            )
                          : Text(AppLocalizations.of(context)!.allow),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Interest selection ─────────────────────────────────────────────────

class _InterestsPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _InterestsPage({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingMd),

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(Icons.favorite_rounded,
                size: AppTheme.iconMd, color: colors.onTertiaryContainer),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            l10n.whatAreYouInto,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            l10n.pickInterestsBody,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: _kInterests.map((interest) {
              final isSelected = selected.contains(interest.label);
              return _InterestChip(
                label: _interestLabel(context, interest.label),
                icon: interest.icon,
                isSelected: isSelected,
                onTap: () => onToggle(interest.label),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          if (selected.isEmpty)
            Text(
              l10n.selectAtLeastOne,
              style: text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant
                    .withValues(alpha: AppTheme.opacityHint),
              ),
            ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.5),
              width: AppTheme.borderDefault,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppTheme.iconSm,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  color:
                      isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 4: Ready ──────────────────────────────────────────────────────────────

class _ReadyPage extends StatefulWidget {
  const _ReadyPage();

  @override
  State<_ReadyPage> createState() => _ReadyPageState();
}

class _ReadyPageState extends State<_ReadyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.primary, colors.tertiary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.30),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 60,
                    color: colors.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              Text(
                l10n.allSetTitle,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              Text(
                l10n.allSetBody,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Three value reminders
              _CheckItem(
                icon: Icons.search_rounded,
                label: l10n.browseNearYou,
                colors: colors,
                text: text,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _CheckItem(
                icon: Icons.tune_rounded,
                label: l10n.filterByDatePrice,
                colors: colors,
                text: text,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _CheckItem(
                icon: Icons.group_rounded,
                label: l10n.seeWhosGoing,
                colors: colors,
                text: text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final TextTheme text;

  const _CheckItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppTheme.iconSm, color: colors.onPrimaryContainer),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Text(
            label,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ── Footer: dots indicator + CTA buttons ──────────────────────────────────────

class _OnboardingFooter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;
  final bool isLastPage;
  final ColorScheme colors;

  const _OnboardingFooter({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
    required this.onFinish,
    required this.isLastPage,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary
                      : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLastPage ? onFinish : onNext,
              child: Text(isLastPage ? l10n.exploreSpotVibe : l10n.continueBtn),
            ),
          ),

          // Skip link (hidden on last page)
          if (!isLastPage) ...[
            const SizedBox(height: AppTheme.spacingXs),
            TextButton(
              onPressed: onSkip,
              child: Text(
                l10n.skipForNow,
                style: text.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Welcome hero with animated glow ───────────────────────────────────────────

/// The onboarding logo mark with a soft, slowly drifting brand-colored aura
/// behind it. The logo stays crisp on top; the glow is a low-opacity,
/// IgnorePointer background so it never affects readability or taps.
class _WelcomeHero extends StatefulWidget {
  const _WelcomeHero();

  @override
  State<_WelcomeHero> createState() => _WelcomeHeroState();
}

class _WelcomeHeroState extends State<_WelcomeHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = _controller.value;
              final c1 = Color.lerp(
                AppTheme.brandViolet,
                AppTheme.brandPink,
                t,
              )!;
              final c2 = Color.lerp(
                AppTheme.brandCyan,
                AppTheme.brandViolet,
                1 - t,
              )!;
              return IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        c1.withValues(alpha: isDark ? 0.30 : 0.20),
                        c2.withValues(alpha: isDark ? 0.16 : 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          const SpotVibeLogo(size: 148, glow: false),
        ],
      ),
    );
  }
}
