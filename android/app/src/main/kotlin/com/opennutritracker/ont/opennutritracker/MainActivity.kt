package com.opennutritracker.ont.opennutritracker

import android.app.LocaleManager
import android.content.Intent
import android.os.Build
import android.os.LocaleList
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (rather than FlutterActivity) is required by the
// health plugin: Health Connect permission requests go through
// registerForActivityResult, which needs a ComponentActivity host.
class MainActivity : FlutterFragmentActivity() {
    private val localeChannelName = "com.opennutritracker/locale"
    private val healthRationaleChannelName = "com.opennutritracker/health_rationale"

    /**
     * Whether Health Connect started us to ask what the app wants health data
     * for, and Dart has not picked it up yet.
     *
     * A flag that Dart pulls, rather than a call pushed at Dart, because the
     * intent is known in onCreate while the Flutter engine and the widget tree
     * that has to react to it are not ready until later. Pushing would mean
     * racing engine startup for the one launch that most needs to work.
     */
    private var healthRationalePending = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // A cold start: the launching intent is the one held by the activity.
        // Or-ing rather than assigning so an intent that arrived through
        // onNewIntent while the engine was being rebuilt is not dropped.
        healthRationalePending = healthRationalePending || isHealthRationaleIntent(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, healthRationaleChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Reading clears the flag: the request is a one-shot event,
                    // and leaving it set would reopen the screen on every
                    // resume for the rest of the session.
                    "consumePendingRequest" -> {
                        result.success(healthRationalePending)
                        healthRationalePending = false
                    }
                    else -> result.notImplemented()
                }
            }

        // Keeps the app's own language picker and Android's per-app language
        // picker (Settings -> Apps -> OpenNutriTracker -> Language) telling
        // the same story. Without this the OS picker is visible but inert for
        // anyone who has ever chosen a language in the app, because Flutter
        // reads its locale from our saved config rather than from the system.
        //
        // The framework LocaleManager is used rather than AppCompatDelegate:
        // FlutterFragmentActivity extends FragmentActivity, not
        // AppCompatActivity, so AppCompatDelegate.setApplicationLocales would
        // silently do nothing. Below API 33 there is no OS picker to stay in
        // step with, so both calls answer harmlessly and the in-app picker
        // remains the only way to change language.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, localeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getApplicationLocale" -> result.success(applicationLocaleTag())
                    "setApplicationLocale" -> {
                        setApplicationLocaleTag(call.argument<String?>("tag"))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * The activity is `launchMode="singleTop"`, so Health Connect reaching a
     * process that is already running delivers the intent here instead of
     * starting a new activity. Reading only the launching intent would work
     * exactly once per process and then quietly stop.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isHealthRationaleIntent(intent)) {
            healthRationalePending = true
        }
    }

    /**
     * Both actions declared for this activity in the manifest mean the same
     * thing to a user: explain the health import. ACTION_SHOW_PERMISSIONS_RATIONALE
     * comes from the grant dialog, VIEW_PERMISSION_USAGE from Health Connect's
     * own settings for an app that already holds permissions.
     *
     * Matched as literals rather than through the Health Connect client's
     * constants, so this file stays independent of the plugin's dependencies
     * and can be read against the manifest side by side.
     */
    private fun isHealthRationaleIntent(intent: Intent?): Boolean =
        when (intent?.action) {
            ACTION_SHOW_PERMISSIONS_RATIONALE, ACTION_VIEW_PERMISSION_USAGE -> true
            else -> false
        }

    /**
     * The language the user picked in Android's settings, or null when they
     * have not overridden it and the app should follow the system.
     */
    private fun applicationLocaleTag(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return null
        val locales = getSystemService(LocaleManager::class.java)?.applicationLocales
        if (locales == null || locales.isEmpty) return null
        return locales[0]?.toLanguageTag()
    }

    /**
     * Records [tag] as the app's language with the OS. A null tag clears the
     * override, which is what "System default" in our own picker means.
     */
    private fun setApplicationLocaleTag(tag: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val localeManager = getSystemService(LocaleManager::class.java) ?: return
        localeManager.applicationLocales =
            if (tag.isNullOrEmpty()) LocaleList.getEmptyLocaleList()
            else LocaleList.forLanguageTags(tag)
    }

    private companion object {
        const val ACTION_SHOW_PERMISSIONS_RATIONALE = "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"
        const val ACTION_VIEW_PERMISSION_USAGE = "android.intent.action.VIEW_PERMISSION_USAGE"
    }
}
