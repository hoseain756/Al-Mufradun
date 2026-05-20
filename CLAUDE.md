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
flutter build apk        # Build Android APK
flutter build ios        # Build iOS (requires macOS)
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

**Notification system:** `NotificationService` is a singleton (`NotificationService.instance`) that wraps `flutter_local_notifications`. It schedules one-shot zonedSchedule notifications per prayer per day across the configured range (week/month/365 days). Notifications are batched 30 at a time via `Future.wait()` to avoid blocking the UI thread. Custom adhan sound is used (`adhan` raw resource on Android, `adhan.mp3` on iOS). A `Workmanager` periodic task refreshes prayer schedules every 24h in the background (entry point: `prayerRefreshCallbackDispatcher` in `main.dart`).

**Navigation:** `MainNavigationScreen` uses a bottom `NavigationBar` with 5 tabs: Qibla, Favorites, Home (default, index 2), Prayer Times, Settings. Tab switches clear the search query. Body uses `AnimatedSwitcher` for 250ms fade transitions.

**Splash & onboarding:** Splash screen uses adaptive timing — navigates when `AppProvider.isDataReady` is true (minimum 1s branding, maximum 5s timeout). First-launch users are routed to a 3-step onboarding carousel before reaching the main screen.

**Fonts:** Three font families are in play:

- `IBM Plex Sans Arabic` (via google_fonts) — UI text (titles, labels, buttons)
- `alnasakh` (bundled) — standard adhkar/supplication text (`bodyLarge` in the text theme)
- `UthmanicHafs` (bundled) — Quranic verses (selected when `AdhkarModel.isQuranicFont` is true)

Use `AppTheme.zekrStyle()` to get the correct TextStyle for adhkar text based on the font attribute.

**Theming:** Material 3 with `ColorScheme.fromSeed` using emerald green (`0xFF10B981`) as seed color. Light, dark, and system-follow themes are defined in `AppTheme`. The M3 type scale and shape tokens are fully specified there.

**Icons:** The app uses Iconsax icons from the `icons_plus` package, aliased through `OctIcons` in `lib/theme/app_icons.dart`.

## Key Features (Redesign)

- **Dhikr counter:** Tap-to-count overlay in detail sheet with circular progress ring, haptic feedback, auto-advance to next dhikr on completion. Counts reset daily. Progress tracked per category.
- **Quick-access buttons:** Morning/evening adhkar hero buttons on Home screen for 1-tap access to the most common flows.
- **Next prayer countdown:** Prayer times screen highlights the next upcoming prayer with a live HH:MM:SS countdown timer.
- **Undo favorites:** SnackBar with 4s undo action on every favorite add/remove.
- **Loading/error/empty states:** Home screen shows skeleton during load, error+retry on failure, empty state if no data.
- **Arabic compass:** Qibla compass uses Arabic cardinal letters (ش/ج/شر/غ) instead of English.
- **Font preview:** Settings shows live preview of adhkar text at selected font size via slider (14-32px).
- **Three-way theme:** System/Light/Dark via SegmentedButton, replacing binary toggle.

## Key Conventions

- Android namespace/applicationId: `com.example.adhkar_viewer` (needs updating before production release)
- App is locked to portrait orientation
- Timezone is configured at startup via `flutter_timezone` + `timezone` package; fallback to UTC on failure
- Notification IDs use a `(prayerId * 1000) + dayOffset` scheme to avoid collisions across prayers and days
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
│   └── notification_service.dart      # Notification scheduling singleton
├── screens/
│   ├── splash_screen.dart             # Adaptive splash (data-readiness based)
│   ├── onboarding_screen.dart         # First-launch 3-step carousel
│   ├── main_navigation_screen.dart    # 5-tab NavigationBar with search reset
│   ├── home_screen.dart               # Quick-access + category grid + loading/error states
│   ├── category_adhkar_screen.dart    # Category list with progress header
│   ├── favorites_screen.dart          # Favorites list with count
│   ├── prayer_times_screen.dart       # Prayer toggles + next prayer countdown
│   ├── settings_screen.dart           # Font slider+preview, theme segmented, about, reset
│   └── qibla_compass_page.dart        # Compass with Arabic cardinals
├── widgets/
│   ├── adhkar_card.dart               # Card + detail sheet + dhikr counter + undo SnackBar
│   └── category_card.dart             # Grid card with progress bar
└── theme/
    ├── app_theme.dart                 # M3 theme config (emerald #10B981)
    └── app_icons.dart                 # Iconsax icon aliases
```

## Redesign Roadmap

- **Phase 1 (P0):** Stable IDs + migration, dhikr counter, quick-access buttons, category progress — *core use case*
- **Phase 2 (P1):** Loading/error states, adaptive splash, search clear, undo favorites, ThemeMode, JSON validation, write debouncing — *reliability*
- **Phase 3 (P2):** Next prayer countdown, Arabic compass, font preview+slider, notification batching, responsive grid — *enhancement*
- **Phase 4 (P3):** Onboarding carousel, expanded settings, haptic feedback, accessibility audit — *polish*

## Important Note

After major changes, please update this file (@CLAUDE.md). Keep this file up-to-date with the project's status.
