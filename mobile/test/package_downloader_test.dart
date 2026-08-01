import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bible_memorization_companion_mobile/core/network/api_client.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/models/catalog_package.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/package_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final artifactChunks = <List<int>>[
  List<int>.filled(1024, 1),
  List<int>.filled(1024, 2),
  List<int>.filled(512, 3),
];

final artifactBytes = Uint8List.fromList(artifactChunks.expand((c) => c).toList());
final artifactChecksum = sha256.convert(artifactBytes).toString();

CatalogPackage packageWith({String? checksum}) {
  return CatalogPackage(
    id: 'cb-daniel-1-6',
    title: 'CB Daniel 1-6',
    packageType: CatalogPackageType.book,
    language: 'es',
    version: '1.0.0',
    sizeBytes: artifactBytes.length,
    isFree: true,
    owned: false,
    artifactUrl: 'https://example.test/package.zip',
    manifestUrl: 'https://example.test/manifest.json',
    checksumSha256: checksum ?? artifactChecksum,
    minAppVersion: '1.0.0',
  );
}

/// Serves [artifactChunks] one chunk at a time so progress can be observed.
///
/// The stream is timer-free on purpose: widget tests drive downloads inside
/// `tester.runAsync`, where fake-async timers would never fire.
http.Client chunkedClient({int statusCode = 200}) {
  return MockClient.streaming((request, _) async {
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(artifactChunks),
      statusCode,
      contentLength: artifactBytes.length,
      request: request,
    );
  });
}

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('bmc-test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  PackageDownloader downloaderWith(http.Client client) =>
      PackageDownloader(httpClient: client, downloadDirectory: tempDir);

  test('downloads the artifact, reports progress and verifies the checksum', () async {
    final downloader = downloaderWith(chunkedClient());
    final package = packageWith();
    final fractions = <double?>[];
    var verified = false;

    final file = await downloader.download(
      package,
      onProgress: (progress) => fractions.add(progress.fraction),
      onVerifying: () => verified = true,
    );

    expect(await file.readAsBytes(), artifactBytes);
    expect(file.path, endsWith('cb-daniel-1-6-1.0.0.zip'));
    expect(verified, isTrue);
    expect(fractions.first, 0.0);
    expect(fractions.last, 1.0);
    expect(fractions.length, artifactChunks.length + 1);
    expect(File('${file.path}.part').existsSync(), isFalse);
  });

  test('rejects and deletes an artifact whose checksum does not match', () async {
    final downloader = downloaderWith(chunkedClient());

    await expectLater(
      downloader.download(packageWith(checksum: 'deadbeef')),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('corrupted'),
        ),
      ),
    );

    expect(tempDir.listSync(), isEmpty);
  });

  test('cancelling mid-download leaves no partial file behind', () async {
    final downloader = downloaderWith(chunkedClient());
    final cancelToken = DownloadCancelToken();

    await expectLater(
      downloader.download(
        packageWith(),
        cancelToken: cancelToken,
        onProgress: (_) => cancelToken.cancel(),
      ),
      throwsA(isA<DownloadCancelledException>()),
    );

    expect(tempDir.listSync(), isEmpty);
  });

  test('maps a non-200 response to an ApiException', () async {
    final downloader = downloaderWith(chunkedClient(statusCode: 404));

    await expectLater(
      downloader.download(packageWith()),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
    );
  });

}
