import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/water_intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/favorites/data/favorite_data_source.dart';
import 'package:opennutritracker/features/fasting/data/data_source/fasting_data_source.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';
import 'package:opennutritracker/features/settings/domain/profiles_backup.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';

/// The export and import usecases wired against [db]'s boxes, the way the
/// locator wires them for the active profile. Their extras carry
/// [profiles] only when given: a profile's folder never lists the profiles
/// again.
BackupUsecases backupUsecasesFor(
  HiveDBProvider db, {
  ProfilesBackup? profiles,
}) {
  final configRepository = ConfigRepository(ConfigDataSource(db));
  final extras = PersonalBackupExtras(
    WaterIntakeRepository(WaterIntakeDataSource(db)),
    CustomMealDataSource(db),
    UserDataSource(db),
    ConfigDataSource(db),
    FastingDataSource(db),
    profiles: profiles,
    favorites: FavoriteDataSource(db),
  );
  final userActivityRepository = UserActivityRepository(
    UserActivityDataSource(db),
  );
  final intakeRepository = IntakeRepository(IntakeDataSource(db));
  final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));
  final recipeRepository = RecipeRepository(RecipeDataSource(db));
  final weightLogRepository = WeightLogRepository(WeightLogDataSource(db));
  final templateRepository = CustomActivityTemplateRepository(
    CustomActivityTemplateDataSource(db),
  );
  return (
    exporter: ExportDataUsecase(
      userActivityRepository,
      intakeRepository,
      trackedDayRepository,
      recipeRepository,
      CustomMealDataSource(db),
      weightLogRepository,
      templateRepository,
      configRepository,
      extras: extras,
    ),
    importer: ImportDataUsecase(
      userActivityRepository,
      intakeRepository,
      trackedDayRepository,
      recipeRepository,
      weightLogRepository,
      templateRepository,
      configRepository,
      extras: extras,
    ),
  );
}
