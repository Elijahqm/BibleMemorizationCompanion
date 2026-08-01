import 'dart:io';

import 'package:bible_memorization_companion_mobile/features/catalog/data/models/catalog_package.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/installed_package.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/package_content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const indexJson = '''
{
  "packageId": "cb-daniel-1-6",
  "abbreviation": "Dan",
  "attribution": "REINA-VALERA 1960",
  "chapterOrder": [1, 2],
  "chapterVerseCounts": {"1": 2, "2": 1},
  "availableSections": true,
  "availableAudio": false
}
''';

const sectionsJson = '''
{
  "packageId": "cb-daniel-1-6",
  "sections": [
    {
      "sectionId": "daniel-en-babilonia",
      "title": "Daniel en Babilonia",
      "startVerseRef": "Dan 1:1",
      "endVerseRef": "Dan 1:2",
      "verseRefs": ["Dan 1:1", "Dan 1:2"]
    },
    {
      "sectionId": "el-sueno",
      "title": "El sueño de Nabucodonosor",
      "startVerseRef": "Dan 2:1",
      "endVerseRef": "Dan 2:1",
      "verseRefs": ["Dan 2:1"]
    }
  ]
}
''';

const chapter1Json = '''
{
  "chapterNumber": 1,
  "verses": [
    {
      "verseRef": "Dan 1:1",
      "verseNumber": 1,
      "text": "[[section:daniel-en-babilonia|Daniel en Babilonia]] En el año tercero..."
    },
    {
      "verseRef": "Dan 1:2",
      "verseNumber": 2,
      "text": "Y el Señor entregó en sus manos..."
    }
  ]
}
''';

const chapter2Json = '''
{
  "chapterNumber": 2,
  "verses": [
    {
      "verseRef": "Dan 2:1",
      "verseNumber": 1,
      "text": "Fortalecido. [[section:el-sueno|El sueño de Nabucodonosor]] En el segundo año..."
    }
  ]
}
''';

InstalledPackage writePackage(Directory root) {
  final contentDir = Directory('${root.path}/content/chapters')
    ..createSync(recursive: true);
  File('${root.path}/content/index.json').writeAsStringSync(indexJson);
  File('${root.path}/content/sections.json').writeAsStringSync(sectionsJson);
  File('${contentDir.path}/001.json').writeAsStringSync(chapter1Json);
  File('${contentDir.path}/002.json').writeAsStringSync(chapter2Json);

  return InstalledPackage(
    id: 'cb-daniel-1-6',
    title: 'CB Daniel 1-6',
    version: '1.0.0',
    language: 'es',
    packageType: CatalogPackageType.book,
    sizeBytes: 17787,
    attribution: 'REINA-VALERA 1960',
    verseCount: 3,
    chapterCount: 2,
    installedAt: DateTime.utc(2026, 7, 31),
    directoryPath: root.path,
  );
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('bmc-content'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('loads sections and verses, splitting inline markers', () async {
    final package = writePackage(root);
    final repository = PackageContentRepository();

    final content = await repository.load(package);

    expect(content.sections, hasLength(2));
    expect(content.versesByRef, hasLength(3));

    final firstVerse = content.versesByRef['Dan 1:1']!;
    final segments = firstVerse.segments;
    expect(segments.first.isHeading, isTrue);
    expect(segments.first.text, 'Daniel en Babilonia');
    expect(segments.last.isHeading, isFalse);
    expect(segments.last.text, contains('año tercero'));

    // Mid-verse marker: text before and after the marker both survive.
    final splitVerse = content.versesByRef['Dan 2:1']!;
    final splitSegments = splitVerse.segments;
    expect(splitSegments, hasLength(3));
    expect(splitSegments[0].text, 'Fortalecido.');
    expect(splitSegments[1].isHeading, isTrue);
    expect(splitSegments[2].text, contains('segundo año'));

    final section = content.sections.first;
    expect(content.versesFor(section).map((v) => v.verseRef), [
      'Dan 1:1',
      'Dan 1:2',
    ]);
  });

  test('caches content per package+version', () async {
    final package = writePackage(root);
    final repository = PackageContentRepository();

    final first = await repository.load(package);
    // Mutate the file on disk; a cached read should not see the change.
    File(
      '${root.path}/content/index.json',
    ).writeAsStringSync(indexJson.replaceAll('Dan', 'XX'));
    final second = await repository.load(package);

    expect(identical(first, second), isTrue);
  });

  test('throws ContentException when the package directory is gone', () async {
    final package = writePackage(root);
    root.deleteSync(recursive: true);

    await expectLater(
      PackageContentRepository().load(package),
      throwsA(isA<ContentException>()),
    );
  });

  test('throws ContentException when a required file is missing', () async {
    final package = writePackage(root);
    File('${root.path}/content/index.json').deleteSync();

    await expectLater(
      PackageContentRepository().load(package),
      throwsA(isA<ContentException>()),
    );
  });

  test('tolerates a package with no sections.json', () async {
    final package = writePackage(root);
    File('${root.path}/content/sections.json').deleteSync();

    final content = await PackageContentRepository().load(package);

    expect(content.sections, isEmpty);
    expect(content.versesByRef, hasLength(3));
  });
}
