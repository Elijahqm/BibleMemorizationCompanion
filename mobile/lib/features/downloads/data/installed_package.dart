import '../../catalog/data/models/catalog_package.dart';
import '../../catalog/data/models/package_manifest.dart';

/// A package that has been downloaded, verified and unzipped on this device.
class InstalledPackage {
  const InstalledPackage({
    required this.id,
    required this.title,
    required this.version,
    required this.language,
    required this.packageType,
    required this.sizeBytes,
    required this.attribution,
    required this.verseCount,
    required this.chapterCount,
    required this.installedAt,
    required this.directoryPath,
  });

  factory InstalledPackage.fromParts({
    required CatalogPackage package,
    required PackageManifest manifest,
    required DateTime installedAt,
    required String directoryPath,
  }) {
    return InstalledPackage(
      id: package.id,
      title: package.title,
      version: package.version,
      language: package.language,
      packageType: package.packageType,
      sizeBytes: package.sizeBytes,
      attribution: manifest.attribution,
      verseCount: manifest.verseCount,
      chapterCount: manifest.chapterCount,
      installedAt: installedAt,
      directoryPath: directoryPath,
    );
  }

  factory InstalledPackage.fromJson(Map<String, dynamic> json) {
    return InstalledPackage(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['id'] as String,
      version: json['version'] as String? ?? '1.0.0',
      language: json['language'] as String? ?? 'en',
      packageType: CatalogPackageType.parse(json['packageType'] as String?),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      attribution: json['attribution'] as String? ?? '',
      verseCount: (json['verseCount'] as num?)?.toInt() ?? 0,
      chapterCount: (json['chapterCount'] as num?)?.toInt() ?? 0,
      installedAt:
          DateTime.tryParse(json['installedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      directoryPath: json['directoryPath'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final String version;
  final String language;
  final CatalogPackageType packageType;
  final int sizeBytes;
  final String attribution;
  final int verseCount;
  final int chapterCount;
  final DateTime installedAt;
  final String directoryPath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'version': version,
    'language': language,
    'packageType': packageType.name,
    'sizeBytes': sizeBytes,
    'attribution': attribution,
    'verseCount': verseCount,
    'chapterCount': chapterCount,
    'installedAt': installedAt.toIso8601String(),
    'directoryPath': directoryPath,
  };
}
