import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/theme/theme.dart';
import 'package:spotvibe_app/widgets/events/search_header.dart';

void main() {
  testWidgets('keyword input waits briefly before starting a live search',
      (tester) async {
    final queries = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SearchHeader(
            onSearch: queries.add,
            onAreaSearch: (_) {},
            onProfileTap: () {},
            isLoggedIn: false,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Albuquerque');
    await tester.pump(const Duration(milliseconds: 349));
    expect(queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(queries, ['Albuquerque']);
  });
}
