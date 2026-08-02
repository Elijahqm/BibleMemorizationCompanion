/// A file listed inside a package manifest.
class ManifestFile {
  const ManifestFile({
    required this.path,
    required this.sizeBytes,
    required this.checksumSha256,
    required this.required,
  });

  factory ManifestFile.fromJson(Map<String, dynamic> json) {
    return ManifestFile(
      path: json['path'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      checksumSha256: json['checksumSha256'] as String? ?? '',
      required: json['required'] as bool? ?? true,
    );
  }

  final String path;
  final int sizeBytes;
  final String checksumSha256;
  final bool required;
}

/// `manifest.json` published next to each package artifact.
class PackageManifest {
  const PackageManifest({
    required this.packageId,
    required this.title,
    required this.version,
    required this.language,
    required this.attribution,
    required this.verseCount,
    required this.chapterCount,
    required this.files,
  });

  factory PackageManifest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    return PackageManifest(
      packageId: json['packageId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      language: json['language'] as String? ?? 'en',
      attribution: json['attribution'] as String? ?? '',
      verseCount: (json['verseCount'] as num?)?.toInt() ?? 0,
      chapterCount: (json['chapterCount'] as num?)?.toInt() ?? 0,
      files: rawFiles is List
          ? rawFiles
                .whereType<Map<String, dynamic>>()
                .map(ManifestFile.fromJson)
                .toList(growable: false)
          : const <ManifestFile>[],
    );
  }

  final String packageId;
  final String title;
  final String version;
  final String language;
  final String attribution;
  final int verseCount;
  final int chapterCount;
  final List<ManifestFile> files;
}
