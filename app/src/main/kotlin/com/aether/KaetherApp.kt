package com.aether

import android.app.Application
import com.aether.core.VirtualCore

/**
 * Aether — BlackBox-style virtualization host.
 * Current hardcoded target: 8 Ball Pool (com.miniclip.eightballpool).
 * Flexible multi-app support is a later phase.
 */
class KaetherApp : Application() {
    override fun onCreate() {
        super.onCreate()
        VirtualCore.init(this)
    }
}
