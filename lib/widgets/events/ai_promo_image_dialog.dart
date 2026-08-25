import 'package:flutter/material.dart';

import '../../services/ai_promo_image_service.dart';
import '../../theme/theme.dart';

/// Lets an organizer choose a visual direction before the server generates an
/// AI promo background. Accurate event text is deliberately not drawn by the
/// model; SpotVibe renders titles and dates separately in its UI/share cards.
Future<AiPromoImageResult?> showAiPromoImageDialog(
  BuildContext context, {
  required String eventId,
  required String title,
  required String description,
  required String category,
  required String venue,
}) {
  return showDialog<AiPromoImageResult>(
    context: context,
    builder: (_) => _AiPromoImageDialog(
      eventId: eventId,
      title: title,
      description: description,
      category: category,
      venue: venue,
    ),
  );
}

class _AiPromoImageDialog extends StatefulWidget {
  const _AiPromoImageDialog({
    required this.eventId,
    required this.title,
    required this.description,
    required this.category,
    required this.venue,
  });

  final String eventId;
  final String title;
  final String description;
  final String category;
  final String venue;

  @override
  State<_AiPromoImageDialog> createState() => _AiPromoImageDialogState();
}

class _AiPromoImageDialogState extends State<_AiPromoImageDialog> {
  static const _styles = <String, String>{
    'vibrant': 'Vibrant',
    'editorial': 'Editorial',
    'neon': 'Neon',
    'minimal': 'Minimal',
    'elegant': 'Elegant',
  };

  static const _ratios = <String, String>{
    'portrait': 'Portrait poster',
    'square': 'Square',
    'landscape': 'Landscape',
  };

  final _service = AiPromoImageService();
  var _style = 'vibrant';
  var _ratio = 'portrait';
  var _generating = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final result = await _service.generate(
        eventId: widget.eventId,
        title: widget.title,
        description: widget.description,
        category: widget.category,
        venue: widget.venue,
        style: _style,
        aspectRatio: _ratio,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Generate AI promo background'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SpotVibe will generate an original visual background for “${widget.title}”. Your event title, date, and venue remain accurate because the app adds them separately.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Style', style: text.titleSmall),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: _styles.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _style == entry.key,
                      onSelected: _generating
                          ? null
                          : (_) => setState(() => _style = entry.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Image shape', style: text.titleSmall),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: _ratios.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _ratio == entry.key,
                      onSelected: _generating
                          ? null
                          : (_) => setState(() => _ratio = entry.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colors.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Generated images are reviewed by you before publishing. Do not use misleading logos, celebrity likenesses, or copyrighted characters.',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                _error!,
                style: TextStyle(color: colors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _generating ? null : _generate,
          icon: _generating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(_generating ? 'Generating…' : 'Generate'),
        ),
      ],
    );
  }
}
