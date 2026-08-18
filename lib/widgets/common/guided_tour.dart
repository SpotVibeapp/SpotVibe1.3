import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/tour_service.dart';
import '../../theme/theme.dart';

/// A single step in a guided tour: a target widget (identified by [targetKey])
/// plus the copy shown in the coach-mark card.
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
  });
}

/// A lightweight coach-mark tour.
///
/// Drop this into a screen (it renders nothing itself) and pass the tour's
/// [tourId] and [steps]. On first visit it dims the screen, spotlights each
/// target in turn with a tap-to-advance overlay, and shows a bottom card with
/// Skip / Next buttons. Seen state is persisted via [TourService], so each
/// tour plays once — unless the user replays it from Profile.
class GuidedTour extends StatefulWidget {
  final String tourId;
  final List<TourStep> steps;
  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;

  const GuidedTour({
    super.key,
    required this.tourId,
    required this.steps,
    this.onCompleted,
    this.onSkipped,
  });

  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> {
  OverlayEntry? _entry;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  Future<void> _maybeStart() async {
    if (!mounted || widget.steps.isEmpty) return;
    final seen = await TourService.isSeen(widget.tourId);
    if (!mounted || seen) return;
    // Give layout a beat so every target GlobalKey has geometry.
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _show();
  }

  void _show() {
    _index = 0;
    _entry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_entry!);
  }

  Rect? _targetRect() {
    final ctx = widget.steps[_index].targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _advance() {
    if (_index + 1 < widget.steps.length) {
      setState(() => _index++);
      _entry?.markNeedsBuild();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await TourService.markSeen(widget.tourId);
    _dismiss();
    widget.onCompleted?.call();
  }

  Future<void> _skip() async {
    await TourService.markSeen(widget.tourId);
    _dismiss();
    widget.onSkipped?.call();
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  Widget _buildOverlay() {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final step = widget.steps[_index];
    final isLast = _index + 1 >= widget.steps.length;

    final target = _targetRect();
    final hole = (target ??
            Rect.fromCenter(
              center: Offset(media.size.width / 2, media.size.height / 2),
              width: 80,
              height: 80,
            ))
        .inflate(10);

    const horizontal = 16.0;
    final cardWidth = media.size.width - horizontal * 2;
    final bottomPad = 24.0 + media.padding.bottom;

    // Arrow position: centered on the hole, clamped inside the card.
    final double arrowLeft = (hole.center.dx - horizontal - 8)
        .clamp(12.0, cardWidth - 28.0)
        .toDouble();

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _advance,
              child: CustomPaint(
                painter: _ScrimPainter(
                  hole: hole,
                  scrim: Colors.black.withValues(alpha: 0.62),
                  ring: colors.primary,
                ),
              ),
            ),
          ),

          // ── Bottom coach-mark card ──────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: horizontal,
                right: horizontal,
                bottom: bottomPad,
              ),
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Pointer arrow toward the spotlighted target.
                    Positioned(
                      top: -8,
                      left: arrowLeft,
                      child: CustomPaint(
                        size: const Size(16, 8),
                        painter: _ArrowPainter(color: colors.surface),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: text.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              TextButton(
                                onPressed: _skip,
                                child: Text(l10n.tourSkip),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            step.description,
                            style: text.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Row(
                            children: [
                              Expanded(
                                child: _Dots(
                                  total: widget.steps.length,
                                  current: _index,
                                  active: colors.primary,
                                  inactive: colors.outlineVariant,
                                ),
                              ),
                              FilledButton(
                                onPressed: _advance,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                ),
                                child:
                                    Text(isLast ? l10n.tourDone : l10n.tourNext),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _ScrimPainter extends CustomPainter {
  final Rect hole;
  final Color scrim;
  final Color ring;

  const _ScrimPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(16));
    final holePath = Path()..addRRect(rrect);

    canvas.drawPath(
      Path.combine(PathOperation.difference, full, holePath),
      Paint()..color = scrim,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.scrim != scrim || old.ring != ring;
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

class _Dots extends StatelessWidget {
  final int total;
  final int current;
  final Color active;
  final Color inactive;

  const _Dots({
    required this.total,
    required this.current,
    required this.active,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final selected = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: selected ? active : inactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
