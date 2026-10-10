# MeroKotha

Find and list rental rooms in Nepal. Single-package Flutter app with a
Firebase backend (Firestore, Auth via Google sign-in, Storage, Cloud
Messaging, App Check).

Every signed-in user can browse rooms and post their own listings from
one shared home screen — no role switching. Verified agents (approved
via in-app application + admin review) get a separate Agent interface;
admins get an admin panel.

## Tech

- Flutter (`>=3.11.3 <4.0.0`), `flutter_riverpod` with code generation,
  `go_router` (routes in `lib/core/router/app_routes.dart`).
- Entrypoint: `lib/main.dart` → `lib/app.dart`.
- Feature-first layout under `lib/features/` (`auth`, `home`, `customer`,
  `owner`, `agent`, `admin`, `chat`, `landing`, `notification`).

## Developer commands

```bash
flutter pub get
flutter run          # Android / iOS
flutter analyze
flutter test         # widget smoke test (test/widget_test.dart)

# Regenerate .g.dart files after editing annotated providers
dart run build_runner build --delete-conflicting-outputs

# Regenerate launcher icons after changing assets/merokotha.png
flutter pub run flutter_launcher_icons:main
```

## Firebase

- Rules: `firestore.rules`, `storage.rules`; indexes:
  `firestore.indexes.json`; functions: `functions/` (Node 20).
- `lib/firebase_options.dart` and `android/app/google-services.json` are
  local-only (git-ignored) — generate via FlutterFire before building.
- Release process: `docs/android-release-checklist.md`.
- One-time owner-contact backfill: `scripts/backfill-owner-contact.mjs`.
