import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/widgets/events/event_card.dart';

import 'support/search_results_harness.dart';

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

void main() {
  // Blake: "You are unable to see a full event card on searches." These render
  // the real search screen at every Galaxy Z Fold 8 configuration.
  for (final textScale in const [1.0, 1.3]) {
    for (final screen in kFoldScreens) {
      testWidgets(
          'search results show a full event card on ${screen.name} '
          '(${screen.logicalSize.width.round()}x'
          '${screen.logicalSize.height.round()} dp, text x$textScale)',
          (tester) async {
        await pumpSearchResults(tester, screen, textScale: textScale);

        // Any RenderFlex overflow or layout error is reported as an exception.
        expect(tester.takeException(), isNull);

        // Scroll the screen (header first, then feed) as a user would until
        // the first result card is on screen, then bring all of it into view.
        await tester.scrollUntilVisible(
          find.byType(EventCard),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        final firstCard = find.byType(EventCard).first;
        await tester.ensureVisible(firstCard);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        final viewport = _visibleRegionOf(tester, firstCard);
        final card = tester.getRect(firstCard);
        final window = Offset.zero & screen.logicalSize;

        expect(card.height, lessThanOrEqualTo(viewport.height + 0.5),
            reason: 'card ($card) is taller than the scroll viewport '
                '($viewport), so it can never be seen in full');
        expect(_contains(viewport, card), isTrue,
            reason: 'first card $card is not fully inside viewport $viewport');
        expect(_contains(window, card), isTrue,
            reason: 'first card $card is not fully on screen $window');
      });
    }
  }

}
