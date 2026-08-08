import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_error.dart';
import '../catalog/data/models/catalog_package.dart';
import 'data/installed_package.dart';
import 'data/installed_package_store.dart';
import 'data/package_downloader.dart';
import 'data/package_installer.dart';

enum DownloadState {
  idle,
  downloading,
  verifying,
  installing,
  installed,
  failed,
}

/// Per-package download/install state exposed to the UI.
class PackageDownload {
  const PackageDownload({
    required this.state,
    this.progress,
    this.error,
  });

  const PackageDownload.idle() : this(state: DownloadState.idle);

  final DownloadState state;
  final DownloadProgress? progress;
  final AppError? error;

  bool get isActive =>
      state == DownloadState.downloading ||
      state == DownloadState.verifying ||
      state == DownloadState.installing;
}

/// Drives the download → verify → install pipeline and owns the list of
/// installed packages shown in the Downloads pane.
class DownloadController extends ChangeNotifier {
  DownloadController({
    PackageDownloader? downloader,
    PackageInstaller? installer,
    InstalledPackageStore? store,
  }) : _downloader = downloader ?? PackageDownloader(),
       _installer = installer ?? PackageInstaller(),
       _store = store ?? InstalledPackageStore();

  final PackageDownloader _downloader;
  final PackageInstaller _installer;
  final InstalledPackageStore _store;

  final Map<String, PackageDownload> _downloads = {};
  final Map<String, DownloadCancelToken> _cancelTokens = {};
  List<InstalledPackage> _installed = const [];
  bool _disposed = false;

  List<InstalledPackage> get installedPackages => _installed;

  PackageDownload statusFor(CatalogPackage package) => statusForId(package.id);

  PackageDownload statusForId(String packageId) {
    final status = _downloads[packageId];
    if (status != null) return status;
    if (installedVersionOf(packageId) != null) {
      return const PackageDownload(state: DownloadState.installed);
    }
    return const PackageDownload.idle();
  }

  String? installedVersionOf(String packageId) {
    for (final installed in _installed) {
      if (installed.id == packageId) return installed.version;
    }
    return null;
  }

  /// True when the catalog lists a different version than the one on disk.
  bool hasUpdate(CatalogPackage package) {
    final installedVersion = installedVersionOf(package.id);
    return installedVersion != null && installedVersion != package.version;
  }

  /// Reads the install index from disk. Safe to call on startup.
  Future<void> loadInstalled() async {
    try {
      _installed = await _store.load();
    } on FileSystemException {
      _installed = const [];
    }
    _notify();
  }

  Future<void> start(CatalogPackage package) async {
    if (statusFor(package).isActive) return;

    final cancelToken = DownloadCancelToken();
    _cancelTokens[package.id] = cancelToken;
    _update(package.id, const PackageDownload(state: DownloadState.downloading));

    File? artifact;
    try {
      artifact = await _downloader.download(
        package,
        cancelToken: cancelToken,
        onProgress: (progress) => _update(
          package.id,
          PackageDownload(state: DownloadState.downloading, progress: progress),
        ),
        onVerifying: () => _update(
          package.id,
          const PackageDownload(state: DownloadState.verifying),
        ),
      );

      _update(package.id, const PackageDownload(state: DownloadState.installing));
      final previousMatches = _installed.where(
        (existing) => existing.id == package.id,
      );
      final previous = previousMatches.isEmpty ? null : previousMatches.first;
      final installed = await _installer.install(package, artifact);
      await _rememberInstalled(installed);
      if (previous != null && previous.version != installed.version) {
        // A version bump installs under a new `packages/{id}/{version}`
        // directory; clean up the now-orphaned old one.
        await _installer.uninstall(previous);
      }

      _downloads.remove(package.id);
      _notify();
    } on DownloadCancelledException {
      _downloads.remove(package.id);
      _notify();
    } on ApiException catch (error) {
      _fail(package.id, asAppError(error));
    } on InstallException catch (error) {
      _fail(package.id, asAppError(error));
    } catch (_) {
      _fail(package.id, const AppError(AppErrorKind.installFailed));
    } finally {
      _cancelTokens.remove(package.id);
      // The zip is only needed while installing.
      await _deleteQuietly(artifact);
    }
  }

  void cancel(CatalogPackage package) {
    _cancelTokens[package.id]?.cancel();
  }

  Future<void> uninstall(InstalledPackage package) async {
    // Drop the install-index entry before touching disk: if the app is
    // killed mid-uninstall, the worst case is an orphaned directory (safe to
    // ignore), never a ghost index entry pointing at files that are gone.
    _installed = _installed
        .where((installed) => installed.id != package.id)
        .toList(growable: false);
    await _store.save(_installed);
    await _installer.uninstall(package);
    _downloads.remove(package.id);
    _notify();
  }

  Future<void> _rememberInstalled(InstalledPackage installed) async {
    _installed = [
      ..._installed.where((existing) => existing.id != installed.id),
      installed,
    ];
    await _store.save(_installed);
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nothing to clean up.
    }
  }

  void _fail(String packageId, AppError error) {
    _update(
      packageId,
      PackageDownload(state: DownloadState.failed, error: error),
    );
  }

  void _update(String packageId, PackageDownload status) {
    _downloads[packageId] = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _downloader.close();
    super.dispose();
  }
}
