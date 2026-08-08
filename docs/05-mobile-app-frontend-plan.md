# 05 Mobile App Frontend Plan

## Frontend Goals

1. Build the Library and Store experience first.
2. Keep all UI states explicit (loading, empty, error, success).
3. Preserve clean navigation between package context and study context.

## Chosen Frontend Stack

- Flutter (Dart)

Suggested app structure:

1. core (theme, routing, app config)
2. features/library
3. features/studies
4. features/progress
5. features/settings
6. data (api, local db, repositories)

## Screen Inventory

1. Splash
2. First-run empty state
3. My Studies (empty and populated)
4. Library (downloaded packages)
5. Store (browse, download free packages, buy add-ons)
6. Create study (chapter, section, custom)
7. Verse study (front and revealed; revealed face renders `analysis` tags —
   individuals, locations, etc. — when the package's `availableAnalysis` is true)
8. Menu drawer
9. Sign-in bottom sheet
10. Settings
11. Appearance / reading settings (theme, font, text size)
12. Progress summary
13. Progress detail

## Navigation Structure

1. Top-level routes:
- My Studies
- Library
- Store
- Progress
- Settings

2. Context-sensitive route:
- Package detail context for active package

3. Modal routes:
- Delete confirmation
- Sign-in prompt

## State Management Plan

Use feature-scoped state modules:

1. StoreState
2. DownloadsState
3. PackageContextState
4. StudyCreationState
5. StudySessionState
6. ProgressState
7. SettingsState

Rules:
- One source of truth per feature
- Derived UI state computed from domain entities
- Side effects handled via service layer, not UI widgets
- Download actions should resolve the package's `artifactUrl` from the catalog and hand off to the download service; the UI should not assume a separate download endpoint.

## UI Component Plan

Reusable components:

1. PackageCard
2. StudyCard
3. TabSegmentControl
4. StatusButton (Download, Buy, Open)
5. EmptyStatePanel
6. ConfirmationDialog
7. VerseCard (front/back flip, learned/difficult toggles, revealed-face analysis tags)
8. ProgressBarRow
9. ChapterVerseGrid

## Frontend Milestones

1. Build static mock screens aligned to UI plan.
2. Connect static screens to local fake data.
3. Wire data to local persistence and download state.
4. Integrate real API and package installer.

## Accessibility Checklist

1. Dynamic text size support.
2. Contrast checks for themes.
3. Semantic labels for controls.
4. Touch targets minimum size.
5. Screen reader-friendly study interactions.
