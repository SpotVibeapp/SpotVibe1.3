import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/theme/theme.dart';
import 'package:spotvibe_app/widgets/events/event_creation_guide.dart';

Widget _testApp(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(height: 700, child: child)),
  );
}

void main() {
  testWidgets('creator guide card keeps Free and Premium media limits visible',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _testApp(EventCreationGuideCard(onOpen: () => opened = true)),
    );

    expect(find.text('Create with confidence'), findsOneWidget);
    expect(
      find.text(
        'Free: 1 cover photo + 1 short video. Premium: up to 5 photos total (including the cover) + 3 short videos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open creator guide'), findsOneWidget);
    await tester.tap(find.text('Open creator guide'));
    expect(opened, isTrue);
  });

  testWidgets('creator guide provides the same clear comparison in Spanish',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        EventCreationGuideCard(onOpen: () {}),
        locale: const Locale('es'),
      ),
    );

    expect(find.text('Crea con confianza'), findsOneWidget);
    expect(
      find.text(
        'Gratis: 1 foto de portada + 1 video corto. Premium: hasta 5 fotos en total (incluida la portada) + 3 videos cortos.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Free creator guide explains the exact upgrade difference',
      (tester) async {
    var openedPremium = false;
    await tester.pumpWidget(
      _testApp(
        EventCreationGuide(
          isPremium: false,
          isAdmin: false,
          onClose: () {},
          onUpgrade: () => openedPremium = true,
        ),
      ),
    );

    expect(find.text('Free plan'), findsWidgets);
    expect(find.text('1. Start with the details'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('1 cover photo total and 1 short video per event'),
      300,
    );
    expect(
      find.text('1 cover photo total and 1 short video per event'),
      findsOneWidget,
    );
    expect(
      find.text('Up to 5 photos total (cover included) and 3 short videos per event'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Explore Premium'), 300);
    await tester.tap(find.text('Explore Premium'));
    expect(openedPremium, isTrue);
  });

  testWidgets('administrator guide omits subscription promotion', (tester) async {
    await tester.pumpWidget(
      _testApp(
        EventCreationGuide(
          isPremium: false,
          isAdmin: true,
          onClose: () {},
        ),
      ),
    );

    expect(find.text('Admin test access'), findsOneWidget);
    expect(find.text('Explore Premium'), findsNothing);
    expect(find.text('Free plan'), findsNothing);
  });

  testWidgets('Premium creator guide identifies active access and media allowance',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        EventCreationGuide(
          isPremium: true,
          isAdmin: false,
          onClose: () {},
        ),
      ),
    );

    expect(find.text('Premium active'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Up to 5 photos total (cover included) and 3 short videos per event'),
      300,
    );
    expect(
      find.text('AI promo backgrounds, analytics, custom branding, and contact links'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Start creating'), 300);
    expect(find.text('Start creating'), findsOneWidget);
  });
}
