import 'package:flutter/services.dart';
import 'package:opennutritracker/features/scanner/util/nutrition_label_parser.dart';

/// Why the text of a photo could not be read.
enum TextRecognitionFailure { unreadableImage, failed, unavailable }

class TextRecognitionException implements Exception {
  final TextRecognitionFailure failure;

  const TextRecognitionException(this.failure);

  @override
  String toString() => 'TextRecognitionException($failure)';
}

/// Reads the text on a photo, on the device. Behind an interface so the
/// label scan can be tested with a fake.
abstract class TextRecognizer {
  /// The recognized lines of the image at [imagePath]; empty when it holds
  /// no text. Throws a [TextRecognitionException].
  Future<List<OcrLine>> recognize(String imagePath);
}

/// [TextRecognizer] on Apple Vision, through the Runner's
/// `NutritionTextRecognizer` (ios/Runner/NutritionTextRecognizer.swift).
class VisionTextRecognizer implements TextRecognizer {
  static const channel = MethodChannel(
    'dev.theocloud.nutritracker/text_recognition',
  );

  const VisionTextRecognizer();

  @override
  Future<List<OcrLine>> recognize(String imagePath) async {
    final List<Map<Object?, Object?>>? rows;
    try {
      rows = await channel.invokeListMethod<Map<Object?, Object?>>(
        'recognizeText',
        {'path': imagePath},
      );
    } on PlatformException catch (error) {
      throw TextRecognitionException(
        error.code == 'unreadable_image'
            ? TextRecognitionFailure.unreadableImage
            : TextRecognitionFailure.failed,
      );
    } on MissingPluginException {
      throw const TextRecognitionException(TextRecognitionFailure.unavailable);
    }
    return [
      for (final row in rows ?? const <Map<Object?, Object?>>[])
        OcrLine(
          text: row['text'] as String,
          x: (row['x'] as num).toDouble(),
          y: (row['y'] as num).toDouble(),
          width: (row['w'] as num).toDouble(),
          height: (row['h'] as num).toDouble(),
          confidence: (row['confidence'] as num?)?.toDouble() ?? 1,
        ),
    ];
  }
}
