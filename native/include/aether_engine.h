#pragma once
#include <cstdint>
#include <cstddef>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// Aether BRAIN — public C ABI (called from Flutter/Dart via dart:ffi).
// All engine logic lives in native/src/aether_engine.cpp.
// ---------------------------------------------------------------------------
int32_t aether_init(const char* work_dir);
int32_t aether_start_engine(const char* target_package);
int32_t aether_is_initialized();
const char* aether_version();

// --- Memory engine (Snake-Engine DNA, hardened) ---------------------------
// Raw AArch64 syscall (svc 0). Bypasses libc PLT/GOT hooks -> anti-frida.
//   n        = syscall number
//   a1..a6   = up to 6 args
// Returns the kernel return value (negative == -errno).
int64_t aether_syscall_raw(int64_t n, int64_t a1, int64_t a2, int64_t a3,
                           int64_t a4, int64_t a5, int64_t a6);

// Attach the engine to a target game process (by PID). Returns 0 on success.
int32_t aether_attach(int32_t pid);

// Discover a game's PID by scanning /proc (generic, multi-game capable -
// better than Snake's hardcoded pid buffer). Returns PID or -1.
int32_t aether_find_game(const char* package_name);

// Read `len` bytes from the target's address space into `out_buf`.
// Returns bytes read (>=0) or negative errno.
int64_t aether_vm_read(int64_t remote_addr, void* out_buf, int64_t len);

// Write `len` bytes from `in_buf` into the target's address space.
int64_t aether_vm_write(int64_t remote_addr, const void* in_buf, int64_t len);

// Anti-analysis: self-integrity via process_vm_readv(getpid()).
// Detects code patching / frida injection. Returns 0 = clean, <0 = tampered.
int32_t aether_self_integrity();

// --- Game-memory scanner (the heart: fluid / traceless / flexible) --------
// Resolve a pointer chain: out = *(*(base + off[0]) + off[1]) ... + off[n-1].
// The standard technique for reaching dynamic game values (HP/score/aim).
// Returns the final address, or 0 on failure. (traceless: process_vm only)
int64_t aether_resolve_chain(int64_t base, const int64_t* offsets, int32_t count);

// Typed game-value access (all via process_vm - no file artifacts).
int32_t aether_read_i32(int64_t addr);
int64_t aether_read_i64(int64_t addr);
float   aether_read_f32(int64_t addr);
int32_t aether_write_i32(int64_t addr, int32_t value);
int32_t aether_write_f32(int64_t addr, float value);

#ifdef __cplusplus
}
#endif
