# AGENTS.md — MeroKotha

Compact context for OpenCode sessions working in this repo.

## Project type

- Single-package Flutter app (SDK `>=3.11.3 <4.0.0`).
- Firebase backend: Firestore, Auth (phone OTP), Storage, Messaging, App Check.
- State management: `flutter_riverpod` with code generation.
- Routing: `go_router`.

## Developer commands

```bash
# Install dependencies
flutter pub get

# Run locally (Android / iOS)
flutter run

# Analyze
flutter analyze

# Test — NOTE: only a stale smoke test exists (test/widget_test.dart) and it will fail
flutter test

# Regenerate Riverpod / routing .g.dart files after editing annotated providers
dart run build_runner build --delete-conflicting-outputs

# Regenerate launcher icons after changing assets/merokotha.png
flutter pub run flutter_launcher_icons:main
```

## Code generation gotchas

- `.g.dart` files are **tracked in git** (13 files) but also listed in `.gitignore`.
- Editing any `@riverpod` or `@Riverpod` annotated file requires running `build_runner`.
- Generated files will still show up in `git diff` when modified because they are tracked.

## Firebase / backend constraints

- `lib/firebase_options.dart` and `android/app/google-services.json` are in `.gitignore` but tracked.
- Firestore rules live in `firestore.rules`; they enforce three roles: `owner`, `customer`, `superAdmin`.
- App Check is configured with `playIntegrity` (Android) and `appAttest` (iOS). For local emulator testing, switch both providers to `.debug` in `lib/main.dart`.

## Architecture

- **Feature-first** structure under `lib/features/`: `auth`, `customer`, `owner`, `admin`, `chat`, `landing`, `notification`.
- **Shared** code: `lib/shared/models/`, `lib/shared/widgets/`, `lib/shared/providers/`.
- **Core** code: `lib/core/router/`, `lib/core/theme/`, `lib/core/constants/`, `lib/core/utils/`.
- Routes are centralized in `lib/core/router/app_routes.dart`; the router provider is in `lib/core/router/app_router.dart`.
- Entrypoint: `lib/main.dart` → `lib/app.dart`.

## Lint / analyzer notes

- `analysis_options.yaml` ignores `deprecated_member_use` and `use_build_context_synchronously`.
- Analyzer excludes all platform directories (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) and `build/`.

## Testing

- There is no real test suite. `test/widget_test.dart` is a leftover counter-app smoke test and will fail.

## No CI / automation

- No GitHub Actions, Makefile, or task runner scripts exist. All tasks are manual Flutter commands.
