package com.aether.proxy

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import com.aether.core.VirtualCore

/**
 * Virtualization launch context for the target app.
 * Flexible-later: replace the direct launch with a real BlackBox
 * BActivityThread bootstrap so the target runs inside Aether's container.
 */
class ProxyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val launch = packageManager.getLaunchIntentForPackage(VirtualCore.TARGET_PACKAGE)
        if (launch != null) {
            try {
                startActivity(launch)
            } catch (e: Exception) {
                Toast.makeText(this, "Launch failed: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        } else {
            Toast.makeText(this, "${VirtualCore.TARGET_NAME} not installed", Toast.LENGTH_SHORT).show()
        }
        finish()
    }
}
