import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import 'data/catalog_cache_store.dart';
import 'data/catalog_repository.dart';
import 'data/models/catalog_package.dart';

enum CatalogStatus { idle, loading, ready, error }

/// Holds the catalog state consumed by the Library screen.
///
/// On [load], a cached catalog (if any) is shown immediately while a network
/// refresh happens in the background — so a cold start with no connection
/// still lists packages, per the offline-cache requirement. If the refresh
/// fails after cached packages are already showing, they stay on screen and
/// [isStale] flips on instead of replacing them with a full error screen.
class CatalogController extends ChangeNotifier {
  CatalogController({CatalogRepository? repository, CatalogCacheStore? cacheStore})
    : _repository = repository ?? CatalogRepository(),
      _cacheStore = cacheStore ?? CatalogCacheStore();

  final CatalogRepository _repository;
  final CatalogCacheStore _cacheStore;

  CatalogStatus _status = CatalogStatus.idle;
  List<CatalogPackage> _packages = const [];
  String? _errorMessage;
  DateTime? _lastUpdated;
  bool _isStale = false;
  bool _disposed = false;

  CatalogStatus get status => _status;
  List<CatalogPackage> get packages => _packages;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CatalogStatus.loading;
  DateTime? get lastUpdated => _lastUpdated;

  /// True once a background refresh has failed while cached packages are
  /// still being shown — the list stays up, but it might be out of date.
  bool get isStale => _isStale;

  CatalogRepository get repository => _repository;

  Future<void> load({bool refresh = false}) async {
    if (_status == CatalogStatus.loading) return;

    if (_packages.isEmpty) {
      final cached = await _cacheStore.load();
      if (cached != null && _packages.isEmpty) {
        _packages = cached.response.packages;
        _lastUpdated = cached.cachedAt;
        _status = CatalogStatus.ready;
        _safeNotify();
      }
    }

    _status = _packages.isEmpty ? CatalogStatus.loading : CatalogStatus.ready;
    _errorMessage = null;
    _safeNotify();

    try {
      final catalog = await _repository.fetchCatalog(refresh: refresh);
      _packages = catalog.packages;
      _lastUpdated = DateTime.now();
      _status = CatalogStatus.ready;
      _isStale = false;
      await _cacheStore.save(catalog, _lastUpdated!);
    } on ApiException catch (error) {
      _fail(error.message);
    } catch (_) {
      _fail('Could not load the catalog.');
    }

    _safeNotify();
  }

  void _fail(String message) {
    _errorMessage = message;
    if (_packages.isEmpty) {
      _status = CatalogStatus.error;
    } else {
      // Keep showing what we have; just flag it as possibly out of date.
      _isStale = true;
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repository.dispose();
    super.dispose();
  }
}
