import 'dart:io';

import 'package:bible_memorization_companion_mobile/core/network/api_client.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/catalog_controller.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/catalog_cache_store.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'catalog_repository_test.dart' show catalogJson;

CatalogRepository _repositoryReturning(http.Response Function() respond) {
  return CatalogRepository(
    apiClient: ApiClient(httpClient: MockClient((_) async => respond())),
  );
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('bmc-catalog-cache'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<Directory> rootProvider() async => root;
  CatalogCacheStore cacheStore() => CatalogCacheStore(rootDirectory: rootProvider);

  test('a cold start with no cache and a failing network shows an error', () async {
    final controller = CatalogController(
      repository: _repositoryReturning(() => http.Response('boom', 500)),
      cacheStore: cacheStore(),
    );

    await controller.load();

    expect(controller.status, CatalogStatus.error);
    expect(controller.packages, isEmpty);
  });

  test('a successful load persists the catalog to disk', () async {
    final controller = CatalogController(
      repository: _repositoryReturning(() => http.Response(catalogJson, 200)),
      cacheStore: cacheStore(),
    );

    await controller.load();

    expect(controller.status, CatalogStatus.ready);
    expect(controller.packages, hasLength(1));
    expect(controller.lastUpdated, isNotNull);
    expect(controller.isStale, isFalse);

    final cached = await cacheStore().load();
    expect(cached, isNotNull);
    expect(cached!.response.packages.single.id, 'cb-hechos-1-9');
  });

  test('a cold start with no network still lists the previously cached packages', () async {
    // Simulates the app having successfully fetched the catalog once before.
    await CatalogController(
      repository: _repositoryReturning(() => http.Response(catalogJson, 200)),
      cacheStore: cacheStore(),
    ).load();

    // A fresh controller (as if the app were relaunched) with no network.
    final offlineController = CatalogController(
      repository: _repositoryReturning(() => http.Response('boom', 500)),
      cacheStore: cacheStore(),
    );
    await offlineController.load();

    expect(offlineController.status, CatalogStatus.ready);
    expect(offlineController.packages, hasLength(1));
    expect(offlineController.isStale, isTrue);
    expect(offlineController.error, isNotNull);
  });
}
