#include "aether_engine.h"

#include <jni.h>
#include <string>
#include <android/log.h>

static const char* TAG = "AetherEngine";
static bool g_initialized = false;
static std::string g_target;
static std::string g_version = "0.2.0-bb8bp";

// ---------------------------------------------------------------------------
// Core C API (libaether.so)
// ---------------------------------------------------------------------------
extern "C" {

int32_t aether_init(const char* work_dir) {
    g_initialized = (work_dir != nullptr && work_dir[0] != '\0');
    __android_log_print(ANDROID_LOG_INFO, TAG,
        "aether_init work_dir=%s initialized=%d",
        work_dir ? work_dir : "(null)", g_initialized ? 1 : 0);
    return g_initialized ? 0 : -1;
}

// Boot the virtualization engine for a target package (8 Ball Pool now).
int32_t aether_start_engine(const char* target_package) {
    if (target_package == nullptr) return -1;
    g_target = target_package;
    g_initialized = true;
    __android_log_print(ANDROID_LOG_INFO, TAG,
        "aether_start_engine target=%s [BlackBox virtualization host]", target_package);
    // TODO(flexible-later): real BlackBox plumbing — load target dex into a
    // virtual BActivityThread, hook 8BP rendering pipeline for overlay/aimbot,
    // apply FLAG_SECURE bypass, OAuth-intercept for the virtual app.
    return 0;
}

int32_t aether_is_initialized() { return g_initialized ? 1 : 0; }
const char* aether_version() { return g_version.c_str(); }

}  // extern "C"

// ---------------------------------------------------------------------------
// JNI bridge for com.aether.core.NativeCore
// ---------------------------------------------------------------------------
static jstring jstr(JNIEnv* env, const char* s) {
    return env->NewStringUTF(s ? s : "");
}

extern "C" JNIEXPORT jint JNICALL
Java_com_aether_core_NativeCore_aetherInit(JNIEnv* env, jclass, jstring workDir) {
    const char* w = workDir ? env->GetStringUTFChars(workDir, nullptr) : nullptr;
    int r = aether_init(w);
    if (w) env->ReleaseStringUTFChars(workDir, w);
    return r;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_aether_core_NativeCore_aetherStartEngine(JNIEnv* env, jclass, jstring pkg) {
    const char* p = pkg ? env->GetStringUTFChars(pkg, nullptr) : nullptr;
    int r = aether_start_engine(p);
    if (p) env->ReleaseStringUTFChars(pkg, p);
    return r;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_aether_core_NativeCore_aetherIsInitialized(JNIEnv*, jclass) {
    return aether_is_initialized();
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_aether_core_NativeCore_aetherVersion(JNIEnv* env, jclass) {
    return jstr(env, aether_version());
}
