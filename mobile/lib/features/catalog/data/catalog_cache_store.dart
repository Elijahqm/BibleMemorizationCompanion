import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_directories.dart';
import 'models/catalog_package.dart';

/// A catalog response as it was last successfully fetched, plus when.
class CachedCatalog {
  const CachedCatalog({required this.response, required this.cachedAt});

  final CatalogResponse response;
  final DateTime cachedAt;
}

/// Persists the last successful catalog fetch so the Store list can render
/// immediately on a cold start before the network round-trip finishes (or
/// even if it never does, e.g. offline).
class CatalogCacheStore {
  CatalogCacheStore({DirectoryProvider? rootDirectory})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory;

  static const String fileName = 'catalog-cache.json';

  final DirectoryProvider _rootDirectory;

  Future<CachedCatalog?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;

      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      final responseJson = decoded['response'];
      if (cachedAt == null || responseJson is! Map<String, dynamic>) {
        return null;
      }

      return CachedCatalog(
        response: CatalogResponse.fromJson(responseJson),
        cachedAt: cachedAt,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(CatalogResponse response, DateTime cachedAt) async {
    final file = await _file();
    final staging = File('${file.path}.tmp');
    await staging.writeAsString(
      jsonEncode({
        'cachedAt': cachedAt.toIso8601String(),
        'response': response.toJson(),
      }),
      flush: true,
    );
    await staging.rename(file.path);
  }

  Future<File> _file() async {
    final root = await _rootDirectory();
    if (!await root.exists()) await root.create(recursive: true);
    return File('${root.path}/$fileName');
  }
}
