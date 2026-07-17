# 🌌 Aether

**BlackBox-style virtualization engine for Android — currently targeting 8 Ball Pool.**

## What it is
- **Kotlin host app** (`com.aether`) that acts as a virtualization container.
- **C++ core** (`libaether.so`) loaded via JNI — the engine that boots the
  virtualized target and (later) hooks its rendering pipeline for overlay/aimbot.
- **Proxy components** (`ProxyActivity` / `ProxyService` / `ProxyContentProvider`)
  — BlackBox-style stubs that are the extension point for real containerization.

## Current target (hardcoded — flexible later)
- Package: `com.miniclip.eightballpool` (8 Ball Pool)
- Set in `core/VirtualCore.kt` (`TARGET_PACKAGE`). Multi-app support is a
  later phase.

## Architecture
```
KaetherApp (Application)
   └─ VirtualCore.init()  ──►  NativeCore.startEngine("com.miniclip.eightballpool")
                                   └─ JNI ──► libaether.so  (aether_start_engine)
MainActivity (UI)  ──►  VirtualCore.launch()  ──►  ProxyActivity
                                                   └─ launches 8 Ball Pool
```

## Build
Local APK builds are forbidden (sandbox policy) — the APK is produced by
GitHub Actions:

- Push to `main`/`develop` → builds **Debug** APK (`aether-debug` artifact).
- Push tag `v*` → (release wiring is the next step).

CI: `.github/workflows/build.yml` installs Android SDK + NDK r26b + CMake,
then runs `:app:assembleDebug`.

## Roadmap
- [x] Native Android (Kotlin) + C++ engine scaffold, 8BP target
- [ ] Real BlackBox containerization (BActivityThread / dex load)
- [ ] 8BP rendering hook + overlay/aimbot engine (migrate Ninja logic)
- [ ] FLAG_SECURE bypass + OAuth-intercept for the virtual app
- [ ] Flexible multi-app target selection

> Educational / research use only.
