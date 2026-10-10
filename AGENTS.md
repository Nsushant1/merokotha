# AGENTS.md — MeroKotha

Compact context for OpenCode sessions working in this repo.

## Project type

- Single-package Flutter app (SDK `>=3.11.3 <4.0.0`).
- Firebase backend: Firestore, Auth (Google sign-in), Storage, Messaging, App Check.
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

# Test — single widget smoke test (test/widget_test.dart)
flutter test

# Regenerate Riverpod / routing .g.dart files after editing annotated providers
dart run build_runner build --delete-conflicting-outputs

# Regenerate launcher icons after changing assets/merokotha.png
flutter pub run flutter_launcher_icons:main
```

## Code generation gotchas

- `.g.dart` files are **tracked in git** but also listed in `.gitignore`.
- Editing any `@riverpod` or `@Riverpod` annotated file requires running `build_runner`.
- Generated files will still show up in `git diff` when modified because they are tracked.

## Firebase / backend constraints

- `lib/firebase_options.dart` and `android/app/google-services.json` are git-ignored local-only files (generate via FlutterFire).
- Firestore rules live in `firestore.rules`; access is capability-based (`agentStatus: none|pending|verified`, admin `superAdmin`); legacy `role` values are display-only.
- App Check is configured with `playIntegrity` (Android) and `appAttest` (iOS). For local emulator testing, switch both providers to `.debug` in `lib/main.dart`.

## Architecture

- **Feature-first** structure under `lib/features/`: `auth`, `home` (shared home/profile/agent applications), `customer`, `owner`, `agent`, `admin`, `chat`, `landing`, `notification`.
- **Shared** code: `lib/shared/models/`, `lib/shared/widgets/`, `lib/shared/providers/`.
- **Core** code: `lib/core/router/`, `lib/core/theme/`, `lib/core/constants/`, `lib/core/utils/`.
- Routes are centralized in `lib/core/router/app_routes.dart`; the router provider is in `lib/core/router/app_router.dart`.
- Entrypoint: `lib/main.dart` → `lib/app.dart`.

## Lint / analyzer notes

- `analysis_options.yaml` ignores `deprecated_member_use` and `use_build_context_synchronously`.
- Analyzer excludes all platform directories (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) and `build/`.

## Testing

- `test/widget_test.dart` is a maintained app-shell smoke test (boots the router with mocked auth) and passes.

## No CI / automation

- No GitHub Actions, Makefile, or task runner scripts exist. All tasks are manual Flutter commands.
