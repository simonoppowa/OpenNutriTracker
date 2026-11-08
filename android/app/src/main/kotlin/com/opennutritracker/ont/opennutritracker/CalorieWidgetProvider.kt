package com.opennutritracker.ont.opennutritracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONObject

/**
 * The Android calorie home-screen widget.
 *
 * Reads the snapshot the Flutter side writes through `home_widget`
 * (`CalorieWidgetSnapshot` in lib/core/utils/widget): one JSON string
 * under `ont_calorie_snapshot` in the plugin's shared-preferences file,
 * plus translated labels under `ont_calorie_labels`. The day boundary
 * matches `DayBoundaryCalc`: subtract the offset, then take the local
 * Gregorian day. When that day no longer matches the snapshot's, the
 * widget shows its placeholder instead of yesterday's intake.
 */
class CalorieWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        WidgetView.refreshAll(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        val minWidth = newOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        WidgetView.refreshOne(context, appWidgetManager, appWidgetId, minWidth)
    }
}

/** One re-render's inputs: snapshot figures, macros, figure labels, and
 * the language-only labels, read in one pass per widget update. */
private class WidgetView private constructor(
    private val snapshot: JSONObject?,
    private val labels: JSONObject,
) {
    private val consumedKcal: Int = snapshot?.optInt("consumed", 0) ?: 0
    private val goalKcal: Int = snapshot?.optInt("goal", 0) ?: 0

    /** Same rule as `DayBoundaryCalc` on the Dart side and the iOS
     * extension: subtract the offset, then take the local Gregorian day. */
    private val isCurrent: Boolean
        get() {
            if (snapshot == null) return false
            // No goal means no figures to show (the Dart side writes
            // hasData false and zeros), so the placeholder stands in.
            if (!snapshot.optBoolean("hasData", false) || goalKcal <= 0) return false
            val storedDay = snapshot.optString("day", "")
            if (storedDay.isEmpty()) return false
            val offset = snapshot.optInt("offsetMinutes", 0)
            if (offset < 0 || offset >= 24 * 60) return false
            val shifted = Date(System.currentTimeMillis() - offset * 60_000L)
            val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            return format.format(shifted) == storedDay
        }

    /** Figure labels live inside the snapshot JSON under `labels`,
     * written beside the figures they describe in one value. */
    private fun figureLabel(name: String, fallback: String? = null): String? {
        val value = snapshot?.optJSONObject("labels")?.optString(name, "").orEmpty()
        return if (value.isEmpty()) fallback else value
    }

    private fun label(name: String, fallback: String): String {
        val value = labels.optString(name, "")
        return if (value.isEmpty()) fallback else value
    }

    fun render(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        minWidthDp: Int,
    ) {
        views.setOnClickPendingIntent(
            R.id.calorie_widget_root,
            PendingIntent.getActivity(
                context,
                0,
                context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            ),
        )

        if (isCurrent) {
            showContent(context, views, wide = minWidthDp >= WIDE_MIN_DP)
        } else {
            showPlaceholder(views)
        }
        manager.updateAppWidget(appWidgetId, views)
    }

    /** Asks for one more update when the snapshot's logical day ends, so
     * yesterday's intake is replaced by the placeholder then rather than at
     * the next 30-minute poll. A window rather than `set()`, which
     * Android stretched to an hour; Android 12 widens the one-minute window
     * asked for here to ten minutes. No exact alarm, which would need its
     * own permission. Non-waking: it lands the next time the
     * device is awake after the boundary, which is when anyone can see
     * the widget. One alarm for all instances, replaced on every update;
     * nothing is scheduled while the placeholder shows. */
    fun scheduleDayEnd(context: Context, manager: AppWidgetManager) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val ids = manager.getAppWidgetIds(
            ComponentName(context, CalorieWidgetProvider::class.java),
        )
        val intent = Intent(context, CalorieWidgetProvider::class.java)
            .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        val pending = PendingIntent.getBroadcast(
            context,
            DAY_END_REQUEST,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val dayEnd = if (isCurrent) dayEndMillis() else null
        if (dayEnd == null) {
            alarms.cancel(pending)
        } else {
            alarms.setWindow(AlarmManager.RTC, dayEnd, DAY_END_WINDOW_MS, pending)
        }
    }

    /** The end of the snapshot's logical day: the next date's own local
     * midnight, plus the offset. Same rule as `nextBoundary()` on the Dart
     * side. */
    private fun dayEndMillis(): Long? {
        val day = snapshot?.optString("day", "").orEmpty()
        val start = runCatching {
            SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(day)
        }.getOrNull() ?: return null
        val offset = snapshot?.optInt("offsetMinutes", 0) ?: 0
        return Calendar.getInstance().apply {
            time = start
            add(Calendar.DAY_OF_MONTH, 1)
            // The next date's midnight, set rather than carried: where a
            // DST change skips midnight on the snapshot's date, `start` is
            // 01:00, and a day on from it would keep that hour. A skipped
            // midnight on the next date resolves to its first hour, the
            // moment the formatted date (and so `isCurrent`) changes.
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.MINUTE, offset)
            // A second past the boundary, so the update reads the new day.
            add(Calendar.SECOND, 1)
        }.timeInMillis
    }

    private fun showPlaceholder(views: RemoteViews) {
        val title = label("title", FALLBACK_TITLE)
        views.setViewVisibility(R.id.calorie_widget_title, View.VISIBLE)
        views.setTextViewText(R.id.calorie_widget_title, title)
        views.setViewVisibility(R.id.calorie_widget_body_wide, View.GONE)
        views.setViewVisibility(R.id.calorie_widget_body_narrow, View.GONE)
        views.setViewVisibility(R.id.calorie_widget_placeholder, View.VISIBLE)
        views.setTextViewText(R.id.calorie_widget_placeholder_title, title)
        views.setTextViewText(
            R.id.calorie_widget_placeholder_hint,
            label("openApp", FALLBACK_HINT),
        )
        views.setContentDescription(
            R.id.calorie_widget_root,
            label("openApp", FALLBACK_HINT),
        )
    }

    private fun showContent(
        context: Context,
        views: RemoteViews,
        wide: Boolean,
    ) {
        val title = label("title", FALLBACK_TITLE)
        val unit = label("unit", FALLBACK_UNIT)
        // The narrow body has no room to spare; the goal caption under the
        // ring already says what a title would.
        views.setViewVisibility(R.id.calorie_widget_title, if (wide) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.calorie_widget_title, "$title ($unit)")
        views.setViewVisibility(R.id.calorie_widget_placeholder, View.GONE)
        views.setViewVisibility(R.id.calorie_widget_body_wide, if (wide) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.calorie_widget_body_narrow, if (wide) View.GONE else View.VISIBLE)
        val ringId = if (wide) R.id.calorie_widget_ring_wide else R.id.calorie_widget_ring_narrow
        val consumedId = if (wide) R.id.calorie_widget_consumed_wide else R.id.calorie_widget_consumed_narrow
        val unitId = if (wide) R.id.calorie_widget_unit_wide else R.id.calorie_widget_unit_narrow

        val progress = if (goalKcal > 0) {
            (consumedKcal.toDouble() / goalKcal * RING_MAX).toInt().coerceIn(0, RING_MAX)
        } else 0
        views.setProgressBar(ringId, RING_MAX, progress, false)
        views.setTextViewText(consumedId, "$consumedKcal")
        views.setTextViewText(unitId, unit)

        // "of 2000" travels beside the figures, so it always describes
        // what is on screen, in the app's language.
        val goalId = if (wide) R.id.calorie_widget_goal_wide else R.id.calorie_widget_goal_caption
        views.setTextViewText(goalId, figureLabel("goal", "/ $goalKcal"))

        // Replaces the placeholder's "Open the app": a launcher may reapply
        // these views to the hierarchy that showed the placeholder.
        views.setContentDescription(
            R.id.calorie_widget_root,
            figureLabel("accessibility", "$consumedKcal / $goalKcal $unit"),
        )

        val macros = snapshot?.optJSONObject("macros")
        val gram = label("gram", FALLBACK_GRAM)
        showMacroRow(
            views, context,
            rowId = R.id.calorie_widget_row_protein,
            nameId = R.id.calorie_widget_protein_name,
            valueId = R.id.calorie_widget_protein_value,
            percentId = R.id.calorie_widget_protein_pct,
            colorRes = R.color.calorie_widget_protein,
            name = label("protein", FALLBACK_PROTEIN),
            intakeG = macros?.optJSONObject("protein")?.optInt("g", 0) ?: 0,
            goalG = macros?.optJSONObject("protein")?.optInt("goalG", 0) ?: 0,
            gram = gram,
        )
        showMacroRow(
            views, context,
            rowId = R.id.calorie_widget_row_carbs,
            nameId = R.id.calorie_widget_carbs_name,
            valueId = R.id.calorie_widget_carbs_value,
            percentId = R.id.calorie_widget_carbs_pct,
            colorRes = R.color.calorie_widget_carbs,
            name = label("carbs", FALLBACK_CARBS),
            intakeG = macros?.optJSONObject("carbs")?.optInt("g", 0) ?: 0,
            goalG = macros?.optJSONObject("carbs")?.optInt("goalG", 0) ?: 0,
            gram = gram,
        )
        showMacroRow(
            views, context,
            rowId = R.id.calorie_widget_row_fat,
            nameId = R.id.calorie_widget_fat_name,
            valueId = R.id.calorie_widget_fat_value,
            percentId = R.id.calorie_widget_fat_pct,
            colorRes = R.color.calorie_widget_fat,
            name = label("fat", FALLBACK_FAT),
            intakeG = macros?.optJSONObject("fat")?.optInt("g", 0) ?: 0,
            goalG = macros?.optJSONObject("fat")?.optInt("goalG", 0) ?: 0,
            gram = gram,
        )
    }

    private fun showMacroRow(
        views: RemoteViews,
        context: Context,
        rowId: Int,
        nameId: Int,
        valueId: Int,
        percentId: Int,
        colorRes: Int,
        name: String,
        intakeG: Int,
        goalG: Int,
        gram: String,
    ) {
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewText(nameId, name)
        views.setTextColor(nameId, ContextCompat.getColor(context, colorRes))
        // A macro goal of zero means the figure is not known yet, and
        // nothing about it is shown rather than an unreachable split.
        if (goalG > 0) {
            val percent = (intakeG.toDouble() / goalG * 100).toInt()
            views.setTextViewText(valueId, "$intakeG $gram")
            views.setTextViewText(percentId, "$percent%")
        } else {
            views.setTextViewText(valueId, "")
            views.setTextViewText(percentId, "")
        }
    }

    companion object {
        private const val RING_MAX = 10_000
        private const val DAY_END_REQUEST = 1
        private const val DAY_END_WINDOW_MS = 60_000L

        /** Below this width in dp, the granted cell span only fits the
         * ring; above it, the macro rows sit beside it. The 24dp padding,
         * the 104dp ring and its 8dp margin leave the rows 124dp here:
         * enough for a name, "123 g" and the 44dp percentage, where 168
         * left them 32dp. */
        private const val WIDE_MIN_DP = 260

        private const val FALLBACK_TITLE = "Calories"
        private const val FALLBACK_UNIT = "kcal"
        private const val FALLBACK_GRAM = "g"
        private const val FALLBACK_PROTEIN = "protein"
        private const val FALLBACK_CARBS = "carbs"
        private const val FALLBACK_FAT = "fat"
        private const val FALLBACK_HINT = "Open the app"

        /** The plugin's shared-preferences file is shared by both keys;
         * one read per update, parsed twice at most. */
        private fun readJson(context: Context, key: String): JSONObject? {
            val raw = context
                .getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE)
                .getString(key, null) ?: return null
            return runCatching { JSONObject(raw) }.getOrNull()
        }

        private fun build(context: Context): WidgetView {
            val labels = readJson(context, LABELS_KEY) ?: JSONObject()
            val snapshot = readJson(context, SNAPSHOT_KEY)
            return WidgetView(snapshot, labels)
        }

        fun refreshAll(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            for (appWidgetId in appWidgetIds) {
                refreshOne(context, appWidgetManager, appWidgetId, 0)
            }
        }

        fun refreshOne(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            minWidth: Int,
        ) {
            val minWidthDp = if (minWidth > 0) minWidth
            else appWidgetManager.getAppWidgetOptions(appWidgetId)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val view = build(context)
            view.render(
                context,
                RemoteViews(context.packageName, R.layout.calorie_widget),
                appWidgetManager,
                appWidgetId,
                minWidthDp,
            )
            view.scheduleDayEnd(context, appWidgetManager)
        }

        /** Matches `HomeWidgetPlugin.PREFERENCES` in the `home_widget`
         * plugin (that constant is internal to the plugin's module, so it
         * is restated here with the file name it actually writes). */
        private const val PREFERENCES_FILE = "HomeWidgetPreferences"
        private const val LABELS_KEY = "ont_calorie_labels"
        private const val SNAPSHOT_KEY = "ont_calorie_snapshot"
    }
}
