import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/json_recipe_importer.dart';

class ImportRecipesJsonResult {
  final int imported;
  final int skippedRecipes;
  final List<String> errorMessages;

  const ImportRecipesJsonResult({
    required this.imported,
    required this.skippedRecipes,
    required this.errorMessages,
  });
}

/// Picks a `.json` file from disk, validates the content via
/// [JsonRecipeImporter.parse], and persists each successfully-parsed
/// recipe via [SaveRecipeUseCase] — symmetric with
/// [ImportRecipesCsvUsecase] so the UI can treat both import paths
/// identically.
class ImportRecipesJsonUsecase {
  final SaveRecipeUseCase _saveRecipeUseCase;

  ImportRecipesJsonUsecase(this._saveRecipeUseCase);

  /// Returns null when the user cancelled the file picker.
  Future<ImportRecipesJsonResult?> importFromPickedFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null || picked.files.single.path == null) {
      return null;
    }

    final file = File(picked.files.single.path!);
    final content = await file.readAsString(encoding: utf8);

    final parseResult = JsonRecipeImporter.parse(content);

    for (final recipe in parseResult.recipes) {
      // SaveRecipeUseCase recomputes nutrition on save, matching the CSV
      // and recipe-builder paths so values land identical regardless of
      // entry point.
      await _saveRecipeUseCase.save(recipe);
    }

    return ImportRecipesJsonResult(
      imported: parseResult.recipes.length,
      skippedRecipes: parseResult.errors.length,
      errorMessages: parseResult.errors,
    );
  }
}
