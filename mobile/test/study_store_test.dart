import 'dart:io';

import 'package:bible_memorization_companion_mobile/features/study/data/active_package_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/study.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/verse_state.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/study_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/verse_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('bmc-study-store'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<Directory> rootProvider() async => root;

  test('StudyStore round-trips studies through disk', () async {
    final store = StudyStore(rootDirectory: rootProvider);
    expect(await store.load(), isEmpty);

    final study = Study(
      id: 'cb-daniel-1-6-1',
      packageId: 'cb-daniel-1-6',
      title: 'Chapter 1',
      mode: StudyMode.chapter,
      verseRefs: const ['Dan 1:1', 'Dan 1:2'],
      createdAt: DateTime.utc(2026, 7, 31),
      lastVerseIndex: 1,
    );
    await store.save([study]);

    final reloaded = await StudyStore(rootDirectory: rootProvider).load();
    expect(reloaded, hasLength(1));
    expect(reloaded.single.title, 'Chapter 1');
    expect(reloaded.single.mode, StudyMode.chapter);
    expect(reloaded.single.verseRefs, ['Dan 1:1', 'Dan 1:2']);
    expect(reloaded.single.lastVerseIndex, 1);
  });

  test('VerseStateStore round-trips verse states through disk', () async {
    final store = VerseStateStore(rootDirectory: rootProvider);
    expect(await store.load(), isEmpty);

    const state = VerseState(
      packageId: 'cb-daniel-1-6',
      verseRef: 'Dan 1:1',
      isLearned: true,
      isDifficult: false,
      reviewCount: 3,
    );
    await store.save({state.key: state});

    final reloaded = await VerseStateStore(rootDirectory: rootProvider).load();
    expect(reloaded, hasLength(1));
    final reloadedState = reloaded['cb-daniel-1-6::Dan 1:1']!;
    expect(reloadedState.isLearned, isTrue);
    expect(reloadedState.reviewCount, 3);
  });

  test('ActivePackageStore round-trips the active package id', () async {
    final store = ActivePackageStore(rootDirectory: rootProvider);
    expect(await store.load(), isNull);

    await store.save('cb-daniel-1-6');

    expect(
      await ActivePackageStore(rootDirectory: rootProvider).load(),
      'cb-daniel-1-6',
    );
  });
}
