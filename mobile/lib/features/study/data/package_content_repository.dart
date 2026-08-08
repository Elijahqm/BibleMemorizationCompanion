import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/storage/app_directories.dart';
import '../../downloads/data/installed_package.dart';
import 'models/package_content.dart';

/// Reads the study content of an installed package from local storage.
///
/// Packages are small (tens of KB), so the whole book is loaded and cached in
/// memory the first time it is opened.
class PackageContentRepository {
  PackageContentRepository({DirectoryProvider? rootDirectory})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory;

  final DirectoryProvider _rootDirectory;
  final Map<String, PackageContent> _cache = {};

  Future<PackageContent> load(InstalledPackage package) async {
    final cacheKey = '${package.id}@${package.version}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final root = await _resolveRoot(package);
    if (root == null) {
      throw ContentException(
        AppErrorKind.contentNotFound,
        params: [package.title],
      );
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

  /// The persisted `directoryPath` can go stale (e.g. the app-support path
  /// changes between launches on some devices), even though the install
  /// index and the actual files are otherwise intact. Before giving up, also
  /// try the canonical `packages/{id}/{version}` layout under the *current*
  /// app-support root — the same layout `PackageInstaller` writes to.
  Future<Directory?> _resolveRoot(InstalledPackage package) async {
    final stored = Directory(package.directoryPath);
    if (await stored.exists()) return stored;

    final appRoot = await _rootDirectory();
    final canonical = Directory(
      '${appRoot.path}/packages/${package.id}/${package.version}',
    );
    if (await canonical.exists()) return canonical;

    debugPrint(
      'PackageContentRepository: "${package.id}" not found.\n'
      '  stored directoryPath: ${package.directoryPath} '
      '(exists: ${await stored.exists()})\n'
      '  canonical path: ${canonical.path} (exists: ${await canonical.exists()})\n'
      '  app-support root: ${appRoot.path} (exists: ${await appRoot.exists()})',
    );
    return null;
  }

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
      throw ContentException(
        AppErrorKind.contentFileMissing,
        params: [file.uri.pathSegments.last],
      );
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw ContentException(
          AppErrorKind.contentMalformed,
          params: [file.uri.pathSegments.last],
        );
      }
      return decoded;
    } on FormatException {
      throw ContentException(
        AppErrorKind.contentInvalidJson,
        params: [file.uri.pathSegments.last],
      );
    }
  }
}
