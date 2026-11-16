import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/l10n/app_localizations.dart';
import 'package:spotvibe_app/models/event_message.dart';
import 'package:spotvibe_app/screens/direct_conversation_screen.dart';
import 'package:spotvibe_app/screens/messages_screen.dart';
import 'package:spotvibe_app/services/event_messaging_service.dart';

Map<String, dynamic> threadDoc({
  String eventId = 'e1',
  String hostId = 'host',
  String attendeeId = 'att',
  int lastMs = 1000,
  String preview = 'See you there',
  String lastAuthor = 'att',
  Map<String, int> unread = const {},
  Map<String, String> names = const {'host': 'Hana Host', 'att': 'Ari Attendee'},
  String title = 'Sunset Market',
}) =>
    {
      'eventId': eventId,
      'eventTitle': title,
      'hostId': hostId,
      'attendeeId': attendeeId,
      'participants': [hostId, attendeeId],
      'lastMessageAtMs': lastMs,
      'lastPreview': preview,
      'lastAuthorId': lastAuthor,
      'startedBy': attendeeId,
      'unread': unread,
      'names': names,
    };

/// Uses a fake Firestore for reads and records callable "sends" instead of
/// hitting Cloud Functions.
class FakeMessagingService extends EventMessagingService {
  FakeMessagingService(this.db) : super(firestore: db);

  final FakeFirebaseFirestore db;
  final sent = <Map<String, String>>[];
  final markedRead = <String>[];

  @override
  Future<String> sendDirectMessage({
    required String eventId,
    required String attendeeId,
    required String text,
  }) async {
    sent.add({'eventId': eventId, 'attendeeId': attendeeId, 'text': text});
    return '';
  }

  @override
  Future<void> markDirectRead(String threadId) async {
    markedRead.add(threadId);
  }
}

Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  group('EventDirectThread', () {
    test('parses participants, unread counts, and names', () {
      final t = EventDirectThread.fromMap('e1_host_att', threadDoc(unread: {'host': 3}));
      expect(t.participants, ['host', 'att']);
      expect(t.unreadFor('host'), 3);
      expect(t.unreadFor('att'), 0);
      expect(t.otherParticipant('host'), 'att');
      expect(t.otherParticipant('att'), 'host');
      expect(t.nameOf('host'), 'Hana Host');
      expect(t.isHost('host'), isTrue);
      expect(t.lastMessageIsMine('att'), isTrue);
      expect(t.eventTitle, 'Sunset Market');
    });

    test('falls back to host/attendee ids for legacy docs', () {
      final t = EventDirectThread.fromMap('x', {'eventId': 'e1', 'hostId': 'h', 'attendeeId': 'a'});
      expect(t.participants, ['h', 'a']);
      expect(t.unread, isEmpty);
      expect(t.nameOf('h'), '');
    });
  });

  group('DirectMessagePolicy', () {
    test('hosts need Premium only to start a conversation', () {
      expect(DirectMessagePolicy.hostNeedsPremium(threadExists: false, isPremium: false), isTrue);
      expect(DirectMessagePolicy.hostNeedsPremium(threadExists: true, isPremium: false), isFalse);
      expect(DirectMessagePolicy.hostNeedsPremium(threadExists: false, isPremium: true), isFalse);
    });

    test('attendees start from an RSVP', () {
      expect(DirectMessagePolicy.attendeeCanStart(hasRsvp: true, threadExists: false), isTrue);
      expect(DirectMessagePolicy.attendeeCanStart(hasRsvp: false, threadExists: false), isFalse);
      expect(DirectMessagePolicy.attendeeCanStart(hasRsvp: false, threadExists: true), isTrue);
    });

    test('unread labels cap at 9+ and totals sum per user', () {
      expect(DirectMessagePolicy.unreadLabel(4), '4');
      expect(DirectMessagePolicy.unreadLabel(12), '9+');
      final threads = [
        EventDirectThread.fromMap('a', threadDoc(unread: {'host': 2})),
        EventDirectThread.fromMap('b', threadDoc(attendeeId: 'att2', unread: {'host': 5, 'att2': 1})),
      ];
      expect(DirectMessagePolicy.totalUnread(threads, 'host'), 7);
      expect(DirectMessagePolicy.totalUnread(threads, 'att2'), 1);
    });
  });

  group('EventMessagingService inbox', () {
    late FakeFirebaseFirestore db;
    late EventMessagingService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = EventMessagingService(firestore: db);
      await db.collection('event_dms').doc('e1_host_att').set(threadDoc(lastMs: 1000, unread: {'host': 2}));
      await db
          .collection('event_dms')
          .doc('e2_host_bob')
          .set(threadDoc(eventId: 'e2', attendeeId: 'bob', lastMs: 3000, unread: {'host': 1}));
      await db
          .collection('event_dms')
          .doc('e3_other_bob')
          .set(threadDoc(eventId: 'e3', hostId: 'other', attendeeId: 'bob', lastMs: 2000));
    });

    test('lists only my conversations, newest first', () async {
      final inbox = await service.watchInbox('host').first;
      expect(inbox.map((t) => t.id), ['e2_host_bob', 'e1_host_att']);
      final bobs = await service.watchInbox('bob').first;
      expect(bobs.map((t) => t.id), ['e2_host_bob', 'e3_other_bob']);
      expect(await service.watchInbox('').first, isEmpty);
    });

    test('sums unread across conversations', () async {
      expect(await service.watchTotalUnread('host').first, 3);
      expect(await service.watchTotalUnread('att').first, 0);
    });

    test('reads the block list', () async {
      await db.collection('blocks').doc('host').collection('blocked').doc('bob').set({'at': 1});
      expect(await service.watchBlockedIds('host').first, {'bob'});
    });

    test('direct messages hide removed messages and stay in order', () async {
      final msgs = db.collection('event_dms').doc('e1_host_att').collection('dm_messages');
      await msgs.add({'authorId': 'att', 'text': 'first', 'createdAtMs': 1});
      await msgs.add({'authorId': 'host', 'text': 'hidden', 'createdAtMs': 2, 'hidden': true});
      await msgs.add({'authorId': 'host', 'text': 'second', 'createdAtMs': 3});
      final out = await service.watchDirectMessages('e1_host_att').first;
      expect(out.map((m) => m.text), ['first', 'second']);
    });
  });

  group('MessagesInboxView', () {
    testWidgets('shows conversations with unread badges and opens one', (tester) async {
      final db = FakeFirebaseFirestore();
      await db.collection('event_dms').doc('e1_host_att').set(threadDoc(unread: {'host': 2}));
      await db.collection('event_dms').doc('e2_host_bob').set(threadDoc(
            eventId: 'e2',
            attendeeId: 'bob',
            lastMs: 500,
            preview: 'Thanks!',
            lastAuthor: 'host',
            names: const {'host': 'Hana Host', 'bob': 'Bob B'},
            title: 'Trivia Night',
          ));
      EventDirectThread? opened;
      await tester.pumpWidget(wrap(Scaffold(
        body: MessagesInboxView(
          uid: 'host',
          service: EventMessagingService(firestore: db),
          onOpen: (t) => opened = t,
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Ari Attendee'), findsOneWidget);
      expect(find.text('Bob B'), findsOneWidget);
      expect(find.text('Sunset Market · See you there'), findsOneWidget);
      expect(find.text('Trivia Night · You: Thanks!'), findsOneWidget);
      expect(find.byKey(const Key('unreadBadge')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('Bob B'));
      expect(opened?.id, 'e2_host_bob');
    });

    testWidgets('hides blocked people and shows the empty state', (tester) async {
      final db = FakeFirebaseFirestore();
      await db.collection('event_dms').doc('e1_host_att').set(threadDoc());
      await db.collection('blocks').doc('host').collection('blocked').doc('att').set({'at': 1});
      await tester.pumpWidget(wrap(Scaffold(
        body: MessagesInboxView(
          uid: 'host',
          service: EventMessagingService(firestore: db),
          onOpen: (_) {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Ari Attendee'), findsNothing);
      expect(find.textContaining('No messages yet'), findsOneWidget);
    });
  });

  group('DirectConversationScreen', () {
    late FakeFirebaseFirestore db;
    late FakeMessagingService service;
    final reports = <String>[];
    final blocks = <String>[];
    var paywallShown = 0;

    Widget screen({required String uid, bool premium = false}) => wrap(DirectConversationScreen(
          eventId: 'e1',
          hostId: 'host',
          attendeeId: 'att',
          uid: uid,
          isPremium: premium,
          eventTitle: 'Sunset Market',
          service: service,
          onReport: ({required contentType, required contentId, required reportedUserId}) async {
            reports.add('$contentType|$contentId|$reportedUserId');
          },
          onBlock: (id) async => blocks.add(id),
          onPremiumRequired: (_) async => paywallShown++,
        ));

    setUp(() {
      db = FakeFirebaseFirestore();
      service = FakeMessagingService(db);
      reports.clear();
      blocks.clear();
      paywallShown = 0;
    });

    testWidgets('an attendee can start a conversation with the host', (tester) async {
      await tester.pumpWidget(screen(uid: 'att'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ask the host a question'), findsOneWidget);
      expect(find.text('About Sunset Market'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('dmComposer')), '  Is parking free?  ');
      await tester.tap(find.byKey(const Key('dmSend')));
      await tester.pumpAndSettle();
      expect(service.sent, [
        {'eventId': 'e1', 'attendeeId': 'att', 'text': 'Is parking free?'},
      ]);
      expect(paywallShown, 0);
    });

    testWidgets('a free host sees the paywall instead of starting one', (tester) async {
      await tester.pumpWidget(screen(uid: 'host'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Start a private conversation'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('dmComposer')), 'Hi!');
      await tester.tap(find.byKey(const Key('dmSend')));
      await tester.pumpAndSettle();
      expect(paywallShown, 1);
      expect(service.sent, isEmpty);
    });

    testWidgets('a Premium host can start one', (tester) async {
      await tester.pumpWidget(screen(uid: 'host', premium: true));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dmComposer')), 'Thanks for the RSVP');
      await tester.tap(find.byKey(const Key('dmSend')));
      await tester.pumpAndSettle();
      expect(service.sent.single['attendeeId'], 'att');
    });

    testWidgets('a free host can reply in an existing conversation, and it is marked read',
        (tester) async {
      final ref = db.collection('event_dms').doc('e1_host_att');
      await ref.set(threadDoc(unread: {'host': 1}));
      await ref.collection('dm_messages').add({'authorId': 'att', 'text': 'Is parking free?', 'createdAtMs': 1});
      await tester.pumpWidget(screen(uid: 'host'));
      await tester.pumpAndSettle();

      expect(find.text('Ari Attendee'), findsOneWidget);
      expect(find.text('Is parking free?'), findsOneWidget);
      expect(find.byType(MessageBubble), findsOneWidget);
      expect(service.markedRead, ['e1_host_att']);

      await tester.enterText(find.byKey(const Key('dmComposer')), 'Yes, lot B');
      await tester.tap(find.byKey(const Key('dmSend')));
      await tester.pumpAndSettle();
      expect(paywallShown, 0);
      expect(service.sent.single['text'], 'Yes, lot B');
    });

    testWidgets('report and block from the menu', (tester) async {
      await db.collection('event_dms').doc('e1_host_att').set(threadDoc());
      await tester.pumpWidget(screen(uid: 'att'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('conversationMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report conversation'));
      await tester.pumpAndSettle();
      expect(reports, ['direct_conversation|e1_host_att|host']);

      await tester.tap(find.byKey(const Key('conversationMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block this person'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Block'));
      await tester.pumpAndSettle();
      expect(blocks, ['host']);
    });

    testWidgets('overlong messages are rejected before sending', (tester) async {
      await tester.pumpWidget(screen(uid: 'att'));
      await tester.pumpAndSettle();
      // maxLength on the field truncates typing; simulate a paste past it.
      final field = tester.widget<TextField>(find.byKey(const Key('dmComposer')));
      field.controller!.text = 'x' * 1001;
      await tester.tap(find.byKey(const Key('dmSend')));
      await tester.pump();
      expect(service.sent, isEmpty);
      expect(find.text('Messages can be up to 1000 characters.'), findsOneWidget);
      // Drain the snackbar timer.
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
