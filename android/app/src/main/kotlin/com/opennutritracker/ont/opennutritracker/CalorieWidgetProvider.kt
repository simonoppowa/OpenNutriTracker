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
import java.time.LocalDate
import java.time.ZoneId
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
        val minHeight = newOptions.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        WidgetView.refreshOne(context, appWidgetManager, appWidgetId, minWidth, minHeight)
    }
}

/** How much of the widget's content fits in the granted size. The rings
 * cannot be resized remotely (pre-31 `RemoteViews` cannot change view
 * dimensions), so each tier has its own views in the layout. */
private enum class CalorieWidgetBody {
    /** Title, 104dp ring beside the macro rows. Needs about 153dp of
     * content height. */
    WIDE,

    /** 88dp ring over the "of 2000" caption. Needs about 133dp. */
    NARROW,

    /** A 76dp ring alone. Fits the 110dp `minHeight` the widget
     * declares, at the smallest vertical resize and on a launcher whose
     * two rows come to less than the narrow body needs. */
    COMPACT,
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

    /** Whichever body fits the granted height, then width. Height is
     * decided first, because the review that found #1516's clip was right
     * that width alone says nothing about whether the ring and the caption
     * fit vertically. An unknown height (no option yet) gets the compact
     * body, which nothing clips. */
    fun bodyFor(minWidthDp: Int, minHeightDp: Int): CalorieWidgetBody {
        if (minHeightDp < NARROW_FULL_MIN_DP) return CalorieWidgetBody.COMPACT
        val fitsMacrosBesideRing =
            minWidthDp >= WIDE_MIN_DP && minHeightDp >= WIDE_FULL_MIN_DP
        return if (fitsMacrosBesideRing) CalorieWidgetBody.WIDE else CalorieWidgetBody.NARROW
    }

    fun render(
        context: Context,
        views: RemoteViews,
        manager: AppWidgetManager,
        appWidgetId: Int,
        minWidthDp: Int,
        minHeightDp: Int,
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
            showContent(context, views, bodyFor(minWidthDp, minHeightDp))
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

    /** The end of the snapshot's logical day: the next date's start in the
     * device's zone, plus the offset. Same rule as `nextBoundary()` on the
     * Dart side. `atStartOfDay` is what makes DST edges right: a midnight a
     * change skips resolves to the first moment that exists, and one it
     * repeats to the earlier of the two, which is when `isCurrent` already
     * rejects the snapshot. Calendar arithmetic got both wrong by an hour. */
    private fun dayEndMillis(): Long? {
        val day = snapshot?.optString("day", "").orEmpty()
        val date = runCatching { LocalDate.parse(day) }.getOrNull() ?: return null
        val offset = snapshot?.optInt("offsetMinutes", 0) ?: 0
        return date.plusDays(1)
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            // The offset in absolute minutes, as `isCurrent` subtracts it,
            // and a second past the boundary so the update reads the new day.
            .plusSeconds(offset * 60L + 1)
            .toEpochMilli()
    }

    private fun showPlaceholder(views: RemoteViews) {
        val title = label("title", FALLBACK_TITLE)
        views.setViewVisibility(R.id.calorie_widget_title, View.VISIBLE)
        views.setTextViewText(R.id.calorie_widget_title, title)
        views.setViewVisibility(R.id.calorie_widget_body_wide, View.GONE)
        views.setViewVisibility(R.id.calorie_widget_body_narrow, View.GONE)
        views.setViewVisibility(R.id.calorie_widget_body_compact, View.GONE)
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
        body: CalorieWidgetBody,
    ) {
        val title = label("title", FALLBACK_TITLE)
        val unit = label("unit", FALLBACK_UNIT)
        // The narrow and compact bodies have no room to spare; the goal
        // caption (narrow) already says what a title would.
        views.setViewVisibility(
            R.id.calorie_widget_title,
            if (body == CalorieWidgetBody.WIDE) View.VISIBLE else View.GONE,
        )
        views.setTextViewText(R.id.calorie_widget_title, "$title ($unit)")
        views.setViewVisibility(R.id.calorie_widget_placeholder, View.GONE)
        views.setViewVisibility(
            R.id.calorie_widget_body_wide,
            if (body == CalorieWidgetBody.WIDE) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.calorie_widget_body_narrow,
            if (body == CalorieWidgetBody.NARROW) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.calorie_widget_body_compact,
            if (body == CalorieWidgetBody.COMPACT) View.VISIBLE else View.GONE,
        )
        val ringId = when (body) {
            CalorieWidgetBody.WIDE -> R.id.calorie_widget_ring_wide
            CalorieWidgetBody.NARROW -> R.id.calorie_widget_ring_narrow
            CalorieWidgetBody.COMPACT -> R.id.calorie_widget_ring_compact
        }
        val consumedId = when (body) {
            CalorieWidgetBody.WIDE -> R.id.calorie_widget_consumed_wide
            CalorieWidgetBody.NARROW -> R.id.calorie_widget_consumed_narrow
            CalorieWidgetBody.COMPACT -> R.id.calorie_widget_consumed_compact
        }
        val unitId = when (body) {
            CalorieWidgetBody.WIDE -> R.id.calorie_widget_unit_wide
            CalorieWidgetBody.NARROW -> R.id.calorie_widget_unit_narrow
            CalorieWidgetBody.COMPACT -> R.id.calorie_widget_unit_compact
        }

        val progress = if (goalKcal > 0) {
            (consumedKcal.toDouble() / goalKcal * RING_MAX).toInt().coerceIn(0, RING_MAX)
        } else 0
        views.setProgressBar(ringId, RING_MAX, progress, false)
        views.setTextViewText(consumedId, "$consumedKcal")
        views.setTextViewText(unitId, unit)

        // "of 2000" travels beside the figures, so it always describes
        // what is on screen, in the app's language.
        if (body == CalorieWidgetBody.NARROW) {
            views.setTextViewText(
                R.id.calorie_widget_goal_caption,
                figureLabel("goal", "/ $goalKcal"),
            )
        } else if (body == CalorieWidgetBody.WIDE) {
            views.setTextViewText(
                R.id.calorie_widget_goal_wide,
                figureLabel("goal", "/ $goalKcal"),
            )
        }

        // Replaces the placeholder's "Open the app": a launcher may reapply
        // these views to the hierarchy that showed the placeholder.
        views.setContentDescription(
            R.id.calorie_widget_root,
            figureLabel("accessibility", "$consumedKcal / $goalKcal $unit"),
        )

        if (body != CalorieWidgetBody.WIDE) {
            // The compact and narrow bodies have no macro rows.
            return
        }

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
         * ring; above it, the macro rows can sit beside it. The 24dp
         * padding, the 104dp ring and its 8dp margin leave the rows 124dp
         * here: enough for a name, "123 g" and the 44dp percentage, where
         * 168 left them 32dp. */
        private const val WIDE_MIN_DP = 260

        /** Content height the narrow body needs: 24dp padding, the 88dp
         * ring, the 4dp margin and a ~17dp caption, plus launchers' own
         * padding around the widget, which the reported height includes.
         * Below it, only the compact body fits without clipping. */
        private const val NARROW_FULL_MIN_DP = 145

        /** Content height the wide body needs: its ring alone stands as
         * high as the narrow ring plus caption, and the title (~21sp bold
         * plus its 4dp margin) sits above. */
        private const val WIDE_FULL_MIN_DP = 165

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
                refreshOne(context, appWidgetManager, appWidgetId, 0, 0)
            }
        }

        fun refreshOne(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            minWidth: Int,
            minHeight: Int,
        ) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidthDp = if (minWidth > 0) minWidth
            else options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val minHeightDp = if (minHeight > 0) minHeight
            else options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            val view = build(context)
            view.render(
                context,
                RemoteViews(context.packageName, R.layout.calorie_widget),
                appWidgetManager,
                appWidgetId,
                minWidthDp,
                minHeightDp,
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
