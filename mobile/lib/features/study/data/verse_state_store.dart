import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_directories.dart';
import 'models/verse_state.dart';

/// Persists per-verse learned/difficult status, keyed by
/// `packageId::verseRef`, so it survives a restart.
class VerseStateStore {
  VerseStateStore({DirectoryProvider? rootDirectory})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory;

  static const String indexFileName = 'verse-states.json';

  final DirectoryProvider _rootDirectory;

  Future<File> _indexFile() async {
    final root = await _rootDirectory();
    if (!await root.exists()) await root.create(recursive: true);
    return File('${root.path}/$indexFileName');
  }

  Future<Map<String, VerseState>> load() async {
    final file = await _indexFile();
    if (!await file.exists()) return const {};

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const {};
      final states = decoded
          .whereType<Map<String, dynamic>>()
          .map(VerseState.fromJson);
      return {for (final state in states) state.key: state};
    } on FormatException {
      return const {};
    }
  }

  Future<void> save(Map<String, VerseState> states) async {
    final file = await _indexFile();
    final payload = jsonEncode(
      states.values.map((s) => s.toJson()).toList(),
    );
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(payload, flush: true);
    await temp.rename(file.path);
  }
}
