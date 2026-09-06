import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/utils/csv_meal_importer.dart';
import 'package:opennutritracker/core/utils/csv_recipe_importer.dart';

class DownloadSampleCsvUsecase {
  static const mealsSampleFileName = 'opennutritracker-meals-sample.csv';
  static const recipesSampleFileName = 'opennutritracker-recipes-sample.csv';

  /// Writes the bundled custom-meal sample CSV to a user-chosen location.
  /// Returns true when the save was confirmed, false when the user cancelled.
  Future<bool> downloadSample() async {
    return _saveCsv(CsvMealImporter.sampleCsv(), mealsSampleFileName);
  }

  /// Writes the bundled recipe sample CSV (denormalized one-row-per-
  /// ingredient) to a user-chosen location.
  Future<bool> downloadRecipeSample() async {
    return _saveCsv(CsvRecipeImporter.sampleCsv(), recipesSampleFileName);
  }

  Future<bool> _saveCsv(String csvString, String fileName) async {
    final bytes = Uint8List.fromList(utf8.encode(csvString));
    final result = await FilePicker.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );
    return result != null;
  }
}
