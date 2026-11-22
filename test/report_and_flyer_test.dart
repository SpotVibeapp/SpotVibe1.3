import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/models/event.dart';
import 'package:spotvibe_app/models/user.dart';
import 'package:spotvibe_app/providers/auth_provider.dart';
import 'package:spotvibe_app/repositories/mock_user_repository.dart';
import 'package:spotvibe_app/services/auth_service.dart';
import 'package:spotvibe_app/widgets/events/event_qr_flyer.dart';
import 'package:spotvibe_app/widgets/events/report_event_sheet.dart';

class _RecordingRepo extends MockUserRepository {
  _RecordingRepo({this.fail = false});
  final bool fail;
  final reports = <Map<String, String>>[];

  @override
  Future<AppUser> login(String email, String password) async =>
      AppUser(id: 'u1', displayName: 'Tester', email: email, avatarUrl: '');

  @override
  Future<void> reportContent({
    required String contentType,
    required String contentId,
    String reportedUserId = '',
    required String reason,
  }) async {
    if (fail) throw Exception('permission-denied');
    reports.add({
      'contentType': contentType,
      'contentId': contentId,
      'reportedUserId': reportedUserId,
      'reason': reason,
    });
  }
}

Event _event() => Event(
      id: 'evt42',
      title: 'Thursday Board Game Night',
      description: 'Bring a friend',
      dateTime: DateTime(2026, 12, 3, 19),
      location: 'Cafe Ludo',
      address: '1 Main St',
      imageUrl: '',
      category: 'Games',
      organizerName: 'Game Night Crew',
      organizerAvatarUrl: '',
      creatorId: 'host1',
      isUserCreated: true,
    );

Future<void> _pumpHost(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showEventReportSheet(context, event: _event()),
                child: const Text('open report'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('buildEventReportReason', () {
    test('code only when there is no note', () {
      expect(buildEventReportReason(EventReportReason.cancelled, '  '),
          'cancelled');
    });

    test('code plus collapsed note', () {
      expect(
          buildEventReportReason(
              EventReportReason.wrongDetails, ' It is on\nFriday  '),
          'wrong_details: It is on Friday');
    });

    test('always fits the 1000-character rules limit with prefix', () {
      final long = 'x' * 5000;
      final r = buildEventReportReason(EventReportReason.other, long);
      expect(r.length, lessThanOrEqualTo(900));
      expect('[event] $r'.length, lessThan(1000));
    });

    test('reason codes are stable', () {
      expect(EventReportReason.values.map((r) => r.code).toList(), [
        'fake_or_spam',
        'wrong_details',
        'cancelled',
        'offensive',
        'other',
      ]);
    });
  });

  group('showEventReportSheet', () {
    testWidgets('files a real event report with the chosen reason',
        (tester) async {
      final repo = _RecordingRepo();
      final auth = AuthProvider(service: AuthService(repository: repo));
      expect(await auth.login('t@example.com', 'password1'), isTrue);
      await _pumpHost(tester, auth);

      await tester.tap(find.text('open report'));
      await tester.pumpAndSettle();

      // Submit is disabled until a reason is picked.
      final submit = find.byKey(const ValueKey('report-submit'));
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('report-reason-wrong_details')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const ValueKey('report-note')), 'It moved to Friday');
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repo.reports, hasLength(1));
      expect(repo.reports.single['contentType'], 'event');
      expect(repo.reports.single['contentId'], 'evt42');
      expect(repo.reports.single['reportedUserId'], 'host1');
      expect(repo.reports.single['reason'], 'wrong_details: It moved to Friday');
      expect(find.text('Report submitted. Thank you!'), findsOneWidget);
    });

    testWidgets('says so when the report could not be saved', (tester) async {
      final repo = _RecordingRepo(fail: true);
      final auth = AuthProvider(service: AuthService(repository: repo));
      expect(await auth.login('t@example.com', 'password1'), isTrue);
      await _pumpHost(tester, auth);

      await tester.tap(find.text('open report'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('report-reason-fake_or_spam')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('report-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Report submitted. Thank you!'), findsNothing);
      expect(
          find.text(
              "Your report wasn't sent. Check your connection and try again."),
          findsOneWidget);
    });

    testWidgets('report sheet fits a Z Fold cover screen (344dp)',
        (tester) async {
      tester.view.physicalSize = const Size(344, 882) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repo = _RecordingRepo();
      final auth = AuthProvider(service: AuthService(repository: repo));
      expect(await auth.login('t@example.com', 'password1'), isTrue);
      await _pumpHost(tester, auth);

      await tester.tap(find.text('open report'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final submit = find.byKey(const ValueKey('report-submit'));
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(882));
    });

    testWidgets('signed-out people are asked to sign in, nothing is filed',
        (tester) async {
      final repo = _RecordingRepo();
      final auth = AuthProvider(service: AuthService(repository: repo));
      await _pumpHost(tester, auth);

      await tester.tap(find.text('open report'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('report-submit')), findsNothing);
      expect(
          find.text('Sign in to report an event so our team can follow up.'),
          findsOneWidget);
      expect(repo.reports, isEmpty);
    });
  });

  group('EventQrFlyer', () {
    // Galaxy Z Fold cover (~344 dp wide) and inner (~690 dp) screens.
    for (final size in const [Size(344, 882), Size(690, 841)]) {
      testWidgets('flyer sheet fits ${size.width.toInt()}dp with share visible',
          (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEventQrFlyerSheet(
                  context,
                  eventId: 'evt42',
                  title: 'Thursday Board Game Night at Cafe Ludo with a '
                      'very long title that wraps',
                  dateLabel: 'Thu, Dec 3 · 7:00 PM',
                  venueLabel: 'Cafe Ludo, El Paso',
                  link: 'https://spotvibeapp.com/app/event/evt42',
                ),
                child: const Text('open flyer'),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('open flyer'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final qr = tester.widget<QrImageView>(find.byType(QrImageView));
        expect(qr, isNotNull);
        expect(find.text('Scan to save this event'), findsOneWidget);
        expect(find.text('spotvibeapp.com/app/event/evt42'), findsOneWidget);

        final share = find.byKey(const ValueKey('flyer-share'));
        expect(share, findsOneWidget);
        final rect = tester.getRect(share);
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      });
    }

    testWidgets('flyer keeps letter proportions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Center(
          child: SizedBox(
            width: 255,
            child: EventQrFlyer(
              title: 'Run club',
              dateLabel: 'Sat 8:00 AM',
              venueLabel: '',
              link: 'https://spotvibeapp.com/app/event/r1',
            ),
          ),
        ),
      ));
      final size = tester.getSize(find.byType(EventQrFlyer));
      expect(size.width / size.height, closeTo(kQrFlyerAspectRatio, 0.01));
      expect(tester.takeException(), isNull);
    });
  });
}
