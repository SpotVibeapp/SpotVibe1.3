import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/theme.dart';

/// Wraps the app and shows a branded animated splash on top for the first few
/// seconds of a cold launch, then fades it away to reveal [child].
///
/// The splash fills the whole screen with the SpotVibe brand gradient (so there
/// is no white space around a tiny logo like the bare native launch screen), a
/// logo that pops in, the "SpotVibe" wordmark flying in from the distance to
/// land under the logo, a tagline, and drifting blue/purple twinkling stars.
class SplashGate extends StatefulWidget {
  final Widget child;

  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  void _onFinished() {
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showSplash)
          Positioned.fill(
            child: _AnimatedSplashOverlay(onFinished: _onFinished),
          ),
      ],
    );
  }
}

class _AnimatedSplashOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const _AnimatedSplashOverlay({required this.onFinished});

  @override
  State<_AnimatedSplashOverlay> createState() => _AnimatedSplashOverlayState();
}

class _AnimatedSplashOverlayState extends State<_AnimatedSplashOverlay>
    with TickerProviderStateMixin {
  // Drives the entrance choreography (logo, wordmark, tagline).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  // Continuous loop for the twinkling / drifting stars.
  late final AnimationController _stars = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  // Fades the whole splash out at the end.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
  );

  // The wordmark "comes from the distance": starts tiny and far, grows bigger
  // and rises up until it lands under the logo with a little overshoot.
  late final Animation<double> _wordScale = Tween<double>(
    begin: 0.18,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.32, 0.74, curve: Curves.elasticOut),
  ));
  late final Animation<double> _wordFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.32, 0.52, curve: Curves.easeOut),
  );
  late final Animation<double> _wordRise = Tween<double>(
    begin: 46,
    end: 0,
  ).animate(CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.32, 0.70, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.72, 0.95, curve: Curves.easeOut),
  );

  final List<_Star> _starField =
      _Star.generate(34, math.Random(0x5B07 /* SpotVibe seed */));

  @override
  void initState() {
    super.initState();
    _intro.forward();
    // Hold the finished splash briefly, then fade out and hand off to the app.
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      await _exit.forward();
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _stars.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - _exit.value,
          child: child,
        );
      },
      child: Material(
        // Deep brand gradient background — no white space anywhere.
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1A5E), // deep violet
                Color(0xFF6C5CE7), // brand violet
                Color(0xFFB0409B), // violet→pink blend
                Color(0xFFE84393), // brand pink
              ],
              stops: [0.0, 0.42, 0.74, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Twinkling, drifting blue/purple stars behind the content.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _stars,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _StarFieldPainter(
                        stars: _starField,
                        progress: _stars.value,
                      ),
                    );
                  },
                ),
              ),
              // Logo + animated wordmark + tagline.
              Center(
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _logoFade.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: _LogoBadge(),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        Transform.translate(
                          offset: Offset(0, _wordRise.value),
                          child: Transform.scale(
                            scale: _wordScale.value,
                            child: Opacity(
                              opacity: _wordFade.value.clamp(0.0, 1.0),
                              child: const _Wordmark(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Opacity(
                          opacity: _taglineFade.value.clamp(0.0, 1.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXl,
                            ),
                            child: Text(
                              l10n.splashTagline,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app logo shown big and centered, on a soft rounded card with a glow so
/// it reads clearly against the gradient at any brightness.
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFFE84393).withValues(alpha: 0.45),
            blurRadius: 46,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Image.asset(
          'assets/icons/splash_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// The "SpotVibe" wordmark. Uses a bright gradient fill so it feels lively as
/// it flies in and lands under the logo.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFEAD9FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: const Text(
        'SpotVibe',
        style: TextStyle(
          color: Colors.white,
          fontSize: 44,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single twinkling star in the background field.
class _Star {
  final double x; // 0..1 of width
  final double y; // 0..1 of height
  final double radius; // base radius in px
  final double phase; // 0..1 offset into the twinkle cycle
  final double drift; // vertical drift amount (fraction of height)
  final bool isBlue; // blue vs purple tint

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.drift,
    required this.isBlue,
  });

  static List<_Star> generate(int count, math.Random rng) {
    return List<_Star>.generate(count, (i) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 1.1 + rng.nextDouble() * 2.6,
        phase: rng.nextDouble(),
        drift: 0.02 + rng.nextDouble() * 0.05,
        isBlue: rng.nextBool(),
      );
    });
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress; // 0..1 loop

  static const _blue = Color(0xFF6EC1FF);
  static const _purple = Color(0xFFC79BFF);

  _StarFieldPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // Twinkle: smooth 0..1..0 pulse offset by the star's phase.
      final t = (progress + star.phase) % 1.0;
      final twinkle = 0.35 + 0.65 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));
      // Gentle vertical drift that wraps around.
      final dy = ((star.y + progress * star.drift) % 1.0) * size.height;
      final dx = star.x * size.width;
      final base = star.isBlue ? _blue : _purple;
      final color = base.withValues(alpha: 0.85 * twinkle);
      final r = star.radius * (0.8 + 0.4 * twinkle);

      // Soft glow.
      canvas.drawCircle(
        Offset(dx, dy),
        r * 2.6,
        Paint()
          ..color = base.withValues(alpha: 0.16 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Bright core.
      canvas.drawCircle(Offset(dx, dy), r, Paint()..color = color);

      // A little four-point sparkle on the brightest stars.
      if (star.radius > 2.4) {
        final sparkle = Paint()
          ..color = color.withValues(alpha: 0.7 * twinkle)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        final len = r * 3.2;
        canvas.drawLine(
          Offset(dx - len, dy),
          Offset(dx + len, dy),
          sparkle,
        );
        canvas.drawLine(
          Offset(dx, dy - len),
          Offset(dx, dy + len),
          sparkle,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
