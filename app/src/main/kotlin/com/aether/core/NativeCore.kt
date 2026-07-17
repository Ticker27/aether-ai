package com.aether.core

/**
 * JNI bridge to libaether.so (the C++ virtualization/engine core).
 * Symbol names mirror src/main/cpp/src/aether_engine.cpp.
 */
object NativeCore {

    init {
        System.loadLibrary("aether")
    }

    @JvmStatic external fun aetherInit(workDir: String): Int

    @JvmStatic external fun aetherStartEngine(targetPackage: String): Int

    @JvmStatic external fun aetherIsInitialized(): Int

    @JvmStatic external fun aetherVersion(): String

    fun startEngine(targetPackage: String): Boolean =
        aetherStartEngine(targetPackage) == 0

    val version: String get() = aetherVersion()

    val isInitialized: Boolean get() = aetherIsInitialized() == 1
}
