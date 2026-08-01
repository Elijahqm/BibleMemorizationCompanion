import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../../core/storage/app_directories.dart';
import '../../catalog/data/models/catalog_package.dart';
import '../../catalog/data/models/package_manifest.dart';
import 'installed_package.dart';

/// Raised when a verified artifact cannot be unpacked into a usable package.
class InstallException implements Exception {
  const InstallException(this.message);

  final String message;

  @override
  String toString() => 'InstallException: $message';
}

/// Unzips a downloaded artifact into the app's private storage.
///
/// The archive is expanded into `{version}.tmp` and only renamed to its final
/// `{version}` directory once every file listed in `manifest.json` matches its
/// checksum, so a half-written install is never visible to the rest of the app.
class PackageInstaller {
  PackageInstaller({DirectoryProvider? rootDirectory, DateTime Function()? now})
    : _rootDirectory = rootDirectory ?? defaultAppDirectory,
      _now = now ?? DateTime.now;

  static const String manifestEntry = 'manifest.json';

  final DirectoryProvider _rootDirectory;
  final DateTime Function() _now;

  Future<Directory> packagesDirectory() async {
    final root = await _rootDirectory();
    final directory = Directory('${root.path}/packages');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> directoryFor(String packageId, String version) async {
    final packages = await packagesDirectory();
    return Directory('${packages.path}/$packageId/$version');
  }

  /// Installs [artifact] (an already checksum-verified zip) for [package].
  Future<InstalledPackage> install(
    CatalogPackage package,
    File artifact,
  ) async {
    final archive = _decode(artifact);
    final manifest = _readManifest(archive);

    final target = await directoryFor(package.id, package.version);
    final staging = Directory('${target.path}.tmp');
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      await _extract(archive, staging);
      await _verifyFiles(manifest, staging);

      if (await target.exists()) await target.delete(recursive: true);
      await staging.rename(target.path);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }

    return InstalledPackage.fromParts(
      package: package,
      manifest: manifest,
      installedAt: _now(),
      directoryPath: target.path,
    );
  }

  Future<void> uninstall(InstalledPackage package) async {
    final directory = await directoryFor(package.id, package.version);
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Archive _decode(File artifact) {
    try {
      return ZipDecoder().decodeBytes(artifact.readAsBytesSync());
    } catch (_) {
      throw const InstallException('The package archive could not be opened.');
    }
  }

  PackageManifest _readManifest(Archive archive) {
    final entry = archive.files.where((file) => file.name == manifestEntry);
    if (entry.isEmpty) {
      throw const InstallException('The package has no manifest.json.');
    }
    try {
      final decoded = jsonDecode(
        utf8.decode(entry.first.content as List<int>),
      );
      return PackageManifest.fromJson(decoded as Map<String, dynamic>);
    } catch (_) {
      throw const InstallException('The package manifest is invalid.');
    }
  }

  Future<void> _extract(Archive archive, Directory staging) async {
    for (final entry in archive.files) {
      if (!entry.isFile) continue;

      final relativePath = _safeRelativePath(entry.name);
      final file = File('${staging.path}/$relativePath');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.content as List<int>, flush: true);
    }
  }

  /// Rejects absolute paths and `..` segments so a malicious archive cannot
  /// write outside the staging directory (zip-slip).
  String _safeRelativePath(String name) {
    final normalized = name.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (normalized.startsWith('/') || segments.contains('..')) {
      throw InstallException('The package contains an unsafe path: $name');
    }
    return normalized;
  }

  Future<void> _verifyFiles(PackageManifest manifest, Directory staging) async {
    for (final entry in manifest.files) {
      final file = File('${staging.path}/${_safeRelativePath(entry.path)}');

      if (!await file.exists()) {
        if (!entry.required) continue;
        throw InstallException('The package is missing ${entry.path}.');
      }

      final bytes = await file.readAsBytes();
      if (entry.sizeBytes > 0 && bytes.length != entry.sizeBytes) {
        throw InstallException('${entry.path} has an unexpected size.');
      }
      if (entry.checksumSha256.isNotEmpty &&
          sha256.convert(bytes).toString() !=
              entry.checksumSha256.toLowerCase()) {
        throw InstallException('${entry.path} failed its checksum check.');
      }
    }
  }
}
