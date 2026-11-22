import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../platform/share_bytes.dart';
import '../../theme/theme.dart';

/// Letter-paper proportions (8.5 x 11 in), so the PNG prints without
/// cropping on home printers and still reads well on a phone.
const double kQrFlyerAspectRatio = 8.5 / 11;

/// A printable, printer-friendly flyer (white background, dark ink) with a
/// QR code that opens the event's public SpotVibe link.
///
/// Organizers tape these to venue windows, cafe boards and front desks.
/// Everything printed comes from the event form; nothing is generated.
class EventQrFlyer extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String venueLabel;
  final String link;

  const EventQrFlyer({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.venueLabel,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const ink = Color(0xFF111111);
    const muted = Color(0xFF555555);
    return AspectRatio(
      aspectRatio: kQrFlyerAspectRatio,
      child: Container(
        color: Colors.white,
        child: LayoutBuilder(builder: (context, box) {
          // Scale type to the flyer width so the preview on a folded cover
          // screen and the 4x export keep the same layout.
          final w = box.maxWidth;
          final pad = w * 0.07;
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  key: const ValueKey('flyer-title'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: w * 0.08,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: w * 0.035),
                Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: w * 0.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (venueLabel.isNotEmpty) ...[
                  SizedBox(height: w * 0.015),
                  Text(
                    venueLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: w * 0.042),
                  ),
                ],
                SizedBox(height: w * 0.04),
                // The QR takes the space left after the text, so a long
                // title shrinks the code instead of overflowing the page.
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * 0.5),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: QrImageView(
                          key: const ValueKey('flyer-qr'),
                          data: link,
                          version: QrVersions.auto,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square, color: ink),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: ink),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: w * 0.025),
                Text(
                  l10n.flyerScanToSave,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  link.replaceFirst(RegExp(r'^https?://'), ''),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontSize: w * 0.03),
                ),
                SizedBox(height: w * 0.03),
                Text(
                  l10n.flyerFooter,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Shows the flyer preview with a share/print button.
///
/// [onShared] runs after a successful share so the caller can count it like
/// any other share.
Future<void> showEventQrFlyerSheet(
  BuildContext context, {
  required String eventId,
  required String title,
  required String dateLabel,
  required String venueLabel,
  required String link,
  VoidCallback? onShared,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QrFlyerSheet(
      eventId: eventId,
      title: title,
      dateLabel: dateLabel,
      venueLabel: venueLabel,
      link: link,
      onShared: onShared,
    ),
  );
}

class _QrFlyerSheet extends StatefulWidget {
  final String eventId;
  final String title;
  final String dateLabel;
  final String venueLabel;
  final String link;
  final VoidCallback? onShared;

  const _QrFlyerSheet({
    required this.eventId,
    required this.title,
    required this.dateLabel,
    required this.venueLabel,
    required this.link,
    this.onShared,
  });

  @override
  State<_QrFlyerSheet> createState() => _QrFlyerSheetState();
}

class _QrFlyerSheetState extends State<_QrFlyerSheet> {
  final GlobalKey _flyerKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _capture() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final boundary = _flyerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // ~4x a phone-width preview gives a sharp letter-size print.
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.flyerFailed)));
        return;
      }
      await sharePngBytes(
        bytes,
        filename: 'spotvibe_flyer_${widget.eventId}.png',
        subject: '${widget.title} — SpotVibe',
        text: widget.link,
      );
      widget.onShared?.call();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.flyerFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppTheme.spacingMd, 0,
            AppTheme.spacingMd, AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.flyerTitle, style: text.titleMedium),
            const SizedBox(height: AppTheme.spacingXs),
            Text(l10n.flyerHint,
                style:
                    text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: AppTheme.spacingMd),
            Center(
              child: ConstrainedBox(
                // Small enough to fit a folded cover screen with the button
                // still visible; the export is scaled up separately.
                constraints: const BoxConstraints(maxWidth: 280),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: RepaintBoundary(
                    key: _flyerKey,
                    child: EventQrFlyer(
                      title: widget.title,
                      dateLabel: widget.dateLabel,
                      venueLabel: widget.venueLabel,
                      link: widget.link,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              key: const ValueKey('flyer-share'),
              onPressed: _busy ? null : _share,
              icon: _busy
                  ? const SizedBox(
                      width: AppTheme.iconSm,
                      height: AppTheme.iconSm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_rounded, size: AppTheme.iconSm),
              label: Text(l10n.flyerShare),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
