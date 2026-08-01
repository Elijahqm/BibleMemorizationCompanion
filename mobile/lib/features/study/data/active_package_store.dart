import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_directories.dart';

/// Persists the id of the last-opened package, so relaunching the app returns
/// to that package's My Studies screen instead of the "select a package"
/// empty state.
class ActivePackageStore {
  ActivePackageStore({DirectoryProvider? rootDirectory})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory;

  static const String fileName = 'active-package.json';

  final DirectoryProvider _rootDirectory;

  Future<File> _file() async {
    final root = await _rootDirectory();
    if (!await root.exists()) await root.create(recursive: true);
    return File('${root.path}/$fileName');
  }

  Future<String?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return decoded['packageId'] as String?;
    } on FormatException {
      return null;
    }
  }

  Future<void> save(String packageId) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode({'packageId': packageId}), flush: true);
    await temp.rename(file.path);
  }
}
