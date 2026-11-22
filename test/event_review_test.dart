import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/event_review.dart';
import 'package:spotvibe_app/services/event_review_service.dart';

void main() {
  test('parses a listEventReviews response with nested callable maps', () {
    final listing = ReviewListing.fromMap(<String, dynamic>{
      'ok': true,
      'stats': <Object?, Object?>{'count': 2, 'avgStars': 4.5},
      'reviews': <Object?>[
        <Object?, Object?>{
          'id': 'e1_u1',
          'eventId': 'e1',
          'authorId': 'u1',
          'authorName': 'Maya',
          'stars': 5,
          'note': 'Great night',
          'reply': 'Thanks!',
          'createdAtMs': 1700000000000,
        },
        <Object?, Object?>{'id': 'bad', 'stars': 0},
        'not a map',
      ],
    });
    expect(listing.stats.count, 2);
    expect(listing.stats.avgStars, 4.5);
    expect(listing.stats.hasRating, isTrue);
    expect(listing.reviews, hasLength(1));
    final review = listing.reviews.single;
    expect(review.id, 'e1_u1');
    expect(review.authorName, 'Maya');
    expect(review.reply, 'Thanks!');
  });

  test('an empty or failed listing shows no rating', () {
    final listing = ReviewListing.fromMap(<String, dynamic>{});
    expect(listing.stats.hasRating, isFalse);
    expect(listing.reviews, isEmpty);
    expect(const ReviewListing().stats.count, 0);
  });

  test('the Play rating prompt fires once, from the second ended RSVP', () {
    expect(shouldRequestPlayReview(count: 1, alreadyPrompted: false), isFalse);
    expect(shouldRequestPlayReview(count: 2, alreadyPrompted: false), isTrue);
    expect(shouldRequestPlayReview(count: 5, alreadyPrompted: true), isFalse);
  });

  test('list scopes match the server callable', () {
    expect(ReviewScope.values.map((s) => s.name), ['event', 'host', 'business', 'gem']);
  });
}
