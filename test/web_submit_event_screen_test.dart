import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spotvibe_app/screens/web_submit_event_screen.dart';

void main() {
  testWidgets('the public web submit form renders without an account', (tester) async {
    final router = GoRouter(
      initialLocation: '/submit',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/submit',
          builder: (_, __) => const WebSubmitEventScreen(),
        ),
        GoRoute(path: '/terms', builder: (_, __) => const Text('Terms')),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Post your event'), findsOneWidget);
    expect(find.text('Submit for review'), findsOneWidget);
    expect(find.text('Event name *'), findsOneWidget);
    expect(find.text('Venue *'), findsOneWidget);
    expect(find.text('Your email * (not shown publicly; used to let you claim the listing)'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);

    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Publica tu evento'), findsOneWidget);
    expect(find.text('Enviar a revisión'), findsOneWidget);
  });
}
