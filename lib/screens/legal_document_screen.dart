import 'package:flutter/material.dart';

import '../data/legal.dart';
import '../theme/theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;
  const LegalDocumentScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingMd,
          AppTheme.spacingLg,
          AppTheme.spacingXl,
        ),
        children: [
          Text(
            'Effective $kLegalEffectiveDate',
            style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(document.intro, style: text.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),
          ...document.sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.heading,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(section.body, style: text.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
