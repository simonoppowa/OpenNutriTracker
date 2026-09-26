import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/domain/usecase/save_recipe_usecase.dart';
import 'package:opennutritracker/core/utils/csv_recipe_importer.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart'
    show PickImportFile;

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

Future<PlatformFile?> _pickCsvFile() => FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

/// Picks a CSV file from disk, parses it via [CsvRecipeImporter], and
/// persists each recipe via [SaveRecipeUseCase] (which re-aggregates
/// nutrition so values are consistent with the rest of the recipe flows).
class ImportRecipesCsvUsecase {
  final SaveRecipeUseCase _saveRecipeUseCase;

  /// Seam for tests: `FilePicker.pickFile` is static and needs a platform
  /// channel, so the picker outcomes plus the save-side wiring
  /// (`totalWeightOverridden`, #1194) can only be driven from here.
  final PickImportFile _pickFile;

  ImportRecipesCsvUsecase(
    this._saveRecipeUseCase, {
    PickImportFile pickFile = _pickCsvFile,
  }) : _pickFile = pickFile;

  /// Returns null when the user cancelled the file picker.
  Future<ImportRecipesCsvResult?> importFromPickedFile() async {
    final picked = await _pickFile();
    if (picked == null || picked.path == null) {
      return null;
    }

    final file = File(picked.path!);
    final content = await file.readAsString(encoding: utf8);

    final parseResult = CsvRecipeImporter.parse(content);

    for (final imported in parseResult.recipes) {
      // The CSV importer pre-computes nutrition, but SaveRecipeUseCase
      // recomputes on save anyway — that's intentional, so the same code
      // path runs whether the recipe came from CSV import, the builder,
      // or QR import. `totalWeightOverridden` is threaded through so an
      // explicit `recipe_total_weight_g` survives the recompute instead
      // of collapsing back to the ingredient sum (#1139 / #1194).
      await _saveRecipeUseCase.save(
        imported.recipe,
        totalWeightOverridden: imported.totalWeightOverridden,
      );
    }

    return ImportRecipesCsvResult(
      imported: parseResult.recipes.length,
      skippedRows: parseResult.errors.length,
      errorMessages: parseResult.errors,
    );
  }
}
