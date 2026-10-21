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

/// The photo of a scanned nutrition table, kept for an optional upload to
/// Open Food Facts (#112). Whoever holds it deletes it when done.
class LabelPhoto {
  final String fileName;
  final Future<List<int>> Function() read;
  final Future<void> Function() delete;

  const LabelPhoto({
    required this.fileName,
    required this.read,
    required this.delete,
  });
}

/// The values read from a nutrition table and, when there were any, the
/// photo they came from.
class LabelScan {
  final NutritionLabelValues values;
  final LabelPhoto? photo;

  const LabelScan(this.values, this.photo);
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

  /// Like [scan], but a photo that gave values is not deleted: it comes back
  /// as [LabelScan.photo] for the caller to upload and delete. A photo
  /// without values or a failed recognition is deleted right away.
  Future<LabelScan?> scanKeepingPhoto(ImageSource source) async {
    final path = await _pickImage(source);
    if (path == null) return null;
    final NutritionLabelValues values;
    try {
      values = parseNutritionLabel(await _recognizer.recognize(path));
    } catch (_) {
      await _deletePhoto(path);
      rethrow;
    }
    if (values.isEmpty) {
      await _deletePhoto(path);
      return LabelScan(values, null);
    }
    return LabelScan(
      values,
      LabelPhoto(
        fileName: path.split(Platform.pathSeparator).last,
        read: () => File(path).readAsBytes(),
        delete: () => _deletePhoto(path),
      ),
    );
  }

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
