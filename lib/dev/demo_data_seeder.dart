import 'dart:io';
import 'dart:math';

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
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_custom_activity_template_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_all_user_data_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_profile_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/dev/unsplash_attribution.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/fasting/data/repository/fasting_repository.dart';
import 'package:opennutritracker/features/fasting/domain/entity/fasting_session_entity.dart';
import 'package:opennutritracker/features/fasting/domain/usecase/acknowledge_fasting_warning_usecase.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('DemoDataSeeder');

const _daysOfHistory = 365;
const _demoProfileName = 'Alex Demo';

/// The current-streak guarantee (see [seedDemoData]) and the day-to-day
/// randomisation both read off this single fixed-seed generator, so the
/// data looks organically noisy (no obvious repeating cycle in the
/// calorie/water graphs) while still being reproducible across runs —
/// handy for a dev tool where you want the same fixture every time you
/// reseed, not a new random one.
final _rng = Random(1337);

/// Wipes the active profile back to a fresh, un-onboarded state and refills
/// it with a full year of realistic demo data — a named, photographed user
/// profile, daily meals sized to hit (and rarely exceed) both the calorie
/// and macro goals on ~90% of days with a 15-day current streak, activities
/// on roughly half the days, noisy (not cyclical) weight/water history for
/// a user who stays outside the "normal" BMI range all year, several
/// recipes, a saved activity template, and fasting sessions in every state
/// — so every screen has a year's worth of realistic-looking history
/// without walking onboarding by hand each run.
///
/// Builds every day's records in memory first and writes each box with a
/// single bulk `addAll` call — a sequential per-day/per-usecase await loop
/// over 365 days would take minutes on a real device.
///
/// Only ever called from `lib/dev/main_dev.dart`; never reachable from the
/// normal `lib/main.dart` entry point.
Future<void> seedDemoData() async {
  _log.info('Seeding demo data ($_daysOfHistory days)...');

  await locator<DeleteAllUserDataUsecase>().deleteAll();
  final hiveDBProvider = locator<HiveDBProvider>();
  await hiveDBProvider.customMealBox.clear();
  await hiveDBProvider.recipeBox.clear();
  await hiveDBProvider.customActivityTemplateBox.clear();

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final user = _demoUser(startOfToday);
  await locator<AddUserUsecase>().addUser(user);
  await locator<AcknowledgeFastingWarningUseCase>()();

  // Hand-picked Unsplash photos, reused across all 365 days' intake
  // entries — see unsplash_attribution.dart for why these are hardcoded
  // URLs rather than a live search.
  final foods = _buildDemoFoods();
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

  for (var daysAgo = _daysOfHistory - 1; daysAgo >= 0; daysAgo--) {
    final day = startOfToday.subtract(Duration(days: daysAgo));

    // Activity on roughly half of all days, always including today so the
    // Home screen has something to show immediately after seeding.
    var activityBurnedKcal = 0.0;
    if (daysAgo == 0 || _rng.nextDouble() < 0.5) {
      final activity = _activityPool[_rng.nextInt(_activityPool.length)];
      final duration = 25.0 + _rng.nextInt(40); // 25-64 min
      final burnedKcal = METCalc.getTotalBurnedKcal(user, activity, duration);
      activityBurnedKcal = burnedKcal;
      activityDBOs.add(
        UserActivityDBO.fromUserActivityEntity(
          UserActivityEntity(
            IdGenerator.getUniqueID(),
            duration,
            burnedKcal,
            _jitteredTime(day, 18),
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

    // The most recent 15 days are always on-track, guaranteeing a 15-day
    // current streak (Trends' "current" streak is the run ending today,
    // within whichever window chip is selected — the default 7d chip
    // only ever looks at 7 days, so the 15-day run only shows once the
    // 30d/90d/All chip is picked). Every other day has a ~10% chance of
    // missing the goal outright (an over- or under-shoot well past the
    // "on track" tolerance), landing overall adherence around 90%. Day 15
    // is always forced to miss (rather than left to the random roll) so
    // the current streak comes out to exactly 15, not "15 or more by
    // chance".
    final isMissedDay =
        daysAgo == 15 || (daysAgo > 15 && _rng.nextDouble() < 0.10);
    final double deficit;
    if (isMissedDay) {
      final overate = _rng.nextBool();
      // Over by 550-1449 kcal (exceeds the >500-over "on track" limit) or
      // under by 1050-1549 kcal (exceeds the >=1000-under limit) — see
      // TrackedDayEntity._hasExceededMaxKcalDifferenceGoal.
      deficit = overate
          ? -(550.0 + _rng.nextInt(900))
          : (1050.0 + _rng.nextInt(500));
    } else {
      // 200-749 kcal under goal — comfortably inside the "on track" band
      // and consistent with this demo user's "lose weight" goal. Random
      // rather than a fixed cycle so the calorie trend graph looks like
      // an actual person's data instead of a repeating sawtooth.
      deficit = 200.0 + _rng.nextInt(550);
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

    final dayIntakes = _buildDailyIntakes(day, targetMacros, foods);
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

    waterIntakeDBOs.addAll(_buildDailyWater(day));
  }

  await locator<IntakeRepository>().addAllIntakeDBOs(intakeDBOs);
  await locator<UserActivityRepository>().addAllUserActivityDBOs(
    activityDBOs,
  );
  await locator<TrackedDayRepository>().addAllTrackedDays(trackedDayDBOs);
  await locator<WaterIntakeRepository>().addAllEntries(waterIntakeDBOs);
  await locator<WeightLogRepository>().addAllEntries(
    _buildWeightLog(startOfToday, user.weightKG),
  );

  final fastingRepository = locator<FastingRepository>();
  for (final session in _buildFastingSessions(now)) {
    await fastingRepository.addSession(session);
  }

  await _seedRecipes(now, foods);
  await _seedCustomActivityTemplate();

  _log.info('Demo data seeded.');
}

/// 178cm / 87kg puts BMI at ~27.5 ("overweight") — solidly outside the
/// normal 18.5-24.9 range all year, since the weight-log trend (see
/// [_buildWeightLog]) never dips below this figure either.
UserEntity _demoUser(DateTime startOfToday) => UserEntity(
  birthday: DateTime(startOfToday.year - 29, 4, 12),
  heightCM: 178,
  weightKG: 87,
  gender: UserGenderEntity.male,
  goal: UserWeightGoalEntity.loseWeight,
  pal: UserPALEntity.active,
  weeklyWeightGoalKg: -0.4,
);

/// [hour]:00 plus up to 44 random minutes, so logged times don't land on
/// the exact same clock minute every single day.
DateTime _jitteredTime(DateTime day, int hour) =>
    DateTime(day.year, day.month, day.day, hour, _rng.nextInt(45));

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
    final response = await http.get(Uri.parse(avatarUrl));
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

/// The fixed set of foods used to build every day's intake and the
/// recipes. Grouped so [_buildDailyIntakes] and [_seedRecipes] don't have
/// to know how they were constructed (with or without a fetched photo).
typedef _DemoFoods = ({
  MealEntity oatmeal,
  MealEntity brownRice,
  MealEntity wholegrainBread,
  MealEntity chickenBreast,
  MealEntity greekYogurt,
  MealEntity salmon,
  MealEntity oliveOil,
  MealEntity almonds,
  MealEntity banana,
  MealEntity apple,
  MealEntity broccoli,
});

/// A per-100g nutrient snapshot broad enough to cover what the diary's
/// micronutrient panel aggregates (see `DailyNutrientPanel`, which sums
/// straight off logged intakes' [MealNutrimentsEntity] — there's no
/// separate "tracked micros" store to seed). Values below are
/// approximate real-world figures for each food, not lab-precise, but
/// plausible enough that the panel shows realistic numbers instead of
/// zeroes.
MealEntity _meal(
  String name, {
  required double kcal100,
  required double carbs100,
  required double fat100,
  required double protein100,
  double? sugars100,
  double? satFat100,
  double? fiber100,
  double? monounsaturatedFat100,
  double? polyunsaturatedFat100,
  double? cholesterol100,
  double? sodium100,
  double? potassium100,
  double? magnesium100,
  double? calcium100,
  double? iron100,
  double? zinc100,
  double? phosphorus100,
  double? vitaminA100,
  double? vitaminC100,
  double? vitaminD100,
  double? vitaminB6100,
  double? vitaminB12100,
  double? niacin100,
  // A curated Unsplash photo id (see unsplash_attribution.dart) — every
  // demo food gets one, so this isn't optional the way a real OFF/FDC
  // search result's photo would be.
  required String photoId,
}) => MealEntity(
  code: IdGenerator.getUniqueID(),
  name: name,
  url: null,
  thumbnailImageUrl: unsplashImageUrl(photoId, width: 200),
  mainImageUrl: unsplashImageUrl(photoId, width: 800),
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  source: MealSourceEntity.custom,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal100,
    carbohydrates100: carbs100,
    fat100: fat100,
    proteins100: protein100,
    sugars100: sugars100 ?? carbs100 * 0.3,
    saturatedFat100: satFat100 ?? fat100 * 0.35,
    fiber100: fiber100 ?? 2.0,
    monounsaturatedFat100: monounsaturatedFat100,
    polyunsaturatedFat100: polyunsaturatedFat100,
    cholesterol100: cholesterol100,
    sodium100: sodium100,
    potassium100: potassium100,
    magnesium100: magnesium100,
    calcium100: calcium100,
    iron100: iron100,
    zinc100: zinc100,
    phosphorus100: phosphorus100,
    vitaminA100: vitaminA100,
    vitaminC100: vitaminC100,
    vitaminD100: vitaminD100,
    vitaminB6100: vitaminB6100,
    vitaminB12100: vitaminB12100,
    niacin100: niacin100,
  ),
);

/// Builds every demo food, each with its curated Unsplash photo id (see
/// unsplash_attribution.dart) — a fixed, hand-picked set rather than a
/// live search, so this needs no network access and returns synchronously.
_DemoFoods _buildDemoFoods() {
  final oatmeal = _meal(
    'Oatmeal',
    photoId: '1548807371-30dc1bbe6cb5',
    kcal100: 150,
    carbs100: 27,
    fat100: 3,
    protein100: 5,
    fiber100: 4,
    sodium100: 6,
    potassium100: 143,
    magnesium100: 63,
    calcium100: 21,
    iron100: 1.7,
    zinc100: 1.3,
    phosphorus100: 180,
    vitaminB6100: 0.05,
    niacin100: 0.4,
    monounsaturatedFat100: 1.0,
    polyunsaturatedFat100: 1.1,
  );
  final brownRice = _meal(
    'Brown rice',
    photoId: '1593357849627-cbbc9fda6b05',
    kcal100: 123,
    carbs100: 26,
    fat100: 1,
    protein100: 3,
    fiber100: 1.8,
    sodium100: 5,
    potassium100: 86,
    magnesium100: 43,
    calcium100: 10,
    iron100: 0.5,
    zinc100: 0.6,
    phosphorus100: 83,
    vitaminB6100: 0.15,
    niacin100: 1.5,
    monounsaturatedFat100: 0.3,
    polyunsaturatedFat100: 0.3,
  );
  // Deliberately not a low-carb-density food like potatoes (20g/100g) —
  // hitting a high daily carb target with a low-density food needs an
  // unrealistically large gram amount (900g+ was showing up in testing).
  final wholegrainBread = _meal(
    'Wholegrain bread',
    photoId: '1552056413-b8b5eed0170b',
    kcal100: 265,
    carbs100: 49,
    fat100: 3.5,
    protein100: 9,
    fiber100: 7,
    sodium100: 400,
    potassium100: 230,
    magnesium100: 65,
    calcium100: 100,
    iron100: 2.5,
    zinc100: 1.5,
    phosphorus100: 200,
    vitaminB6100: 0.1,
    niacin100: 4.0,
    monounsaturatedFat100: 0.4,
    polyunsaturatedFat100: 1.2,
  );
  final chickenBreast = _meal(
    'Chicken breast',
    photoId: '1762631934518-f75e233413ca',
    kcal100: 165,
    carbs100: 0,
    fat100: 3.6,
    protein100: 31,
    satFat100: 1,
    cholesterol100: 85,
    sodium100: 74,
    potassium100: 256,
    magnesium100: 29,
    calcium100: 15,
    iron100: 1.0,
    zinc100: 1.0,
    phosphorus100: 220,
    vitaminB6100: 0.6,
    vitaminB12100: 0.3,
    niacin100: 13.7,
    monounsaturatedFat100: 1.24,
    polyunsaturatedFat100: 0.8,
  );
  final greekYogurt = _meal(
    'Greek yogurt',
    photoId: '1571212515416-fef01fc43637',
    kcal100: 59,
    carbs100: 3.6,
    fat100: 0.4,
    protein100: 10,
    sugars100: 3.6,
    cholesterol100: 5,
    sodium100: 36,
    potassium100: 141,
    magnesium100: 11,
    calcium100: 110,
    iron100: 0.05,
    zinc100: 0.5,
    phosphorus100: 135,
    vitaminB6100: 0.05,
    vitaminB12100: 0.5,
    monounsaturatedFat100: 0.1,
  );
  final salmon = _meal(
    'Salmon fillet',
    photoId: '1739785938237-73b3654200d5',
    kcal100: 208,
    carbs100: 0,
    fat100: 13,
    protein100: 20,
    satFat100: 3.1,
    cholesterol100: 55,
    sodium100: 59,
    potassium100: 363,
    magnesium100: 27,
    calcium100: 9,
    iron100: 0.3,
    zinc100: 0.4,
    phosphorus100: 240,
    vitaminD100: 11,
    vitaminB12100: 3.2,
    niacin100: 8.0,
    monounsaturatedFat100: 3.8,
    polyunsaturatedFat100: 3.9,
  );
  final oliveOil = _meal(
    'Olive oil',
    photoId: '1757801333069-f7b3cabaec4a',
    kcal100: 884,
    carbs100: 0,
    fat100: 100,
    protein100: 0,
    satFat100: 14,
    monounsaturatedFat100: 73,
    polyunsaturatedFat100: 11,
  );
  final almonds = _meal(
    'Almonds',
    photoId: '1627820752174-acae1b399128',
    kcal100: 579,
    carbs100: 22,
    fat100: 50,
    protein100: 21,
    fiber100: 12.5,
    sodium100: 1,
    potassium100: 733,
    magnesium100: 270,
    calcium100: 269,
    iron100: 3.7,
    zinc100: 3.1,
    phosphorus100: 481,
    vitaminB6100: 0.14,
    niacin100: 3.6,
    monounsaturatedFat100: 31,
    polyunsaturatedFat100: 12,
  );
  final banana = _meal(
    'Banana',
    photoId: '1757332050958-b797a022c910',
    kcal100: 89,
    carbs100: 23,
    fat100: 0.3,
    protein100: 1.1,
    sugars100: 12,
    fiber100: 2.6,
    sodium100: 1,
    potassium100: 358,
    magnesium100: 27,
    calcium100: 5,
    iron100: 0.26,
    zinc100: 0.15,
    phosphorus100: 22,
    vitaminB6100: 0.37,
    vitaminC100: 8.7,
    niacin100: 0.7,
  );
  final apple = _meal(
    'Apple',
    photoId: '1567306226416-28f0efdc88ce',
    kcal100: 52,
    carbs100: 14,
    fat100: 0.2,
    protein100: 0.3,
    sugars100: 10,
    fiber100: 2.4,
    sodium100: 1,
    potassium100: 107,
    magnesium100: 5,
    calcium100: 6,
    iron100: 0.12,
    vitaminC100: 4.6,
    niacin100: 0.09,
  );
  final broccoli = _meal(
    'Broccoli',
    photoId: '1646161762904-043f71f256f1',
    kcal100: 35,
    carbs100: 7,
    fat100: 0.4,
    protein100: 2.4,
    fiber100: 3.3,
    sodium100: 33,
    potassium100: 316,
    magnesium100: 21,
    calcium100: 47,
    iron100: 0.7,
    zinc100: 0.4,
    phosphorus100: 66,
    vitaminA100: 31,
    vitaminC100: 89,
    vitaminB6100: 0.18,
    niacin100: 0.6,
  );

  return (
    oatmeal: oatmeal,
    brownRice: brownRice,
    wholegrainBread: wholegrainBread,
    chickenBreast: chickenBreast,
    greekYogurt: greekYogurt,
    salmon: salmon,
    oliveOil: oliveOil,
    almonds: almonds,
    banana: banana,
    apple: apple,
    broccoli: broccoli,
  );
}

double _roundToNearest5g(double grams) => max(10.0, (grams / 5).round() * 5.0);

/// Grams of [meal] needed to supply [targetGrams] of the macro read off by
/// [macroPer100] (e.g. `(n) => n.proteins100`). Zero when the food doesn't
/// carry that macro or the target is already met.
double _gramsFor(
  MealEntity meal,
  double targetGrams,
  double? Function(MealNutrimentsEntity) macroPer100,
) {
  final per100 = macroPer100(meal.nutriments) ?? 0;
  if (per100 <= 0 || targetGrams <= 0) return 0;
  return targetGrams / per100 * 100;
}

double _macroGrams(
  MealEntity meal,
  double amount,
  double? Function(MealNutrimentsEntity) macroPer100,
) => (macroPer100(meal.nutriments) ?? 0) * amount / 100;

/// Builds the day's intake by solving for each food's portion in turn —
/// veg and fruit are fixed-size sides; the carb target is split across a
/// breakfast and a dinner starch (rather than one giant bowl of rice);
/// the fat target is split across a dinner oil and a snack-time handful
/// of almonds; and the protein source is sized last, to whatever protein
/// target is left after every other food's contribution is known. Both
/// the splitting and the protein-last ordering exist for the same
/// reason: a single food sized to cover an entire day's target for one
/// macro produces an unrealistic portion (900g+ of rice) and, for
/// protein specifically, routinely overshoots the goal once the other
/// foods' incidental protein is added on top.
///
/// Which foods and what split ratios are chosen is randomised per day (see
/// [_rng]) rather than rotated through a fixed cycle, so the week doesn't
/// visibly repeat itself.
List<IntakeEntity> _buildDailyIntakes(
  DateTime day,
  ({double carbs, double fat, double protein}) targetMacros,
  _DemoFoods foods,
) {
  final carbPool = [foods.oatmeal, foods.brownRice, foods.wholegrainBread];
  final proteinPool = [foods.chickenBreast, foods.greekYogurt, foods.salmon];
  final carbMealA = carbPool[_rng.nextInt(carbPool.length)];
  final carbMealB = carbPool[_rng.nextInt(carbPool.length)];
  final proteinMeal = proteinPool[_rng.nextInt(proteinPool.length)];
  final fruitMeal = _rng.nextBool() ? foods.banana : foods.apple;

  final veggieAmount = 80.0 + _rng.nextInt(60); // 80-139g
  final fruitAmount = 100.0 + _rng.nextInt(60); // 100-159g
  final veggieCarb = _macroGrams(foods.broccoli, veggieAmount, (n) => n.carbohydrates100);
  final veggieFat = _macroGrams(foods.broccoli, veggieAmount, (n) => n.fat100);
  final veggieProtein = _macroGrams(foods.broccoli, veggieAmount, (n) => n.proteins100);
  final fruitCarb = _macroGrams(fruitMeal, fruitAmount, (n) => n.carbohydrates100);
  final fruitFat = _macroGrams(fruitMeal, fruitAmount, (n) => n.fat100);
  final fruitProtein = _macroGrams(fruitMeal, fruitAmount, (n) => n.proteins100);

  // Carb target split ~30-60% breakfast / rest dinner starch.
  final carbShareA = 0.3 + _rng.nextDouble() * 0.3;
  final remainingCarb = targetMacros.carbs - veggieCarb - fruitCarb;
  final carbAmountA = _roundToNearest5g(
    _gramsFor(carbMealA, remainingCarb * carbShareA, (n) => n.carbohydrates100),
  );
  final carbAmountB = _roundToNearest5g(
    _gramsFor(
      carbMealB,
      remainingCarb * (1 - carbShareA),
      (n) => n.carbohydrates100,
    ),
  );
  final carbFat =
      _macroGrams(carbMealA, carbAmountA, (n) => n.fat100) +
      _macroGrams(carbMealB, carbAmountB, (n) => n.fat100);
  final carbProtein =
      _macroGrams(carbMealA, carbAmountA, (n) => n.proteins100) +
      _macroGrams(carbMealB, carbAmountB, (n) => n.proteins100);

  // Fat target split ~50-75% dinner oil / rest a handful of almonds.
  final oilShare = 0.5 + _rng.nextDouble() * 0.25;
  final remainingFat = targetMacros.fat - veggieFat - fruitFat - carbFat;
  final oilAmount = _roundToNearest5g(
    _gramsFor(foods.oliveOil, remainingFat * oilShare, (n) => n.fat100),
  );
  final almondAmount = _roundToNearest5g(
    _gramsFor(
      foods.almonds,
      remainingFat * (1 - oilShare),
      (n) => n.fat100,
    ),
  );
  final almondProtein = _macroGrams(foods.almonds, almondAmount, (n) => n.proteins100);

  final remainingProtein = targetMacros.protein -
      veggieProtein -
      fruitProtein -
      carbProtein -
      almondProtein;
  final proteinAmount = _roundToNearest5g(
    _gramsFor(proteinMeal, remainingProtein, (n) => n.proteins100),
  );

  return [
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: carbAmountA,
      type: IntakeTypeEntity.breakfast,
      meal: carbMealA,
      dateTime: _jitteredTime(day, 8),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: proteinAmount,
      type: IntakeTypeEntity.lunch,
      meal: proteinMeal,
      dateTime: _jitteredTime(day, 13),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: veggieAmount,
      type: IntakeTypeEntity.dinner,
      meal: foods.broccoli,
      dateTime: _jitteredTime(day, 19),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: carbAmountB,
      type: IntakeTypeEntity.dinner,
      meal: carbMealB,
      dateTime: _jitteredTime(day, 19),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: oilAmount,
      type: IntakeTypeEntity.dinner,
      meal: foods.oliveOil,
      dateTime: _jitteredTime(day, 19),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: fruitAmount,
      type: IntakeTypeEntity.snack,
      meal: fruitMeal,
      dateTime: _jitteredTime(day, 16),
    ),
    IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: 'g',
      amount: almondAmount,
      type: IntakeTypeEntity.snack,
      meal: foods.almonds,
      dateTime: _jitteredTime(day, 16),
    ),
  ];
}

const _runningVigorous = PhysicalActivityEntity(
  '12150',
  'Running, vigorous effort',
  'Running at a fast pace',
  12.0,
  [],
  PhysicalActivityTypeEntity.running,
);
const _bicyclingModerate = PhysicalActivityEntity(
  '01015',
  'Bicycling, moderate speed',
  'Bicycling at a moderate speed on flat terrain',
  8.0,
  [],
  PhysicalActivityTypeEntity.bicycling,
);
const _dancingLight = PhysicalActivityEntity(
  '03015',
  'Dancing, light effort',
  'Dancing with light effort, e.g., slow ballroom dancing',
  4.0,
  [],
  PhysicalActivityTypeEntity.dancing,
);
const _activityPool = [_runningVigorous, _bicyclingModerate, _dancingLight];

/// 2-4 glasses of randomised size — a fixed "500 + 500 + 300-600" pattern
/// repeating every few days made the Trends water graph look mechanical;
/// real logging is noisier (and some days people just log less).
List<WaterIntakeDBO> _buildDailyWater(DateTime day) {
  final glassCount = 2 + _rng.nextInt(3);
  final hours = [8, 11, 15, 18, 21];
  return [
    for (var i = 0; i < glassCount; i++)
      WaterIntakeDBO.fromWaterIntakeEntity(
        WaterIntakeEntity(
          id: IdGenerator.getUniqueID(),
          dateTime: _jitteredTime(day, hours[i]),
          amountMl: 200 + _rng.nextInt(5) * 100, // 200-600 ml
        ),
      ),
  ];
}

/// Weigh-ins roughly every 2 days (frequent enough that the Trends 7-day
/// window — which previously could contain zero or one point, since the
/// old weekly cadence rarely landed inside a 7-day range — always has
/// several) trending from a year-ago starting weight down to the user's
/// current weight, with randomised jitter so the chart doesn't look like
/// a perfectly straight or perfectly formulaic line. Both ends of the
/// trend (96kg -> 87kg at 178cm) stay well above the ~78.9kg upper bound
/// of a normal BMI, so the user is never in the "normal" range.
List<WeightLogDBO> _buildWeightLog(DateTime startOfToday, double currentWeightKg) {
  const startWeightKg = 96.0;
  final entries = <WeightLogDBO>[];

  var daysAgo = _daysOfHistory - 1;
  while (daysAgo > 0) {
    final progress = 1 - daysAgo / (_daysOfHistory - 1);
    final trendWeight =
        startWeightKg + (currentWeightKg - startWeightKg) * progress;
    final jitter = (_rng.nextDouble() - 0.5) * 0.6; // +/- 0.3kg
    entries.add(
      WeightLogDBO.fromWeightLogEntity(
        WeightLogEntity(
          date: startOfToday.subtract(Duration(days: daysAgo)),
          weightKg: double.parse((trendWeight + jitter).toStringAsFixed(1)),
        ),
      ),
    );
    daysAgo -= 2 + _rng.nextInt(2); // every 2-3 days
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

/// A fasting session roughly every 9-14 days across the year — mostly
/// completed, occasionally broken early — plus one still in progress so
/// the fasting timer has something live to show right after seeding.
List<FastingSessionEntity> _buildFastingSessions(DateTime now) {
  final sessions = <FastingSessionEntity>[];
  var daysAgo = _daysOfHistory - 1;
  while (daysAgo >= 3) {
    final start = now.subtract(Duration(days: daysAgo, hours: 8));
    final targetMinutes = 14 * 60 + _rng.nextInt(181); // 14-17h
    final brokeEarly = _rng.nextDouble() < 0.08;
    sessions.add(
      FastingSessionEntity(
        id: IdGenerator.getUniqueID(),
        startedAt: start,
        targetDurationMinutes: targetMinutes,
        completedAt: brokeEarly
            ? null
            : start.add(Duration(minutes: targetMinutes + 5)),
        cancelledAt: brokeEarly
            ? start.add(Duration(hours: 3 + _rng.nextInt(3)))
            : null,
      ),
    );
    daysAgo -= 9 + _rng.nextInt(6);
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

MealNutrimentsEntity _emptyRecipeNutriments() => MealNutrimentsEntity.empty();

/// A handful of saved recipes spanning breakfast and dinner, high-protein
/// and lighter options — `SaveRecipeUseCase.save` recomputes the
/// aggregated nutriments from the ingredient list, so only the ingredient
/// amounts need to be realistic.
Future<void> _seedRecipes(DateTime now, _DemoFoods foods) async {
  RecipeIngredientEntity ingredient(MealEntity meal, double amountG) =>
      RecipeIngredientEntity(
        snapshotMeal: meal,
        amount: amountG,
        unit: 'g',
        convertedAmountG: amountG,
      );

  final recipes = [
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Protein Power Bowl',
      description: 'Grilled chicken over brown rice, meal-prep friendly.',
      ingredients: [
        ingredient(foods.chickenBreast, 200),
        ingredient(foods.brownRice, 150),
      ],
      totalWeightG: 350,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 2,
      tags: const ['high-protein'],
    ),
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Salmon & Greens Bowl',
      description:
          'Pan-seared salmon with rice and steamed broccoli — an easy '
          'omega-3-rich dinner for two.',
      ingredients: [
        ingredient(foods.salmon, 180),
        ingredient(foods.brownRice, 150),
        ingredient(foods.broccoli, 100),
      ],
      totalWeightG: 430,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 2,
      tags: const ['omega-3', 'high-protein'],
    ),
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Morning Oat Bowl',
      description: 'Oatmeal topped with banana and almonds.',
      ingredients: [
        ingredient(foods.oatmeal, 200),
        ingredient(foods.banana, 100),
        ingredient(foods.almonds, 20),
      ],
      totalWeightG: 320,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 1,
      tags: const ['breakfast', 'vegetarian'],
    ),
    RecipeEntity(
      id: IdGenerator.getUniqueID(),
      name: 'Greek Yogurt Parfait',
      description: 'Greek yogurt layered with banana and a scattering of almonds.',
      ingredients: [
        ingredient(foods.greekYogurt, 200),
        ingredient(foods.banana, 80),
        ingredient(foods.almonds, 15),
      ],
      totalWeightG: 295,
      aggregatedNutrimentsPer100: _emptyRecipeNutriments(),
      createdAt: now,
      updatedAt: now,
      servingsCount: 1,
      tags: const ['breakfast', 'high-protein'],
    ),
  ];

  final saveRecipe = locator<SaveRecipeUseCase>();
  for (final recipe in recipes) {
    await saveRecipe.save(recipe);
  }
}

Future<void> _seedCustomActivityTemplate() async {
  await locator<AddCustomActivityTemplateUsecase>().addTemplate(
    const CustomActivityTemplateEntity(
      name: 'Gym session',
      typicalKcal: 400,
      notes: 'Full-body strength training',
    ),
  );
}
