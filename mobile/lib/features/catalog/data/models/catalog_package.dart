/// Package kinds published by the backend catalog.
enum CatalogPackageType {
  book,
  season,
  audio,
  unknown;

  static CatalogPackageType parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'book':
        return CatalogPackageType.book;
      case 'season':
        return CatalogPackageType.season;
      case 'audio':
        return CatalogPackageType.audio;
      default:
        return CatalogPackageType.unknown;
    }
  }

  String get label {
    switch (this) {
      case CatalogPackageType.book:
        return 'Book';
      case CatalogPackageType.season:
        return 'Season';
      case CatalogPackageType.audio:
        return 'Audio add-on';
      case CatalogPackageType.unknown:
        return 'Package';
    }
  }
}

/// Price of a paid package (`null` on the wire for free packages).
class CatalogPrice {
  const CatalogPrice({required this.amount, required this.currency});

  factory CatalogPrice.fromJson(Map<String, dynamic> json) {
    return CatalogPrice(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  final double amount;
  final String currency;

  String get label => '${amount.toStringAsFixed(2)} $currency';

  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};
}

/// One entry of `GET /api/v1/catalog`.
class CatalogPackage {
  const CatalogPackage({
    required this.id,
    required this.title,
    required this.packageType,
    required this.language,
    required this.version,
    required this.sizeBytes,
    required this.isFree,
    required this.owned,
    required this.artifactUrl,
    required this.manifestUrl,
    required this.checksumSha256,
    required this.minAppVersion,
    this.price,
    this.basePackageId,
  });

  factory CatalogPackage.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    return CatalogPackage(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['id'] as String,
      packageType: CatalogPackageType.parse(json['packageType'] as String?),
      language: json['language'] as String? ?? 'en',
      version: json['version'] as String? ?? '1.0.0',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      isFree: json['isFree'] as bool? ?? true,
      owned: json['owned'] as bool? ?? false,
      artifactUrl: json['artifactUrl'] as String? ?? '',
      manifestUrl: json['manifestUrl'] as String? ?? '',
      checksumSha256: json['checksumSha256'] as String? ?? '',
      minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
      price: price is Map<String, dynamic> ? CatalogPrice.fromJson(price) : null,
      basePackageId: json['basePackageId'] as String?,
    );
  }

  final String id;
  final String title;
  final CatalogPackageType packageType;
  final String language;
  final String version;
  final int sizeBytes;
  final bool isFree;
  final bool owned;
  final String artifactUrl;
  final String manifestUrl;
  final String checksumSha256;
  final String minAppVersion;
  final CatalogPrice? price;
  final String? basePackageId;

  /// Content is downloadable when it is free or already owned by the user.
  bool get isDownloadable => isFree || owned;

  String get sizeLabel {
    if (sizeBytes <= 0) return 'Unknown size';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'packageType': packageType.name,
    'language': language,
    'version': version,
    'sizeBytes': sizeBytes,
    'isFree': isFree,
    'owned': owned,
    'artifactUrl': artifactUrl,
    'manifestUrl': manifestUrl,
    'checksumSha256': checksumSha256,
    'minAppVersion': minAppVersion,
    if (price != null) 'price': price!.toJson(),
    if (basePackageId != null) 'basePackageId': basePackageId,
  };
}

/// Response envelope of `GET /api/v1/catalog`.
class CatalogResponse {
  const CatalogResponse({
    required this.catalogVersion,
    required this.publishedAt,
    required this.packages,
  });

  factory CatalogResponse.fromJson(Map<String, dynamic> json) {
    final rawPackages = json['packages'];
    return CatalogResponse(
      catalogVersion: json['catalogVersion']?.toString() ?? '1',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      packages: rawPackages is List
          ? rawPackages
                .whereType<Map<String, dynamic>>()
                .map(CatalogPackage.fromJson)
                .toList(growable: false)
          : const <CatalogPackage>[],
    );
  }

  final String catalogVersion;
  final DateTime? publishedAt;
  final List<CatalogPackage> packages;

  Map<String, dynamic> toJson() => {
    'catalogVersion': catalogVersion,
    'publishedAt': publishedAt?.toIso8601String(),
    'packages': packages.map((package) => package.toJson()).toList(),
  };
}
