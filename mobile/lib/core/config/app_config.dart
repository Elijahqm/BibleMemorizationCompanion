/// Runtime configuration for the app.
///
/// The API base URL can be overridden at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080`.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bqcompanion.iqstudiogt.com',
  );

  /// Version the client reports/compares against `minAppVersion` in the catalog.
  static const String appVersion = '1.0.0';

  static const Duration requestTimeout = Duration(seconds: 20);
}
