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

**MazdoorLink** — a bilingual (English/Urdu) Flutter app for booking inspection visits from approved plumbers and electricians. Firebase Authentication and Firestore back user profiles, visits, and legacy repair bookings.

### State management

`AppController` (ChangeNotifier) holds global `role` (customer/worker/admin) and `locale` (en/ur). Wired through `AppScope` (InheritedNotifier) — accessed via `AppScope.of(context)` throughout widgets. Role and locale preferences are persisted with SharedPreferences.

### Routing

All routes defined in `AppRoutes` class (`lib/screens/mazdoor_flow.dart`). Uses `onGenerateRoute` with custom page transitions (fade + slide). Routes are keyed by role:
- **Customer**: `/customer/home` → `/customer/workers` → `/customer/worker-public-profile` → `/customer/request-visit` → `/shared/visits`
- **Worker**: `/worker/onboarding` → `/worker/dashboard` → `/shared/visits`
- **Legacy repairs**: `/shared/history` → `/customer/tracking` and `/customer/rating` for existing jobs only

### Key files

| File | Purpose |
|------|---------|
| `lib/app_state.dart` | `AppController` + `AppScope` (global role/locale state) |
| `lib/app_theme.dart` | Custom teal/amber Material 3 theme, WorkSans font, text styles |
| `lib/screens/mazdoor_flow.dart` | Routes, navigation, auth, worker dashboard, and legacy repair screens |
| `lib/l10n/app_localizations.dart` | Custom localization (en/ur) with ~150 keys — NOT using Flutter's intl codegen |
| `lib/data/mock_data.dart` | Trade categories and Firestore worker directory model |
| `lib/services/visit_repository.dart` | Visit creation, participant-specific streams, and status changes in `visit_requests` |
| `lib/services/notification_service.dart` | Firebase Messaging wrapper (placeholder) |
| `lib/services/speech_service.dart` | Urdu speech-to-text stub |
| `lib/services/translation_service.dart` | Google Cloud Translation stub |

### UI patterns

- **`MzScaffold`** — shared wrapper with app bar (optional back button), max-width container (430px), and `RoleBottomNav` (4 tabs with central mic button)
- **Bilingual helper**: `bilingual(context, en, ur)` reads `AppScope.isUrdu` to pick text
- **RTL**: `Directionality` set from `AppController.isUrdu` at the scaffold level
- **Voice overlay**: `VoiceOverlaySheet` bottom sheet with animated wave bars, speech commands for category discovery and visits
- **Chat screen**, **worker earnings dashboard**, **admin dashboard**, **booking history** are standalone screens in `lib/screens/`

### Testing

Run `flutter test` for Dart and widget tests. See the README for the Firestore emulator tests.

### Dependencies

- `http` — network calls (including the voice assistant)
- `firebase_messaging` — push notifications (stub)
- `flutter_localizations` + `intl` — locale support
- `cupertino_icons` — iOS icon set