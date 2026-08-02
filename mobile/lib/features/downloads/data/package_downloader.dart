import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../catalog/data/models/catalog_package.dart';

/// Raised when a download is cancelled by the user.
class DownloadCancelledException implements Exception {
  const DownloadCancelledException();

  @override
  String toString() => 'DownloadCancelledException';
}

/// Cooperative cancellation for an in-flight download.
class DownloadCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Bytes received so far for a download.
class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});

  final int received;
  final int total;

  /// `null` while the total size is unknown, so the UI can stay indeterminate.
  double? get fraction {
    if (total <= 0) return null;
    return (received / total).clamp(0.0, 1.0);
  }
}

/// Streams a package artifact to disk and verifies its SHA-256 checksum.
///
/// The file is written to a `.part` file first and only renamed once the
/// checksum matches, so a partial or corrupted download is never mistaken for a
/// complete artifact. Installing (unzipping) the artifact is a separate step.
class PackageDownloader {
  PackageDownloader({http.Client? httpClient, Directory? downloadDirectory})
    : _httpClient = httpClient ?? http.Client(),
      _downloadDirectory = downloadDirectory;

  final http.Client _httpClient;
  final Directory? _downloadDirectory;

  Future<Directory> resolveDirectory() async {
    final directory =
        _downloadDirectory ??
        Directory('${Directory.systemTemp.path}/bmc-downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String fileNameFor(CatalogPackage package) =>
      '${package.id}-${package.version}.zip';

  /// Resolves [url] against the configured API base URL when it's a
  /// backend-relative path (e.g. `/packages/...`), or parses it as-is when
  /// it's already absolute.
  Uri _resolveArtifactUri(String url) => url.startsWith('http')
      ? Uri.parse(url)
      : Uri.parse('${AppConfig.apiBaseUrl}$url');

  /// Downloads [package] and returns the verified artifact file.
  ///
  /// Throws [DownloadCancelledException] when [cancelToken] is cancelled and
  /// [ApiException] on transport, HTTP or checksum failures.
  Future<File> download(
    CatalogPackage package, {
    void Function(DownloadProgress progress)? onProgress,
    void Function()? onVerifying,
    DownloadCancelToken? cancelToken,
  }) async {
    if (package.artifactUrl.isEmpty) {
      throw const ApiException('This package has no artifact URL.');
    }

    final directory = await resolveDirectory();
    final target = File('${directory.path}/${fileNameFor(package)}');
    final partial = File('${target.path}.part');

    final http.StreamedResponse response;
    try {
      final request = http.Request(
        'GET',
        _resolveArtifactUri(package.artifactUrl),
      );
      response = await _httpClient
          .send(request)
          .timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('The download took too long to start.');
    } on SocketException {
      throw const ApiException('No internet connection.');
    } on http.ClientException catch (error) {
      throw ApiException('Network error: ${error.message}');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Could not download ${package.title}.',
        statusCode: response.statusCode,
      );
    }

    final total = response.contentLength ?? package.sizeBytes;
    final digestSink = AccumulatorSink<Digest>();
    final hasher = sha256.startChunkedConversion(digestSink);
    final sink = partial.openWrite();

    var received = 0;
    onProgress?.call(DownloadProgress(received: 0, total: total));

    try {
      await for (final chunk in response.stream) {
        if (cancelToken?.isCancelled ?? false) {
          throw const DownloadCancelledException();
        }
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        onProgress?.call(DownloadProgress(received: received, total: total));
      }
      await sink.flush();
    } on http.ClientException catch (error) {
      hasher.close();
      await _discard(sink, partial);
      throw ApiException('The download was interrupted: ${error.message}');
    } catch (_) {
      hasher.close();
      await _discard(sink, partial);
      rethrow;
    }

    await sink.close();
    hasher.close();
    onVerifying?.call();

    final expected = package.checksumSha256.toLowerCase();
    final actual = digestSink.events.single.toString();
    if (expected.isNotEmpty && actual != expected) {
      await _deleteQuietly(partial);
      throw const ApiException(
        'The downloaded file is corrupted (checksum mismatch).',
      );
    }

    if (await target.exists()) {
      await _deleteQuietly(target);
    }
    return partial.rename(target.path);
  }

  Future<void> _discard(IOSink sink, File file) async {
    try {
      await sink.close();
    } catch (_) {
      // The sink may already be closed; the partial file is deleted anyway.
    }
    await _deleteQuietly(file);
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nothing to clean up.
    }
  }

  void close() => _httpClient.close();
}
