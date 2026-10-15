import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_csv_usecase.dart';

// #1194: driving importFromPickedFile end to end against the real
// SaveRecipeUseCase pins the wire the parse-side tests can't reach —
// that `imported.totalWeightOverridden` is threaded into
// SaveRecipeUseCase.save, so an explicit recipe_total_weight_g survives
// the save-time recompute instead of collapsing back to the ingredient sum.
// Same shape as the JSON counterpart added in #1169.

class _FakeRecipeRepository implements RecipeRepository {
  final List<RecipeEntity> saved = [];

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async {
    saved.add(recipe);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

base class _StubPlatformFile extends PlatformFile {
  _StubPlatformFile({required this.name, required String path})
      : uri = Uri.file(path);

  @override
  final String name;

  @override
  final Uri uri;

  // The importer only reads `.path`. Anything else is a bug in the test;
  // matches the `Never get xFile` shape used by the other PlatformFile
  // stubs in this repo so no transitive dependency on `cross_file` is
  // needed.
  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => null;

  @override
  Future<int> length() async => (await File(path!).stat()).size;

  @override
  Future<Uint8List> readAsBytes() => File(path!).readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      File(path!).openRead().map((c) => Uint8List.fromList(c));
}

Future<PlatformFile?> Function() _pickerReturning(File file) {
  return () async => _StubPlatformFile(
        name: file.uri.pathSegments.last,
        path: file.path,
      );
}

ImportRecipesCsvUsecase _buildUsecase(
  _FakeRecipeRepository repo,
  File pickedFile,
) {
  return ImportRecipesCsvUsecase(
    SaveRecipeUseCase(repo, ComputeRecipeNutritionUseCase()),
    pickFile: _pickerReturning(pickedFile),
  );
}

File _writeTempCsv(String contents) {
  // Register the tear-down before writing so the temp dir is removed even
  // if `writeAsStringSync` throws.
  final dir = Directory.systemTemp.createTempSync('ont_csv_recipes_');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  final file = File('${dir.path}/recipes.csv');
  file.writeAsStringSync(contents);
  return file;
}

const _header = 'recipe_name,recipe_description,recipe_servings,'
    'recipe_total_weight_g,recipe_tags,ingredient_name,'
    'ingredient_brands,ingredient_amount,ingredient_unit,'
    'ingredient_kcal_100,ingredient_carbs_100,ingredient_fat_100,'
    'ingredient_protein_100,ingredient_sugars_100,'
    'ingredient_sat_fat_100,ingredient_fiber_100\n';

void main() {
  group('ImportRecipesCsvUsecase.importFromPickedFile', () {
    test(
      'preserves an explicit recipe_total_weight_g through save '
      '(issue #1194 numbers)',
      () async {
        final file = _writeTempCsv(
          '${_header}Test,,,300,,Flour,,110,g,360,,,,,,\n',
        );
        final repo = _FakeRecipeRepository();
        final usecase = _buildUsecase(repo, file);

        final result = await usecase.importFromPickedFile();

        expect(result, isNotNull);
        expect(result!.imported, 1);
        expect(result.skippedRows, 0);
        expect(repo.saved, hasLength(1));
        final saved = repo.saved.single;
        expect(saved.name, 'Test');
        expect(saved.totalWeightG, 300);
        expect(
          saved.aggregatedNutrimentsPer100.energyKcal100,
          closeTo(132, 1e-9),
        );
      },
    );

    test(
      'without recipe_total_weight_g, save-time recompute falls back to '
      'the ingredient sum',
      () async {
        final file = _writeTempCsv(
          '${_header}Test,,,,,Flour,,110,g,360,,,,,,\n',
        );
        final repo = _FakeRecipeRepository();
        final usecase = _buildUsecase(repo, file);

        final result = await usecase.importFromPickedFile();

        expect(result!.imported, 1);
        final saved = repo.saved.single;
        expect(saved.totalWeightG, 110);
        expect(
          saved.aggregatedNutrimentsPer100.energyKcal100,
          closeTo(360, 1e-9),
        );
      },
    );

    test('returns null when the picker is cancelled', () async {
      final repo = _FakeRecipeRepository();
      final usecase = ImportRecipesCsvUsecase(
        SaveRecipeUseCase(repo, ComputeRecipeNutritionUseCase()),
        pickFile: () async => null,
      );

      final result = await usecase.importFromPickedFile();

      expect(result, isNull);
      expect(repo.saved, isEmpty);
    });

    test(
      'a rejected recipe_total_weight_g is reported and never reaches save',
      () async {
        final file = _writeTempCsv(
          '${_header}Zero,,,0,,Flour,,110,g,360,,,,,,\n',
        );
        final repo = _FakeRecipeRepository();
        final usecase = _buildUsecase(repo, file);

        final result = await usecase.importFromPickedFile();

        expect(result!.imported, 0);
        expect(result.skippedRows, 1);
        expect(
          result.errorMessages.single,
          contains(
            'recipe_total_weight_g must be a positive finite number',
          ),
        );
        expect(repo.saved, isEmpty);
      },
    );
  });
}
