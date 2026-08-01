import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import 'data/catalog_repository.dart';
import 'data/models/catalog_package.dart';

enum CatalogStatus { idle, loading, ready, error }

/// Holds the catalog state consumed by the Library screen.
class CatalogController extends ChangeNotifier {
  CatalogController({CatalogRepository? repository})
    : _repository = repository ?? CatalogRepository();

  final CatalogRepository _repository;

  CatalogStatus _status = CatalogStatus.idle;
  List<CatalogPackage> _packages = const [];
  String? _errorMessage;
  bool _disposed = false;

  CatalogStatus get status => _status;
  List<CatalogPackage> get packages => _packages;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CatalogStatus.loading;

  CatalogRepository get repository => _repository;

  Future<void> load({bool refresh = false}) async {
    if (_status == CatalogStatus.loading) return;

    _status = CatalogStatus.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final catalog = await _repository.fetchCatalog(refresh: refresh);
      _packages = catalog.packages;
      _status = CatalogStatus.ready;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = CatalogStatus.error;
    } catch (_) {
      _errorMessage = 'Could not load the catalog.';
      _status = CatalogStatus.error;
    }

    _safeNotify();
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
