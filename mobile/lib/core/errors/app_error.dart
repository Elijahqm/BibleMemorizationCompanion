import '../l10n/app_localizations.dart';

/// Machine-readable category for every user-visible failure the app can
/// report. The UI maps each [AppErrorKind] to a localized message via
/// [localizedAppError]; no raw English strings live in the data layer.
enum AppErrorKind {
  generic,
  requestTimeout,
  noInternet,
  network,
  requestFailed,
  unexpectedResponse,
  invalidJson,
  missingArtifactUrl,
  downloadTimeout,
  downloadFailed,
  downloadInterrupted,
  checksumMismatch,
  installFailed,
  archiveOpenFailed,
  missingManifest,
  invalidManifest,
  unsafePath,
  missingFile,
  fileSizeMismatch,
  fileChecksumMismatch,
  catalogLoadFailed,
  contentNotFound,
  contentFileMissing,
  contentMalformed,
  contentInvalidJson,
}

/// A failure paired with the values (file names, titles, sizes, …) needed to
/// render its localized message.
class AppError {
  const AppError(this.kind, {this.params = const []});

  final AppErrorKind kind;

  /// Positional values substituted into the localized message, in the order
  /// the ARB placeholders expect.
  final List<String> params;

  @override
  String toString() => 'AppError($kind, params: $params)';
}

/// Navigational/transport errors raised while talking to the backend.
class ApiException extends AppError implements Exception {
  const ApiException(
    super.kind, {
    super.params,
    this.statusCode,
  });

  final int? statusCode;

  @override
  String toString() =>
      'ApiException($statusCode): ${super.toString()}';
}

/// Raised when a downloaded artifact cannot be unpacked into a package.
class InstallException extends AppError implements Exception {
  const InstallException(super.kind, {super.params});

  @override
  String toString() => 'InstallException: ${super.toString()}';
}

/// Raised when an installed package's content cannot be read from disk.
class ContentException extends AppError implements Exception {
  const ContentException(super.kind, {super.params});

  @override
  String toString() => 'ContentException: ${super.toString()}';
}

/// Coerces any thrown object into an [AppError]. Unknown errors (including
/// unexpected `Error`s) map to [AppErrorKind.generic] so the user always gets
/// a localized message instead of an unhandled raw string.
AppError asAppError(Object error) {
  if (error is AppError) return error;
  return const AppError(AppErrorKind.generic);
}

/// Resolves the localized, user-facing message for a thrown [error].
String localizedAppError(AppLocalizations l10n, Object error) {
  final failure = asAppError(error);
  return switch (failure.kind) {
    AppErrorKind.generic => l10n.errorGeneric,
    AppErrorKind.requestTimeout => l10n.errorRequestTimeout,
    AppErrorKind.noInternet => l10n.errorNoInternet,
    AppErrorKind.network => l10n.errorNetwork,
    AppErrorKind.requestFailed => l10n.errorRequestFailed,
    AppErrorKind.unexpectedResponse => l10n.errorUnexpectedResponse,
    AppErrorKind.invalidJson => l10n.errorInvalidJson,
    AppErrorKind.missingArtifactUrl => l10n.errorMissingArtifactUrl,
    AppErrorKind.downloadTimeout => l10n.errorDownloadTimeout,
    AppErrorKind.downloadFailed => l10n.errorDownloadFailedTitle(
      failure.params.isNotEmpty ? failure.params.first : '',
    ),
    AppErrorKind.downloadInterrupted => l10n.errorDownloadInterrupted,
    AppErrorKind.checksumMismatch => l10n.errorChecksumMismatch,
    AppErrorKind.installFailed => l10n.errorInstallGeneric,
    AppErrorKind.archiveOpenFailed => l10n.errorArchiveOpen,
    AppErrorKind.missingManifest => l10n.errorMissingManifest,
    AppErrorKind.invalidManifest => l10n.errorInvalidManifest,
    AppErrorKind.unsafePath => l10n.errorUnsafePath,
    AppErrorKind.missingFile => l10n.errorMissingFile(_param(failure, 0)),
    AppErrorKind.fileSizeMismatch => l10n.errorFileSize(_param(failure, 0)),
    AppErrorKind.fileChecksumMismatch =>
      l10n.errorFileChecksum(_param(failure, 0)),
    AppErrorKind.catalogLoadFailed => l10n.errorCatalogLoad,
    AppErrorKind.contentNotFound => l10n.errorContentMissing(_param(failure, 0)),
    AppErrorKind.contentFileMissing =>
      l10n.errorContentFileMissing(_param(failure, 0)),
    AppErrorKind.contentMalformed => l10n.errorContentMalformed(_param(failure, 0)),
    AppErrorKind.contentInvalidJson =>
      l10n.errorContentInvalidJson(_param(failure, 0)),
  };
}

String _param(AppError failure, int index) =>
    index < failure.params.length ? failure.params[index] : '';