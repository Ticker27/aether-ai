package com.aether

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter host + thin Android glue.
 * No engine logic here — the C++ brain (libaether.so) owns that.
 * This class only performs Android OS calls the brain requests.
 */
class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.aether/android"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launch" -> {
                        val pkg = call.arguments as? String
                        if (pkg != null) launchApp(pkg, result)
                        else result.error("NO_PKG", "missing package", null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Launch the target app (8 Ball Pool) — an Android OS call. */
    private fun launchApp(pkg: String, result: MethodChannel.Result) {
        val launch = packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            try {
                startActivity(launch)
                result.success("ok")
            } catch (e: Exception) {
                result.error("LAUNCH_FAIL", e.message, null)
            }
        } else {
            result.error("NOT_INSTALLED", "$pkg not installed", null)
        }
    }
}
