import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_directories.dart';
import 'models/study.dart';

/// Persists user-created studies to disk, so they survive a restart.
class StudyStore {
  StudyStore({DirectoryProvider? rootDirectory})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory;

  static const String indexFileName = 'studies.json';

  final DirectoryProvider _rootDirectory;

  Future<File> _indexFile() async {
    final root = await _rootDirectory();
    if (!await root.exists()) await root.create(recursive: true);
    return File('${root.path}/$indexFileName');
  }

  Future<List<Study>> load() async {
    final file = await _indexFile();
    if (!await file.exists()) return const [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Study.fromJson)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<Study> studies) async {
    final file = await _indexFile();
    final payload = jsonEncode(studies.map((s) => s.toJson()).toList());
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(payload, flush: true);
    await temp.rename(file.path);
  }
}
