import '../models/moderation_result.dart';

/// Client-side AI content moderation service.
///
/// Currently uses a rule/pattern-based engine to simulate AI moderation with
/// zero latency and no API key required. To upgrade to a real AI API (e.g.
/// OpenAI Moderation API or Google Perspective API), replace [moderateText]
/// with an HTTP call and map the response to [ModerationResult].
///
/// Usage:
///   final result = await moderationService.moderateText(input);
///   if (result.isRejected) { /* block submission */ }
///   if (result.isFlagged)  { /* warn but allow */ }
class AiModerationService {
  // ─── Rejected patterns — content that is always blocked ───────────────────

  static const List<_ModerationRule> _rejectedRules = [
    _ModerationRule(
      category: 'Hate Speech',
      reason: 'This content contains language targeting individuals or groups.',
      patterns: [
        r'\b(hate|kill|murder|die)\s+(all\s+)?(blacks?|whites?|jews?|muslims?|christians?|gays?|lesbians?|trans)\b',
        r'\b(racial|ethnic)\s+slur\b',
        r'\bn[i!1]+gg[ae3]r\b',
        r'\bf[a@]gg[o0]t\b',
        r'\bk[i!1]ke\b',
        r'\bsp[i!1]c\b',
        r'\bgook\b',
        r'\bchink\b',
        r'\bretard(ed)?\b',
      ],
    ),
    _ModerationRule(
      category: 'Violence',
      reason: 'This content contains explicit threats or violent language.',
      patterns: [
        r'\b(i will|im going to|gonna)\s+(kill|hurt|attack|shoot|stab|bomb)\s+(you|him|her|them|everyone)\b',
        r'\b(shoot|bomb|attack)\s+(this|the)\s+(event|place|venue|crowd)\b',
        r'\bmass\s+(shooting|murder|killing)\b',
        r'\bbomb\s+threat\b',
        r'\bthreat(en)?(ing)?\s+(to\s+)?(kill|harm|hurt|attack)\b',
      ],
    ),
    _ModerationRule(
      category: 'Self-Harm',
      reason: 'This content contains references to self-harm. Please reach out to a support line.',
      patterns: [
        r'\b(going to|want to|planning to)\s+(kill|hurt)\s+myself\b',
        r'\bsuicide\s+(method|plan|how\s+to)\b',
        r'\bself[- ]harm\s+(tips|instructions|how)\b',
      ],
    ),
    _ModerationRule(
      category: 'Sexual Content',
      reason: 'This content contains explicit sexual material not appropriate for this platform.',
      patterns: [
        r'\b(naked|nude|sex(ual)?|porn(ography)?|xxx)\s+(photo|video|pic|image)\b',
        r'\bonly\s*fans\b',
        r'\b(escort|prostitut(e|ion)|sex\s+work)\b',
      ],
    ),
    _ModerationRule(
      category: 'Personal Information',
      reason: 'This content appears to contain sensitive personal information (SSN, credit card, etc.).',
      patterns: [
        r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b', // SSN pattern
        r'\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13})\b', // Credit card
      ],
    ),
  ];

  // ─── Flagged patterns — content that is warned but allowed ────────────────

  static const List<_ModerationRule> _flaggedRules = [
    _ModerationRule(
      category: 'Profanity',
      reason: 'This comment contains strong language. Please keep it respectful.',
      patterns: [
        r'\bf+u+c+k+(ing|ed|er|s)?\b',
        r'\bs+h+i+t+(ty|ter|s)?\b',
        r'\ba+s+s+h+o+l+e?\b',
        r'\bb+i+t+c+h+(es|ing|y)?\b',
        r'\bd+a+m+n+(it|ed)?\b',
        r'\bc+r+a+p+(py|s)?\b',
      ],
    ),
    _ModerationRule(
      category: 'Spam',
      reason: 'This comment looks like spam. Please avoid repetitive or promotional content.',
      patterns: [
        r'(.)\1{6,}', // Same character 7+ times
        r'(https?://\S+\s*){3,}', // 3+ URLs
        r'\b(buy now|click here|free money|make money fast|work from home|earn \$\d+)\b',
        r'(\b\w+\b)(?:\s+\1){4,}', // Same word repeated 5+ times
        // NOTE: the all-caps check ([A-Z\s]{20,}) is implemented explicitly in
        // moderateText() — as a regex here it would run case-insensitively on
        // lowercased text and flag every message of 20+ characters as spam.
      ],
    ),
    _ModerationRule(
      category: 'Contact Sharing',
      reason: 'Please avoid sharing phone numbers or external contact info in comments.',
      patterns: [
        r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b', // Phone number
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email
      ],
    ),
  ];

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Moderates a single piece of text content.
  ///
  /// Returns [ModerationResult.approved] if safe,
  /// [ModerationResult] with [ModerationStatus.flagged] as a warning,
  /// or [ModerationResult] with [ModerationStatus.rejected] to block.
  Future<ModerationResult> moderateText(String text) async {
    if (text.trim().isEmpty) return ModerationResult.approved;

    final lower = text.toLowerCase();

    // Check rejected rules first — highest priority
    for (final rule in _rejectedRules) {
      for (final pattern in rule.patterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
          return ModerationResult(
            status: ModerationStatus.rejected,
            category: rule.category,
            reason: rule.reason,
          );
        }
      }
    }

    // Check flagged rules — lower priority, warning only
    for (final rule in _flaggedRules) {
      for (final pattern in rule.patterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
          return ModerationResult(
            status: ModerationStatus.flagged,
            category: rule.category,
            reason: rule.reason,
          );
        }
      }
    }

    // All-caps spam check. Must run against the ORIGINAL text with a
    // case-sensitive regex: [A-Z\s] here means uppercase letters and spaces
    // only. (Running it case-insensitively or on lowercased text would match
    // any 20+ character message and flag everything as spam.)
    if (RegExp(r'[A-Z\s]{20,}').hasMatch(text)) {
      return const ModerationResult(
        status: ModerationStatus.flagged,
        category: 'Spam',
        reason: 'This comment looks like spam. Please avoid repetitive or promotional content.',
      );
    }

    return ModerationResult.approved;
  }

  /// Moderates multiple fields (e.g. event title + description).
  ///
  /// Returns the first non-approved result found, or [ModerationResult.approved].
  Future<ModerationResult> moderateFields(List<String> fields) async {
    for (final field in fields) {
      final result = await moderateText(field);
      if (!result.isApproved) return result;
    }
    return ModerationResult.approved;
  }
}

// ─── Internal helper class ────────────────────────────────────────────────────

class _ModerationRule {
  final String category;
  final String reason;
  final List<String> patterns;

  const _ModerationRule({
    required this.category,
    required this.reason,
    required this.patterns,
  });
}
