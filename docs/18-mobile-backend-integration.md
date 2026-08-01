# 18 — Mobile ↔ Backend integration plan

Short plan for wiring the Flutter app to the deployed API
(`https://bqcompanion.iqstudiogt.com`). No local backend is required.

Step-by-step progress is tracked in
[19 Integration checklist](19-integration-checklist.md).

## Step 1 — Catalog (done in `feat/mobile-catalog-integration`)

| Piece | Where |
| --- | --- |
| Base URL + timeouts (`--dart-define=API_BASE_URL`) | `lib/core/config/app_config.dart` |
| JSON client, timeout/offline/HTTP error mapping | `lib/core/network/api_client.dart` |
| Catalog + manifest models | `lib/features/catalog/data/models/` |
| Repository with in-memory cache | `lib/features/catalog/data/catalog_repository.dart` |
| `ChangeNotifier` state (idle/loading/ready/error) | `lib/features/catalog/catalog_controller.dart` |
| Store list, pull-to-refresh, retry, detail manifest | `lib/features/shell/app_shell.dart` |

Also: `INTERNET` permission added to the release Android manifest; the demo package
list was removed (studies are still demo data).

Endpoints consumed: `GET /api/v1/catalog` and each package's `manifestUrl`.

## Step 2 — Download & install (next)

1. Add `path_provider`, `crypto`, `archive`.
2. Download `artifactUrl` to a temp file with progress, verify `checksumSha256`.
3. Unzip into `<app-support>/packages/{id}/{version}/`, verify per-file checksums
   from `manifest.json`, then atomically mark the version installed.
4. Persist an install index (JSON file first, `sqlite` later) so the **Downloads**
   pane lists real installed packages and survives restarts.

## Step 3 — Real study content

1. Read `content/index.json` + `content/chapters/*.json` from the installed package.
2. Replace `demoStudies` with sections/verses parsed from disk.
3. Store per-verse progress locally; keep attribution from the manifest visible.

## Step 4 — Housekeeping

- Compare `minAppVersion` against `AppConfig.appVersion` and hide/flag unsupported packages.
- Cache the catalog response on disk for offline launches (backend sends `cache-control: max-age=300`).
- Update-available detection by comparing catalog `version` with the installed version.
