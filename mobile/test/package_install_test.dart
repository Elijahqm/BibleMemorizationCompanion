import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bible_memorization_companion_mobile/core/errors/app_error.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/models/catalog_package.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/installed_package.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/installed_package_store.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/package_installer.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/download_controller.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/package_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final chapterBytes = utf8.encode('{"chapter":1,"verses":[]}');
final indexBytes = utf8.encode('{"packageId":"cb-daniel-1-6"}');

/// Builds a package zip; [corruptChapter] writes content that no longer matches
/// the checksum declared in the manifest.
Uint8List buildZip({bool corruptChapter = false, bool unsafePath = false}) {
  final manifest = {
    'packageId': 'cb-daniel-1-6',
    'title': 'CB Daniel 1-6',
    'version': '1.0.0',
    'language': 'es',
    'attribution': 'REINA-VALERA 1960',
    'verseCount': 196,
    'chapterCount': 6,
    'files': [
      {
        'path': 'content/chapters/001.json',
        'sizeBytes': chapterBytes.length,
        'checksumSha256': sha256.convert(chapterBytes).toString(),
        'required': true,
      },
      {
        'path': 'content/index.json',
        'sizeBytes': indexBytes.length,
        'checksumSha256': sha256.convert(indexBytes).toString(),
        'required': true,
      },
    ],
  };

  final manifestBytes = utf8.encode(jsonEncode(manifest));
  final chapter = corruptChapter ? utf8.encode('tampered') : chapterBytes;

  final archive = Archive()
    ..addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    )
    ..addFile(
      ArchiveFile(
        unsafePath ? '../escaped.json' : 'content/chapters/001.json',
        chapter.length,
        chapter,
      ),
    )
    ..addFile(
      ArchiveFile('content/index.json', indexBytes.length, indexBytes),
    );

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

CatalogPackage packageFor(Uint8List zip, {String version = '1.0.0', String minAppVersion = '1.0.0'}) {
  return CatalogPackage(
    id: 'cb-daniel-1-6',
    title: 'CB Daniel 1-6',
    packageType: CatalogPackageType.book,
    language: 'es',
    version: version,
    sizeBytes: zip.length,
    isFree: true,
    owned: false,
    artifactUrl: 'https://example.test/package.zip',
    manifestUrl: 'https://example.test/manifest.json',
    checksumSha256: sha256.convert(zip).toString(),
    minAppVersion: minAppVersion,
  );
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('bmc-install'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<Directory> rootProvider() async => root;

  File artifactFile(Uint8List bytes) {
    final file = File('${root.path}/artifact.zip');
    file.writeAsBytesSync(bytes);
    return file;
  }

  test('installs a package and verifies every manifest file', () async {
    final zip = buildZip();
    final installer = PackageInstaller(rootDirectory: rootProvider);

    final installed = await installer.install(
      packageFor(zip),
      artifactFile(zip),
    );

    expect(installed.id, 'cb-daniel-1-6');
    expect(installed.attribution, 'REINA-VALERA 1960');
    expect(installed.verseCount, 196);
    expect(
      File('${installed.directoryPath}/content/chapters/001.json').existsSync(),
      isTrue,
    );
    expect(
      Directory('${installed.directoryPath}.tmp').existsSync(),
      isFalse,
      reason: 'the staging directory must be gone after a successful install',
    );
  });

  test('rejects a package whose content fails its checksum', () async {
    final zip = buildZip(corruptChapter: true);
    final installer = PackageInstaller(rootDirectory: rootProvider);

    await expectLater(
      installer.install(packageFor(zip), artifactFile(zip)),
      throwsA(isA<InstallException>()),
    );

    final target = await installer.directoryFor('cb-daniel-1-6', '1.0.0');
    expect(target.existsSync(), isFalse);
    expect(Directory('${target.path}.tmp').existsSync(), isFalse);
  });

  test('rejects archive entries that escape the target directory', () async {
    final zip = buildZip(unsafePath: true);
    final installer = PackageInstaller(rootDirectory: rootProvider);

    await expectLater(
      installer.install(packageFor(zip), artifactFile(zip)),
      throwsA(
        isA<InstallException>().having(
          (e) => e.kind,
          'kind',
          AppErrorKind.unsafePath,
        ),
      ),
    );
    expect(File('${root.path}/packages/escaped.json').existsSync(), isFalse);
  });

  test('the install index round-trips through disk', () async {
    final store = InstalledPackageStore(rootDirectory: rootProvider);
    expect(await store.load(), isEmpty);

    await store.save([
      InstalledPackage(
        id: 'cb-daniel-1-6',
        title: 'CB Daniel 1-6',
        version: '1.0.0',
        language: 'es',
        packageType: CatalogPackageType.book,
        sizeBytes: 17787,
        attribution: 'REINA-VALERA 1960',
        verseCount: 196,
        chapterCount: 6,
        installedAt: DateTime.utc(2026, 7, 31),
        directoryPath: '${root.path}/packages/cb-daniel-1-6/1.0.0',
      ),
    ]);

    final reloaded = await InstalledPackageStore(
      rootDirectory: rootProvider,
    ).load();
    expect(reloaded, hasLength(1));
    expect(reloaded.single.title, 'CB Daniel 1-6');
    expect(reloaded.single.chapterCount, 6);
  });

  group('DownloadController', () {
    late Uint8List zip;
    late CatalogPackage package;

    setUp(() {
      zip = buildZip();
      package = packageFor(zip);
    });

    DownloadController controllerServing(Uint8List bytes, {int status = 200}) {
      return DownloadController(
        downloader: PackageDownloader(
          downloadDirectory: Directory('${root.path}/downloads'),
          httpClient: MockClient.streaming(
            (request, _) async => http.StreamedResponse(
              Stream<List<int>>.fromIterable([bytes]),
              status,
              contentLength: bytes.length,
              request: request,
            ),
          ),
        ),
        installer: PackageInstaller(rootDirectory: rootProvider),
        store: InstalledPackageStore(rootDirectory: rootProvider),
      );
    }

    test('downloads, installs and remembers the package', () async {
      final controller = controllerServing(zip);
      final states = <DownloadState>[];
      controller.addListener(
        () => states.add(controller.statusFor(package).state),
      );

      await controller.start(package);

      expect(states.first, DownloadState.downloading);
      expect(states, containsAll([DownloadState.verifying, DownloadState.installing]));
      expect(controller.statusFor(package).state, DownloadState.installed);
      expect(controller.installedPackages, hasLength(1));

      // A fresh controller reads the same index back from disk.
      final restarted = controllerServing(zip);
      await restarted.loadInstalled();
      expect(restarted.installedVersionOf('cb-daniel-1-6'), '1.0.0');
      expect(restarted.statusFor(package).state, DownloadState.installed);
    });

    test('deletes the artifact once the package is installed', () async {
      final controller = controllerServing(zip);
      await controller.start(package);

      final downloads = Directory('${root.path}/downloads');
      expect(
        downloads.existsSync() ? downloads.listSync() : const [],
        isEmpty,
      );
    });

    test('reports a failed install without leaving an entry behind', () async {
      final broken = buildZip(corruptChapter: true);
      final controller = controllerServing(broken);

      await controller.start(packageFor(broken));

      expect(controller.statusForId('cb-daniel-1-6').state, DownloadState.failed);
      expect(controller.installedPackages, isEmpty);
    });

    test('hasUpdate flags a newer catalog version and reinstall cleans up the old one', () async {
      final controller = controllerServing(zip);
      await controller.start(package);

      final bumped = packageFor(zip, version: '1.0.1');
      expect(controller.hasUpdate(bumped), isTrue);
      expect(controller.hasUpdate(package), isFalse);

      final oldDirectory = Directory(controller.installedPackages.single.directoryPath);
      await controller.start(bumped);

      expect(controller.installedVersionOf('cb-daniel-1-6'), '1.0.1');
      expect(controller.hasUpdate(bumped), isFalse);
      expect(oldDirectory.existsSync(), isFalse);
    });

    test('uninstall removes the files and the index entry', () async {
      final controller = controllerServing(zip);
      await controller.start(package);

      final installed = controller.installedPackages.single;
      await controller.uninstall(installed);

      expect(Directory(installed.directoryPath).existsSync(), isFalse);
      expect(controller.installedPackages, isEmpty);
      expect(controller.statusFor(package).state, DownloadState.idle);
    });
  });
}
