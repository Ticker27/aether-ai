# 🌌 Aether

**BlackBox-style virtualization engine for 8 Ball Pool — Flutter UI + C++ brain.**

## Architecture (clean separation of concerns)

```
┌─────────────────────────┐
│   Flutter (Dart)  UI    │   ← view layer: status, version, LAUNCH button
│   lib/main.dart         │
│   lib/core/aether_      │
│     bindings.dart (FFI) │
└───────────┬─────────────┘
            │ dart:ffi  (DynamicLibrary.open('libaether.so'))
┌───────────▼─────────────┐
│   C++ BRAIN             │   ← all engine logic
│   native/src/           │      aether_init / aether_start_engine
│     aether_engine.cpp   │      / aether_is_initialized / aether_version
│   → libaether.so        │
└───────────┬─────────────┘
            │ MethodChannel "com.aether/android"
┌───────────▼─────────────┐
│   Kotlin glue           │   ← Android OS calls only (no logic)
│   MainActivity.kt        │      launch target app (8 Ball Pool)
└─────────────────────────┘
```

- **Flutter UI** — presentation only.
- **C++ brain (`libaether.so`)** — owns engine state & logic; built via
  `externalNativeBuild` and loaded from Dart through `dart:ffi`.
- **Kotlin** — just the Flutter host + a thin `MethodChannel` handler that
  performs Android OS calls (launching the target) the brain requests.

## Current target (hardcoded — flexible later)
- Package: `com.miniclip.eightballpool` (8 Ball Pool)
- Set in `lib/main.dart` (`_target`) and engaged by the brain via
  `AetherEngine.startEngine(_target)`.

## Build
Local APK builds are forbidden (sandbox policy) — the APK is produced by
GitHub Actions:

- Push to `main`/`develop` → builds **Debug** APK (`aether-debug` artifact).
- CI (`.github/workflows/build.yml`): installs Android SDK + NDK r26b + CMake,
  runs `flutter pub get`, ensures the Gradle wrapper, then `flutter build apk --debug`.

## Roadmap
- [x] Flutter UI + C++ brain scaffold, 8BP target via FFI + MethodChannel
- [ ] Real BlackBox containerization in the C++ brain
      (load target dex into virtual BActivityThread)
- [ ] 8BP rendering hook + overlay/aimbot engine (migrate Ninja logic)
- [ ] FLAG_SECURE bypass + OAuth-intercept for the virtual app
- [ ] Flexible multi-app target selection

> Educational / research use only.
