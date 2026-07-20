import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_all_user_data_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_profile_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/utils/demo/demo_content.dart';
import 'package:opennutritracker/core/utils/demo/unsplash_attribution.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/acknowledge_fasting_warning_usecase.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('DemoSeeder');

const _demoProfileName = 'Alex Demo';

/// What varies between the exhaustive dev QA fixture and the shorter,
/// always-on-track dataset shown to a prospective user who taps "try it
/// with sample data" before onboarding. Everything else — the food set,
/// the macro-targeting algorithm, recipes, activity pool — is identical
/// (see `demo_content.dart`).
class DemoSeedOptions {
  final int daysOfHistory;

  /// Chance any day beyond [guaranteedStreakDays] misses its calorie goal
  /// outright. Zero means every day lands on-track by construction — no
  /// separate "flattering" content needed, just this dial.
  final double missedDayProbability;
  final int guaranteedStreakDays;

  /// Weight-log starting point — the trend runs from this down to the
  /// demo user's current weight (87kg) across [daysOfHistory].
  final double startWeightKg;

  const DemoSeedOptions({
    required this.daysOfHistory,
    required this.missedDayProbability,
    required this.guaranteedStreakDays,
    required this.startWeightKg,
  });

  /// The exhaustive year-long QA fixture used by `lib/dev/main_dev.dart` —
  /// deliberately imperfect (missed days, a realistic weight-loss plateau)
  /// so every screen and edge case gets exercised.
  static const dev = DemoSeedOptions(
    daysOfHistory: 365,
    missedDayProbability: 0.10,
    guaranteedStreakDays: 15,
    startWeightKg: 96.0,
  );

  /// The public "try it with sample data" onboarding fixture — three
  /// weeks, always on-track, so a prospective user's first impression is
  /// a polished one. The weight trend runs the demo user's actual
  /// -0.4kg/week goal literally (unlike [dev]'s deliberately-undershot
  /// year-long plateau — a 3-week window is too short for a plateau to
  /// read as realistic).
  static const onboarding = DemoSeedOptions(
    daysOfHistory: 21,
    missedDayProbability: 0.0,
    guaranteedStreakDays: 21,
    startWeightKg: 87.0 + 0.4 * 3,
  );
}

/// Wipes the active profile back to a fresh, un-onboarded state and
/// refills it with realistic demo data — a named, photographed user
/// profile, daily meals sized to hit (and, per [options], rarely or never
/// exceed) both the calorie and macro goals, activities on roughly half
/// the days, noisy (not cyclical) weight/water history, several recipes,
/// a saved activity template, and fasting sessions in every state.
///
/// Builds every day's records in memory first and writes each box with a
/// single bulk `addAll` call — a sequential per-day/per-usecase await loop
/// would take minutes for [DemoSeedOptions.dev]'s 365 days.
///
/// Called from two places: `lib/dev/main_dev.dart` (dev-only, [DemoSeedOptions.dev])
/// and the onboarding intro page's "try it with sample data" link
/// ([DemoSeedOptions.onboarding], shipped in every build).
Future<void> seedDemoData(DemoSeedOptions options) async {
  _log.info('Seeding demo data (${options.daysOfHistory} days)...');
  // Reproducible fixture even when seedDemoData runs more than once in
  // the same process (exit demo → try sample data again, or repeated
  // `just dev_seed` hot-restarts that skip a full process restart).
  resetDemoRng();

  await _wipeActiveProfileAndDemoContent();

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final user = _demoUser(startOfToday);
  await locator<AddUserUsecase>().addUser(user);
  await locator<AcknowledgeFastingWarningUseCase>()();

  // Hand-picked Unsplash photos, reused across every day's intake entries
  // — see unsplash_attribution.dart for why these are hardcoded URLs
  // rather than a live search.
  final foods = buildDemoFoods();
  await _setupActiveProfile();

  // Base (activity-free) goal, computed once — recomputing per day via the
  // async usecases would mean thousands of repeated Hive reads for a value
  // that doesn't change day to day for a fixed user/config.
  final config = await locator<ConfigRepository>().getConfig();
  final baseKcalGoal = CalorieGoalCalc.getTotalKcalGoal(
    user,
    0,
    kcalUserAdjustment: config.userKcalAdjustment,
    caloriesTaperEnabled: user.caloriesTaperEnabled,
  );
  final baseCarbsGoal = MacroCalc.getTotalCarbsGoal(
    baseKcalGoal,
    userCarbsGoal: config.userCarbGoalPct,
  );
  final baseFatGoal = MacroCalc.getTotalFatsGoal(
    baseKcalGoal,
    userFatsGoal: config.userFatGoalPct,
  );
  final baseProteinGoal = MacroCalc.getTotalProteinsGoal(
    baseKcalGoal,
    userProteinsGoal: config.userProteinGoalPct,
  );

  final intakeDBOs = <IntakeDBO>[];
  final activityDBOs = <UserActivityDBO>[];
  final trackedDayDBOs = <TrackedDayDBO>[];
  final waterIntakeDBOs = <WaterIntakeDBO>[];

  for (var daysAgo = options.daysOfHistory - 1; daysAgo >= 0; daysAgo--) {
    final day = startOfToday.subtract(Duration(days: daysAgo));

    // Activity on roughly half of all days, always including today so the
    // Home screen has something to show immediately after seeding.
    var activityBurnedKcal = 0.0;
    if (daysAgo == 0 || demoRng.nextDouble() < 0.5) {
      final activity = demoActivityPool[demoRng.nextInt(demoActivityPool.length)];
      final duration = 25.0 + demoRng.nextInt(40); // 25-64 min
      final burnedKcal = METCalc.getTotalBurnedKcal(user, activity, duration);
      activityBurnedKcal = burnedKcal;
      activityDBOs.add(
        UserActivityDBO.fromUserActivityEntity(
          UserActivityEntity(
            IdGenerator.getUniqueID(),
            duration,
            burnedKcal,
            jitteredTime(day, 18),
            activity,
          ),
        ),
      );
    }

    // Mirrors ActivityDetailBloc._updateTrackedDay: burned activity kcal
    // raises the day's calorie (and proportional macro) headroom.
    final dayKcalGoal = baseKcalGoal + activityBurnedKcal;
    final dayCarbsGoal =
        baseCarbsGoal + MacroCalc.getTotalCarbsGoal(activityBurnedKcal);
    final dayFatGoal =
        baseFatGoal + MacroCalc.getTotalFatsGoal(activityBurnedKcal);
    final dayProteinGoal =
        baseProteinGoal + MacroCalc.getTotalProteinsGoal(activityBurnedKcal);

    // The most recent [guaranteedStreakDays] are always on-track,
    // guaranteeing a current streak of that length (Trends' "current"
    // streak is the run ending today, within whichever window chip is
    // selected — the default 7d chip only ever looks at 7 days, so a
    // longer guaranteed run only shows once the 30d/90d/All chip is
    // picked). Beyond that, each day has a [missedDayProbability] chance
    // of missing the goal outright (an over- or under-shoot well past the
    // "on track" tolerance) — zero for the onboarding fixture, so every
    // day lands on-track by construction. The boundary day is always
    // forced to miss (rather than left to the random roll) so a nonzero
    // streak comes out to exactly [guaranteedStreakDays], not "at least".
    final isMissedDay = options.missedDayProbability > 0 &&
        (daysAgo == options.guaranteedStreakDays ||
            (daysAgo > options.guaranteedStreakDays &&
                demoRng.nextDouble() < options.missedDayProbability));
    final double deficit;
    if (isMissedDay) {
      final overate = demoRng.nextBool();
      // Over by 550-1449 kcal (exceeds the >500-over "on track" limit) or
      // under by 1050-1549 kcal (exceeds the >=1000-under limit) — see
      // TrackedDayEntity._hasExceededMaxKcalDifferenceGoal.
      deficit = overate
          ? -(550.0 + demoRng.nextInt(900))
          : (1050.0 + demoRng.nextInt(500));
    } else {
      // 200-749 kcal under goal — comfortably inside the "on track" band
      // and consistent with this demo user's "lose weight" goal. Random
      // rather than a fixed cycle so the calorie trend graph looks like
      // an actual person's data instead of a repeating sawtooth.
      deficit = 200.0 + demoRng.nextInt(550);
    }
    final targetKcal = dayKcalGoal - deficit;

    // Scale the day's macro targets by the same ratio as the calorie
    // target, so a day eaten under goal is also under its macro goals
    // (macros should "rarely exceed" per-goal, not just calories).
    final kcalRatio = targetKcal / dayKcalGoal;
    final targetMacros = (
      carbs: dayCarbsGoal * kcalRatio,
      fat: dayFatGoal * kcalRatio,
      protein: dayProteinGoal * kcalRatio,
    );

    final dayIntakes = buildDailyIntakes(day, targetMacros, foods);
    intakeDBOs.addAll(dayIntakes.map(IntakeDBO.fromIntakeEntity));

    final totalKcal = dayIntakes.fold(0.0, (sum, i) => sum + i.totalKcal);
    final totalCarbs = dayIntakes.fold(
      0.0,
      (sum, i) => sum + i.totalCarbsGram,
    );
    final totalFat = dayIntakes.fold(0.0, (sum, i) => sum + i.totalFatsGram);
    final totalProtein = dayIntakes.fold(
      0.0,
      (sum, i) => sum + i.totalProteinsGram,
    );

    trackedDayDBOs.add(
      TrackedDayDBO(
        day: day,
        calorieGoal: dayKcalGoal,
        caloriesTracked: totalKcal,
        carbsGoal: dayCarbsGoal,
        carbsTracked: totalCarbs,
        fatGoal: dayFatGoal,
        fatTracked: totalFat,
        proteinGoal: dayProteinGoal,
        proteinTracked: totalProtein,
      ),
    );

    waterIntakeDBOs.addAll(
      buildDailyWater(day).map(WaterIntakeDBO.fromWaterIntakeEntity),
    );
  }

  await locator<IntakeRepository>().addAllIntakeDBOs(intakeDBOs);
  await locator<UserActivityRepository>().addAllUserActivityDBOs(
    activityDBOs,
  );
  await locator<TrackedDayRepository>().addAllTrackedDays(trackedDayDBOs);
  await locator<WaterIntakeRepository>().addAllEntries(waterIntakeDBOs);
  await locator<WeightLogRepository>().addAllEntries(
    _buildWeightLog(startOfToday, user.weightKG, options),
  );

  final fastingRepository = locator<FastingRepository>();
  for (final session in _buildFastingSessions(now, options.daysOfHistory)) {
    await fastingRepository.addSession(session);
  }

  await seedRecipes(now, foods);
  await seedCustomActivityTemplate();

  // Marks the active profile as holding sample, not real, data — drives
  // the Home screen's demo-mode banner (see `main_screen.dart`) and, as a
  // side effect, lets `just dev_seed` exercise that same banner/exit flow.
  await locator<AddConfigUsecase>().setConfigIsDemoData(true);

  _log.info('Demo data seeded.');
}

/// Wipes the active profile's tracked data plus the demo-only shared
/// content a seed writes (custom meals, recipes, activity templates —
/// see [HiveDBProvider]'s doc comment on why those live outside
/// [DeleteAllUserDataUsecase]'s per-profile clear). Shared by
/// [seedDemoData]'s own pre-reseed wipe and [exitDemoMode] so the two
/// can't drift apart.
Future<void> _wipeActiveProfileAndDemoContent() async {
  await locator<DeleteAllUserDataUsecase>().deleteAll();
  final hiveDBProvider = locator<HiveDBProvider>();
  await hiveDBProvider.customMealBox.clear();
  await hiveDBProvider.recipeBox.clear();
  await hiveDBProvider.customActivityTemplateBox.clear();
}

/// Called when the user taps "Set up your profile" on the demo-mode
/// banner to leave demo mode. [DeleteAllUserDataUsecase.deleteAll] alone
/// isn't enough here: it deliberately leaves the shared recipe/custom-meal/
/// activity-template libraries and the profile registry untouched, since
/// for its usual caller (Settings' "delete all my data") those are shared
/// across profiles and profile identity isn't part of "my data" to begin
/// with. But demo mode reuses the single active profile rather than a
/// separate one, so *everything* [seedDemoData] wrote — content libraries
/// included — is demo-only and needs to go, and the profile's demo name
/// and photo need to fall back to the same blank slate
/// `bootstrapActiveProfile` creates on first run, so a subsequent real
/// onboarding starts from nothing.
Future<void> exitDemoMode() async {
  final active = locator<GetProfilesUsecase>().getActiveProfile();

  await _wipeActiveProfileAndDemoContent();

  if (active == null) return;
  if (active.imagePath != null) {
    await UserImageStorage.delete(active.imagePath!);
  }
  await locator<UpdateProfileUsecase>().updateProfile(
    ProfileEntity(
      id: active.id,
      name: '',
      createdAt: active.createdAt,
      boxSuffix: active.boxSuffix,
      imagePath: null,
    ),
  );
}

/// 178cm / 87kg puts BMI at ~27.5 ("overweight") — solidly outside the
/// normal 18.5-24.9 range regardless of [DemoSeedOptions] duration, since
/// [_buildWeightLog] never lets the trend dip below this figure either.
UserEntity _demoUser(DateTime startOfToday) => UserEntity(
  birthday: DateTime(startOfToday.year - 29, 4, 12),
  heightCM: 178,
  weightKG: 87,
  gender: UserGenderEntity.male,
  goal: UserWeightGoalEntity.loseWeight,
  pal: UserPALEntity.active,
  weeklyWeightGoalKg: -0.4,
);

/// The one hand-picked Unsplash portrait used for the demo profile's
/// avatar (see unsplash_attribution.dart) — a friendly, neutral headshot,
/// since Unsplash has no "people" search angle the way Open Food Facts
/// has product photos.
const _profilePhotoId = '1651684215020-f7a5b6610f23';

/// Renames the active profile and, best-effort, downloads and stores the
/// curated Unsplash portrait as its avatar, recording the photographer
/// credit in a sidecar file (read back by `profile_editor_screen.dart`).
/// Network/storage failures are swallowed — a missing avatar shouldn't
/// abort the whole seed.
Future<void> _setupActiveProfile() async {
  final active = locator<GetProfilesUsecase>().getActiveProfile();
  if (active == null) return;

  String? imagePath;
  try {
    final avatarUrl = unsplashImageUrl(_profilePhotoId, width: 500);
    final response = await http
        .get(Uri.parse(avatarUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/demo_profile_avatar_source');
      await tempFile.writeAsBytes(response.bodyBytes);
      imagePath = await UserImageStorage.importFrom(
        kind: UserImageKind.profile,
        ownerId: active.id,
        sourcePath: tempFile.path,
      );
      await tempFile.delete();
      final credit = unsplashCreditForUrl(avatarUrl);
      if (credit != null) {
        await UserImageStorage.writeCredit(
          imagePath,
          name: credit.name,
          profileUrl: credit.profileUrl,
        );
      }
    }
  } catch (e) {
    _log.warning('Could not download demo profile picture: $e');
  }

  await locator<UpdateProfileUsecase>().updateProfile(
    ProfileEntity(
      id: active.id,
      name: _demoProfileName,
      createdAt: active.createdAt,
      boxSuffix: active.boxSuffix,
      imagePath: imagePath ?? active.imagePath,
    ),
  );
}

/// Weigh-ins roughly every 2 days (frequent enough that the Trends 7-day
/// window always has several, unlike a weekly cadence which could land
/// zero or one point inside any given 7-day range) trending from
/// [DemoSeedOptions.startWeightKg] down to the user's current weight, with
/// randomised jitter so the chart doesn't look like a perfectly straight
/// or perfectly formulaic line.
List<WeightLogDBO> _buildWeightLog(
  DateTime startOfToday,
  double currentWeightKg,
  DemoSeedOptions options,
) {
  final entries = <WeightLogDBO>[];
  final totalDays = options.daysOfHistory - 1;

  var daysAgo = totalDays;
  while (daysAgo > 0) {
    final progress = totalDays == 0 ? 1.0 : 1 - daysAgo / totalDays;
    final trendWeight = options.startWeightKg +
        (currentWeightKg - options.startWeightKg) * progress;
    final jitter = (demoRng.nextDouble() - 0.5) * 0.6; // +/- 0.3kg
    entries.add(
      WeightLogDBO.fromWeightLogEntity(
        WeightLogEntity(
          date: startOfToday.subtract(Duration(days: daysAgo)),
          weightKg: double.parse((trendWeight + jitter).toStringAsFixed(1)),
        ),
      ),
    );
    daysAgo -= 2 + demoRng.nextInt(2); // every 2-3 days
  }
  // Today's exact current weight, matching the profile — no jitter, so it
  // stays consistent with what the Home/Profile screens show elsewhere.
  entries.add(
    WeightLogDBO.fromWeightLogEntity(
      WeightLogEntity(date: startOfToday, weightKg: currentWeightKg),
    ),
  );
  return entries;
}

/// A fasting session roughly every 9-14 days across [daysOfHistory] —
/// mostly completed, occasionally broken early — plus one still in
/// progress so the fasting timer has something live to show right after
/// seeding.
List<FastingSessionEntity> _buildFastingSessions(DateTime now, int daysOfHistory) {
  final sessions = <FastingSessionEntity>[];
  var daysAgo = daysOfHistory - 1;
  while (daysAgo >= 3) {
    final start = now.subtract(Duration(days: daysAgo, hours: 8));
    final targetMinutes = 14 * 60 + demoRng.nextInt(181); // 14-17h
    final brokeEarly = demoRng.nextDouble() < 0.08;
    sessions.add(
      FastingSessionEntity(
        id: IdGenerator.getUniqueID(),
        startedAt: start,
        targetDurationMinutes: targetMinutes,
        completedAt: brokeEarly
            ? null
            : start.add(Duration(minutes: targetMinutes + 5)),
        cancelledAt: brokeEarly
            ? start.add(Duration(hours: 3 + demoRng.nextInt(3)))
            : null,
      ),
    );
    daysAgo -= 9 + demoRng.nextInt(6);
  }

  sessions.add(
    FastingSessionEntity(
      id: IdGenerator.getUniqueID(),
      startedAt: now.subtract(const Duration(hours: 5)),
      targetDurationMinutes: 16 * 60,
    ),
  );
  return sessions;
}
