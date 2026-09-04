import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/csv_meal_importer.dart';

class ImportMealsCsvResult {
  final int imported;
  final int skipped;
  final List<String> errorMessages;

  /// True when at least one imported meal had a barcode set. The UI uses
  /// this to nudge the user to contribute the product to Open Food Facts.
  final bool anyImportedHadBarcode;

  const ImportMealsCsvResult({
    required this.imported,
    required this.skipped,
    required this.errorMessages,
    required this.anyImportedHadBarcode,
  });
}

/// Picks a CSV file from disk, parses it via [CsvMealImporter], and saves
/// the successfully-parsed meals into the existing custom-meal box. The
/// caller surfaces the counts via a snackbar / dialog.
class ImportMealsCsvUsecase {
  final CustomMealDataSource _customMealDataSource;

  ImportMealsCsvUsecase(this._customMealDataSource);

  /// Returns null when the user cancelled the file picker.
  Future<ImportMealsCsvResult?> importFromPickedFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.path == null) {
      return null;
    }

    final file = File(picked.path!);
    final content = await file.readAsString(encoding: utf8);

    final parseResult = CsvMealImporter.parse(content);

    for (final meal in parseResult.meals) {
      await _customMealDataSource.saveCustomMeal(MealDBO.fromMealEntity(meal));
    }

    return ImportMealsCsvResult(
      imported: parseResult.meals.length,
      skipped: parseResult.errors.length,
      errorMessages: parseResult.errors,
      anyImportedHadBarcode: parseResult.meals.any(
        (m) => m.code != null && m.code!.isNotEmpty,
      ),
    );
  }
}
