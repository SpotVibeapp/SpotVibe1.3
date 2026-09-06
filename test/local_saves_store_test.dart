import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotvibe_app/repositories/local_saves_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty', () async {
    final store = LocalSavesStore();
    expect(await store.load(), isEmpty);
  });

  test('set stores flags and merges unspecified ones', () async {
    final store = LocalSavesStore();
    await store.set('evt_1', bookmarked: true, interested: false);
    await store.set('evt_1', bookmarked: true, interested: true);

    final saves = await store.load();
    expect(saves['evt_1']!.bookmarked, isTrue);
    expect(saves['evt_1']!.interested, isTrue);
  });

  test('set can flip a flag back off', () async {
    final store = LocalSavesStore();
    await store.set('evt_1', bookmarked: true, interested: false);
    await store.set('evt_1', bookmarked: false, interested: false);

    final saves = await store.load();
    expect(saves['evt_1']!.bookmarked, isFalse);
    expect(saves['evt_1']!.interested, isFalse);
  });

  test('remove deletes the entry', () async {
    final store = LocalSavesStore();
    await store.set('evt_1', bookmarked: true, interested: true);
    await store.remove('evt_1');
    expect(await store.load(), isEmpty);
  });

  test('entries are keyed per event and survive a new store instance',
      () async {
    await LocalSavesStore().set('evt_1', bookmarked: true, interested: false);
    await LocalSavesStore().set('evt_2', bookmarked: false, interested: true);

    // A brand-new instance reads the same SharedPreferences-backed data,
    // which is what survives feed refreshes and app restarts.
    final saves = await LocalSavesStore().load();
    expect(saves['evt_1']!.bookmarked, isTrue);
    expect(saves['evt_2']!.interested, isTrue);
  });

  test('clear removes everything', () async {
    final store = LocalSavesStore();
    await store.set('evt_1', bookmarked: true, interested: false);
    await store.clear();
    expect(await store.load(), isEmpty);
  });
}
