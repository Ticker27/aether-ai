package com.aether.core

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import com.aether.proxy.ProxyActivity

/**
 * BlackBox-style virtualization core.
 *
 * Phase 1 (now): targets 8 Ball Pool directly.
 * Later phase: real containerization via BActivityThread / dex load /
 * package-manager virtualization — the [ProxyActivity] is the extension point.
 */
object VirtualCore {

    // Hardcoded target — flexible later.
    const val TARGET_PACKAGE = "com.miniclip.eightballpool"
    const val TARGET_NAME = "8 Ball Pool"

    var engineReady = false
        private set

    fun init(context: Context) {
        engineReady = NativeCore.startEngine(TARGET_PACKAGE)
    }

    fun isTargetInstalled(context: Context): Boolean {
        return try {
            context.packageManager.getPackageInfo(TARGET_PACKAGE, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    /** Launch the target app inside the Aether virtualization host. */
    fun launch(context: Context) {
        val intent = Intent(context, ProxyActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}
