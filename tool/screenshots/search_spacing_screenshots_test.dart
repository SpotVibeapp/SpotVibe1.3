// Renders the search results screen at the Galaxy Z Fold 8 sizes to PNG files.
// Not part of the unit suite (lives outside test/). Run with:
//   flutter test tool/screenshots/search_spacing_screenshots_test.dart \
//     --dart-define=SHOTS_DIR=/abs/out/dir --dart-define=SHOTS_LABEL=after
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spotvibe_app/widgets/events/event_card.dart';

import '../../test/support/search_results_harness.dart';

const _outDir = String.fromEnvironment('SHOTS_DIR');
const _label = String.fromEnvironment('SHOTS_LABEL', defaultValue: 'shot');

Future<void> _loadFonts() async {
  final fontsDir =
      '${Platform.environment['FLUTTER_ROOT'] ?? ''}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$fontsDir/$f').readAsBytes());
  // The app's Plus Jakarta Sans is fetched at runtime by google_fonts, which
  // tests cannot do, so stand in Roboto (same metrics class) for readability.
  const weights = {
    'regular': 'Roboto-Regular.ttf',
    '400': 'Roboto-Regular.ttf',
    '500': 'Roboto-Medium.ttf',
    '600': 'Roboto-Medium.ttf',
    '700': 'Roboto-Bold.ttf',
    '800': 'Roboto-Black.ttf',
    '900': 'Roboto-Black.ttf',
  };
  // google_fonts names each weight as its own family, e.g. PlusJakartaSans_700.
  for (final entry in weights.entries) {
    final loader = FontLoader('PlusJakartaSans_${entry.key}')
      ..addFont(read(entry.value));
    await loader.load();
  }
  for (final family in ['PlusJakartaSans', 'Roboto']) {
    final loader = FontLoader(family);
    for (final f in {...weights.values}) {
      loader.addFont(read(f));
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _shoot(WidgetTester tester, Key key, FoldScreen screen, String suffix) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: screen.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_outDir/${_label}_${screen.name}$suffix.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Tests have no network; the stand-in fonts below are used instead.
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  for (final screen in kFoldScreens) {
    testWidgets('screenshot ${screen.name}', (tester) async {
      final key = GlobalKey();
      await pumpSearchResults(tester, screen, boundaryKey: key);
      // Let the asset cover photos decode for real.
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump(const Duration(milliseconds: 100));
      await _shoot(tester, key, screen, '');

      // Then scroll as far as the layout allows toward showing the first card
      // in full (before the fix that is impossible: the feed is too short).
      try {
        await tester.scrollUntilVisible(
          find.byType(EventCard),
          120,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 20,
        );
      } catch (_) {}
      if (find.byType(EventCard).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.byType(EventCard).first);
      }
      await tester.pump(const Duration(milliseconds: 300));
      await _shoot(tester, key, screen, '_scrolled-to-first-card');
      // Layout errors (the bug, in "before" runs) must not stop the capture.
      while (tester.takeException() != null) {}
    });
  }
}
