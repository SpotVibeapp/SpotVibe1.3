import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/moderation_result.dart';
import 'package:spotvibe_app/services/ai_moderation_service.dart';

void main() {
  group('AiModerationService.moderateText', () {
    final service = AiModerationService();

    test('approves clean, friendly content', () async {
      final result = await service.moderateText(
        'This concert looks amazing, can\'t wait to go with friends!',
      );
      expect(result.isApproved, isTrue);
      expect(result.category, isNull);
    });

    test('rejects violent threats (bomb threat)', () async {
      final result = await service.moderateText('this is a bomb threat');
      expect(result.isRejected, isTrue);
      expect(result.category, 'Violence');
      expect(result.reason, isNotNull);
    });

    test('flags spam phrases like "buy now"', () async {
      final result = await service.moderateText('buy now for the best deal');
      expect(result.isFlagged, isTrue);
      expect(result.category, 'Spam');
    });

    test('flags contact sharing (phone numbers)', () async {
      final result = await service.moderateText('call me at 555-123-4567');
      expect(result.isFlagged, isTrue);
      expect(result.category, 'Contact Sharing');
    });

    test('flags mild profanity but does not reject', () async {
      final result = await service.moderateText('damn, that lineup is good');
      expect(result.isFlagged, isTrue);
      expect(result.isRejected, isFalse);
      expect(result.category, 'Profanity');
    });

    test('empty text is approved', () async {
      final result = await service.moderateText('');
      expect(result.isApproved, isTrue);
    });

    test('is case-insensitive for rejected categories', () async {
      final result = await service.moderateText('THIS IS A BOMB THREAT');
      expect(result.isRejected, isTrue);
    });

    test('flags genuinely all-caps shouting (20+ chars)', () async {
      final result = await service.moderateText('THIS EVENT IS THE BEST EVER');
      expect(result.isFlagged, isTrue);
      expect(result.category, 'Spam');
    });

    test('normal mixed-case sentences are NOT flagged as all-caps spam (regression)',
        () async {
      // Previously [A-Z\s]{20,} ran case-insensitively on lowercased text,
      // so every message of 20+ characters was flagged as spam.
      final result = await service.moderateText(
        'This concert looks amazing, cannot wait!',
      );
      expect(result.isApproved, isTrue);
    });
  });

  group('ModerationResult', () {
    test('approved constant helpers', () {
      expect(ModerationResult.approved.isApproved, isTrue);
      expect(ModerationResult.approved.isFlagged, isFalse);
      expect(ModerationResult.approved.isRejected, isFalse);
    });
  });
}
