import 'package:flutter/foundation.dart';

import '../models/moderation_result.dart';
import 'ai_moderation_service.dart';
import 'parallel_moderation_service.dart';

/// Runs the existing moderator and then the parallel one.
///
/// The value returned is always the primary result. The parallel review is
/// recorded for operators (server) and for this session (device). If it
/// throws or flags, the user flow keeps the primary decision.
class ModerationPipeline {
  static Future<ModerationResult> moderateText({
    required AiModerationService primary,
    ParallelModerationService? parallel,
    required String text,
    String authorId = '',
  }) async {
    final result = await primary.moderateText(text);
    await _observe(parallel, text, authorId);
    return result;
  }

  static Future<ModerationResult> moderateFields({
    required AiModerationService primary,
    ParallelModerationService? parallel,
    required List<String> fields,
    String authorId = '',
  }) async {
    final result = await primary.moderateFields(fields);
    await _observe(parallel, fields.join('\n'), authorId);
    return result;
  }

  static Future<void> _observe(
    ParallelModerationService? parallel,
    String text,
    String authorId,
  ) async {
    if (parallel == null) return;
    try {
      await parallel.observe(text: text, authorId: authorId);
    } catch (error) {
      debugPrint('Parallel moderation skipped (${error.runtimeType}).');
    }
  }
}
