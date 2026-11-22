/// Which reviews a `listEventReviews` call returns.
enum ReviewScope { event, host, business, gem }

class ReviewStats {
  final int count;
  final double avgStars;

  const ReviewStats({this.count = 0, this.avgStars = 0});

  bool get hasRating => count > 0;

  factory ReviewStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ReviewStats();
    return ReviewStats(
      count: (data['count'] as num?)?.toInt() ?? 0,
      avgStars: (data['avgStars'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EventReview {
  final String id;
  final String eventId;
  final String authorId;
  final String authorName;
  final int stars;
  final String note;
  final String hostId;
  final String? businessId;
  final String? gemId;
  final String? reply;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hidden;

  const EventReview({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.authorName,
    required this.stars,
    this.note = '',
    this.hostId = '',
    this.businessId,
    this.gemId,
    this.reply,
    required this.createdAt,
    this.updatedAt,
    this.hidden = false,
  });

  factory EventReview.fromMap(String id, Map<String, dynamic> data) {
    final createdMs = (data['createdAtMs'] as num?)?.toInt();
    final updatedMs = (data['updatedAtMs'] as num?)?.toInt();
    return EventReview(
      id: id,
      eventId: data['eventId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      stars: (data['stars'] as num?)?.toInt() ?? 0,
      note: data['note'] as String? ?? '',
      hostId: data['hostId'] as String? ?? '',
      businessId: data['businessId'] as String?,
      gemId: data['gemId'] as String?,
      reply: data['reply'] as String?,
      createdAt: createdMs != null
          ? DateTime.fromMillisecondsSinceEpoch(createdMs)
          : DateTime.now(),
      updatedAt: updatedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedMs),
      hidden: data['hidden'] == true,
    );
  }
}

/// One `listEventReviews` response: visible reviews plus stats.
class ReviewListing {
  final ReviewStats stats;
  final List<EventReview> reviews;

  const ReviewListing({this.stats = const ReviewStats(), this.reviews = const []});

  factory ReviewListing.fromMap(Map<String, dynamic> data) {
    final rawStats = data['stats'];
    final rawReviews = data['reviews'];
    final reviews = <EventReview>[];
    if (rawReviews is List) {
      for (final row in rawReviews) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final review = EventReview.fromMap(map['id'] as String? ?? '', map);
        if (!review.hidden && review.stars >= 1 && review.stars <= 5) reviews.add(review);
      }
    }
    return ReviewListing(
      stats: ReviewStats.fromMap(rawStats is Map ? Map<String, dynamic>.from(rawStats) : null),
      reviews: reviews,
    );
  }
}
