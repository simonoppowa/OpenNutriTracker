package com.opennutritracker.ont.opennutritracker

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import android.content.Context
import java.time.Instant

/**
 * Reads finished exercise sessions straight from Health Connect.
 *
 * This exists because the `health` plugin cannot read a workout without also
 * reading distance and steps: its `handleWorkoutData` issues a
 * `DistanceRecord` and a `StepsRecord` read for every session it returns, and
 * Health Connect answers an ungranted read with a SecurityException that takes
 * the whole workout query with it. Play's Health Connect permissions policy
 * rejected exactly those two permissions (plus body fat) as excessive for what
 * this app offers — enforced 8 Sept 2026 — so the app cannot hold them and
 * cannot use the plugin's workout path.
 *
 * Nothing is lost by reading the session directly: the app already ignored the
 * plugin's totals on Android and attributes energy itself from raw
 * TOTAL_CALORIES_BURNED records (see `androidWorkoutEnergyKcal`), so distance
 * and steps were read and thrown away. Everything the import actually consumes
 * — id, start, end, activity type, writing app — is on the session record.
 *
 * Only `READ_EXERCISE` is needed here. The calorie read stays on the plugin,
 * which needs only `READ_TOTAL_CALORIES_BURNED`.
 */
object HealthConnectWorkoutReader {

    /**
     * Sessions that START inside `[from, to)`, as plain maps for the method
     * channel. Paged to exhaustion: Health Connect caps a response and hands
     * back a token, and stopping at the first page would silently drop the
     * older half of a long catch-up import.
     */
    suspend fun readExerciseSessions(
        context: Context,
        fromMillis: Long,
        toMillis: Long,
    ): List<Map<String, Any?>> {
        val client = HealthConnectClient.getOrCreate(context)
        val timeRange = TimeRangeFilter.between(
            Instant.ofEpochMilli(fromMillis),
            Instant.ofEpochMilli(toMillis),
        )

        val sessions = mutableListOf<Map<String, Any?>>()
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = timeRange,
                    pageToken = pageToken,
                ),
            )
            for (record in response.records) {
                sessions.add(
                    mapOf(
                        "uuid" to record.metadata.id,
                        "activityTypeName" to exerciseTypeName(record.exerciseType),
                        "startMillis" to record.startTime.toEpochMilli(),
                        "endMillis" to record.endTime.toEpochMilli(),
                        "sourceName" to record.metadata.dataOrigin.packageName,
                    ),
                )
            }
            pageToken = response.pageToken
        } while (pageToken != null)

        return sessions
    }

    /**
     * Health Connect's exercise type as the name the import's compendium
     * lookup expects — the `HealthWorkoutActivityType` spelling the plugin
     * used to hand over, so nothing above the data-source layer changes.
     *
     * Written as type-to-name rather than the plugin's name-to-type map on
     * purpose. Three Health Connect types are the target of several names
     * (dancing, skiing, wheelchair), and the plugin resolves those by taking
     * the first key out of a `hashMapOf` — an arbitrary choice that can differ
     * between runs. Naming the one canonical spelling here makes the answer
     * deterministic, and picks the spelling the compendium table actually
     * carries.
     *
     * A type absent from this table is reported by its Health Connect name if
     * the import can use it and otherwise becomes a custom activity, which is
     * what an unmapped type did before too.
     */
    private fun exerciseTypeName(exerciseType: Int): String = when (exerciseType) {
        ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN -> "AMERICAN_FOOTBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AUSTRALIAN -> "AUSTRALIAN_FOOTBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON -> "BADMINTON"
        ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL -> "BASEBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL -> "BASKETBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_BIKING -> "BIKING"
        ExerciseSessionRecord.EXERCISE_TYPE_BOXING -> "BOXING"
        ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS -> "CALISTHENICS"
        ExerciseSessionRecord.EXERCISE_TYPE_CRICKET -> "CRICKET"
        // One Health Connect type, three plugin names, all three the same
        // compendium code (03015).
        ExerciseSessionRecord.EXERCISE_TYPE_DANCING -> "DANCING"
        ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL -> "ELLIPTICAL"
        ExerciseSessionRecord.EXERCISE_TYPE_FENCING -> "FENCING"
        ExerciseSessionRecord.EXERCISE_TYPE_FRISBEE_DISC -> "FRISBEE_DISC"
        ExerciseSessionRecord.EXERCISE_TYPE_GOLF -> "GOLF"
        ExerciseSessionRecord.EXERCISE_TYPE_GUIDED_BREATHING -> "GUIDED_BREATHING"
        ExerciseSessionRecord.EXERCISE_TYPE_GYMNASTICS -> "GYMNASTICS"
        ExerciseSessionRecord.EXERCISE_TYPE_HANDBALL -> "HANDBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING ->
            "HIGH_INTENSITY_INTERVAL_TRAINING"
        ExerciseSessionRecord.EXERCISE_TYPE_HIKING -> "HIKING"
        ExerciseSessionRecord.EXERCISE_TYPE_ICE_SKATING -> "ICE_SKATING"
        ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS -> "MARTIAL_ARTS"
        ExerciseSessionRecord.EXERCISE_TYPE_PARAGLIDING -> "PARAGLIDING"
        ExerciseSessionRecord.EXERCISE_TYPE_PILATES -> "PILATES"
        ExerciseSessionRecord.EXERCISE_TYPE_RACQUETBALL -> "RACQUETBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING -> "ROCK_CLIMBING"
        ExerciseSessionRecord.EXERCISE_TYPE_ROWING -> "ROWING"
        ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE -> "ROWING_MACHINE"
        ExerciseSessionRecord.EXERCISE_TYPE_RUGBY -> "RUGBY"
        ExerciseSessionRecord.EXERCISE_TYPE_RUNNING -> "RUNNING"
        ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL -> "RUNNING_TREADMILL"
        ExerciseSessionRecord.EXERCISE_TYPE_SAILING -> "SAILING"
        ExerciseSessionRecord.EXERCISE_TYPE_SCUBA_DIVING -> "SCUBA_DIVING"
        ExerciseSessionRecord.EXERCISE_TYPE_SKATING -> "SKATING"
        // DOWNHILL_SKIING and SKIING share compendium code 19075;
        // CROSS_COUNTRY_SKIING (19080) is a different activity Health Connect
        // does not distinguish, so the generic spelling is the honest one.
        ExerciseSessionRecord.EXERCISE_TYPE_SKIING -> "SKIING"
        ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING -> "SNOWBOARDING"
        ExerciseSessionRecord.EXERCISE_TYPE_SNOWSHOEING -> "SNOWSHOEING"
        ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL -> "SOFTBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_SQUASH -> "SQUASH"
        ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING -> "STAIR_CLIMBING"
        ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING_MACHINE -> "STAIR_CLIMBING_MACHINE"
        ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING -> "STRENGTH_TRAINING"
        ExerciseSessionRecord.EXERCISE_TYPE_SURFING -> "SURFING"
        ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER -> "SWIMMING_OPEN_WATER"
        ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL -> "SWIMMING_POOL"
        ExerciseSessionRecord.EXERCISE_TYPE_TABLE_TENNIS -> "TABLE_TENNIS"
        ExerciseSessionRecord.EXERCISE_TYPE_TENNIS -> "TENNIS"
        ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL -> "VOLLEYBALL"
        ExerciseSessionRecord.EXERCISE_TYPE_WALKING -> "WALKING"
        ExerciseSessionRecord.EXERCISE_TYPE_WATER_POLO -> "WATER_POLO"
        ExerciseSessionRecord.EXERCISE_TYPE_WEIGHTLIFTING -> "WEIGHTLIFTING"
        // WHEELCHAIR_RUN_PACE and WHEELCHAIR_WALK_PACE are HealthKit
        // spellings of the same Health Connect type.
        ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR -> "WHEELCHAIR"
        ExerciseSessionRecord.EXERCISE_TYPE_YOGA -> "YOGA"

        // Types the plugin's table never mapped, so they arrived as OTHER and
        // became a custom activity. Each of these does have a compendium
        // counterpart the import can use, so naming them is a small
        // improvement over the behaviour being replaced.
        ExerciseSessionRecord.EXERCISE_TYPE_SOCCER -> "SOCCER"
        ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY -> "BIKING_STATIONARY"
        ExerciseSessionRecord.EXERCISE_TYPE_ICE_HOCKEY -> "HOCKEY"
        ExerciseSessionRecord.EXERCISE_TYPE_STRETCHING -> "FLEXIBILITY"
        // The compendium table also carries JUMP_ROPE, but Health Connect has
        // no exercise type for it in connect-client 1.1.0-alpha11 — a skipping
        // session arrives as OTHER_WORKOUT and becomes a custom activity.

        else -> "OTHER"
    }
}
