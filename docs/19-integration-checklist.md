# 19 — Integration checklist (working document)

Live checklist for the `feat/mobile-catalog-integration` delivery. **One step at a
time**: a step is only checked off after Hugo reviews and approves it.

Background plan: [18 Mobile ↔ Backend integration](18-mobile-backend-integration.md).

---

## Step 0 — Catalog wiring ✅ (approved)

- [x] `AppConfig` with `--dart-define=API_BASE_URL`
- [x] `ApiClient` (timeout, offline, HTTP and JSON error mapping)
- [x] Catalog + manifest models and `CatalogRepository` (in-memory cache)
- [x] `CatalogController` states: idle / loading / ready / error
- [x] Store pane lists live packages; pull-to-refresh and retry
- [x] Package detail loads the real `manifest.json`
- [x] `INTERNET` permission in the release Android manifest
- [x] Tests: repository (MockClient) + 3 widget tests

---

## Step 1 — Download an artifact ✅ (approved)

- [x] Add `crypto`; stream `artifactUrl` to a temp file with progress
- [x] Verify `checksumSha256` before accepting the download (`.part` → rename)
- [x] Per-package UI state: idle / downloading (%) / verifying / failed
- [x] Cancel and retry
- [x] Test: download, checksum mismatch, cancel, HTTP error + widget progress

**Acceptance:** tapping Download on CB Daniel 1-6 reaches 100% and verifies.

---

## Step 2 — Install and track installed packages ✅ (approved)

- [x] Add `archive` + `path_provider`; unzip into
      `<app-support>/packages/{id}/{version}/`
- [x] Verify per-file checksums and sizes from the manifest inside the zip
- [x] Atomic install (`{version}.tmp` staging → rename) + JSON install index
- [x] Reject zip-slip paths (`..`, absolute) before writing anything
- [x] Downloads pane lists real installed packages; delete/uninstall
- [x] Test: install index survives a restart

**Acceptance:** after installing, Downloads shows the package and it survives a restart.

---

## Step 3 — Real study content ✅ (approved)

First pass wrongly auto-listed every content *section* as an
immediately-tappable "study" the moment a package was installed. Corrected
against `docs/MVP-Round-4.html` (screens `4a`–`4m`) and
`docs/08-data-models-and-storage.md`: studies are **user-created**, never
auto-generated. Sections/chapters are inputs to creating a study, not
studies themselves.

- [x] Read `content/index.json`, `content/sections.json` and
      `content/chapters/*.json` from disk (`PackageContentRepository`,
      now also grouping verses by chapter)
- [x] `Study` + `VerseState` domain models, persisted to disk
      (`StudyStore`, `VerseStateStore`, `ActivePackageStore`) — installing a
      package creates zero studies
- [x] "My Studies" scoped to the last-opened ("active") package: prompts to
      pick a package → "No studies yet" + Create study CTA → study cards
      once created (title, learned/total, Resume/Start, delete w/ confirm)
- [x] **Create study** flow with 3 tabs: By chapter / By section (instant) /
      Custom (chapter-grouped checklist, All/Difficult/Learned view-only
      filter, editable name)
- [x] Library's installed-package cards get an explicit **Open** button
      (previously missing) that sets the active package
- [x] Verse study screen runs on a `Study`; Learned/Difficult toggles
      (package-scoped, shared across studies) and resume position persist
- [x] Inline `[[section:id|Title]]` markers still rendered as headings,
      mid-verse too
- [x] Progress tab shows real learned/total per package from `VerseState`
- [x] Uninstalling a package cascades: its studies and verse states are removed
- [x] Tests: store round-trips, controller (create ×3 modes, delete, toggle,
      cascade-delete, resume persistence), full widget flow (open package →
      empty state → create by section → toggle learned → progress updates)

**Acceptance:** installing a package creates no studies; the verse screen
shows real RVR1960/KJV text only for studies the user explicitly created.

---

## Step 4 — Progress detail and updates ✅ (approved)

- [x] Per-chapter verse heatmap (wireframe screen `9b`): tapping a package's
      row on the Progress tab opens `PackageProgressScreen` — one card per
      chapter with a colored cell per verse (learned / difficult / neither),
      built from the same `PackageContent` + `VerseState` data the study flow
      already uses
- [x] `DownloadController.hasUpdate(package)` compares the catalog `version`
      against the installed one; Store cards and the package detail screen
      show "Update available (vX)" with an **Update** action instead of
      "Installed" once the backend publishes a newer version. Reinstalling
      cleans up the now-orphaned previous-version directory
- [x] `VersionCompare` (numeric, not lexical, dotted-version compare) +
      `CatalogPackage.isSupported` flag packages whose `minAppVersion` is
      above `AppConfig.appVersion`: the Download button is replaced with an
      explanatory message rather than hiding the package outright
- [x] Tests: `VersionCompare` unit tests, `hasUpdate` + orphan-cleanup on
      reinstall

**Acceptance:** the heatmap reflects real per-verse state; a bumped package
version shows an update.

---

## Step 5 — Offline catalog cache ⬅️ implemented, pending review

- [x] `CatalogCacheStore` persists the last successful catalog response to
      disk (`catalog-cache.json`, atomic temp-then-rename, same pattern as
      the other stores)
- [x] `CatalogController.load()` shows the cached catalog immediately (no
      spinner) while refreshing from the network in the background
- [x] If cached packages are already showing and the refresh fails, they
      stay on screen — a banner shows "Last updated Xm/h/d ago" normally, or
      "Could not refresh — showing the last known list" when stale. A true
      cold start with no cache and no network still shows the full error +
      Retry screen (nothing to show yet)
- [x] Tests: cold start with no network still lists the previously cached
      packages (`catalog_controller_test.dart`), successful load persists to
      disk, no-cache + failed network still errors correctly

**Acceptance:** airplane mode on a second launch still shows the Store list.

