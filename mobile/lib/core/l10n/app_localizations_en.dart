// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bible Memorization Companion';

  @override
  String get navStudies => 'Studies';

  @override
  String get navLibrary => 'Library';

  @override
  String get navStore => 'Store';

  @override
  String get navProgress => 'Progress';

  @override
  String get navSettings => 'Settings';

  @override
  String get shellMyStudies => 'My Studies';

  @override
  String get account => 'Account';

  @override
  String get signInTitle => 'Sign in only when it helps';

  @override
  String get signInBody =>
      'Free scripture downloads stay guest-friendly without an account. An account is reserved for future paid audio, purchase recovery, and cross-device sync.';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get previewSignInLater => 'Preview sign-in later';

  @override
  String updateRequiredForPackage(String version) {
    return 'Update the app to at least version $version to get this package.';
  }

  @override
  String get studiesGetStartedTitle => 'Select a package to get started';

  @override
  String get studiesGetStartedBody =>
      'Open a downloaded package from the Library to create your first study.';

  @override
  String get goToLibrary => 'Go to Library';

  @override
  String get createStudy => 'Create study';

  @override
  String get studiesNoStudiesTitle => 'No studies yet';

  @override
  String get studiesNoStudiesBody =>
      'No studies yet for this package. Create your first one.';

  @override
  String get deleteStudyTitle => 'Delete this study?';

  @override
  String deleteStudyMessage(String title) {
    return '\"$title\" and its progress will be permanently removed.';
  }

  @override
  String get deleteStudyTooltip => 'Delete study';

  @override
  String get notStarted => 'Not started';

  @override
  String get resume => 'Resume';

  @override
  String get start => 'Start';

  @override
  String progressOf(int learned, int total) {
    return '$learned of $total learned';
  }

  @override
  String get libraryPaneDownloads => 'Downloads';

  @override
  String get libraryNoDownloadsTitle => 'No downloads yet';

  @override
  String get libraryNoDownloadsBody =>
      'Packages you download from the Store will be listed here and stay available offline.';

  @override
  String get libraryErrorTitle => 'Could not load the catalog';

  @override
  String get tryAgain => 'Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get libraryEmptyTitle => 'The catalog is empty';

  @override
  String get libraryEmptyBody => 'No packages have been published yet.';

  @override
  String get catalogFresh => 'Showing cached results.';

  @override
  String catalogLastUpdated(String time) {
    return 'Last updated $time.';
  }

  @override
  String get catalogStaleSuffix =>
      'Could not refresh — showing the last known list.';

  @override
  String get statusFree => 'Free';

  @override
  String get statusOwned => 'Owned';

  @override
  String get statusPaid => 'Paid';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionUnlock => 'Unlock';

  @override
  String get packageTypeBook => 'Book';

  @override
  String get packageTypeSeason => 'Season';

  @override
  String get packageTypeAudio => 'Audio add-on';

  @override
  String get packageTypePackage => 'Package';

  @override
  String get unknownSize => 'Unknown size';

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get storeBannerDownloadsTitle => 'Offline-ready downloads';

  @override
  String get storeBannerDownloadsBody =>
      'Downloaded packages stay available without a network connection, ready for verse-by-verse review.';

  @override
  String get storeBannerCatalogTitle => 'Guest-first scripture catalog';

  @override
  String get storeBannerCatalogBody =>
      'Free scripture content can be browsed and downloaded without signing in. Locked cards preview future paid audio add-ons.';

  @override
  String downloadingPercent(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get downloadingStarting => 'Starting…';

  @override
  String get downloadingVerifying => 'Verifying checksum…';

  @override
  String get downloadingInstalling => 'Installing…';

  @override
  String get cancel => 'Cancel';

  @override
  String get downloadInstalled => 'Installed';

  @override
  String updateAvailable(String version) {
    return 'Update available (v$version)';
  }

  @override
  String get update => 'Update';

  @override
  String get open => 'Open';

  @override
  String get downloadFailedFallback => 'The download failed.';

  @override
  String get retryDownload => 'Retry download';

  @override
  String requiresAppVersion(String version) {
    return 'Requires app version $version or newer.';
  }

  @override
  String get packageContents => 'Package contents';

  @override
  String get manifestErrorTitle => 'Could not load the package contents';

  @override
  String creditAttribution(String attribution) {
    return 'Credit: $attribution';
  }

  @override
  String get removeDownloadTitle => 'Remove this download?';

  @override
  String removeDownloadMessage(String title) {
    return '\"$title\" and its studies will be permanently removed from this device.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get removeDownloadTooltip => 'Remove download';

  @override
  String get progressPackagesInstalled => 'Packages installed';

  @override
  String get progressVersesLearned => 'Verses learned';

  @override
  String get progressEmptyTitle => 'Nothing installed yet';

  @override
  String get progressEmptyBody =>
      'Install a package and create a study to see progress here.';

  @override
  String get progressByPackage => 'By package';

  @override
  String progressVersesOf(int learned, int total) {
    return '$learned of $total verses learned';
  }

  @override
  String chapterWithNumber(int chapter) {
    return 'Chapter $chapter';
  }

  @override
  String learnedOf(int learned, int total) {
    return '$learned of $total';
  }

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextSizeSubtitle =>
      'Comfortable reading with larger verse cards';

  @override
  String get settingsThemeTone => 'Theme tone';

  @override
  String get settingsThemeToneSubtitle =>
      'Calm parchment with strong scripture contrast';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsAppLanguageSubtitle =>
      'Follow device language with English fallback';

  @override
  String get settingsAudioTeaser => 'Audio teaser';

  @override
  String get settingsAudioTeaserSubtitle =>
      'Preview-only in the first release shell';

  @override
  String get settingStandard => 'Standard';

  @override
  String get settingLight => 'Light';

  @override
  String get settingAuto => 'Auto';

  @override
  String get settingOff => 'Off';

  @override
  String get studyByChapter => 'By chapter';

  @override
  String get studyBySection => 'By section';

  @override
  String get studyCustom => 'Custom';

  @override
  String studyOpenErrorTitle(String title) {
    return 'Could not open $title';
  }

  @override
  String get contentReadError => 'The package contents could not be read.';

  @override
  String get noChaptersTitle => 'No chapters found';

  @override
  String get noChaptersBody => 'This package has no chapter data.';

  @override
  String get byChapterHint =>
      'Tap a chapter to create & start a study with all its verses.';

  @override
  String get noSectionsTitle => 'No sections in this package';

  @override
  String get noSectionsBody => 'This package ships without a sections file.';

  @override
  String get bySectionHint => 'Tap a titled section to create & start.';

  @override
  String sectionSubtitle(String range, int count) {
    return '$range · $count verses';
  }

  @override
  String get filterHint =>
      'Filters what you see below — your checked verses stay checked either way.';

  @override
  String get filterAll => 'All';

  @override
  String get filterDifficult => 'Difficult';

  @override
  String get filterLearned => 'Learned';

  @override
  String get studyNameField => 'Study name';

  @override
  String versesSelected(int count) {
    return '$count verses selected';
  }

  @override
  String get go => 'Go';

  @override
  String get studyEmptyBody => 'This study has no verses.';

  @override
  String verseProgress(int current, int total) {
    return 'Verse $current of $total';
  }

  @override
  String get revealHint =>
      'Tap to reveal the verse text, then tap again to hide it and test recall.';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String defaultStudyName(int number) {
    return 'My study $number';
  }

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$_temp0';
  }

  @override
  String chaptersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get drawerTagline =>
      'Clear, calm scripture practice with offline-ready packages.';

  @override
  String get catalogPackages => 'Catalog packages';

  @override
  String get installedPackages => 'Installed packages';

  @override
  String get guestModeNote =>
      'Guest mode stays fully supported for free scripture downloads.';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorRequestTimeout => 'The server took too long to respond.';

  @override
  String get errorNoInternet => 'No internet connection.';

  @override
  String get errorNetwork => 'Network error.';

  @override
  String get errorRequestFailed => 'Unable to reach the server.';

  @override
  String get errorUnexpectedResponse => 'Unexpected response format.';

  @override
  String get errorInvalidJson => 'The server returned invalid data.';

  @override
  String get errorMissingArtifactUrl => 'This package has no download link.';

  @override
  String get errorDownloadTimeout => 'The download took too long to start.';

  @override
  String errorDownloadFailedTitle(String title) {
    return 'Could not download $title.';
  }

  @override
  String get errorDownloadInterrupted => 'The download was interrupted.';

  @override
  String get errorChecksumMismatch =>
      'The downloaded file could not be verified.';

  @override
  String get errorInstallGeneric => 'The package could not be installed.';

  @override
  String get errorArchiveOpen => 'The package file could not be opened.';

  @override
  String get errorMissingManifest => 'The package has no manifest.json.';

  @override
  String get errorInvalidManifest => 'The package manifest is invalid.';

  @override
  String get errorUnsafePath => 'The package contains an unsafe path.';

  @override
  String errorMissingFile(String file) {
    return 'The package is missing $file.';
  }

  @override
  String errorFileSize(String file) {
    return '$file has an unexpected size.';
  }

  @override
  String errorFileChecksum(String file) {
    return '$file failed its checksum.';
  }

  @override
  String get errorCatalogLoad => 'Could not load the catalog.';

  @override
  String errorContentMissing(String title) {
    return '$title is no longer on this device.';
  }

  @override
  String errorContentFileMissing(String file) {
    return 'Missing $file.';
  }

  @override
  String errorContentMalformed(String file) {
    return '$file is malformed.';
  }

  @override
  String errorContentInvalidJson(String file) {
    return '$file is not valid JSON.';
  }
}
