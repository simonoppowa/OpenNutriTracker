import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/csv_recipe_importer.dart';

class ImportRecipesCsvResult {
  final int imported;
  final int skippedRows;
  final List<String> errorMessages;

  const ImportRecipesCsvResult({
    required this.imported,
    required this.skippedRows,
    required this.errorMessages,
  });
}

/// Picks a CSV file from disk, parses it via [CsvRecipeImporter], and
/// persists each recipe via [SaveRecipeUseCase] (which re-aggregates
/// nutrition so values are consistent with the rest of the recipe flows).
class ImportRecipesCsvUsecase {
  final SaveRecipeUseCase _saveRecipeUseCase;

  ImportRecipesCsvUsecase(this._saveRecipeUseCase);

  /// Returns null when the user cancelled the file picker.
  Future<ImportRecipesCsvResult?> importFromPickedFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.path == null) {
      return null;
    }

    final file = File(picked.path!);
    final content = await file.readAsString(encoding: utf8);

    final parseResult = CsvRecipeImporter.parse(content);

    for (final recipe in parseResult.recipes) {
      // The CSV importer pre-computes nutrition, but SaveRecipeUseCase
      // recomputes on save anyway — that's intentional, so the same code
      // path runs whether the recipe came from CSV import, the builder,
      // or QR import.
      await _saveRecipeUseCase.save(recipe);
    }

    return ImportRecipesCsvResult(
      imported: parseResult.recipes.length,
      skippedRows: parseResult.errors.length,
      errorMessages: parseResult.errors,
    );
  }
}
