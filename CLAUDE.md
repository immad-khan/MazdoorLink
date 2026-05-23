# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Architecture

**MazdoorConnect** — a bilingual (English/Urdu) Flutter service platform connecting customers with verified workers (plumbers, electricians, carpenters). Built for Pakistan's low-literacy market with Urdu-first UI patterns.

### State management

`AppController` (ChangeNotifier) holds global `role` (customer/worker/admin) and `locale` (en/ur). Wired through `AppScope` (InheritedNotifier) — accessed via `AppScope.of(context)` throughout widgets. No persistence or backend integration.

### Routing

All routes defined in `AppRoutes` class (`lib/screens/mazdoor_flow.dart`). Uses `onGenerateRoute` with custom page transitions (fade + slide). Routes are keyed by role:
- **Customer**: `/customer/home` → `/customer/job-posting` → `/customer/recommendations` → `/customer/worker-profile` → `/customer/tracking` → `/customer/rating`
- **Worker**: `/worker/onboarding` → `/worker/dashboard` → `/worker/earnings`, `/worker/job-notification`
- **Shared**: `/shared/chat`, `/shared/history`, `/shared/settings`

### Key files

| File | Purpose |
|------|---------|
| `lib/app_state.dart` | `AppController` + `AppScope` (global role/locale state) |
| `lib/app_theme.dart` | Custom teal/amber Material 3 theme, WorkSans font, text styles |
| `lib/screens/mazdoor_flow.dart` | **~5000 lines** — contains most screens inline: auth, home, job posting, recommendations, worker profile, tracking, worker dashboard, earnings, bottom nav bar, voice overlay |
| `lib/l10n/app_localizations.dart` | Custom localization (en/ur) with ~150 keys — NOT using Flutter's intl codegen |
| `lib/data/mock_data.dart` | In-memory `ServiceCategory`, `WorkerModel`, `JobModel` definitions |
| `lib/services/notification_service.dart` | Firebase Messaging wrapper (placeholder) |
| `lib/services/speech_service.dart` | Urdu speech-to-text stub |
| `lib/services/translation_service.dart` | Google Cloud Translation stub |

### UI patterns

- **`MzScaffold`** — shared wrapper with app bar (optional back button), max-width container (430px), and `RoleBottomNav` (4 tabs with central mic button)
- **Bilingual helper**: `bilingual(context, en, ur)` reads `AppScope.isUrdu` to pick text
- **RTL**: `Directionality` set from `AppController.isUrdu` at the scaffold level
- **Voice overlay**: `VoiceOverlaySheet` bottom sheet with animated wave bars, simulated speech recognition → navigates to `/shared/history`
- **Chat screen**, **worker earnings dashboard**, **admin dashboard**, **booking history** are standalone screens in `lib/screens/`

### Testing

Single widget test at `test/widget_test.dart` — verifies app loads and renders MaterialApp.

### Dependencies

- `http` — network calls (unused in current code)
- `firebase_messaging` — push notifications (stub)
- `flutter_localizations` + `intl` — locale support
- `cupertino_icons` — iOS icon set