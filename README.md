MazdoorConnect Flutter App

Overview
- Full customer + worker prototype flow implemented with named routes, shared app state (`role` + `language`), bilingual UI, and consistent teal/amber theme.
- Includes auth (welcome, login, signup, OTP), customer booking journey, worker onboarding/dashboard journey, and shared chat/history/settings screens.

Implemented route flow
- ` / ` Welcome role selection
- `/login` and `/signup` (phone + OTP)
- Customer:
  - `/customer/home`
  - `/customer/job-posting`
  - `/customer/recommendations`
  - `/customer/worker-profile`
  - `/customer/tracking`
  - `/customer/rating`
- Worker:
  - `/worker/onboarding`
  - `/worker/dashboard`
  - `/worker/job-notification`
  - `/worker/earnings`
- Shared:
  - `/shared/chat`
  - `/shared/history`
  - `/shared/settings`

Key files
- `lib/main.dart` app bootstrap, theme, and route registration
- `lib/app_state.dart` global role/language state with `AppScope`
- `lib/data/mock_data.dart` categories/workers/jobs mock source
- `lib/screens/mazdoor_flow.dart` all implemented pages and flow navigation

Run locally
```bash
flutter pub get
flutter run
```

Test
```bash
flutter test
```

Note
- In this coding environment, `flutter` CLI is not installed, so tests could not be executed here. Please run the commands above on your machine.
