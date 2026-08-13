import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/pricing.dart';

void main() {
  test('launch Premium is \$15 monthly only', () {
    expect(kPremiumMonthlyPrice, 15);
    expect(kFreePrice, 0);
  });

  test('free users may post only one active event', () {
    expect(canPostAnotherFreeEvent(0, isPremium: false), isTrue);
    expect(canPostAnotherFreeEvent(1, isPremium: false), isFalse);
    expect(canPostAnotherFreeEvent(3, isPremium: true), isTrue);
  });

  test('active events are those still in the future', () {
    final now = DateTime(2026, 8, 13, 12);
    final count = countActiveUserEvents([
      DateTime(2026, 8, 12),
      DateTime(2026, 8, 20),
      DateTime(2026, 9, 1),
    ], now: now);
    expect(count, 2);
  });

  test('personal email domains are flagged for claim proof', () {
    expect(isPersonalEmail('owner@plaza-theatre.com'), isFalse);
    expect(isPersonalEmail('promoter@gmail.com'), isTrue);
    expect(isValidEmail('bad'), isFalse);
    expect(isValidEmail('a@b.co'), isTrue);
  });
}
