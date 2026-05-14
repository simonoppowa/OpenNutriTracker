import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/utils/json_meal_importer.dart';
import 'package:opennutritracker/core/utils/json_recipe_importer.dart';

/// Saves the bundled JSON samples (meals or recipes) to a user-chosen
/// location. Mirrors [DownloadSampleCsvUsecase] which holds both the
/// meals and recipes CSV samples in a single class for the same reason.
class DownloadSampleJsonUsecase {
  static const mealsSampleFileName = 'opennutritracker-meals-sample.json';
  static const recipesSampleFileName = 'opennutritracker-recipes-sample.json';

  /// Writes [JsonMealImporter.sampleJson] to a user-chosen path.
  /// Returns true when the save was confirmed, false when the user cancelled.
  Future<bool> downloadSample() async {
    return _saveJson(JsonMealImporter.sampleJson(), mealsSampleFileName);
  }

  /// Writes [JsonRecipeImporter.sampleJson] to a user-chosen path.
  Future<bool> downloadRecipeSample() async {
    return _saveJson(JsonRecipeImporter.sampleJson(), recipesSampleFileName);
  }

  Future<bool> _saveJson(String content, String fileName) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final result = await FilePicker.saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return result != null && result.isNotEmpty;
  }
}
