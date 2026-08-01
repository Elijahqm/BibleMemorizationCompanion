import 'dart:convert';
import 'dart:io';

import '../../downloads/data/installed_package.dart';
import 'models/package_content.dart';

/// Raised when an installed package cannot be read from disk.
class ContentException implements Exception {
  const ContentException(this.message);

  final String message;

  @override
  String toString() => 'ContentException: $message';
}

/// Reads the study content of an installed package from local storage.
///
/// Packages are small (tens of KB), so the whole book is loaded and cached in
/// memory the first time it is opened.
class PackageContentRepository {
  final Map<String, PackageContent> _cache = {};

  Future<PackageContent> load(InstalledPackage package) async {
    final cacheKey = '${package.id}@${package.version}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final root = Directory(package.directoryPath);
    if (!await root.exists()) {
      throw ContentException('${package.title} is no longer on this device.');
    }

    final index = PackageIndex.fromJson(
      await _readJsonObject('${root.path}/content/index.json'),
    );
    final sections = await _readSections('${root.path}/content/sections.json');
    final versesByChapter = await _readVersesByChapter(root, index);
    final versesByRef = {
      for (final verses in versesByChapter.values)
        for (final verse in verses) verse.verseRef: verse,
    };

    final content = PackageContent(
      packageId: package.id,
      title: package.title,
      index: index,
      sections: sections,
      versesByRef: versesByRef,
      versesByChapter: versesByChapter,
    );
    _cache[cacheKey] = content;
    return content;
  }

  void evict(InstalledPackage package) =>
      _cache.remove('${package.id}@${package.version}');

  Future<List<ContentSection>> _readSections(String path) async {
    final file = File(path);
    if (!await file.exists()) return const [];

    final json = await _readJsonObject(path);
    final sections = json['sections'];
    if (sections is! List) return const [];
    return sections
        .whereType<Map<String, dynamic>>()
        .map(ContentSection.fromJson)
        .toList(growable: false);
  }

  Future<Map<int, List<Verse>>> _readVersesByChapter(
    Directory root,
    PackageIndex index,
  ) async {
    final versesByChapter = <int, List<Verse>>{};

    for (final chapter in index.chapterOrder) {
      final path =
          '${root.path}/content/chapters/'
          '${chapter.toString().padLeft(3, '0')}.json';
      if (!await File(path).exists()) continue;

      final json = await _readJsonObject(path);
      final entries = json['verses'];
      if (entries is! List) continue;

      final verses = entries
          .whereType<Map<String, dynamic>>()
          .map(Verse.fromJson)
          .where((verse) => verse.verseRef.isNotEmpty)
          .toList(growable: false);
      versesByChapter[chapter] = verses;
    }

    return versesByChapter;
  }

  Future<Map<String, dynamic>> _readJsonObject(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ContentException('Missing ${file.uri.pathSegments.last}.');
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw ContentException('${file.uri.pathSegments.last} is malformed.');
      }
      return decoded;
    } on FormatException {
      throw ContentException('${file.uri.pathSegments.last} is not valid JSON.');
    }
  }
}
