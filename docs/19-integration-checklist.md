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

## Step 3 — Real study content ⬅️ implemented, pending review

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

## Step 4 — Progress detail and updates

- [ ] Per-chapter verse heatmap (wireframe screen `9b`) — learned/to-learn
      grid per package
- [ ] Compare catalog `version` with the installed one → "Update available"
- [ ] Respect `minAppVersion` (hide or flag unsupported packages)

**Acceptance:** the heatmap reflects real per-verse state; a bumped package
version shows an update.

---

## Step 5 — Offline catalog cache

- [ ] Persist the last catalog response to disk (`path_provider`)
- [ ] On launch: show the cached catalog immediately, refresh in background
- [ ] Show "last updated" / stale indicator when the refresh fails
- [ ] Test: cold start with no network still lists packages

**Acceptance:** airplane mode on a second launch still shows the Store list.

---

## Step 6 — Localization (en / es, follows the device) — LAST

Deliberately left for the end: it needs its own discussion (which languages we
commit to, app language vs content language, whether the user can override the
device locale, how it interacts with the catalog's `language` field). Until then
the UI stays in English.

- [ ] Decide scope first (see the questions above)
- [ ] Add `flutter_localizations` + `intl`, enable `generate: true` (gen-l10n)
- [ ] `lib/l10n/app_en.arb` and `app_es.arb`
- [ ] Move every hardcoded string into ARB files
- [ ] `MaterialApp`: `localizationsDelegates`, `supportedLocales`, English fallback
- [ ] Language setting tile shows the resolved language (Auto)
- [ ] Test: pump with `locale: Locale('es')` and assert a translated label

**Acceptance:** phone in Spanish → app in Spanish; phone in French → English fallback.
