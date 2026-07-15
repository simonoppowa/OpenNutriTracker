import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/scoped_hive_db_provider.dart';

/// Copies logged intakes into one or more *other* profiles.
///
/// Each target profile keeps its own isolated box-set, so this opens the
/// target's boxes scoped (without making it active) and reuses the normal
/// add-intake + update-tracked-day flow against them. The intake is
/// duplicated with a fresh id; the source profile keeps its own copy.
class SendIntakeToProfilesUsecase {
  final HiveDBProvider _hiveDBProvider;

  SendIntakeToProfilesUsecase(this._hiveDBProvider);

  Future<void> copyToProfiles(
    List<IntakeEntity> intakes,
    List<ProfileEntity> targetProfiles,
  ) async {
    for (final target in targetProfiles) {
      await _copyToProfile(intakes, target);
    }
  }

  Future<void> _copyToProfile(
    List<IntakeEntity> intakes,
    ProfileEntity target,
  ) async {
    final suffix = target.boxSuffix;

    // Guard against copying into the active profile — its boxes are live
    // and open. Closing them in the finally-block would tear down the
    // app's working set. The sheet already filters the active profile out
    // today, but this keeps the usecase safe regardless of caller.
    if (target.id == _hiveDBProvider.activeProfileId) return;

    final scoped = ScopedHiveDBProvider(
      intakeBox: await _hiveDBProvider.openScopedBox<IntakeDBO>(
        HiveDBProvider.intakeBoxName,
        suffix,
      ),
      trackedDayBox: await _hiveDBProvider.openScopedBox<TrackedDayDBO>(
        HiveDBProvider.trackedDayBoxName,
        suffix,
      ),
      userBox: await _hiveDBProvider.openScopedBox<UserDBO>(
        HiveDBProvider.userBoxName,
        suffix,
      ),
      configBox: await _hiveDBProvider.openScopedBox<ConfigDBO>(
        HiveDBProvider.configBoxName,
        suffix,
      ),
      userActivityBox: await _hiveDBProvider.openScopedBox<UserActivityDBO>(
        HiveDBProvider.userActivityBoxName,
        suffix,
      ),
      // App config is shared, so the goal calc reads the same global box.
      appConfigBox: _hiveDBProvider.appConfigBox,
    );

    final userRepository = UserRepository(UserDataSource(scoped));
    // A profile that hasn't finished onboarding has no user data and no
    // goals to seed a tracked day with — skip it rather than guess. Still
    // close the boxes we just opened so this early return doesn't leak them.
    if (!await userRepository.hasUserData()) {
      await _closeScoped(suffix);
      return;
    }

    try {
      final intakeRepository = IntakeRepository(IntakeDataSource(scoped));
      final addTrackedDay = AddTrackedDayUsecase(
        TrackedDayRepository(TrackedDayDataSource(scoped)),
      );
      final configRepository = ConfigRepository(ConfigDataSource(scoped));
      final getKcalGoal = GetKcalGoalUsecase(
        userRepository,
        configRepository,
        UserActivityRepository(UserActivityDataSource(scoped)),
      );
      final getMacroGoal = GetMacroGoalUsecase(configRepository);

      for (final intake in intakes) {
        final copy = IntakeEntity(
          id: IdGenerator.getUniqueID(),
          unit: intake.unit,
          amount: intake.amount,
          type: intake.type,
          meal: intake.meal,
          dateTime: intake.dateTime,
        );
        await intakeRepository.addIntake(copy);

        final day = copy.dateTime;
        if (!await addTrackedDay.hasTrackedDay(day)) {
          final kcalGoal = await getKcalGoal.getKcalGoal();
          await addTrackedDay.addNewTrackedDay(
            day,
            kcalGoal,
            await getMacroGoal.getCarbsGoal(kcalGoal),
            await getMacroGoal.getFatsGoal(kcalGoal),
            await getMacroGoal.getProteinsGoal(kcalGoal),
          );
        }
        await addTrackedDay.addDayCaloriesTracked(day, copy.totalKcal);
        await addTrackedDay.addDayMacrosTracked(
          day,
          carbsTracked: copy.totalCarbsGram,
          fatTracked: copy.totalFatsGram,
          proteinTracked: copy.totalProteinsGram,
        );
      }
    } finally {
      // These boxes were opened solely for this copy — close them so they
      // don't stay resident (memory/file handles) for the rest of the app's
      // lifetime, mirroring how switching profiles closes the outgoing
      // box-set. The shared appConfigBox is left untouched.
      await _closeScoped(suffix);
    }
  }

  Future<void> _closeScoped(String suffix) => Future.wait([
    _hiveDBProvider.closeScopedBox<IntakeDBO>(
      HiveDBProvider.intakeBoxName,
      suffix,
    ),
    _hiveDBProvider.closeScopedBox<TrackedDayDBO>(
      HiveDBProvider.trackedDayBoxName,
      suffix,
    ),
    _hiveDBProvider.closeScopedBox<UserDBO>(HiveDBProvider.userBoxName, suffix),
    _hiveDBProvider.closeScopedBox<ConfigDBO>(
      HiveDBProvider.configBoxName,
      suffix,
    ),
    _hiveDBProvider.closeScopedBox<UserActivityDBO>(
      HiveDBProvider.userActivityBoxName,
      suffix,
    ),
  ]);
}
