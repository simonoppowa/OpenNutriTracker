import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/json_recipe_importer.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart'
    show PickImportFile;

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

Future<PlatformFile?> _pickJsonFile() => FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

/// Picks a `.json` file from disk, validates the content via
/// [JsonRecipeImporter.parse], and persists each successfully-parsed
/// recipe via [SaveRecipeUseCase] — symmetric with
/// [ImportRecipesCsvUsecase] so the UI can treat both import paths
/// identically.
class ImportRecipesJsonUsecase {
  final SaveRecipeUseCase _saveRecipeUseCase;

  /// Seam for tests: `FilePicker.pickFile` is static and needs a platform
  /// channel, so the picker outcomes plus the save-side wiring (#1139:
  /// `totalWeightOverridden` threading) can only be driven from here.
  final PickImportFile _pickFile;

  ImportRecipesJsonUsecase(
    this._saveRecipeUseCase, {
    PickImportFile pickFile = _pickJsonFile,
  }) : _pickFile = pickFile;

  /// Returns null when the user cancelled the file picker.
  Future<ImportRecipesJsonResult?> importFromPickedFile() async {
    final picked = await _pickFile();
    if (picked == null || picked.path == null) {
      return null;
    }

    final file = File(picked.path!);
    final content = await file.readAsString(encoding: utf8);

    final parseResult = JsonRecipeImporter.parse(content);

    for (final imported in parseResult.recipes) {
      // SaveRecipeUseCase recomputes nutrition on save, matching the CSV
      // and recipe-builder paths so values land identical regardless of
      // entry point. `totalWeightOverridden` is threaded through so an
      // explicit `totalWeight` in the JSON survives the recompute instead
      // of collapsing back to the ingredient sum (#1139).
      await _saveRecipeUseCase.save(
        imported.recipe,
        totalWeightOverridden: imported.totalWeightOverridden,
      );
    }

    return ImportRecipesJsonResult(
      imported: parseResult.recipes.length,
      skippedRecipes: parseResult.errors.length,
      errorMessages: parseResult.errors,
    );
  }
}
