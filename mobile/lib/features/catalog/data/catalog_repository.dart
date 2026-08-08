import '../../../core/errors/app_error.dart';
import '../../../core/network/api_client.dart';
import 'models/catalog_package.dart';
import 'models/package_manifest.dart';

/// Reads the backend catalog and package manifests.
///
/// Responses are cached in memory for the lifetime of the app so switching
/// screens does not re-hit the network; `refresh: true` forces a reload.
class CatalogRepository {
  CatalogRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  static const String catalogPath = '/api/v1/catalog';

  final ApiClient _apiClient;
  final Map<String, PackageManifest> _manifestCache = {};
  CatalogResponse? _cachedCatalog;

  Future<CatalogResponse> fetchCatalog({bool refresh = false}) async {
    final cached = _cachedCatalog;
    if (cached != null && !refresh) return cached;

    final json = await _apiClient.getJson(catalogPath);
    final catalog = CatalogResponse.fromJson(json);
    _cachedCatalog = catalog;
    return catalog;
  }

  Future<PackageManifest> fetchManifest(CatalogPackage package) async {
    final cacheKey = '${package.id}@${package.version}';
    final cached = _manifestCache[cacheKey];
    if (cached != null) return cached;

    if (package.manifestUrl.isEmpty) {
      throw const ApiException(AppErrorKind.generic);
    }

    final json = await _apiClient.getJson(package.manifestUrl);
    final manifest = PackageManifest.fromJson(json);
    _manifestCache[cacheKey] = manifest;
    return manifest;
  }

  void dispose() => _apiClient.close();
}
