package com.aether.proxy

import android.app.Service
import android.content.Intent
import android.os.IBinder

/** BlackBox-style proxy service stub (extension point for later phases). */
class ProxyService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
}
