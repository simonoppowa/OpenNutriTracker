import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/features/scanner/data/text_recognizer.dart';
import 'package:opennutritracker/features/scanner/util/nutrition_label_parser.dart';

Future<String?> _pickWithImagePicker(ImageSource source) async =>
    (await ImagePicker().pickImage(source: source))?.path;

/// Deletes the photo; one that cannot be deleted stays in the app's
/// temporary folder, which iOS empties on its own.
Future<void> _deleteFile(String path) async {
  try {
    final photo = File(path);
    if (await photo.exists()) await photo.delete();
  } on FileSystemException {
    return;
  }
}

/// Photo of a nutrition table to values: takes or picks the photo, reads
/// its text on the device ([TextRecognizer]) and parses it
/// ([parseNutritionLabel]). The photo is only needed for that and is deleted
/// right after, whatever the outcome.
class NutritionLabelScanner {
  final TextRecognizer _recognizer;
  final Future<String?> Function(ImageSource source) _pickImage;
  final Future<void> Function(String path) _deletePhoto;

  NutritionLabelScanner(
    this._recognizer, {
    Future<String?> Function(ImageSource source)? pickImage,
    Future<void> Function(String path)? deletePhoto,
  }) : _pickImage = pickImage ?? _pickWithImagePicker,
       _deletePhoto = deletePhoto ?? _deleteFile;

  /// The values on the photographed table, empty when none were found;
  /// null when the user took no photo. Throws a [TextRecognitionException].
  Future<NutritionLabelValues?> scan(ImageSource source) async {
    final path = await _pickImage(source);
    if (path == null) return null;
    try {
      return parseNutritionLabel(await _recognizer.recognize(path));
    } finally {
      await _deletePhoto(path);
    }
  }
}
