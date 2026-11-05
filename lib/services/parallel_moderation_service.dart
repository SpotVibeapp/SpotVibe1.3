import 'package:flutter/foundation.dart';

/// On-device half of the parallel moderator.
///
/// This is the same idea as `functions/lib/parallelModeration.js`: a second
/// opinion that never replaces [AiModerationService]. The device only sees
/// this session, so cross-account signals stay on the Cloud Function. A
/// failure here returns [ParallelModerationReport.failed] and must not be
/// turned into a block.
class ParallelSignal {
  const ParallelSignal({
    required this.code,
    required this.score,
    required this.detail,
  });

  final String code;
  final double score;
  final String detail;
}

class ParallelModerationReport {
  const ParallelModerationReport({
    required this.flagged,
    required this.signals,
    this.failed = false,
  });

  final bool flagged;
  final List<ParallelSignal> signals;
  final bool failed;

  static const clear = ParallelModerationReport(flagged: false, signals: []);
  static const failedReport = ParallelModerationReport(
    flagged: false,
    signals: [],
    failed: true,
  );
}

class _LocalPost {
  const _LocalPost({
    required this.authorId,
    required this.text,
    required this.createdAtMs,
  });

  final String authorId;
  final String text;
  final int createdAtMs;
}

class ParallelModerationService {
  final List<_LocalPost> _recent = [];

  /// Reviews [text] against this session and remembers it for the next call.
  /// Never throws.
  Future<ParallelModerationReport> observe({
    required String text,
    String authorId = '',
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final report = assessParallelModeration(
        text: text,
        authorId: authorId,
        createdAtMs: now,
        recent: [
          for (final post in _recent)
            {
              'authorId': post.authorId,
              'text': post.text,
              'createdAtMs': post.createdAtMs,
            },
        ],
      );
      _recent.add(_LocalPost(authorId: authorId, text: text, createdAtMs: now));
      if (_recent.length > 40) _recent.removeAt(0);
      return report;
    } catch (error) {
      debugPrint(
        'Parallel moderation skipped (${error.runtimeType}).',
      );
      return ParallelModerationReport.failedReport;
    }
  }
}

const int kParallelRateWindowMs = 10 * 60 * 1000;
const int kParallelRatePriorLimit = 4;
const int kParallelLookbackMs = 30 * 60 * 1000;
const double kParallelDupJaccard = 0.82;
const int kParallelMinTokens = 4;

final RegExp _zeroWidth = RegExp(r'[\u200B-\u200D\uFEFF\u2060]');

String normalizeParallelText(String text) {
  return text
      .toLowerCase()
      .replaceAll(_zeroWidth, '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

Set<String> _tokenSet(String text) {
  return normalizeParallelText(text)
      .split(' ')
      .where((part) => part.length > 1)
      .toSet();
}

double _jaccard(Set<String> left, Set<String> right) {
  if (left.isEmpty || right.isEmpty) return 0;
  final shared = left.intersection(right).length;
  final union = left.length + right.length - shared;
  if (union == 0) return 0;
  return shared / union;
}

String? _limitProbeDetail(String raw) {
  if (_zeroWidth.hasMatch(raw)) return 'zero-width characters';
  final probes = <(RegExp, String)>[
    (
      RegExp(
        r'\bignore\b[\s\S]{0,40}\b(previous|instructions|rules)\b',
        caseSensitive: false,
      ),
      'instruction override',
    ),
    (
      RegExp(
        r'\bbypass\b[\s\S]{0,40}\b(filter|moderation|rules)\b',
        caseSensitive: false,
      ),
      'filter bypass',
    ),
    (RegExp(r'\b(moderation|filter)\s+test\b', caseSensitive: false), 'moderation test'),
    (
      RegExp(r'\bis this (banned|allowed|flagged)\b', caseSensitive: false),
      'limit question',
    ),
    (
      RegExp(
        r'h[\W_]*a[\W_]*t[\W_]*e[\W_]*f[\W_]*u[\W_]*l[\W_]*p[\W_]*l[\W_]*a[\W_]*c[\W_]*e[\W_]*h[\W_]*o[\W_]*l[\W_]*d[\W_]*e[\W_]*r',
        caseSensitive: false,
      ),
      'obfuscated blocklist token',
    ),
  ];
  for (final probe in probes) {
    if (probe.$1.hasMatch(raw)) return probe.$2;
  }
  return null;
}

/// Pure review used by [ParallelModerationService] and by tests.
///
/// Keep the thresholds aligned with `functions/lib/parallelModeration.js`.
@visibleForTesting
ParallelModerationReport assessParallelModeration({
  required String text,
  String authorId = '',
  required int createdAtMs,
  int? authorCreatedAtMs,
  List<Map<String, Object?>> recent = const [],
}) {
  final signals = <ParallelSignal>[];
  final probe = _limitProbeDetail(text);
  if (probe != null) {
    signals.add(ParallelSignal(code: 'limit_probe', score: 0.9, detail: probe));
  }

  final priors = recent.where((row) {
    final at = row['createdAtMs'];
    return at is int && createdAtMs >= at && createdAtMs - at <= kParallelLookbackMs;
  }).toList();
  final currentTokens = _tokenSet(text);

  if (authorId.isNotEmpty) {
    final mine = priors.where((row) {
      final at = row['createdAtMs'];
      return row['authorId'] == authorId &&
          at is int &&
          createdAtMs - at <= kParallelRateWindowMs;
    });
    if (mine.length >= kParallelRatePriorLimit) {
      signals.add(ParallelSignal(
        code: 'rate_abuse',
        score: 0.8,
        detail: '${mine.length} earlier posts in 10 minutes',
      ));
    }
  }

  if (currentTokens.length >= kParallelMinTokens) {
    var nearOwn = false;
    final otherAuthors = <String>{};
    final freshOthers = <String>{};
    for (final row in priors) {
      final otherTokens = _tokenSet('${row['text'] ?? ''}');
      if (otherTokens.length < kParallelMinTokens) continue;
      if (_jaccard(currentTokens, otherTokens) < kParallelDupJaccard) continue;
      final rowAuthor = row['authorId'];
      if (authorId.isNotEmpty && rowAuthor == authorId) {
        nearOwn = true;
        continue;
      }
      if (rowAuthor is! String || rowAuthor.isEmpty) continue;
      otherAuthors.add(rowAuthor);
      final created = row['authorCreatedAtMs'];
      if (created is int && createdAtMs - created <= 48 * 60 * 60 * 1000) {
        freshOthers.add(rowAuthor);
      }
    }
    if (nearOwn) {
      signals.add(const ParallelSignal(
        code: 'near_duplicate',
        score: 0.85,
        detail: 'near-duplicate of an earlier post by the same account',
      ));
    }
    if (otherAuthors.length >= 2) {
      signals.add(ParallelSignal(
        code: 'coordinated_spam',
        score: 0.88,
        detail: '${otherAuthors.length} other accounts posted nearly the same text',
      ));
    }
    final callerIsNew = authorCreatedAtMs != null &&
        createdAtMs - authorCreatedAtMs <= 48 * 60 * 60 * 1000;
    if (callerIsNew && freshOthers.isNotEmpty) {
      signals.add(ParallelSignal(
        code: 'multi_account',
        score: 0.84,
        detail: '${freshOthers.length + 1} new accounts posted nearly the same text',
      ));
    }
  }

  return ParallelModerationReport(
    flagged: signals.isNotEmpty,
    signals: signals,
  );
}
