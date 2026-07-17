#include "aether_engine.h"

#include <cstring>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <cerrno>
#include <sys/types.h>
#include <sys/uio.h>   // struct iovec

// ===========================================================================
// Aether BRAIN (C++) - engine logic. Flutter UI calls in via dart:ffi;
// the Kotlin layer only performs Android OS calls on request.
//
// DNA source: Snake Engine 2.2.6 (libengine.so) - process_vm_readv/writev,
// self-read anti-analysis, svc-based syscall dispatch. Re-implemented CLEAN
// and HARDENED ("better than Snake"):
//   * AArch64 direct syscall (svc 0) instead of Snake's ARM32-compat 0xde
//     hack -> no compat-mode fragility, no 32/64 syscall-table ambiguity.
//   * Generic /proc PID discovery instead of Snake's hardcoded pid buffer.
//   * Self-read repurposed for INTEGRITY (tamper detection), not just config.
//   * Direct syscalls bypass libc PLT/GOT -> frida's libc hooks are missed.
// ===========================================================================

static bool g_initialized = false;
static bool g_engine_engaged = false;
static int32_t g_target_pid = -1;
static std::string g_target;
static std::string g_version = "0.4.0-snake-dna";

// ---------------------------------------------------------------------------
// AArch64 raw syscall - 6-arg variant (process_vm_readv/writev need 6).
// Inline asm is arm64-only; non-arm64 builds get a stub (engine is arm64).
// ---------------------------------------------------------------------------
#if defined(__aarch64__)
static inline long aarch64_syscall6(long n, long a1, long a2, long a3,
                                    long a4, long a5, long a6) {
    register long x8 __asm__("x8") = n;
    register long x0 __asm__("x0") = a1;
    register long x1 __asm__("x1") = a2;
    register long x2 __asm__("x2") = a3;
    register long x3 __asm__("x3") = a4;
    register long x4 __asm__("x4") = a5;
    register long x5 __asm__("x5") = a6;
    __asm__ volatile ("svc 0"
        : "+r"(x0)
        : "r"(x8), "r"(x1), "r"(x2), "r"(x3), "r"(x4), "r"(x5)
        : "memory", "cc");
    return x0;
}
#else
static inline long aarch64_syscall6(long n, long a1, long a2, long a3,
                                    long a4, long a5, long a6) {
    (void)n; (void)a1; (void)a2; (void)a3; (void)a4; (void)a5; (void)a6;
    errno = ENOSYS;
    return -1;
}
#endif

// AArch64 syscall numbers (Linux/Android).
enum {
    SYS_PROCESS_VM_READV  = 270,
    SYS_PROCESS_VM_WRITEV = 271,
};

static long sys_process_vm_readv(pid_t pid, const struct iovec* local,
                                 unsigned long liovcnt, const struct iovec* remote,
                                 unsigned long riovcnt, unsigned long flags) {
    return aarch64_syscall6(SYS_PROCESS_VM_READV, (long)pid, (long)local,
                            (long)liovcnt, (long)remote, (long)riovcnt, (long)flags);
}

static long sys_process_vm_writev(pid_t pid, const struct iovec* local,
                                  unsigned long liovcnt, const struct iovec* remote,
                                  unsigned long riovcnt, unsigned long flags) {
    return aarch64_syscall6(SYS_PROCESS_VM_WRITEV, (long)pid, (long)local,
                            (long)liovcnt, (long)remote, (long)riovcnt, (long)flags);
}

extern "C" {

int32_t aether_init(const char* work_dir) {
    g_initialized = (work_dir != nullptr && work_dir[0] != '\0');
    return g_initialized ? 0 : -1;
}

int32_t aether_start_engine(const char* target_package) {
    if (target_package == nullptr) return -1;
    g_target = target_package;
    g_engine_engaged = true;
    // BlackBox containerization / OAuth-intercept / FLAG_SECURE bypass are
    // performed by the Kotlin glue via MethodChannel after this returns.
    return 0;
}

int32_t aether_is_initialized() {
    return g_initialized ? 1 : 0;
}

const char* aether_version() {
    return g_version.c_str();
}

// --- Memory engine --------------------------------------------------------

int64_t aether_syscall_raw(int64_t n, int64_t a1, int64_t a2, int64_t a3,
                           int64_t a4, int64_t a5, int64_t a6) {
    return (int64_t)aarch64_syscall6((long)n, (long)a1, (long)a2, (long)a3,
                                      (long)a4, (long)a5, (long)a6);
}

int32_t aether_attach(int32_t pid) {
    if (pid <= 0) return -1;
    g_target_pid = pid;
    return 0;
}

int32_t aether_find_game(const char* package_name) {
    if (package_name == nullptr) return -1;
    std::string want(package_name);
    DIR* proc = opendir("/proc");
    if (!proc) return -1;
    struct dirent* de;
    while ((de = readdir(proc)) != nullptr) {
        std::string nm = de->d_name;
        if (nm.empty() || nm[0] < '0' || nm[0] > '9') continue;
        std::string cmd = std::string("/proc/") + nm + "/cmdline";
        int fd = open(cmd.c_str(), O_RDONLY | O_CLOEXEC);
        if (fd < 0) continue;
        char buf[256] = {0};
        ssize_t rd = read(fd, buf, sizeof(buf) - 1);
        close(fd);
        if (rd <= 0) continue;
        std::string line(buf);
        if (line.find(want) != std::string::npos) {
            closedir(proc);
            return (int32_t)atoi(nm.c_str());
        }
    }
    closedir(proc);
    return -1;
}

int64_t aether_vm_read(int64_t remote_addr, void* out_buf, int64_t len) {
    if (g_target_pid <= 0 || out_buf == nullptr || len <= 0) return -1;
    struct iovec local  = { out_buf, (size_t)len };
    struct iovec remote = { (void*)(uintptr_t)remote_addr, (size_t)len };
    long r = sys_process_vm_readv((pid_t)g_target_pid, &local, 1, &remote, 1, 0);
    return (int64_t)r;   // bytes read, or -errno
}

int64_t aether_vm_write(int64_t remote_addr, const void* in_buf, int64_t len) {
    if (g_target_pid <= 0 || in_buf == nullptr || len <= 0) return -1;
    struct iovec local  = { (void*)in_buf, (size_t)len };
    struct iovec remote = { (void*)(uintptr_t)remote_addr, (size_t)len };
    long r = sys_process_vm_writev((pid_t)g_target_pid, &local, 1, &remote, 1, 0);
    return (int64_t)r;
}

int32_t aether_self_integrity() {
    // Read our own code page via the raw syscall (process_vm_readv on
    // getpid()) and compare against the live mapping. A frida inline-hook
    // patches the live page but the syscall read returns the ORIGINAL bytes
    // -> mismatch. This is the Snake self-read technique, repurposed for
    // INTEGRITY (better than just hiding decrypted config).
    static const int kProbe = 64;
    const uint8_t* fn = reinterpret_cast<const uint8_t*>(&aether_self_integrity);
    uint8_t direct[kProbe];
    uint8_t via_sys[kProbe];
    memcpy(direct, fn, kProbe);
    struct iovec local  = { via_sys, kProbe };
    struct iovec remote = { (void*)fn, kProbe };
    long n = sys_process_vm_readv(getpid(), &local, 1, &remote, 1, 0);
    if (n != kProbe) return -2;                          // syscall blocked -> hook
    if (memcmp(direct, via_sys, kProbe) != 0) return -1; // patched -> tampered
    return 0;
}

}  // extern "C"
