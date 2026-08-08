import 'dart:async';
import 'dart:io';

import 'package:bible_memorization_companion_mobile/core/network/api_client.dart';
import 'package:bible_memorization_companion_mobile/core/theme/app_theme.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/catalog_controller.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/catalog_cache_store.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/catalog_repository.dart';
import 'package:bible_memorization_companion_mobile/features/catalog/data/models/catalog_package.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/installed_package.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/installed_package_store.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/package_downloader.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/data/package_installer.dart';
import 'package:bible_memorization_companion_mobile/features/downloads/download_controller.dart';
import 'package:bible_memorization_companion_mobile/features/shell/app_shell.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/active_package_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/package_content.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/study.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/models/verse_state.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/package_content_repository.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/study_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/data/verse_state_store.dart';
import 'package:bible_memorization_companion_mobile/features/study/study_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'catalog_repository_test.dart' show catalogJson;

/// Catalog cache kept in memory — the real store hits path_provider, which
/// widget tests don't mock.
class _MemoryCatalogCacheStore implements CatalogCacheStore {
  CachedCatalog? _cached;

  @override
  Future<CachedCatalog?> load() async => _cached;

  @override
  Future<void> save(CatalogResponse response, DateTime cachedAt) async {
    _cached = CachedCatalog(response: response, cachedAt: cachedAt);
  }
}

CatalogController _controllerReturning(http.Response Function() respond) {
  return CatalogController(
    repository: CatalogRepository(
      apiClient: ApiClient(httpClient: MockClient((_) async => respond())),
    ),
    cacheStore: _MemoryCatalogCacheStore(),
  );
}

/// Downloader whose progress and completion are driven by the test.
class _ScriptedDownloader implements PackageDownloader {
  final _completer = Completer<File>();
  void Function(DownloadProgress)? _onProgress;
  void Function()? _onVerifying;

  void emitProgress(DownloadProgress progress) => _onProgress?.call(progress);

  void complete() {
    _onVerifying?.call();
    _completer.complete(File('artifact.zip'));
  }

  @override
  Future<File> download(
    CatalogPackage package, {
    void Function(DownloadProgress progress)? onProgress,
    void Function()? onVerifying,
    DownloadCancelToken? cancelToken,
  }) {
    _onProgress = onProgress;
    _onVerifying = onVerifying;
    return _completer.future;
  }

  @override
  String fileNameFor(CatalogPackage package) => 'artifact.zip';

  @override
  Future<Directory> resolveDirectory() async => Directory.systemTemp;

  @override
  void close() {}
}

/// Installer that succeeds immediately without touching the filesystem.
class _ScriptedInstaller implements PackageInstaller {
  @override
  Future<InstalledPackage> install(CatalogPackage package, File artifact) async {
    return InstalledPackage(
      id: package.id,
      title: package.title,
      version: package.version,
      language: package.language,
      packageType: package.packageType,
      sizeBytes: package.sizeBytes,
      attribution: 'REINA-VALERA 1960',
      verseCount: 336,
      chapterCount: 9,
      installedAt: DateTime.utc(2026, 7, 31),
      directoryPath: '/packages/${package.id}/${package.version}',
    );
  }

  @override
  Future<void> uninstall(InstalledPackage package) async {}

  @override
  Future<Directory> packagesDirectory() async => Directory.systemTemp;

  @override
  Future<Directory> directoryFor(String packageId, String version) async =>
      Directory.systemTemp;
}

/// Install index kept in memory for widget tests.
class _MemoryStore implements InstalledPackageStore {
  List<InstalledPackage> _packages = const [];

  @override
  Future<List<InstalledPackage>> load() async => _packages;

  @override
  Future<void> save(List<InstalledPackage> packages) async =>
      _packages = packages;
}

/// Install index that starts pre-populated, for tests that need an installed
/// package present as soon as the shell loads.
class _PreloadedStore implements InstalledPackageStore {
  _PreloadedStore(this._packages);

  List<InstalledPackage> _packages;

  @override
  Future<List<InstalledPackage>> load() async => _packages;

  @override
  Future<void> save(List<InstalledPackage> packages) async =>
      _packages = packages;
}

/// Content repository that always returns the same, prebuilt content.
class _FakeContentRepository implements PackageContentRepository {
  _FakeContentRepository(this._content);

  final PackageContent _content;

  @override
  Future<PackageContent> load(InstalledPackage package) async => _content;

  @override
  void evict(InstalledPackage package) {}
}

/// In-memory StudyStore/VerseStateStore/ActivePackageStore, so StudyController
/// can be exercised in widget tests without touching the filesystem.
class _MemoryStudyStore implements StudyStore {
  List<Study> _studies = const [];

  @override
  Future<List<Study>> load() async => _studies;

  @override
  Future<void> save(List<Study> studies) async => _studies = studies;
}

class _MemoryVerseStateStore implements VerseStateStore {
  Map<String, VerseState> _states = const {};

  @override
  Future<Map<String, VerseState>> load() async => _states;

  @override
  Future<void> save(Map<String, VerseState> states) async => _states = states;
}

class _MemoryActivePackageStore implements ActivePackageStore {
  String? _packageId;

  @override
  Future<String?> load() async => _packageId;

  @override
  Future<void> save(String packageId) async => _packageId = packageId;
}

StudyController _newStudyController() => StudyController(
  studyStore: _MemoryStudyStore(),
  verseStateStore: _MemoryVerseStateStore(),
  activePackageStore: _MemoryActivePackageStore(),
);

Widget _wrap(
  CatalogController controller, {
  DownloadController? downloads,
  PackageContentRepository? content,
  StudyController? studies,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: AppShell(
      catalogController: controller,
      downloadController: downloads,
      contentRepository: content,
      studyController: studies,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('app shell renders primary navigation', (tester) async {
    await tester.pumpWidget(
      _wrap(_controllerReturning(() => http.Response(catalogJson, 200))),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Studies'), findsOneWidget);
    expect(find.text('Library'), findsAtLeastNWidgets(1));
    expect(find.text('Progress'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsAtLeastNWidgets(1));
  });

  testWidgets('library store pane lists packages from the catalog API', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_controllerReturning(() => http.Response(catalogJson, 200))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();

    expect(find.text('CB Hechos 1-9'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('My Studies prompts to pick a package before any is opened', (
    tester,
  ) async {
    final installed = InstalledPackage(
      id: 'cb-hechos-1-9',
      title: 'CB Hechos 1-9',
      version: '1.0.0',
      language: 'es',
      packageType: CatalogPackageType.book,
      sizeBytes: 27679,
      attribution: 'REINA-VALERA 1960',
      verseCount: 1,
      chapterCount: 1,
      installedAt: DateTime.utc(2026, 7, 31),
      directoryPath: '/packages/cb-hechos-1-9/1.0.0',
    );

    await tester.pumpWidget(
      _wrap(
        _controllerReturning(() => http.Response(catalogJson, 200)),
        downloads: DownloadController(store: _PreloadedStore([installed])),
        studies: _newStudyController(),
      ),
    );
    await tester.pumpAndSettle();

    // No package has been opened yet, so studies are never auto-listed.
    expect(find.text('Select a package to get started'), findsOneWidget);
    expect(find.text('Pentecostés'), findsNothing);
    expect(find.text('Create study'), findsNothing);

    await tester.tap(find.text('Go to Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(find.text('CB Hechos 1-9'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
    'opening a package with no studies shows only the Create study CTA',
    (tester) async {
      final installed = InstalledPackage(
        id: 'cb-hechos-1-9',
        title: 'CB Hechos 1-9',
        version: '1.0.0',
        language: 'es',
        packageType: CatalogPackageType.book,
        sizeBytes: 27679,
        attribution: 'REINA-VALERA 1960',
        verseCount: 1,
        chapterCount: 1,
        installedAt: DateTime.utc(2026, 7, 31),
        directoryPath: '/packages/cb-hechos-1-9/1.0.0',
      );

      await tester.pumpWidget(
        _wrap(
          _controllerReturning(() => http.Response(catalogJson, 200)),
          downloads: DownloadController(store: _PreloadedStore([installed])),
          studies: _newStudyController(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Downloads'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('CB Hechos 1-9'), findsOneWidget);
      expect(find.text('No studies yet'), findsOneWidget);
      expect(find.text('Create study'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a study by section and marking a verse learned updates progress',
    (tester) async {
      final installed = InstalledPackage(
        id: 'cb-hechos-1-9',
        title: 'CB Hechos 1-9',
        version: '1.0.0',
        language: 'es',
        packageType: CatalogPackageType.book,
        sizeBytes: 27679,
        attribution: 'REINA-VALERA 1960',
        verseCount: 1,
        chapterCount: 1,
        installedAt: DateTime.utc(2026, 7, 31),
        directoryPath: '/packages/cb-hechos-1-9/1.0.0',
      );

      const section = ContentSection(
        sectionId: 'pentecostes',
        title: 'Pentecostés',
        startVerseRef: 'Hechos 2:1',
        endVerseRef: 'Hechos 2:1',
        verseRefs: ['Hechos 2:1'],
      );
      const verse = Verse(
        verseRef: 'Hechos 2:1',
        verseNumber: 1,
        text:
            '[[section:pentecostes|Pentecostés]] Cuando llegó el día de '
            'Pentecostés.',
      );
      final content = PackageContent(
        packageId: installed.id,
        title: installed.title,
        index: const PackageIndex(
          packageId: 'cb-hechos-1-9',
          abbreviation: 'Hch',
          attribution: 'REINA-VALERA 1960',
          chapterOrder: [1],
          chapterVerseCounts: {1: 1},
          availableSections: true,
        ),
        sections: const [section],
        versesByRef: const {'Hechos 2:1': verse},
        versesByChapter: const {
          1: [verse],
        },
      );

      final studies = _newStudyController();

      await tester.pumpWidget(
        _wrap(
          _controllerReturning(() => http.Response(catalogJson, 200)),
          downloads: DownloadController(store: _PreloadedStore([installed])),
          content: _FakeContentRepository(content),
          studies: studies,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Downloads'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create study'));
      await tester.pumpAndSettle();

      expect(find.text('By chapter'), findsOneWidget);
      expect(find.text('By section'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      await tester.tap(find.text('By section'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pentecostés'));
      await tester.pumpAndSettle();

      // Creating the study replaced Create study with the verse screen.
      expect(find.text('Hechos 2:1'), findsOneWidget);
      await tester.tap(find.byType(Card).first);
      await tester.pump();
      expect(find.textContaining('Cuando llegó el día'), findsOneWidget);

      await tester.tap(find.byTooltip('Learned'));
      await tester.pump();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Pentecostés'), findsOneWidget);
      expect(find.text('1 of 1 learned'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
    },
  );

  testWidgets('downloading a package shows progress and a verified result', (
    tester,
  ) async {
    // A scripted downloader keeps the widget test free of real I/O; the real
    // downloader is covered by package_downloader_test.dart.
    final downloader = _ScriptedDownloader();
    final downloads = DownloadController(
      downloader: downloader,
      installer: _ScriptedInstaller(),
      store: _MemoryStore(),
    );

    await tester.pumpWidget(
      _wrap(
        _controllerReturning(() => http.Response(catalogJson, 200)),
        downloads: downloads,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download'));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    downloader.emitProgress(const DownloadProgress(received: 50, total: 100));
    await tester.pump();
    expect(find.text('Downloading 50%'), findsOneWidget);

    downloader.complete();
    await tester.pumpAndSettle();
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);

    // The installed package now shows up in the Downloads pane.
    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(find.text('CB Hechos 1-9'), findsOneWidget);
    expect(find.text('9 chapters'), findsOneWidget);
  });

  testWidgets('library shows an error state with retry when the API fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_controllerReturning(() => http.Response('boom', 500))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();

    expect(find.text('Could not load the catalog'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
