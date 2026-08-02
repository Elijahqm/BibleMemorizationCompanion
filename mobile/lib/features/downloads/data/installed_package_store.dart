import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_directories.dart';
import 'installed_package.dart';

/// Persists which packages are installed, so the Downloads pane survives a
/// restart. A single JSON file is enough at this stage; a database can replace
/// it later behind the same API.
class InstalledPackageStore {
  InstalledPackageStore({DirectoryProvider? rootDirectory})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory;

  static const String indexFileName = 'installed-packages.json';

  final DirectoryProvider _rootDirectory;

  Future<File> _indexFile() async {
    final root = await _rootDirectory();
    if (!await root.exists()) await root.create(recursive: true);
    return File('${root.path}/$indexFileName');
  }

  Future<List<InstalledPackage>> load() async {
    final file = await _indexFile();
    if (!await file.exists()) return const [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(InstalledPackage.fromJson)
          .toList(growable: false);
    } on FormatException {
      // A corrupted index should not brick the library; start from scratch.
      return const [];
    }
  }

  Future<void> save(List<InstalledPackage> packages) async {
    final file = await _indexFile();
    final payload = jsonEncode(packages.map((p) => p.toJson()).toList());
    // Write to a temp file first so an interrupted write cannot truncate the
    // existing index.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(payload, flush: true);
    await temp.rename(file.path);
  }
}
