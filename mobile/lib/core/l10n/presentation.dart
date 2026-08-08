import '../../features/catalog/data/models/catalog_package.dart';
import 'app_localizations.dart';

/// Localized presentation labels for catalog types. These used to live as
/// raw English getters on the data model; they were moved here so the model
/// stays UI-agnostic and the text follows the active locale.
extension CatalogPackageTypeL10n on CatalogPackageType {
  String label(AppLocalizations l10n) => switch (this) {
    CatalogPackageType.book => l10n.packageTypeBook,
    CatalogPackageType.season => l10n.packageTypeSeason,
    CatalogPackageType.audio => l10n.packageTypeAudio,
    CatalogPackageType.unknown => l10n.packageTypePackage,
  };
}

/// Localized presentation helpers for the catalog-driven widgets.
extension CatalogPackageL10n on CatalogPackage {
  String statusLabel(AppLocalizations l10n) {
    if (isFree) return l10n.statusFree;
    if (owned) return l10n.statusOwned;
    return price?.label ?? l10n.statusPaid;
  }

  String primaryActionLabel(AppLocalizations l10n) =>
      isDownloadable ? l10n.actionDownload : l10n.actionUnlock;

  String sizeLabel(AppLocalizations l10n) {
    if (sizeBytes <= 0) return l10n.unknownSize;
    if (sizeBytes < 1024 * 1024) {
      return l10n.sizeKilobytes((sizeBytes / 1024).toStringAsFixed(0));
    }
    return l10n.sizeMegabytes(
      (sizeBytes / (1024 * 1024)).toStringAsFixed(1),
    );
  }

  /// Compact one-liner for package list cards.
  String listSubtitle(AppLocalizations l10n) =>
      '${packageType.label(l10n)} · ${language.toUpperCase()} · v$version';
}