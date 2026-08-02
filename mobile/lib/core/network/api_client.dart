import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Error surfaced to the UI when a backend call fails.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON client over the backend. Keeps timeout, decoding and error
/// mapping in one place so repositories stay small.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Uri resolve(String path) => Uri.parse('$_baseUrl$path');

  /// GETs [url] (absolute) or a path relative to the configured base URL and
  /// decodes the response as a JSON object.
  Future<Map<String, dynamic>> getJson(String pathOrUrl) async {
    final uri = pathOrUrl.startsWith('http')
        ? Uri.parse(pathOrUrl)
        : resolve(pathOrUrl);

    late final http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on SocketException {
      throw const ApiException('No internet connection.');
    } on http.ClientException catch (error) {
      throw ApiException('Network error: ${error.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Request to ${uri.path} failed.',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Unexpected response format.');
      }
      return decoded;
    } on FormatException {
      throw const ApiException('The server returned invalid JSON.');
    }
  }

  void close() => _httpClient.close();
}
