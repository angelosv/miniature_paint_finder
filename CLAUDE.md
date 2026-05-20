# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (`miniature_paint_finder`, Dart SDK `^3.7.2`) targeting iOS and Android. Helps miniature hobbyists track paint inventory, wishlists, palettes, and find equivalent colors across brands. Web/macOS/Linux/Windows scaffolding exists but is not the primary target.

Backend: `https://paints-api.reachu.io/api` (dev/prod share the same host; staging is `staging-paints-api.reachu.io`).

## Common commands

```bash
flutter pub get                              # install deps
cd ios && pod install && cd ..               # iOS setup (required after pubspec changes)
flutter run                                  # dev run
flutter analyze                              # lint (uses flutter_lints)

# Release builds — sets dart-defines for ENVIRONMENT/API_BASE_URL/DEBUG_MODE/SESSION_REPLAY_*:
./scripts/build.sh development ios           # or staging/production, ios/android/web

# Tests — note that scripts/test.sh skips service tests (need mock setup):
./scripts/test.sh unit                       # config + widget tests only
./scripts/test.sh all                        # adds integration + coverage (genhtml optional)
flutter test test/config/app_config_test.dart   # single file
flutter test --name "should return correct API URL"   # single test by name
```

A `.env` file at the repo root is loaded by `flutter_dotenv` (declared as an asset in `pubspec.yaml`). Without it the app still boots — `AppConfig` falls back to defaults — but env-driven overrides won't apply.

## Architecture

### Cache-first data flow

The core architectural decision is a **cache-first** read path documented across the root-level `*_CACHE_OPTIMIZATION.md` files and `CACHE_IMPLEMENTATION_GUIDE.md`. Four `ChangeNotifier` cache services live in `lib/services/`:

- `LibraryCacheService` — full paint catalog (wraps `PaintApiService`)
- `InventoryCacheService` — user's owned paints (wraps `InventoryService`)
- `WishlistCacheService` — user's wishlist (wraps `PaintService`)
- `PaletteCacheService` — user's palettes

Reads return cached data immediately, then background-sync from the API and notify listeners. Writes use **optimistic updates** with rollback on API failure, and queue offline operations to replay on reconnect. Screens (`lib/screens/`) and controllers (`lib/controllers/`) consume these via `Provider`; do not bypass them by calling the underlying API services directly from UI code unless you are intentionally going around the cache.

### Cache migration

`main.dart` reads `cache_version` from `SharedPreferences` and, if it differs from the in-code `currentCacheVersion` (currently `'1.0.0'`), clears all keys prefixed `library_cache_`, `inventory_cache_`, `wishlist_cache_`, `palette_cache_`. **Bump that constant whenever you change cache schema** — there is no per-service migration code.

### Dependency wiring

`main.dart` is the single composition root. It builds `ApiService`, repositories (`PaintRepositoryImpl`, `ApiPaletteRepository`, `ApiProjectRepository`), the four cache services, `AuthService`, and `MixpanelService`, then injects everything through one `MultiProvider`. There is no other DI framework — adding a new top-level service means registering it here.

`ApiService` (`lib/services/api_service.dart`) automatically attaches a Firebase ID token (`FirebaseAuth.instance.currentUser?.getIdToken()`) to every request. All authenticated endpoints rely on this; do not add a parallel HTTP client.

### Config

`lib/config/app_config.dart` resolves each setting in this order: `String.fromEnvironment(...)` (build-time `--dart-define`) → `dotenv.env[...]` → per-environment default in the switch. `scripts/build.sh` is the canonical way to pass dart-defines for release builds. `Environment` is currently hardcoded to `development` in `main.dart` (`AppConfig.initialize(env: Environment.development)`) — the actual environment is driven by the API_BASE_URL/DEBUG_MODE values passed at build time, not by this enum.

### Auth + guest mode

`AuthService` supports Firebase email/password, Google, Apple (`sign_in_with_apple`, enabled on this branch), and phone auth, plus a **guest mode** (no Firebase user) gated by a server flag fetched from `/flags/guest-logic` and exposed via `GuestLogicProvider`. Guest-accessible features are listed in `GuestService`; use `AuthUtils.checkFeatureAccess()` before any restricted action. See `GUEST_MODE.md`.

### Analytics

`MixpanelService` is a singleton initialized in a `Future.microtask` (non-blocking). `AnalyticsRouteObserver` (registered on `MaterialApp`) tracks navigation automatically, and screens can mix in `ScreenAnalyticsMixin` (`lib/screens/screen_analytics.dart`) for per-screen events. See `docs/MIXPANEL_INTEGRATION.md`.

## Platform-specific gotchas

- **iOS minimum**: deployment target is **15.5**, configured in the `Podfile`'s `post_install`.
- **Apple Silicon Macs**: `MLImage.framework` / `mobile_scanner` builds often fail on simulators. The full recovery sequence (clean, `pod install`, `lipo -thin arm64` workaround) is documented in `docs/SETUP_GUIDE.md` — follow it before debugging build errors further.
- **`flutter_local_notifications`** is overridden to the MaikuB master branch via `dependency_overrides` in `pubspec.yaml` (the pub.dev version is incompatible). `flutter pub get` will fetch from git.
- **`flutter_barcode_scanner`** is commented out in `pubspec.yaml`; use `mobile_scanner` instead.

## Repo hygiene notes

- `lib/components/paint_list_tab.dart.bak` and the root-level `fix.sh` (a one-shot `sed` patch against line 1616 of `paint_list_tab.dart`) are leftover repair artifacts — do not rely on them.
- `test_wishlist.dart` at the repo root is a stray script, not part of the `test/` suite.
- The numerous root-level `*.md` files (cache guides, executive summary, testing checklist, etc.) are historical design docs for the cache rollout. `README_CACHE_SYSTEM.md` is the entry point if you need that context.
