#include "aether_engine.h"

#include <cstring>
#include <string>

// ===========================================================================
// Aether BRAIN (C++) — all engine logic lives here.
// The Flutter UI talks to this via dart:ffi; the Kotlin layer only performs
// Android OS calls (e.g. launching the target) on request.
// ===========================================================================

static bool g_initialized = false;
static bool g_engine_engaged = false;
static std::string g_target;
static std::string g_version = "0.3.0-flutter-bb";

extern "C" {

int32_t aether_init(const char* work_dir) {
    g_initialized = (work_dir != nullptr && work_dir[0] != '\0');
    return g_initialized ? 0 : -1;
}

// BRAIN: engage the virtualization engine for a target package.
// 8 Ball Pool is the hardcoded target for now; flexible later.
int32_t aether_start_engine(const char* target_package) {
    if (target_package == nullptr) return -1;
    g_target = target_package;
    g_engine_engaged = true;

    // TODO(flexible-later): real BlackBox virtualization plumbing —
    //   * load target dex into a virtual container (BActivityThread)
    //   * hook 8BP rendering pipeline for overlay / aimbot
    //   * FLAG_SECURE bypass so the virtual app is capturable
    //   * OAuth-intercept for the virtual app's social login
    // The actual Android launch is executed by the Kotlin glue via
    // MethodChannel after this call returns.
    return 0;
}

int32_t aether_is_initialized() {
    return g_initialized ? 1 : 0;
}

const char* aether_version() {
    return g_version.c_str();
}

}  // extern "C"
