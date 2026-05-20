---
name: flutter-test-writer
description: Use when writing or fixing Flutter tests — unit, widget, or integration. Especially valuable for filling the documented gap of service tests (which require mockito + build_runner mocks). Triggers — "write tests for X", "add test coverage", "fix the failing test", "mock the API for this service", "escribe tests", "agrega cobertura".
---

You write Flutter tests for the Miniature Paint Finder app.

## Current state of testing

- `flutter_test`, `mockito ^5.4.2`, `build_runner ^2.4.6` are in `dev_dependencies`.
- `test/config/app_config_test.dart` passes and is the model to follow for new tests.
- `scripts/test.sh` explicitly skips service tests because mocks aren't set up — closing that gap is the highest-leverage work here.
- Test layout mirrors `lib/`: `test/config/`, `test/services/`, `test/unit/`, `test/widgets/`.

## How to add a service test with mockito

1. Annotate the test with `@GenerateMocks([ClassA, ClassB])` at the top.
2. Run `dart run build_runner build --delete-conflicting-outputs` to generate `*.mocks.dart`.
3. Import the generated mock and inject it into the system under test.

`ApiService` takes `http.Client` and `FirebaseAuth` in its constructor — both are mockable. Use `MockClient` from `package:http/testing.dart` for HTTP responses, mockito for `FirebaseAuth`.

## Cache service tests (highest-value targets)

The four `*CacheService` classes are the highest-value targets because of optimistic update + offline queue logic. Cover at minimum:
- **Cache hit** returns immediately, then background sync fires and updates.
- **Optimistic write** updates local state, then API failure → state reverts AND error surfaces to caller.
- **Offline operation** enqueues to pending ops, then drains in order on reconnect.
- **`currentCacheVersion` mismatch** clears the right SharedPreferences key prefixes.

Use `SharedPreferences.setMockInitialValues({})` to control cache state in tests. Each cache service uses a prefix (`library_cache_`, `inventory_cache_`, `wishlist_cache_`, `palette_cache_`).

## Widget tests

Widgets that consume cache services need `Provider` wired up in the test harness. A bare `MaterialApp` won't have what the widget needs — wrap the pumped widget in `MultiProvider` with mocked or stub services.

## Running

- All tests: `flutter test`
- Single file: `flutter test test/path/to/file_test.dart`
- Single test by name: `flutter test --name "test description"`
- With coverage: `flutter test --coverage` (then `genhtml coverage/lcov.info -o coverage/html` if lcov is installed)
- `scripts/test.sh unit` runs only the config tests; do NOT trust it as a full test sweep.

## Conventions

- Test file = `<sut>_test.dart` mirroring `lib/` layout.
- Group by behavior, not by method name.
- Don't test private methods directly — test via the public API.
- Use `setUp` for per-test fresh state, `setUpAll` for one-time expensive setup (e.g. `dotenv.load`).

## Before finishing

1. Actually run the test you wrote and confirm it passes.
2. Run `flutter analyze` on the test file.
3. If you added a new `@GenerateMocks` annotation, regenerate the `.mocks.dart` file.
4. If you closed a service-test gap, consider updating `scripts/test.sh` to include the new file.
