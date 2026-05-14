import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/utils/json_meal_importer.dart';

/// Saves the bundled JSON-paste sample to a user-chosen location, mirroring
/// [DownloadSampleCsvUsecase] for the JSON import flow added in #181.
class DownloadSampleJsonUsecase {
  static const sampleFileName = 'opennutritracker-meals-sample.json';

  /// Writes [JsonMealImporter.sampleJson] to a user-chosen path. Returns
  /// true when the save was confirmed, false when the user cancelled.
  Future<bool> downloadSample() async {
    final bytes = Uint8List.fromList(utf8.encode(JsonMealImporter.sampleJson()));
    final result = await FilePicker.saveFile(
      fileName: sampleFileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return result != null && result.isNotEmpty;
  }
}
