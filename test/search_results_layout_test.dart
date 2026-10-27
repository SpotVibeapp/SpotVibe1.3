import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/widgets/events/event_card.dart';

import 'support/search_results_harness.dart';

final _pageBar = find.byKey(const Key('feed-pagination-bar'));

/// The part of the screen where [finder] can actually be seen: the
/// intersection of every scroll viewport it sits in (the feed is nested
/// inside the scrolling search header).
Rect _visibleRegionOf(WidgetTester tester, Finder finder) {
  Rect? region;
  BuildContext context = tester.element(finder);
  while (true) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) break;
    final box = scrollable.context.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    region = region == null ? rect : region.intersect(rect);
    context = scrollable.context;
  }
  return region!;
}

bool _contains(Rect outer, Rect inner) {
  const eps = 0.5;
  return inner.left >= outer.left - eps &&
      inner.top >= outer.top - eps &&
      inner.right <= outer.right + eps &&
      inner.bottom <= outer.bottom + eps;
}

/// Configurations where the first card must be fully visible the moment the
/// results appear, without scrolling. Cover landscape (~200 dp of feed) can
/// only show a whole card once the header has scrolled away.
bool _fullCardOnArrival(FoldScreen screen) => screen.name != 'cover-landscape';

void _expectPageBarOnScreen(WidgetTester tester, FoldScreen screen) {
  expect(_pageBar, findsOneWidget, reason: 'page bar must stay visible');
  final bar = tester.getRect(_pageBar);
  expect(_contains(Offset.zero & screen.logicalSize, bar), isTrue,
      reason: 'page bar $bar is not fully on screen');
  expect(bar.height, lessThanOrEqualTo(48.5),
      reason: 'page bar should stay slim, is ${bar.height} dp');
  expect(find.descendant(of: _pageBar, matching: find.text('Page 1 of 2')),
      findsOneWidget);
}

void main() {
  // Blake: "You are unable to see a full event card on searches." These render
  // the real search screen at every Galaxy Z Fold 8 configuration.
  for (final textScale in const [1.0, 1.3]) {
    for (final screen in kFoldScreens) {
      testWidgets(
          'search results show a full event card and the page bar on '
          '${screen.name} (${screen.logicalSize.width.round()}x'
          '${screen.logicalSize.height.round()} dp, text x$textScale)',
          (tester) async {
        await pumpSearchResults(tester, screen, textScale: textScale);

        // Any RenderFlex overflow or layout error is reported as an exception.
        expect(tester.takeException(), isNull);
        _expectPageBarOnScreen(tester, screen);
        final window = Offset.zero & screen.logicalSize;

        if (_fullCardOnArrival(screen)) {
          final firstCard = find.byType(EventCard).first;
          final card = tester.getRect(firstCard);
          final visible = _visibleRegionOf(tester, firstCard);
          expect(_contains(visible, card), isTrue,
              reason: 'on arrival, first card $card is not fully inside the '
                  'visible feed $visible');
          expect(card.bottom, lessThanOrEqualTo(tester.getRect(_pageBar).top + 0.5),
              reason: 'first card runs under the page bar');
        }

        // Scrolling (header first, then feed) must always reveal a full card.
        if (find.byType(EventCard).evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            find.byType(EventCard),
            120,
            scrollable: find.byType(Scrollable).first,
          );
        }
        final firstCard = find.byType(EventCard).first;
        await tester.ensureVisible(firstCard);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        final visible = _visibleRegionOf(tester, firstCard);
        final card = tester.getRect(firstCard);
        expect(card.height, lessThanOrEqualTo(visible.height + 0.5),
            reason: 'card ($card) is taller than the visible feed '
                '($visible), so it can never be seen in full');
        expect(_contains(visible, card), isTrue,
            reason: 'first card $card is not fully inside $visible');
        expect(_contains(window, card), isTrue,
            reason: 'first card $card is not fully on screen $window');

        // The page numbers do not scroll away with the feed.
        _expectPageBarOnScreen(tester, screen);
      });
    }
  }

  testWidgets('active search shows as a compact chip that clears the query',
      (tester) async {
    final provider = await pumpSearchResults(tester, kFoldScreens.first);
    expect(tester.takeException(), isNull);

    final chip = find.byKey(const Key('home-active-query'));
    expect(chip, findsOneWidget);
    expect(find.descendant(of: chip, matching: find.textContaining('Music Night')),
        findsOneWidget);
    expect(tester.getRect(chip).height, lessThanOrEqualTo(40));

    // Reopening the search panel keeps the typed query.
    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(TextField, 'Music Night'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.descendant(of: chip, matching: find.byTooltip('Clear')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(provider.searchQuery, isEmpty);
    expect(find.byKey(const Key('home-active-query')), findsNothing);
  });

  testWidgets('pinned page bar moves to the next page', (tester) async {
    await pumpSearchResults(tester, kFoldScreens.first);
    await tester.tap(find.descendant(of: _pageBar, matching: find.text('Next')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.descendant(of: _pageBar, matching: find.text('Page 2 of 2')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ask SpotVibe is a compact icon in the top row', (tester) async {
    await pumpSearchResults(tester, kFoldScreens.first);
    final ask = find.byKey(const Key('home-ask-spotvibe'));
    expect(ask, findsOneWidget);
    expect(tester.getSize(ask).height, lessThanOrEqualTo(48));
    // Signed out, Ask SpotVibe sends people to sign in (unchanged behaviour).
    expect(find.text('Ask SpotVibe'), findsNothing);
  });
}

