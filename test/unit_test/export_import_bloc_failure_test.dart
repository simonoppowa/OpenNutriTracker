import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/custom_activity_template_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_json_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_error_text.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/test_l10n.dart';

/// A pick the plugin hands back; `path` derives from the URI as in the
/// real [PlatformFile].
final class _PickedFile extends PlatformFile {
  _PickedFile(this.name, this.uri);

  @override
  final String name;

  @override
  final Uri uri;

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => null;

  @override
  Future<int> length() => File(path!).length();

  @override
  Future<Uint8List> readAsBytes() => File(path!).readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => File(path!).openRead().cast();
}

/// Export that fails the way the test says. The archive assembly is
/// covered elsewhere; here only the bloc's handling of the failure is
/// under test.
class _ThrowingExportDataUsecase extends ExportDataUsecase {
  _ThrowingExportDataUsecase(this.error)
    : super(
        UserActivityRepository(UserActivityDataSource(_provider)),
        IntakeRepository(IntakeDataSource(_provider)),
        TrackedDayRepository(TrackedDayDataSource(_provider)),
        RecipeRepository(RecipeDataSource(_provider)),
        CustomMealDataSource(_provider),
        WeightLogRepository(WeightLogDataSource(_provider)),
        CustomActivityTemplateRepository(
          CustomActivityTemplateDataSource(_provider),
        ),
      );

  final Object error;

  @override
  Future<bool> exportData(
    String exportZipFileName,
    String userActivityJsonFileName,
    String userIntakeJsonFileName,
    String trackedDayJsonFileName,
    String recipeJsonFileName,
    String weightLogJsonFileName,
    String customActivityTemplateJsonFileName, {
    ExportFormat format = ExportFormat.json,
    String userActivityCsvFileName = 'user_activity.csv',
    String userIntakeCsvFileName = 'user_intake.csv',
    String trackedDayCsvFileName = 'user_tracked_day.csv',
  }) async {
    throw error;
  }
}

class _ThrowingDownloadSampleCsvUsecase extends DownloadSampleCsvUsecase {
  _ThrowingDownloadSampleCsvUsecase(this.error);

  final Object error;

  @override
  Future<bool> downloadSample() async => throw error;
}

final _provider = FakeHiveDBProvider();

/// Wires a bloc whose import path is the *real* [ImportDataUsecase] over
/// [pickFile], so the cancel / wrong-format mapping is exercised end to
/// end from the event to the state. Everything else is inert.
ExportImportBloc _bloc({
  Future<PlatformFile?> Function()? pickFile,
  Object? exportError,
  Object? sampleCsvError,
}) {
  final userActivityRepository = UserActivityRepository(
    UserActivityDataSource(_provider),
  );
  final intakeRepository = IntakeRepository(IntakeDataSource(_provider));
  final trackedDayRepository = TrackedDayRepository(
    TrackedDayDataSource(_provider),
  );
  final recipeRepository = RecipeRepository(RecipeDataSource(_provider));
  final customMealDataSource = CustomMealDataSource(_provider);
  final configRepository = ConfigRepository(ConfigDataSource(_provider));
  final saveRecipeUseCase = SaveRecipeUseCase(
    recipeRepository,
    ComputeRecipeNutritionUseCase(),
  );

  return ExportImportBloc(
    _ThrowingExportDataUsecase(exportError ?? StateError('unused')),
    ImportDataUsecase(
      userActivityRepository,
      intakeRepository,
      trackedDayRepository,
      recipeRepository,
      WeightLogRepository(WeightLogDataSource(_provider)),
      CustomActivityTemplateRepository(
        CustomActivityTemplateDataSource(_provider),
      ),
      pickFile: pickFile ?? () async => throw StateError('unused'),
    ),
    ImportMealsCsvUsecase(customMealDataSource),
    ImportRecipesCsvUsecase(saveRecipeUseCase),
    _ThrowingDownloadSampleCsvUsecase(sampleCsvError ?? StateError('unused')),
    DownloadSampleJsonUsecase(),
    ImportMealsJsonUsecase(
      AddIntakeUsecase(intakeRepository),
      AddTrackedDayUsecase(trackedDayRepository),
      GetKcalGoalUsecase(
        UserRepository(UserDataSource(_provider)),
        configRepository,
        userActivityRepository,
      ),
      GetMacroGoalUsecase(configRepository),
      customMealDataSource,
    ),
    ImportRecipesJsonUsecase(saveRecipeUseCase),
  );
}

/// Adds [event] and returns every state up to and including the first
/// one that is not the loading indicator.
Future<List<ExportImportState>> _drive(
  ExportImportBloc bloc,
  ExportImportEvent event,
) async {
  final states = <ExportImportState>[];
  final done = Completer<void>();
  final sub = bloc.stream.listen((state) {
    states.add(state);
    if (state is! ExportImportLoadingState && !done.isCompleted) {
      done.complete();
    }
  });
  bloc.add(event);
  await done.future.timeout(const Duration(seconds: 5));
  await sub.cancel();
  return states;
}

void main() {
  late Directory tempDir;
  late List<LogRecord> logs;
  late StreamSubscription<LogRecord> logSub;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('export_import_bloc_test');
    logs = [];
    Logger.root.level = Level.ALL;
    logSub = Logger.root.onRecord
        .where((r) => r.loggerName == 'ExportImportBloc')
        .listen(logs.add);
  });

  tearDown(() async {
    await logSub.cancel();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ExportImportBloc failure handling (#1103)', () {
    test(
      'a cancelled picker returns to initial and renders no error',
      () async {
        final bloc = _bloc(pickFile: () async => null);
        addTearDown(bloc.close);

        final states = await _drive(bloc, const ImportDataEvent());

        expect(states, [ExportImportLoadingState(), ExportImportInitial()]);
        expect(states.whereType<ExportImportError>(), isEmpty);
        expect(logs.where((r) => r.level >= Level.SEVERE), isEmpty);
      },
    );

    test(
      'a .csv picked for the JSON zip import is unreadableOrWrongFormat',
      () async {
        final csv = File('${tempDir.path}/meals.csv')
          ..writeAsBytesSync(utf8.encode('name,kcal\nApple,52\n'));
        final bloc = _bloc(
          pickFile: () async => _PickedFile('meals.csv', csv.uri),
        );
        addTearDown(bloc.close);

        final states = await _drive(bloc, const ImportDataEvent());

        expect(states, [
          ExportImportLoadingState(),
          const ExportImportError(
            ExportImportFailureReason.unreadableOrWrongFormat,
          ),
        ]);
      },
    );

    test(
      'a classified failure is logged with its exception and stack trace',
      () async {
        final csv = File('${tempDir.path}/meals.csv')
          ..writeAsBytesSync(utf8.encode('name,kcal\nApple,52\n'));
        final bloc = _bloc(
          pickFile: () async => _PickedFile('meals.csv', csv.uri),
        );
        addTearDown(bloc.close);

        await _drive(bloc, const ImportDataEvent());

        final severe = logs.where((r) => r.level == Level.SEVERE).toList();
        expect(severe, hasLength(1));
        expect(severe.single.error, isA<ExportImportFailure>());
        expect(severe.single.stackTrace, isNotNull);
        expect(severe.single.message, contains('unreadableOrWrongFormat'));
      },
    );

    test('an export whose save failed surfaces writeFailed', () async {
      final bloc = _bloc(
        exportError: const ExportImportFailure(
          ExportImportFailureReason.writeFailed,
          'Could not save opennutritracker-export.zip',
        ),
      );
      addTearDown(bloc.close);

      final states = await _drive(bloc, const ExportDataEvent());

      expect(states.last, isA<ExportImportError>());
      expect(
        (states.last as ExportImportError).reason,
        ExportImportFailureReason.writeFailed,
      );
    });

    test(
      'an unclassified exception surfaces as unexpected, and is logged',
      () async {
        // The ticket's headline case: a StateError with a useful message
        // that used to be thrown away.
        final error = StateError(
          'Export archive was empty, refusing to save it',
        );
        final bloc = _bloc(exportError: error);
        addTearDown(bloc.close);

        final states = await _drive(bloc, const ExportDataEvent());

        expect(
          states.last,
          const ExportImportError(ExportImportFailureReason.unexpected),
        );
        final severe = logs.where((r) => r.level == Level.SEVERE).toList();
        expect(severe, hasLength(1));
        expect(severe.single.error, same(error));
        expect(severe.single.stackTrace, isNotNull);
      },
    );

    test('sample downloads share the classification', () async {
      final bloc = _bloc(
        sampleCsvError: const ExportImportFailure(
          ExportImportFailureReason.writeFailed,
          'Could not save opennutritracker-meals-sample.csv',
        ),
      );
      addTearDown(bloc.close);

      final states = await _drive(bloc, DownloadSampleCsvEvent());

      expect(
        states.last,
        const ExportImportError(ExportImportFailureReason.writeFailed),
      );
    });
  });

  group('exportImportErrorText', () {
    test('says something different for each rendered reason', () {
      final rendered = {
        ExportImportFailureReason.unreadableOrWrongFormat,
        ExportImportFailureReason.writeFailed,
        ExportImportFailureReason.unexpected,
      }.map((reason) => exportImportErrorText(l10nEn, reason)).toList();

      expect(rendered.toSet(), hasLength(rendered.length));
      expect(rendered.every((text) => text.trim().isNotEmpty), isTrue);
    });
  });
}
