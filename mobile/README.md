# Bible Memorization Companion — Mobile

Flutter frontend for the Bible Memorization Companion app, targeting Android and iOS.

## Getting started

```sh
flutter pub get
flutter run
```

## Backend configuration

The app reads the catalog from the deployed API by default
(`https://bqcompanion.iqstudiogt.com`). Point it at another backend at build time:

```sh
# local backend from an Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

The base URL lives in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart);
catalog access goes through `CatalogRepository` (`lib/features/catalog/`).

## Validation

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
```
