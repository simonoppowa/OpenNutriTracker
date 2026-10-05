import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_json_usecase.dart';

// #1139: driving importFromPickedFile end to end against the real
// SaveRecipeUseCase pins the wire that the parse-side tests can't reach —
// that `imported.totalWeightOverridden` is threaded into
// SaveRecipeUseCase.save, so an explicit totalWeight survives the save-time
// recompute instead of collapsing back to the ingredient sum.

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

ImportRecipesJsonUsecase _buildUsecase(
  _FakeRecipeRepository repo,
  File pickedFile,
) {
  return ImportRecipesJsonUsecase(
    SaveRecipeUseCase(repo, ComputeRecipeNutritionUseCase()),
    pickFile: _pickerReturning(pickedFile),
  );
}

File _writeTempJson(String contents) {
  // Register the tear-down before writing so the temp dir is removed even
  // if `writeAsStringSync` throws — matches the addTearDown pattern the
  // neighbouring tests use for their own scratch directories.
  final dir = Directory.systemTemp.createTempSync('ont_json_recipes_');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  final file = File('${dir.path}/recipes.json');
  file.writeAsStringSync(contents);
  return file;
}

void main() {
  group('ImportRecipesJsonUsecase.importFromPickedFile', () {
    test(
      'preserves the JSON totalWeight through save (issue #1139 numbers)',
      () async {
        final file = _writeTempJson('''{
  "name": "Test Recipe",
  "totalWeight": 300,
  "ingredients": [
    {"name": "Ingredient", "amount": 110, "unit": "g", "kcalPer100": 360}
  ]
}''');
        final repo = _FakeRecipeRepository();
        final usecase = _buildUsecase(repo, file);

        final result = await usecase.importFromPickedFile();

        expect(result, isNotNull);
        expect(result!.imported, 1);
        expect(result.skippedRecipes, 0);
        expect(repo.saved, hasLength(1));
        final saved = repo.saved.single;
        expect(saved.totalWeightG, 300);
        expect(saved.aggregatedNutrimentsPer100.energyKcal100, closeTo(132, 1e-9));
      },
    );

    test(
      'without totalWeight, save-time recompute falls back to ingredient sum',
      () async {
        final file = _writeTempJson('''{
  "name": "Test Recipe",
  "ingredients": [
    {"name": "Ingredient", "amount": 110, "unit": "g", "kcalPer100": 360}
  ]
}''');
        final repo = _FakeRecipeRepository();
        final usecase = _buildUsecase(repo, file);

        final result = await usecase.importFromPickedFile();

        expect(result!.imported, 1);
        expect(repo.saved.single.totalWeightG, 110);
        expect(
          repo.saved.single.aggregatedNutrimentsPer100.energyKcal100,
          closeTo(360, 1e-9),
        );
      },
    );

    test('returns null when the picker is cancelled', () async {
      final repo = _FakeRecipeRepository();
      final usecase = ImportRecipesJsonUsecase(
        SaveRecipeUseCase(repo, ComputeRecipeNutritionUseCase()),
        pickFile: () async => null,
      );

      final result = await usecase.importFromPickedFile();

      expect(result, isNull);
      expect(repo.saved, isEmpty);
    });

    test('a rejected totalWeight is reported and never reaches save', () async {
      final file = _writeTempJson('''{
  "name": "Zero",
  "totalWeight": 0,
  "ingredients": [
    {"name": "Ingredient", "amount": 110, "unit": "g", "kcalPer100": 360}
  ]
}''');
      final repo = _FakeRecipeRepository();
      final usecase = _buildUsecase(repo, file);

      final result = await usecase.importFromPickedFile();

      expect(result!.imported, 0);
      expect(result.skippedRecipes, 1);
      expect(result.errorMessages.single,
          contains('"totalWeight" must be a positive finite number'));
      expect(repo.saved, isEmpty);
    });
  });
}
