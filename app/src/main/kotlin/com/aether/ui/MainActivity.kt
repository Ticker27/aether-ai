package com.aether.ui

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.aether.R
import com.aether.core.NativeCore
import com.aether.core.VirtualCore

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val status = findViewById<TextView>(R.id.statusText)
        val launchBtn = findViewById<Button>(R.id.launchBtn)

        status.text = if (NativeCore.isInitialized)
            "✅ Engine Ready (v${NativeCore.version})"
        else
            "❌ Engine Offline"

        launchBtn.text = "LAUNCH ${VirtualCore.TARGET_NAME}"

        launchBtn.setOnClickListener {
            if (VirtualCore.isTargetInstalled(this)) {
                VirtualCore.launch(this)
                status.text = "▶ Launching ${VirtualCore.TARGET_NAME}…"
            } else {
                status.text = "❌ ${VirtualCore.TARGET_NAME} not installed"
            }
        }
    }
}
