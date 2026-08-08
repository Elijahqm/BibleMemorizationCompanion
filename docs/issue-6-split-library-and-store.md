# Issue #6 — Split Library and Store into separate top-level nav tabs

- **Issue:** https://github.com/Elijahqm/BibleMemorizationCompanion/issues/6
- **Priority:** P0 (foundational) — Order 2 of 9
- **Assignee:** hugoqui
- **Labels:** `enhancement`, `mobile`, `priority-P0`
- **Status:** Open
- **Dependencies:** None hard. Soft-ordered after #5 (land after it so the new nav bar picks up the rebuilt theme).

---

## Context

`AppShell` still uses a `LibraryPane` segmented control (`Downloads`/`Store`) nested inside a single "Library" tab. `docs/05-mobile-app-frontend-plan.md` (updated against the claude.ai/design mockup) specifies 5 flat top-level tabs: **Studies / Library / Store / Progress / Settings**, with Store as its own destination, not nested under Library. This is a structural information-architecture difference, not cosmetic.

Two additional gaps from the mockup belong in this same rebuild (both touch the same nav/app-chrome widgets this issue rewrites):

### Gap 1 — Nav bar is the wrong shape

The mockup's bottom bar is a **floating capsule**, not a docked full-width `NavigationBar`.

Spec from `docs/Bible Memorization Companion (standalone).html`:

```
position: absolute; left: 20px; right: 20px; bottom: 28px;
height: 64px; border-radius: 32px;
background: {{ th.navBg }}; backdrop-filter: blur(16px);
box-shadow: 0 12px 28px oklch(0.3 0.02 260 / 0.18);
```

- Inset 20px from side edges, 28px off the bottom.
- Fully rounded (radius = half the height), translucent/blurred `navBg`, floating over content rather than pushing it up.
- Each destination's selected state is a **pill wrapping both icon and label together** (`background: oklch(0.3 0.02 260 / 0.08); border-radius: 999px`), NOT Material 3's default indicator (which only pills the icon, label sits outside below).
- Needs a **custom widget** — Material's `NavigationBar` can't produce this via theming alone — built as a `Stack`-positioned floating overlay (`Scaffold(extendBody: true)`), not a themed stock component.

### Gap 2 — Remove the hamburger menu / side drawer

The mockup has no side drawer. Required removals:

- `_AppDrawer` (leftover MVP chrome: catalog/installed counts + "Guest mode" note).
- The `AppBar`'s auto-generated hamburger icon.
- Settings is reachable as its own nav destination instead.

### Gap 3 — Multi-language (i18n)

Since this stage rewrites all the app chrome (nav bar, AppBar, titles, labels), wire in localization at the same time so no string has to be hard-coded twice.

- Detect the device/OS language at startup (Flutter: `WidgetsBinding.instance.platformDispatcher.locale` / `MediaQuery`) and resolve it against the set of supported locales.
- Fall back to a default locale (e.g. `en`) when the device language is not supported; the app must never render untranslated or empty strings.
- Use `flutter_localizations` + `flutter gen-l10n` (`l10n.yaml`, `.arb` resources for each `Locale`) so Material components (back-tooltips, date pickers, etc.) are localized as well, not just our own labels.
- All user-facing strings in the rewritten chrome (nav destinations: Studies/Library/Store/Progress/Settings, Store catalog actions, empty/error states, retry, freshness banner) go through the generated `AppLocalizations` lookups instead of literals.
- Wire `MaterialApp` with `locale`, `supportedLocales`, `localizationsDelegates`, and `localeResolutionCallback`.
- Nav labels are translated in the selected language; the pill width/geometry must accommodate the longest label per locale (no overflow).

---

## Acceptance criteria

- [ ] Bottom nav is a custom floating capsule bar (not a stock `NavigationBar`) matching the spec above — inset margins, 32px corner radius, blurred translucent background, drop shadow — with 5 destinations in this order: Studies, Library, Store, Progress, Settings
- [ ] Selected destination renders as a single pill covering both icon and label; unselected destinations have no pill background
- [ ] Screen content extends behind the floating bar (`extendBody`-style), not letterboxed above it, matching the mockup's overlay behavior
- [ ] `_AppDrawer` and the `Scaffold`'s `drawer:` are removed; the AppBar no longer shows a hamburger icon
- [ ] `LibraryPane` enum and segmented-control switching logic removed; Library shows only installed/downloaded packages (no pane switcher)
- [ ] Store becomes its own top-level screen showing the full catalog list (the content previously in the "Store" pane), preserving existing behavior: pull-to-refresh, retry, catalog freshness banner, package cards with download/buy actions
- [ ] `_buildPage()` switch and `_titleForIndex()` updated for the new 5-index mapping
- [ ] Device language detected at startup; app shows all chrome text (nav labels, AppBar, catalog actions, empty/error states, retry, freshness banner) in that language via `AppLocalizations`, with fallback to a default locale when unsupported
- [ ] Material components (e.g. back-tooltips) localized too; no hard-coded user-facing strings remain in the rewritten chrome
- [ ] Existing widget test asserting nav labels updated to expect all 5 destinations, including "Store" as distinct from "Library"
- [ ] Manual check: Store → package detail → back returns to the Store tab (not Library); Library → installed package → Open still routes to the Studies tab as before
- [ ] `flutter test` passes

---

## Referenced docs

- `docs/05-mobile-app-frontend-plan.md` — source of the 5-tab IA and theme
- `docs/Bible Memorization Companion (standalone).html` — mockup with exact nav bar spec
- Flutter i18n docs — `flutter_localizations` + `flutter gen-l10n` (`.arb`), locale resolution and fallback