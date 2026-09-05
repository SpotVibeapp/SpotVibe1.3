import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/category_labels.dart';
import '../../theme/category_colors.dart';
import '../../theme/theme.dart';

/// Visual templates available in Poster Studio. The app, not the image model,
/// draws all structured event information onto the final image.
enum PosterTemplate { bold, editorial, neon, minimal }

/// Where the text block is placed in a poster template.
enum PosterTextAlignment { left, center }

/// The verified event information rendered into a poster.
///
/// Keeping these values structured means title, date, time, venue, and price
/// always match the event form. They are never guessed or typeset by an image
/// model.
class EventPosterDetails {
  final String title;
  final DateTime dateTime;
  final DateTime? endDateTime;
  final String venue;
  final String address;
  final String city;
  final String state;
  final double? cost;
  final String category;
  final String backgroundImageUrl;
  final String? localBackgroundPath;

  const EventPosterDetails({
    required this.title,
    required this.dateTime,
    this.endDateTime,
    required this.venue,
    required this.address,
    required this.city,
    required this.state,
    required this.cost,
    required this.category,
    required this.backgroundImageUrl,
    this.localBackgroundPath,
  });

  String get locationLine => posterLocationLine(
        venue: venue,
        address: address,
        city: city,
        state: state,
      );
}

/// Builds a concise location line for the poster without repeating blanks.
String posterLocationLine({
  required String venue,
  required String address,
  required String city,
  required String state,
}) {
  final cityState = [city.trim(), state.trim()]
      .where((part) => part.isNotEmpty)
      .join(', ');
  final primary = venue.trim().isNotEmpty ? venue.trim() : address.trim();
  return [primary, cityState].where((part) => part.isNotEmpty).join(' · ');
}

/// Formats a price from the event form rather than letting an image model
/// invent one. A blank or zero price is intentionally shown as free.
String posterPriceLabel(double? cost, {required String freeLabel}) {
  if (cost == null || cost <= 0) return freeLabel.toUpperCase();
  return '\$${cost.toStringAsFixed(2)}';
}

/// Formats the event's exact start and end time for a share poster.
String posterTimeLabel(DateTime dateTime, DateTime? endDateTime) {
  final start = dateTime.toLocal();
  final startLabel = DateFormat('h:mm a').format(start);
  if (endDateTime == null) return startLabel;

  final end = endDateTime.toLocal();
  final sameDay = start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (sameDay) return '$startLabel – ${DateFormat('h:mm a').format(end)}';
  return '$startLabel – ${DateFormat('EEE h:mm a').format(end)}';
}

/// Opens the full-screen poster composer for a draft or existing event.
/// Poster Studio shares a separate poster and leaves the in-app cover intact.
Future<void> showEventPosterStudio(
  BuildContext context, {
  required EventPosterDetails details,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => EventPosterStudio(details: details),
    ),
  );
}

/// Lets a creator turn their selected cover (including an AI background) into
/// a share-ready vertical poster. The creator may share it immediately while
/// keeping the selected photo or AI artwork as the event's public cover.
class EventPosterStudio extends StatefulWidget {
  final EventPosterDetails details;

  const EventPosterStudio({super.key, required this.details});

  @override
  State<EventPosterStudio> createState() => _EventPosterStudioState();
}

class _EventPosterStudioState extends State<EventPosterStudio> {
  final GlobalKey _posterKey = GlobalKey();
  PosterTemplate _template = PosterTemplate.editorial;
  PosterTextAlignment _alignment = PosterTextAlignment.left;
  bool _showVenue = true;
  bool _showPrice = true;
  bool _isExporting = false;

  Future<Uint8List?> _capturePoster() async {
    // Give the current template selection and image frame a chance to paint.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final boundary = _posterKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    try {
      // 2× produces a crisp 2:3 social poster without exceeding the six MB
      // image upload limit used by the event media pipeline.
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _showCaptureFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.posterCaptureFailed)),
    );
  }

  Future<void> _sharePoster() async {
    if (_isExporting) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.posterSharingMobileOnly),
        ),
      );
      return;
    }

    setState(() => _isExporting = true);
    final bytes = await _capturePoster();
    if (!mounted) return;
    if (bytes == null) {
      setState(() => _isExporting = false);
      _showCaptureFailure();
      return;
    }

    try {
      final path =
          '${Directory.systemTemp.path}/spotvibe_poster_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${widget.details.title} — SpotVibe',
        text: '${widget.details.title} — made with SpotVibe',
      );
    } catch (_) {
      if (mounted) _showCaptureFailure();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _templateLabel(AppLocalizations l10n, PosterTemplate template) {
    switch (template) {
      case PosterTemplate.bold:
        return l10n.posterTemplateBold;
      case PosterTemplate.editorial:
        return l10n.posterTemplateEditorial;
      case PosterTemplate.neon:
        return l10n.posterTemplateNeon;
      case PosterTemplate.minimal:
        return l10n.posterTemplateMinimal;
    }
  }

  String _alignmentLabel(AppLocalizations l10n, PosterTextAlignment alignment) {
    switch (alignment) {
      case PosterTextAlignment.left:
        return l10n.posterLayoutLeft;
      case PosterTextAlignment.center:
        return l10n.posterLayoutCenter;
    }
  }

  IconData _templateIcon(PosterTemplate template) {
    switch (template) {
      case PosterTemplate.bold:
        return Icons.bolt_rounded;
      case PosterTemplate.editorial:
        return Icons.auto_stories_rounded;
      case PosterTemplate.neon:
        return Icons.nightlight_round;
      case PosterTemplate.minimal:
        return Icons.crop_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.posterStudio),
        actions: [
          TextButton(
            onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingXl,
          ),
          children: [
            Text(
              l10n.posterStudioIntro,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_rounded, color: colors.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      l10n.posterExactDetails,
                      style: text.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: EventPosterGraphic(
                      details: widget.details,
                      template: _template,
                      alignment: _alignment,
                      showVenue: _showVenue,
                      showPrice: _showPrice,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            _PosterSectionLabel(label: l10n.posterTemplate),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: PosterTemplate.values
                  .map(
                    (template) => ChoiceChip(
                      avatar: Icon(
                        _templateIcon(template),
                        size: AppTheme.iconSm,
                      ),
                      label: Text(_templateLabel(l10n, template)),
                      selected: _template == template,
                      onSelected: _isExporting
                          ? null
                          : (_) => setState(() => _template = template),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _PosterSectionLabel(label: l10n.posterLayout),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: PosterTextAlignment.values
                  .map(
                    (alignment) => ChoiceChip(
                      avatar: Icon(
                        alignment == PosterTextAlignment.left
                            ? Icons.format_align_left_rounded
                            : Icons.format_align_center_rounded,
                        size: AppTheme.iconSm,
                      ),
                      label: Text(_alignmentLabel(l10n, alignment)),
                      selected: _alignment == alignment,
                      onSelected: _isExporting
                          ? null
                          : (_) => setState(() => _alignment = alignment),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.posterShowVenue),
              value: _showVenue,
              onChanged: _isExporting
                  ? null
                  : (value) => setState(() => _showVenue = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.posterShowPrice),
              value: _showPrice,
              onChanged: _isExporting
                  ? null
                  : (value) => setState(() => _showPrice = value),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingSm,
            AppTheme.spacingMd,
            AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.40),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _isExporting ? null : _sharePoster,
                icon: _isExporting
                    ? SizedBox(
                        width: AppTheme.iconSm,
                        height: AppTheme.iconSm,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  _isExporting ? l10n.posterPreparing : l10n.sharePoster,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                l10n.posterCoverStays,
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterSectionLabel extends StatelessWidget {
  final String label;

  const _PosterSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

/// The 2:3 graphic captured by Poster Studio and sent to the device share
/// sheet. It has no AI-rendered text: every line comes from [details].
class EventPosterGraphic extends StatelessWidget {
  final EventPosterDetails details;
  final PosterTemplate template;
  final PosterTextAlignment alignment;
  final bool showVenue;
  final bool showPrice;

  const EventPosterGraphic({
    super.key,
    required this.details,
    required this.template,
    required this.alignment,
    required this.showVenue,
    required this.showPrice,
  });

  LinearGradient _overlay(Color accent) {
    switch (template) {
      case PosterTemplate.bold:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x58000000),
            accent.withValues(alpha: 0.30),
            const Color(0xEE08050F),
          ],
          stops: const [0, 0.48, 1],
        );
      case PosterTemplate.editorial:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x40000000), Color(0x22000000), Color(0xF4141020)],
          stops: [0, 0.42, 1],
        );
      case PosterTemplate.neon:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0x4D1C063D),
            AppTheme.brandPink.withValues(alpha: 0.28),
            const Color(0xF10A0618),
          ],
          stops: const [0, 0.50, 1],
        );
      case PosterTemplate.minimal:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x18000000),
            const Color(0x85000000),
            accent.withValues(alpha: 0.72),
          ],
          stops: const [0, 0.52, 1],
        );
    }
  }

  TextStyle _titleStyle(TextTheme text) {
    final base = text.displaySmall ?? const TextStyle(fontSize: 34);
    return base.copyWith(
      color: Colors.white,
      fontWeight: template == PosterTemplate.editorial
          ? FontWeight.w700
          : FontWeight.w900,
      fontSize: template == PosterTemplate.editorial ? 34 : 36,
      height: 0.98,
      letterSpacing: template == PosterTemplate.minimal ? -0.6 : -1.0,
      shadows: const [
        Shadow(color: Color(0xA6000000), blurRadius: 9, offset: Offset(0, 2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = categoryAccent(details.category);
    final centered = alignment == PosterTextAlignment.center;
    final textAlign = centered ? TextAlign.center : TextAlign.left;
    final crossAxis = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final category = categoryLabel(context, details.category).toUpperCase();
    final date = DateFormat('EEE, MMM d').format(details.dateTime);
    final time = posterTimeLabel(details.dateTime, details.endDateTime);
    final location = details.locationLine;
    final price = posterPriceLabel(details.cost, freeLabel: l10n.free);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PosterBackground(details: details, accent: accent),
          DecoratedBox(
            decoration: BoxDecoration(gradient: _overlay(accent)),
          ),
          Positioned(
            top: -78,
            right: -58,
            child: IgnorePointer(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 5,
              decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xD9120D1D),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'SpotVibe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: crossAxis,
                  children: [
                    Text(
                      details.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: textAlign,
                      style: _titleStyle(text),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Wrap(
                      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppTheme.spacingMd,
                      runSpacing: AppTheme.spacingSm,
                      children: [
                        _PosterInfo(icon: Icons.calendar_today_rounded, label: date),
                        _PosterInfo(icon: Icons.schedule_rounded, label: time),
                      ],
                    ),
                    if (showVenue && location.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      _PosterInfo(
                        icon: Icons.location_on_rounded,
                        label: location,
                        centered: centered,
                        maxWidth: 280,
                      ),
                    ],
                    if (showPrice) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          price,
                          style: TextStyle(
                            color: template == PosterTemplate.neon
                                ? AppTheme.brandPink
                                : accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterBackground extends StatelessWidget {
  final EventPosterDetails details;
  final Color accent;

  const _PosterBackground({required this.details, required this.accent});

  @override
  Widget build(BuildContext context) {
    final localPath = details.localBackgroundPath;
    if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }

    final url = details.backgroundImageUrl.trim();
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    }
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _gradientFallback(),
        placeholder: (_, __) => _gradientFallback(),
      );
    }
    return _gradientFallback();
  }

  Widget _gradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, AppTheme.brandVioletDeep, AppTheme.brandPink],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -56,
            left: -52,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 80,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.23),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool centered;
  final double? maxWidth;

  const _PosterInfo({
    required this.icon,
    required this.label,
    this.centered = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(
            color: Color(0xA6000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );

    if (maxWidth == null) {
      // This version sits inside a Wrap, whose children have loose horizontal
      // constraints. Do not use Expanded/Flexible here.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          labelWidget,
        ],
      );
    }

    return SizedBox(
      width: maxWidth,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Expanded(child: labelWidget),
        ],
      ),
    );
  }
}
