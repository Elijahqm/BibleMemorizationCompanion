import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Bible Memorization Companion'**
  String get appName;

  /// No description provided for @navStudies.
  ///
  /// In en, this message translates to:
  /// **'Studies'**
  String get navStudies;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get navStore;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @shellMyStudies.
  ///
  /// In en, this message translates to:
  /// **'My Studies'**
  String get shellMyStudies;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in only when it helps'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Free scripture downloads stay guest-friendly without an account. An account is reserved for future paid audio, purchase recovery, and cross-device sync.'**
  String get signInBody;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @previewSignInLater.
  ///
  /// In en, this message translates to:
  /// **'Preview sign-in later'**
  String get previewSignInLater;

  /// No description provided for @updateRequiredForPackage.
  ///
  /// In en, this message translates to:
  /// **'Update the app to at least version {version} to get this package.'**
  String updateRequiredForPackage(String version);

  /// No description provided for @studiesGetStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a package to get started'**
  String get studiesGetStartedTitle;

  /// No description provided for @studiesGetStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Open a downloaded package from the Library to create your first study.'**
  String get studiesGetStartedBody;

  /// No description provided for @goToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Go to Library'**
  String get goToLibrary;

  /// No description provided for @createStudy.
  ///
  /// In en, this message translates to:
  /// **'Create study'**
  String get createStudy;

  /// No description provided for @studiesNoStudiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No studies yet'**
  String get studiesNoStudiesTitle;

  /// No description provided for @studiesNoStudiesBody.
  ///
  /// In en, this message translates to:
  /// **'No studies yet for this package. Create your first one.'**
  String get studiesNoStudiesBody;

  /// No description provided for @deleteStudyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this study?'**
  String get deleteStudyTitle;

  /// No description provided for @deleteStudyMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and its progress will be permanently removed.'**
  String deleteStudyMessage(String title);

  /// No description provided for @deleteStudyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete study'**
  String get deleteStudyTooltip;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @progressOf.
  ///
  /// In en, this message translates to:
  /// **'{learned} of {total} learned'**
  String progressOf(int learned, int total);

  /// No description provided for @libraryPaneDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get libraryPaneDownloads;

  /// No description provided for @libraryNoDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get libraryNoDownloadsTitle;

  /// No description provided for @libraryNoDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'Packages you download from the Store will be listed here and stay available offline.'**
  String get libraryNoDownloadsBody;

  /// No description provided for @libraryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the catalog'**
  String get libraryErrorTitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get tryAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The catalog is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No packages have been published yet.'**
  String get libraryEmptyBody;

  /// No description provided for @catalogFresh.
  ///
  /// In en, this message translates to:
  /// **'Showing cached results.'**
  String get catalogFresh;

  /// No description provided for @catalogLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}.'**
  String catalogLastUpdated(String time);

  /// No description provided for @catalogStaleSuffix.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh — showing the last known list.'**
  String get catalogStaleSuffix;

  /// No description provided for @statusFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get statusFree;

  /// No description provided for @statusOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get statusOwned;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @actionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get actionUnlock;

  /// No description provided for @packageTypeBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get packageTypeBook;

  /// No description provided for @packageTypeSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get packageTypeSeason;

  /// No description provided for @packageTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio add-on'**
  String get packageTypeAudio;

  /// No description provided for @packageTypePackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packageTypePackage;

  /// No description provided for @unknownSize.
  ///
  /// In en, this message translates to:
  /// **'Unknown size'**
  String get unknownSize;

  /// No description provided for @sizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String sizeKilobytes(String size);

  /// No description provided for @sizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMegabytes(String size);

  /// No description provided for @storeBannerDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline-ready downloads'**
  String get storeBannerDownloadsTitle;

  /// No description provided for @storeBannerDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'Downloaded packages stay available without a network connection, ready for verse-by-verse review.'**
  String get storeBannerDownloadsBody;

  /// No description provided for @storeBannerCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest-first scripture catalog'**
  String get storeBannerCatalogTitle;

  /// No description provided for @storeBannerCatalogBody.
  ///
  /// In en, this message translates to:
  /// **'Free scripture content can be browsed and downloaded without signing in. Locked cards preview future paid audio add-ons.'**
  String get storeBannerCatalogBody;

  /// No description provided for @downloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String downloadingPercent(int percent);

  /// No description provided for @downloadingStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get downloadingStarting;

  /// No description provided for @downloadingVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying checksum…'**
  String get downloadingVerifying;

  /// No description provided for @downloadingInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get downloadingInstalling;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @downloadInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get downloadInstalled;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available (v{version})'**
  String updateAvailable(String version);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @downloadFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'The download failed.'**
  String get downloadFailedFallback;

  /// No description provided for @retryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get retryDownload;

  /// No description provided for @requiresAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Requires app version {version} or newer.'**
  String requiresAppVersion(String version);

  /// No description provided for @packageContents.
  ///
  /// In en, this message translates to:
  /// **'Package contents'**
  String get packageContents;

  /// No description provided for @manifestErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the package contents'**
  String get manifestErrorTitle;

  /// No description provided for @creditAttribution.
  ///
  /// In en, this message translates to:
  /// **'Credit: {attribution}'**
  String creditAttribution(String attribution);

  /// No description provided for @removeDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this download?'**
  String get removeDownloadTitle;

  /// No description provided for @removeDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and its studies will be permanently removed from this device.'**
  String removeDownloadMessage(String title);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownloadTooltip;

  /// No description provided for @progressPackagesInstalled.
  ///
  /// In en, this message translates to:
  /// **'Packages installed'**
  String get progressPackagesInstalled;

  /// No description provided for @progressVersesLearned.
  ///
  /// In en, this message translates to:
  /// **'Verses learned'**
  String get progressVersesLearned;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing installed yet'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Install a package and create a study to see progress here.'**
  String get progressEmptyBody;

  /// No description provided for @progressByPackage.
  ///
  /// In en, this message translates to:
  /// **'By package'**
  String get progressByPackage;

  /// No description provided for @progressVersesOf.
  ///
  /// In en, this message translates to:
  /// **'{learned} of {total} verses learned'**
  String progressVersesOf(int learned, int total);

  /// No description provided for @chapterWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter}'**
  String chapterWithNumber(int chapter);

  /// No description provided for @learnedOf.
  ///
  /// In en, this message translates to:
  /// **'{learned} of {total}'**
  String learnedOf(int learned, int total);

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comfortable reading with larger verse cards'**
  String get settingsTextSizeSubtitle;

  /// No description provided for @settingsThemeTone.
  ///
  /// In en, this message translates to:
  /// **'Theme tone'**
  String get settingsThemeTone;

  /// No description provided for @settingsThemeToneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calm parchment with strong scripture contrast'**
  String get settingsThemeToneSubtitle;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsAppLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow device language with English fallback'**
  String get settingsAppLanguageSubtitle;

  /// No description provided for @settingsAudioTeaser.
  ///
  /// In en, this message translates to:
  /// **'Audio teaser'**
  String get settingsAudioTeaser;

  /// No description provided for @settingsAudioTeaserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview-only in the first release shell'**
  String get settingsAudioTeaserSubtitle;

  /// No description provided for @settingStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get settingStandard;

  /// No description provided for @settingLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingLight;

  /// No description provided for @settingAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingAuto;

  /// No description provided for @settingOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingOff;

  /// No description provided for @studyByChapter.
  ///
  /// In en, this message translates to:
  /// **'By chapter'**
  String get studyByChapter;

  /// No description provided for @studyBySection.
  ///
  /// In en, this message translates to:
  /// **'By section'**
  String get studyBySection;

  /// No description provided for @studyCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get studyCustom;

  /// No description provided for @studyOpenErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open {title}'**
  String studyOpenErrorTitle(String title);

  /// No description provided for @contentReadError.
  ///
  /// In en, this message translates to:
  /// **'The package contents could not be read.'**
  String get contentReadError;

  /// No description provided for @noChaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'No chapters found'**
  String get noChaptersTitle;

  /// No description provided for @noChaptersBody.
  ///
  /// In en, this message translates to:
  /// **'This package has no chapter data.'**
  String get noChaptersBody;

  /// No description provided for @byChapterHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a chapter to create & start a study with all its verses.'**
  String get byChapterHint;

  /// No description provided for @noSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sections in this package'**
  String get noSectionsTitle;

  /// No description provided for @noSectionsBody.
  ///
  /// In en, this message translates to:
  /// **'This package ships without a sections file.'**
  String get noSectionsBody;

  /// No description provided for @bySectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a titled section to create & start.'**
  String get bySectionHint;

  /// No description provided for @sectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{range} · {count} verses'**
  String sectionSubtitle(String range, int count);

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'Filters what you see below — your checked verses stay checked either way.'**
  String get filterHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterDifficult.
  ///
  /// In en, this message translates to:
  /// **'Difficult'**
  String get filterDifficult;

  /// No description provided for @filterLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get filterLearned;

  /// No description provided for @studyNameField.
  ///
  /// In en, this message translates to:
  /// **'Study name'**
  String get studyNameField;

  /// No description provided for @versesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} verses selected'**
  String versesSelected(int count);

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @studyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This study has no verses.'**
  String get studyEmptyBody;

  /// No description provided for @verseProgress.
  ///
  /// In en, this message translates to:
  /// **'Verse {current} of {total}'**
  String verseProgress(int current, int total);

  /// No description provided for @revealHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal the verse text, then tap again to hide it and test recall.'**
  String get revealHint;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @defaultStudyName.
  ///
  /// In en, this message translates to:
  /// **'My study {number}'**
  String defaultStudyName(int number);

  /// No description provided for @versesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verse} other{{count} verses}}'**
  String versesCount(int count);

  /// No description provided for @chaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String chaptersCount(int count);

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String filesCount(int count);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @drawerTagline.
  ///
  /// In en, this message translates to:
  /// **'Clear, calm scripture practice with offline-ready packages.'**
  String get drawerTagline;

  /// No description provided for @catalogPackages.
  ///
  /// In en, this message translates to:
  /// **'Catalog packages'**
  String get catalogPackages;

  /// No description provided for @installedPackages.
  ///
  /// In en, this message translates to:
  /// **'Installed packages'**
  String get installedPackages;

  /// No description provided for @guestModeNote.
  ///
  /// In en, this message translates to:
  /// **'Guest mode stays fully supported for free scripture downloads.'**
  String get guestModeNote;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get errorRequestTimeout;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoInternet;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error.'**
  String get errorNetwork;

  /// No description provided for @errorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server.'**
  String get errorRequestFailed;

  /// No description provided for @errorUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response format.'**
  String get errorUnexpectedResponse;

  /// No description provided for @errorInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The server returned invalid data.'**
  String get errorInvalidJson;

  /// No description provided for @errorMissingArtifactUrl.
  ///
  /// In en, this message translates to:
  /// **'This package has no download link.'**
  String get errorMissingArtifactUrl;

  /// No description provided for @errorDownloadTimeout.
  ///
  /// In en, this message translates to:
  /// **'The download took too long to start.'**
  String get errorDownloadTimeout;

  /// No description provided for @errorDownloadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not download {title}.'**
  String errorDownloadFailedTitle(String title);

  /// No description provided for @errorDownloadInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The download was interrupted.'**
  String get errorDownloadInterrupted;

  /// No description provided for @errorChecksumMismatch.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file could not be verified.'**
  String get errorChecksumMismatch;

  /// No description provided for @errorInstallGeneric.
  ///
  /// In en, this message translates to:
  /// **'The package could not be installed.'**
  String get errorInstallGeneric;

  /// No description provided for @errorArchiveOpen.
  ///
  /// In en, this message translates to:
  /// **'The package file could not be opened.'**
  String get errorArchiveOpen;

  /// No description provided for @errorMissingManifest.
  ///
  /// In en, this message translates to:
  /// **'The package has no manifest.json.'**
  String get errorMissingManifest;

  /// No description provided for @errorInvalidManifest.
  ///
  /// In en, this message translates to:
  /// **'The package manifest is invalid.'**
  String get errorInvalidManifest;

  /// No description provided for @errorUnsafePath.
  ///
  /// In en, this message translates to:
  /// **'The package contains an unsafe path.'**
  String get errorUnsafePath;

  /// No description provided for @errorMissingFile.
  ///
  /// In en, this message translates to:
  /// **'The package is missing {file}.'**
  String errorMissingFile(String file);

  /// No description provided for @errorFileSize.
  ///
  /// In en, this message translates to:
  /// **'{file} has an unexpected size.'**
  String errorFileSize(String file);

  /// No description provided for @errorFileChecksum.
  ///
  /// In en, this message translates to:
  /// **'{file} failed its checksum.'**
  String errorFileChecksum(String file);

  /// No description provided for @errorCatalogLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the catalog.'**
  String get errorCatalogLoad;

  /// No description provided for @errorContentMissing.
  ///
  /// In en, this message translates to:
  /// **'{title} is no longer on this device.'**
  String errorContentMissing(String title);

  /// No description provided for @errorContentFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing {file}.'**
  String errorContentFileMissing(String file);

  /// No description provided for @errorContentMalformed.
  ///
  /// In en, this message translates to:
  /// **'{file} is malformed.'**
  String errorContentMalformed(String file);

  /// No description provided for @errorContentInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'{file} is not valid JSON.'**
  String errorContentInvalidJson(String file);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
