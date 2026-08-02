import 'dart:io';

import 'package:bible_memorization_companion_mobile/features/study/data/active_package_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/package_content.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/study.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/study_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/verse_state_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/study_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const packageId = 'cb-daniel-1-6';

const verse1 = Verse(verseRef: 'Dan 1:1', verseNumber: 1, text: 'In the third year...');
const verse2 = Verse(verseRef: 'Dan 1:2', verseNumber: 2, text: 'And the Lord gave...');
const verse3 = Verse(verseRef: 'Dan 2:1', verseNumber: 1, text: 'In the second year...');

const section = ContentSection(
  sectionId: 'daniel-in-babylon',
  title: 'Daniel in Babylon',
  startVerseRef: 'Dan 1:1',
  endVerseRef: 'Dan 1:2',
  verseRefs: ['Dan 1:1', 'Dan 1:2'],
);

final content = PackageContent(
  packageId: packageId,
  title: 'CB Daniel 1-6',
  index: const PackageIndex(
    packageId: packageId,
    abbreviation: 'Dan',
    attribution: 'REINA-VALERA 1960',
    chapterOrder: [1, 2],
    chapterVerseCounts: {1: 2, 2: 1},
    availableSections: true,
  ),
  sections: const [section],
  versesByRef: const {'Dan 1:1': verse1, 'Dan 1:2': verse2, 'Dan 2:1': verse3},
  versesByChapter: const {
    1: [verse1, verse2],
    2: [verse3],
  },
);

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('bmc-study-ctrl'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<Directory> rootProvider() async => root;

  StudyController controller() => StudyController(
    studyStore: StudyStore(rootDirectory: rootProvider),
    verseStateStore: VerseStateStore(rootDirectory: rootProvider),
    activePackageStore: ActivePackageStore(rootDirectory: rootProvider),
  );

  test('creates a chapter study with the chapter verses in order', () async {
    final studies = controller();
    await studies.load();

    final study = await studies.createChapterStudy(content, 1);

    expect(study.mode, StudyMode.chapter);
    expect(study.title, 'CB Daniel 1-6 Chapter 1');
    expect(study.verseRefs, ['Dan 1:1', 'Dan 1:2']);
    expect(studies.studiesFor(packageId), [study]);
  });

  test('creates a section study named after the section', () async {
    final studies = controller();
    await studies.load();

    final study = await studies.createSectionStudy(content, section);

    expect(study.mode, StudyMode.section);
    expect(study.title, 'Daniel in Babylon');
    expect(study.verseRefs, ['Dan 1:1', 'Dan 1:2']);
  });

  test('creates a custom study from hand-picked verses', () async {
    final studies = controller();
    await studies.load();

    final study = await studies.createCustomStudy(
      packageId: packageId,
      title: 'My study 1',
      verseRefs: ['Dan 2:1', 'Dan 1:1'],
    );

    expect(study.mode, StudyMode.custom);
    expect(study.verseRefs, ['Dan 2:1', 'Dan 1:1']);
  });

  test('deleting a study removes only that study', () async {
    final studies = controller();
    await studies.load();

    final a = await studies.createChapterStudy(content, 1);
    final b = await studies.createChapterStudy(content, 2);

    await studies.deleteStudy(a);

    expect(studies.studiesFor(packageId), [b]);
  });

  test('toggling learned updates progress and is shared across studies', () async {
    final studies = controller();
    await studies.load();

    final chapterStudy = await studies.createChapterStudy(content, 1);
    final sectionStudy = await studies.createSectionStudy(content, section);

    expect(studies.progressFor(chapterStudy), (0, 2));

    await studies.toggleLearned(packageId, 'Dan 1:1');

    expect(studies.progressFor(chapterStudy), (1, 2));
    // The section study shares "Dan 1:1", so its progress reflects the mark too.
    expect(studies.progressFor(sectionStudy), (1, 2));
    expect(studies.stateFor(packageId, 'Dan 1:1').isLearned, isTrue);

    await studies.toggleLearned(packageId, 'Dan 1:1');
    expect(studies.stateFor(packageId, 'Dan 1:1').isLearned, isFalse);
  });

  test('toggling difficult is independent from learned', () async {
    final studies = controller();
    await studies.load();

    await studies.toggleDifficult(packageId, 'Dan 1:1');

    final state = studies.stateFor(packageId, 'Dan 1:1');
    expect(state.isDifficult, isTrue);
    expect(state.isLearned, isFalse);
  });

  test('updateResumeIndex persists the last verse shown', () async {
    final studies = controller();
    await studies.load();

    final study = await studies.createChapterStudy(content, 1);
    await studies.updateResumeIndex(study, 1);

    expect(studies.studiesFor(packageId).single.lastVerseIndex, 1);

    final reloaded = controller();
    await reloaded.load();
    expect(reloaded.studiesFor(packageId).single.lastVerseIndex, 1);
  });

  test('setActivePackage persists across a restart', () async {
    final studies = controller();
    await studies.load();
    await studies.setActivePackage(packageId);

    final reloaded = controller();
    await reloaded.load();
    expect(reloaded.activePackageId, packageId);
  });

  test('studiesFor orders by most recently opened, not creation order', () async {
    final studies = controller();
    await studies.load();

    final a = await studies.createChapterStudy(content, 1);
    final b = await studies.createChapterStudy(content, 2);
    expect(studies.studiesFor(packageId), [b, a]);

    await studies.markOpened(a);

    final ordered = studies.studiesFor(packageId);
    expect(ordered.first.id, a.id);

    final reloaded = controller();
    await reloaded.load();
    expect(reloaded.studiesFor(packageId).first.id, a.id);
  });

  test('uninstalling a package cascades to its studies and verse states', () async {
    final studies = controller();
    await studies.load();
    await studies.setActivePackage(packageId);
    await studies.createChapterStudy(content, 1);
    await studies.toggleLearned(packageId, 'Dan 1:1');

    await studies.onPackageUninstalled(packageId);

    expect(studies.studiesFor(packageId), isEmpty);
    expect(studies.stateFor(packageId, 'Dan 1:1').isLearned, isFalse);
    expect(studies.activePackageId, isNull);

    final reloaded = controller();
    await reloaded.load();
    expect(reloaded.studiesFor(packageId), isEmpty);
  });
}
