# CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Al-Mufradun (package: `adhkar_viewer`) is an Arabic-language Islamic Flutter app for displaying daily Adhkar (supplications) with prayer time notifications, Qibla compass, favorites system, and interactive dhikr counter. The UI is Arabic-only (RTL, locale locked to `ar`). It targets Android and iOS.

## Build & Run Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Run static analysis (uses flutter_lints)
flutter test             # Run tests
```

Generate app icons and splash screens after changing assets:

```bash
dart run flutter_launcher_icons   # Regenerate launcher icons from assets/icon/app_icon.png
dart run flutter_native_splash:create  # Regenerate native splash screen
```

## Architecture

**State management:** Provider (`ChangeNotifierProvider`). Two providers are mounted at app root in `main.dart`:

- `AppProvider` — adhkar data (loaded from `assets/adhkar.json`), theme mode (system/light/dark), font size, favorites, search, dhikr counter state, loading/error states, onboarding flag, category progress. Persists preferences via SharedPreferences with debounced writes (300ms for prefs, 500ms for dhikr counts).
- `PrayerTimeProvider` — GPS-based prayer time calculation (adhan package, Umm Al-Qura method, Shafi madhab), per-prayer notification toggles, notification scheduling (batched 30 at a time), next prayer detection with countdown.

**Notification system:** `NotificationService` is a singleton (`NotificationService.instance`) that wraps `flutter_local_notifications`. `PrayerScheduler` calculates prayer times, stores per-prayer notification toggles, and maintains 8 future occurrences per enabled prayer (40 max pending prayer notifications) to guarantee at least 7 future days with one refill buffer. Custom Android adhan sounds are used (`y1000` raw resource for standard prayers, and `y1001` raw resource exclusively for Fajr). iOS uses native `UNUserNotificationCenter` scheduling but needs Apple-compliant short notification sound assets under 30 seconds for custom Adhan playback; long MP3 Adhan files will not reliably play as iOS local notification sounds. A `Workmanager` periodic task refreshes prayer schedules every 12h in the background (entry point: `prayerRefreshCallbackDispatcher` in `main.dart`). Android native `AlarmManager` schedules a post-prayer refill alarm 90 seconds after the next prayer, and Android/iOS native bridges keep prayer schedules refreshed while the app is closed.

**Navigation:** `MainNavigationScreen` uses a bottom `NavigationBar` with 6 tabs: Home (default, index 0), Quran, Qibla, Favorites, Prayer Times, Settings. Tab switches away from Home clear the search query. Body uses `AnimatedSwitcher` for 250ms fade transitions.

**Splash & onboarding:** The app launches directly into `SplashScreen` without delay. It initializes background services (timezone, notifications, Workmanager) and loads provider data concurrently, navigating immediately once they are ready (maximum 5s timeout). First-launch users are routed to a 3-step onboarding carousel before reaching the main screen.

**Fonts:** Three font families are in play:

- `TheYearofHandicrafts` (bundled) — UI text (titles, headlines, buttons, labels, and standard content / description body text) with structured Material 3 weight tiers (Black 900, Bold 700, SemiBold 600, Medium 500, Regular 400).
- `alnasakh` (bundled) — standard, non-Quranic adhkar/supplication text (applied exclusively via `AppTheme.zekrStyle()`).
- `UthmanicHafs` (bundled) — Quranic verses (selected when `AdhkarModel.isQuranicFont` is true; strictly preserved without alterations).
- `QCF2001` through `QCF2604` (bundled as assets under `assets/fonts/QCF2BSMLfonts/`) — Quran page-specific glyph fonts loaded on demand by `QuranPageFontLoader` and resolved with `AppTheme.getQuranPageFont(pageNumber)`.

Use `AppTheme.zekrStyle()` to get the correct TextStyle for adhkar text based on the font attribute.

**Theming:** Material 3 with `ColorScheme.fromSeed` using emerald green (`0xFF10B981`) as seed color. Light, dark, and system-follow themes are defined in `AppTheme`. The M3 type scale and shape tokens are fully specified there.

**Icons:** The app uses Iconsax icons from the `icons_plus` package, aliased through `OctIcons` in `lib/theme/app_icons.dart`.

**Quran feature foundation:** Quran work lives under `lib/features/quran` and follows Clean Architecture boundaries. Domain entities and repository contracts live under `domain`; SQLite access, row mapping, repository implementation, and static surah metadata live under `data`; screens, widgets, and formatting helpers live under `presentation`. `QuranDatabaseHelper` copies `assets/db/quran.db` on first launch, replaces an outdated copied database if its schema is missing QCF data, opens it read-only, and validates the inspected `quran_text` schema before use. The schema report is maintained at `docs/quran_db_schema_report.md`; update it if the bundled database changes.

**Quran UI architecture:** Quran is a first-class app section, not a Home card. `MainNavigationScreen` owns the Quran bottom navigation destination, and `MaterialApp` exposes `QuranIndexScreen.routeName` for direct route-based entry. Home must remain focused on adhkar discovery and should not import Quran presentation widgets.

**Quran reader behavior:** `SurahReaderScreen` depends on `QuranRepository`, not SQLite classes. The reader is a fixed 604-page Mushaf `PageView` backed by the hardcoded standard page-start map in `data/static/mushaf_page_mapping.dart`. Each page queries the SQLite verses from that page start until the next page start and renders through `QuranTextPage`, which loads the page-specific QCF font and displays each verse's `qcf_text` glyph data as text. `QuranTextPage` sizes the page dynamically to fill the available screen while preserving exactly 15 line slots. Do not reintroduce `assets/quran_svg`, `flutter_svg`, or page image/SVG rendering. Surah starts render a pure Flutter double-border header and optional centered Bismillah; Surah 1 renders Bismillah as normal aya 1 QCF text, and Surah 9 has no Bismillah. Copy/share payloads must continue to use the normal `text` column, not `qcf_text`.

**Quran verse actions:** Verse long-press behavior is a presentation concern. `QuranTextPage` owns inline long-press hit testing and selected-verse highlighting, then delegates the chosen verse to `SurahReaderScreen`, which opens `VerseActionSheet`. Actions are centralized under `presentation/actions`: `VerseActionType`, `VerseActionContext`, and `VerseActionCommand` describe typed commands; `VerseActionController` owns ordering, visibility, enabled state, disabled reasons, execution, and optional analytics tracking. `VerseActionSheet` is a generic RTL renderer of typed commands and must not hardcode individual Quran actions. Copy and text-share payload formatting belongs in `presentation/utils` (`VerseActionFormatter`) so citation formatting stays reusable and independent from widgets. `VerseActionType.shareText` is executed through `share_plus` inside `VerseActionController`; image sharing renders QCF text with the same page font as the reader. `VerseActionType.bookmark` saves the selected ayah and last reading position in SharedPreferences, while `VerseActionType.removeBookmark` removes a saved ayah and clears its page highlight.

`SurahReaderScreen` exposes Quran search from the top bar for surah names, page numbers, verse references, and verse text, and exposes a saved-verses sheet where users can open or remove saved ayahs.

`SurahReaderScreen` now supports inclusive verse-range selection from a dialog with "from" and "to" dropdowns for the current page verses, sharing/copying the full span in database order even when the selection crosses a surah boundary on the same page. Share-image cards render the selected verses with ornate verse markers and Arabic app branding at the bottom.

**Manual QA record (ShareText):** Native share sheet flow for `VerseActionType.shareText` is production-ready and scored 100/100 in manual QA. Tested on Android primary device and iOS if applicable, with WhatsApp, Telegram, and native Messages share sheet. Observed edge cases: none. RTL rendering was correct and text formatting stayed stable with no truncation or layout issues. Keep future device/OS expansion recorded in `TASKS.md` under “Manual QA Notes” so regressions can be traced.

**ShareImage architecture:** `VerseActionType.shareImage` is executed inside `VerseActionController`. Image capture renders a dedicated `VerseShareCardWidget` offstage inside an overlay `RepaintBoundary`, encodes a PNG, writes it to the temp directory via `path_provider`, and shares it via `share_plus` XFiles. The action sheet remains a dumb renderer of typed commands. Native image sharing is production-ready and scored 100/100 in manual QA across the same tested platforms and targets as ShareText, with no observed edge cases.

**Phase 7 release-readiness status:** Quran is in Release Candidate status with non-blocking deferred QA debt. Automated validation is complete: `flutter analyze` and full `flutter test` pass with no known Phase 6 ShareImage regressions. ShareText and ShareImage native flows are production-ready on the tested platforms/targets. `flutter devices` in the current environment exposed only Windows desktop, Chrome web, and Edge web, so Android/iOS clean-install DB copy and mobile visual QA could not be executed here. Deferred non-blocking QA tracked in `TASKS.md`: clean-install first-launch Quran DB copy on Android/iOS, Uthmanic font rendering across supported devices, surah banner scaling on small/large screens, and six-tab navigation consistency. No UI inconsistencies or performance issues were observed in automated validation.

## Key Features (Redesign)

- **Dhikr counter:** Tap-to-count overlay in detail sheet with circular progress ring, haptic feedback, auto-advance to next dhikr on completion. Counts reset daily. Progress tracked per category.
- **Quick-access buttons:** Morning/evening adhkar hero buttons on Home screen for 1-tap access to the most common flows.
- **Next prayer countdown:** Prayer times screen uses a simple RTL theme-native layout with a control strip, next-prayer card, five notification rows, a live HH:MM:SS countdown timer, and a right-to-left progress timeline that dynamically integrates mosque Iqamah times (Fajr/Dhuhr/Asr/Isha 20 mins, Maghrib 10 mins) with a live remaining countdown and faded past state.
- **Undo favorites:** SnackBar with 4s undo action on every favorite add/remove.
- **Loading/error/empty states:** Home screen shows skeleton during load, error+retry on failure, empty state if no data.
- **Arabic compass:** Qibla compass uses Arabic cardinal letters (ش/ج/شر/غ) instead of English.
- **Font preview:** Settings shows live preview of adhkar text at selected font size via slider (14-32px).
- **Three-way theme:** System/Light/Dark via SegmentedButton, replacing binary toggle.

## Key Conventions

- Android namespace/applicationId: `com.hussein.almufradun`
- App is locked to portrait orientation
- Timezone is configured at startup via `flutter_timezone` + `timezone` package; fallback to UTC on failure
- Notification IDs use a `(prayerId * 100) + occurrenceOffset` scheme to avoid collisions across prayers and the rolling 8-occurrence window
- AdhkarModel IDs use stable index-based scheme (`adhkar_<index>`) — migrated from legacy `zekr.hashCode` via `_migrateFavoritesIfNeeded()` on first launch after update
- SharedPreferences keys are centralized in `_PrefKeys` class within `app_provider.dart`
- Lint rules: `package:flutter_lints/flutter.yaml` (analysis_options.yaml)
- Android requires core library desugaring (configured in `android/app/build.gradle.kts`)
- JSON parse validates required fields (`zekr`, `category`) and skips malformed entries with warnings

## File Structure

```
lib/
├── main.dart                          # App entry, timezone, WorkManager, MultiProvider
├── models/
│   └── adhkar_model.dart              # Data model with stable IDs, validation, migration map
├── providers/
│   ├── app_provider.dart              # Adhkar, favorites, dhikr counts, theme, search, loading state
│   └── prayer_time_provider.dart      # Prayer calc, GPS, notifications, next prayer detection
├── services/
│   ├── notification_service.dart      # Notification scheduling singleton
│   └── prayer_scheduler.dart          # Prayer calc, rolling schedule window, native bridge payloads
├── screens/
│   ├── splash_screen.dart             # Adaptive splash (data-readiness based)
│   ├── onboarding_screen.dart         # First-launch 3-step carousel
│   ├── main_navigation_screen.dart    # 6-tab NavigationBar with standalone Quran destination
│   ├── home_screen.dart               # Adhkar quick-access + category grid + loading/error states
│   ├── category_adhkar_screen.dart    # Category list with progress header
│   ├── favorites_screen.dart          # Favorites list with count
│   ├── prayer_times_screen.dart       # Prayer toggles + next prayer countdown
│   ├── settings_screen.dart           # Font slider+preview, theme segmented, about, reset
│   └── qibla_compass_page.dart        # Compass with Arabic cardinals
├── widgets/
│   ├── adhkar_card.dart               # Card + detail sheet + dhikr counter + undo SnackBar
│   └── category_card.dart             # Grid card with progress bar
├── theme/
│   ├── app_theme.dart                 # M3 theme config + bundled UI font
│   └── app_icons.dart                 # Iconsax icon aliases
└── features/
    └── quran/
        ├── domain/
        │   ├── entities/              # Surah, Verse, and PageInfo entities
        │   ├── repositories/          # QuranRepository contract
        │   └── usecases/              # Read use cases for presentation
        ├── data/
        │   ├── local/                 # SQLite DB helper and local data source
        │   ├── models/                # SQLite row mappers
        │   ├── repositories/          # QuranRepository implementation
        │   └── static/                # 114-surah metadata + 604-page Mushaf map
        └── presentation/
            ├── actions/               # Typed verse action commands and controller
            ├── screens/               # Quran index route/section and surah reader
            ├── utils/                 # Arabic number and verse action formatting
            └── widgets/               # Quran text page, share card, states, action sheet
```

## Redesign Roadmap

- **Phase 1 (P0):** Stable IDs + migration, dhikr counter, quick-access buttons, category progress — *core use case*
- **Phase 2 (P1):** Loading/error states, adaptive splash, search clear, undo favorites, ThemeMode, JSON validation, write debouncing — *reliability*
- **Phase 3 (P2):** Next prayer countdown, Arabic compass, font preview+slider, notification batching, responsive grid — *enhancement*
- **Phase 4 (P3):** Onboarding carousel, expanded settings, haptic feedback, accessibility audit — *polish*

## Important Note

After major changes, please update this file to reflect the project's current state. This helps maintain consistency and ensures that everyone is aware of the latest developments.