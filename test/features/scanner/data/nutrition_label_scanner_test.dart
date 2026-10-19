import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/features/scanner/data/nutrition_label_scanner.dart';
import 'package:opennutritracker/features/scanner/data/text_recognizer.dart';
import 'package:opennutritracker/features/scanner/util/nutrition_label_parser.dart';

class _FakeRecognizer implements TextRecognizer {
  final List<OcrLine> lines;
  final TextRecognitionException? error;
  String? seenPath;

  _FakeRecognizer(this.lines, {this.error});

  @override
  Future<List<OcrLine>> recognize(String imagePath) async {
    seenPath = imagePath;
    if (error != null) throw error!;
    return lines;
  }
}

OcrLine _line(String text, double y, {double x = 0.1}) =>
    OcrLine(text: text, x: x, y: y, width: 0.3, height: 0.04);

void main() {
  late Directory dir;
  late File photo;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('label_scan');
    photo = File('${dir.path}/label.jpg')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('reads the photo and deletes it afterwards', () async {
    final recognizer = _FakeRecognizer([
      _line('Brennwert 1046 kJ / 250 kcal', 0.1),
      _line('Fett 9,5 g', 0.2),
    ]);
    ImageSource? asked;
    final scanner = NutritionLabelScanner(
      recognizer,
      pickImage: (source) async {
        asked = source;
        return photo.path;
      },
    );

    final values = await scanner.scan(ImageSource.camera);

    expect(asked, ImageSource.camera);
    expect(recognizer.seenPath, photo.path);
    expect(values!.energyKcal, 250);
    expect(values.fat, 9.5);
    expect(photo.existsSync(), isFalse);
  });

  test('a cancelled picker gives nothing and recognizes nothing', () async {
    final recognizer = _FakeRecognizer(const []);
    final scanner = NutritionLabelScanner(
      recognizer,
      pickImage: (_) async => null,
    );

    expect(await scanner.scan(ImageSource.gallery), isNull);
    expect(recognizer.seenPath, isNull);
  });

  test('a photo without a nutrition table gives empty values', () async {
    final scanner = NutritionLabelScanner(
      _FakeRecognizer([_line('Zutaten: Wasser, Zucker', 0.1)]),
      pickImage: (_) async => photo.path,
    );

    final values = await scanner.scan(ImageSource.camera);

    expect(values!.isEmpty, isTrue);
    expect(photo.existsSync(), isFalse);
  });

  test('a failed recognition still deletes the photo', () async {
    final scanner = NutritionLabelScanner(
      _FakeRecognizer(
        const [],
        error: const TextRecognitionException(
          TextRecognitionFailure.unreadableImage,
        ),
      ),
      pickImage: (_) async => photo.path,
    );

    await expectLater(
      scanner.scan(ImageSource.camera),
      throwsA(isA<TextRecognitionException>()),
    );
    expect(photo.existsSync(), isFalse);
  });
}
