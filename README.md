# 🌌 Aether

**BlackBox-style virtualization engine — Flutter UI + C++ brain (`libaether.so`).**

A clean-room re-implementation inspired by **Snake Engine 2.2.6** (`libengine.so`),
built to be **better than Snake**: precise AArch64 native syscalls, generic
multi-game PID discovery, and self-integrity anti-tamper. **No Ninja code,
logic, or C2 infrastructure is used or referenced.**

## Architecture (clean separation of concerns)

```
┌─────────────────────────┐
│   Flutter (Dart)  UI    │   ← view layer: status, version, LAUNCH, DIAGNOSE
│   lib/main.dart         │
│   lib/core/aether_      │
│     bindings.dart (FFI) │
└───────────┬─────────────┘
            │ dart:ffi  (DynamicLibrary.open('libaether.so'))
┌───────────▼─────────────┐
│   C++ BRAIN             │   ← all engine logic
│   native/src/           │      aether_init / aether_start_engine
│     aether_engine.cpp   │      aether_find_game / aether_attach
│   → libaether.so        │      aether_vm_read / aether_vm_write
│                         │      aether_self_integrity / aether_syscall_raw
└───────────┬─────────────┘
            │ MethodChannel "com.aether/android"
┌───────────▼─────────────┐
│   Kotlin glue           │   ← Android OS calls only (no logic)
│   MainActivity.kt        │      launch target app (BlackBox virtualized)
└─────────────────────────┘
```

- **Flutter UI** — presentation only.
- **C++ brain (`libaether.so`)** — owns engine state & logic; built via
  `externalNativeBuild` and loaded from Dart through `dart:ffi`.
- **Kotlin** — just the Flutter host + a thin `MethodChannel` handler that
  performs Android OS calls (launching the target) the brain requests.

## Snake-Engine DNA, hardened ("better than Snake")

| Capability | Snake Engine 2.2.6 | Aether (this repo) |
|------------|--------------------|--------------------|
| Memory I/O | `process_vm_readv/writev` via `svc 0` w/ ARM32-compat `0xde` hack | AArch64 native `svc 0` syscall #270/`271` — no compat fragility |
| Syscall path | mixed PLT + compat svc | **direct `svc 0`** → bypasses libc PLT/GOT frida hooks |
| Game PID discovery | hardcoded pid buffer (self-read) | generic `/proc` scan → multi-game ready |
| Anti-analysis | self-read decrypted config | self-read repurposed for **integrity** (tamper/frida detection) |
| Obfuscation | Allatori-style flat names | clean C++ namespace, debuggable build |

## Native API (`native/include/aether_engine.h`)

| Function | Purpose |
|----------|---------|
| `aether_init(work_dir)` | boot the brain |
| `aether_start_engine(pkg)` | engage for a target package |
| `aether_find_game(pkg)` | discover target PID via `/proc` |
| `aether_attach(pid)` | attach the memory engine to a PID |
| `aether_vm_read(addr,buf,len)` | read target memory (process_vm_readv) |
| `aether_vm_write(addr,buf,len)` | write target memory (process_vm_writev) |
| `aether_self_integrity()` | anti-tamper check (0 = clean) |
| `aether_syscall_raw(...)` | raw AArch64 syscall escape hatch |

## Current target (hardcoded — flexible later)
- Package: `com.miniclip.eightballpool` (8 Ball Pool)
- Set in `lib/main.dart` (`_target`) and engaged by the brain via
  `AetherEngine.startEngine(_target)`.

## Build
Local APK builds are forbidden (sandbox policy) — the APK is produced by
GitHub Actions (`scripts/github.sh` → push → CI artifact):

- Push to `main`/`develop` → builds **Debug** APK (`aether-debug` artifact).
- Tag `v*` → builds **Release** APK.
- CI (`.github/workflows/build.yml`): installs Android SDK + NDK r26b + CMake,
  runs `flutter pub get`, ensures the Gradle wrapper, then `flutter build apk`.

> Built for AArch64 only (`abiFilters 'arm64-v8a'`) — the engine is arm64 by design.

## Roadmap
- [x] Flutter UI + C++ brain scaffold, 8BP target via FFI + MethodChannel
- [x] Native memory engine: process_vm_readv/writev (AArch64 direct syscall)
- [x] Generic `/proc` game-PID discovery + attach
- [x] Self-integrity anti-tamper (syscall self-read)
- [ ] Real BlackBox containerization in the C++ brain (virtual BActivityThread)
- [ ] 8BP rendering hook + overlay/aimbot engine (migrate Snake DNA)
- [ ] FLAG_SECURE bypass + OAuth-intercept for the virtual app
- [ ] Flexible multi-app target selection

> Educational / research use only. Snake Engine is the structural reference;
> no Ninja/2.1.0 code, keys, or C2 endpoints are included.
