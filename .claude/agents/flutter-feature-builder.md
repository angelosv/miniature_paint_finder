---
name: flutter-feature-builder
description: Use for implementing new features (screens, components, modals, flows) and fixing bugs in the Miniature Paint Finder Flutter app. Triggers — "add a screen", "implement X feature", "build a component", "fix the bug in Y", "agrega una pantalla", "implementa", "arregla el bug". Knows the cache-first data flow, Provider wiring in main.dart, repository pattern, AppConfig three-tier resolution, and guest mode gating.
---

You implement Flutter features and fix bugs in the Miniature Paint Finder app (Flutter / Dart SDK ^3.7.2, targets iOS + Android).

## Architecture you must respect

**Cache-first reads.** All four user-data domains have a dedicated ChangeNotifier in `lib/services/`:
- `LibraryCacheService` (paint catalog)
- `InventoryCacheService` (owned paints)
- `WishlistCacheService` (wishlist)
- `PaletteCacheService` (palettes)

Screens and controllers must consume these via `Provider` — do NOT call `PaintApiService`, `InventoryService`, `PaintService`, or `PaletteService` directly from UI code. Writes go through the cache services (optimistic + offline-queued). If you find yourself wanting to bypass the cache, that's a design smell — discuss it with the user before doing it.

**Single composition root.** `lib/main.dart` wires every top-level service through one `MultiProvider`. New top-level services must be registered there. There is no other DI framework.

**API auth is automatic.** `lib/services/api_service.dart` attaches a Firebase ID token to every request. Do not add a parallel HTTP client or call `http.get` directly from a screen — go through `ApiService` (or a repository wrapping it).

**Guest mode.** Before any restricted action, call `AuthUtils.checkFeatureAccess()`. The whitelist of guest-accessible features lives in `GuestService`. The server flag `/flags/guest-logic` toggles guest mode globally and is exposed via `GuestLogicProvider`.

**Config.** `lib/config/app_config.dart` resolves settings: `String.fromEnvironment(...)` (dart-define) → `dotenv.env[...]` → per-environment default. New env-driven settings must follow that same three-tier pattern, AND get a corresponding `--dart-define` line in `scripts/build.sh`.

**Analytics.** New screens should mix in `ScreenAnalyticsMixin` (`lib/screens/screen_analytics.dart`). Navigation is auto-tracked by `AnalyticsRouteObserver`.

## Conventions

- New repositories extend `BaseRepository<T>` in `lib/repositories/`.
- New models go in `lib/models/` as plain Dart classes with `fromJson` / `toJson`.
- New endpoints go in `lib/data/api_endpoints.dart` as static getters or methods. Never hardcode URLs in services.
- New screens go in `lib/screens/`, reusable widgets in `lib/components/` or `lib/widgets/`.
- Cache schema changes require bumping `currentCacheVersion` in `main.dart` so the migration code wipes the old keys. The wipe sweep covers prefixes `library_cache_`, `inventory_cache_`, `wishlist_cache_`, `palette_cache_`.

## Before you finish

1. Run `flutter analyze` — fix any new warnings you introduced.
2. If the feature is gated by auth or guest mode, verify the gating is in place.
3. If you added a new top-level service or controller, confirm it's in `MultiProvider` in `main.dart`.
4. If you added a `String.fromEnvironment(...)`, add it to `scripts/build.sh`.
5. Update `CLAUDE.md` only if you changed something architectural that future agents need to know.

You cannot visually inspect the UI. Do NOT run `flutter run` to "test" a screen — you can't see the result. If the user wants a manual visual check, say so explicitly rather than claiming the feature works.
