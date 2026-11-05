import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/sample_feed.dart';
import 'package:spotvibe_app/models/event.dart';

Event _live(String id) {
  return Event(
    id: id,
    title: 'Live',
    description: 'A real listing',
    dateTime: DateTime.utc(2026, 11, 6, 20),
    location: 'Venue',
    address: '1 Main',
    imageUrl: '',
    category: 'Music',
    organizerName: 'Host',
    organizerAvatarUrl: '',
  );
}

void main() {
  test('sample rows are the bundled seed and every one is labeled', () {
    final samples = buildSampleFeedEvents(DateTime.utc(2026, 11, 5));
    expect(samples, isNotEmpty);
    expect(samples.every((event) => event.isSample), isTrue);
    expect(samples.every((event) => event.city == 'El Paso'), isTrue);
  });

  test('an empty home feed stays empty until the person opts in', () {
    final waiting = applySampleFeed(
      loaded: const [],
      optIn: null,
      homeFeed: true,
      samples: buildSampleFeedEvents(DateTime.utc(2026, 11, 5)),
    );
    expect(waiting.events, isEmpty);
    expect(waiting.showingSamples, isFalse);

    final optedIn = applySampleFeed(
      loaded: const [],
      optIn: true,
      homeFeed: true,
      samples: buildSampleFeedEvents(DateTime.utc(2026, 11, 5)),
    );
    expect(optedIn.showingSamples, isTrue);
    expect(optedIn.events.every((event) => event.isSample), isTrue);
  });

  test('opt-in does not replace a city search, and hide strips samples', () {
    final samples = buildSampleFeedEvents(DateTime.utc(2026, 11, 5));
    final duringSearch = applySampleFeed(
      loaded: const [],
      optIn: true,
      homeFeed: false,
      samples: samples,
    );
    expect(duringSearch.events, isEmpty);

    final hidden = applySampleFeed(
      loaded: samples,
      optIn: false,
      homeFeed: true,
      samples: samples,
    );
    expect(hidden.events, isEmpty);
    expect(hidden.showingSamples, isFalse);
  });

  test('live rows are left alone', () {
    final decision = applySampleFeed(
      loaded: [_live('tm_1')],
      optIn: true,
      homeFeed: true,
      samples: buildSampleFeedEvents(DateTime.utc(2026, 11, 5)),
    );
    expect(decision.events.map((event) => event.id), ['tm_1']);
    expect(decision.showingSamples, isFalse);
  });
}
