import 'package:bible_memorization_companion_mobile/core/network/api_client.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/catalog_repository.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/models/catalog_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const catalogJson = '''
{
  "catalogVersion": "1",
  "publishedAt": "2026-07-22T00:00:00+00:00",
  "packages": [
    {
      "id": "cb-hechos-1-9",
      "title": "CB Hechos 1-9",
      "packageType": "book",
      "language": "es",
      "version": "1.0.0",
      "sizeBytes": 27679,
      "isFree": true,
      "price": null,
      "owned": false,
      "artifactUrl": "https://example.test/package.zip",
      "manifestUrl": "https://example.test/manifest.json",
      "checksumSha256": "abc",
      "minAppVersion": "1.0.0",
      "basePackageId": null
    }
  ]
}
''';

const manifestJson = '''
{
  "packageId": "cb-hechos-1-9",
  "title": "CB Hechos 1-9",
  "version": "1.0.0",
  "language": "es",
  "attribution": "REINA-VALERA 1960",
  "verseCount": 336,
  "chapterCount": 9,
  "files": [
    {
      "path": "content/chapters/001.json",
      "sizeBytes": 5920,
      "checksumSha256": "def",
      "required": true
    }
  ]
}
''';

void main() {
  test('parses the catalog payload and caches it', () async {
    var calls = 0;
    final repository = CatalogRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        httpClient: MockClient((request) async {
          calls++;
          expect(request.url.path, CatalogRepository.catalogPath);
          return http.Response(catalogJson, 200);
        }),
      ),
    );

    final catalog = await repository.fetchCatalog();
    expect(catalog.packages, hasLength(1));

    final package = catalog.packages.single;
    expect(package.id, 'cb-hechos-1-9');
    expect(package.packageType, CatalogPackageType.book);
    expect(package.isFree, isTrue);
    expect(package.isDownloadable, isTrue);
    expect(package.sizeLabel, '27 KB');

    await repository.fetchCatalog();
    expect(calls, 1, reason: 'second read should hit the in-memory cache');

    await repository.fetchCatalog(refresh: true);
    expect(calls, 2);
  });

  test('parses a package manifest from its absolute URL', () async {
    final repository = CatalogRepository(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('manifest.json')) {
            return http.Response(manifestJson, 200);
          }
          return http.Response(catalogJson, 200);
        }),
      ),
    );

    final catalog = await repository.fetchCatalog();
    final manifest = await repository.fetchManifest(catalog.packages.single);

    expect(manifest.verseCount, 336);
    expect(manifest.chapterCount, 9);
    expect(manifest.attribution, 'REINA-VALERA 1960');
    expect(manifest.files, hasLength(1));
  });

  test('maps a failing response to an ApiException', () async {
    final repository = CatalogRepository(
      apiClient: ApiClient(
        httpClient: MockClient((_) async => http.Response('nope', 500)),
      ),
    );

    expect(
      () => repository.fetchCatalog(),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
      ),
    );
  });
}
