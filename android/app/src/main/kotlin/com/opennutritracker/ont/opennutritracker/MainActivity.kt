package com.opennutritracker.ont.opennutritracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.opennutritracker/share_intent"

    // Holds text shared to the app until Flutter consumes it.
    private var pendingSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capture any text present in the launch intent (cold start).
        pendingSharedText = extractSharedText(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedText" -> {
                        result.success(pendingSharedText)
                        pendingSharedText = null
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Called when the app is already running and receives a new share intent
    // (singleTop behaviour — Android re-uses the existing activity).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        pendingSharedText = extractSharedText(intent)
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        val type = intent.type ?: return null
        if (!type.startsWith("text/") && type != "application/json") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }
}
