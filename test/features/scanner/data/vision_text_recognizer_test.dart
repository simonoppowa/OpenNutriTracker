import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/scanner/data/text_recognizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const recognizer = VisionTextRecognizer();
  MethodCall? lastCall;

  void answer(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(VisionTextRecognizer.channel, (call) {
      lastCall = call;
      return handler(call);
    });
  }

  tearDown(
    () =>
        messenger.setMockMethodCallHandler(VisionTextRecognizer.channel, null),
  );

  test('sends the image path and maps the recognized lines', () async {
    answer(
      (_) async => [
        {
          'text': 'Fett',
          'x': 0.08,
          'y': 0.31,
          'w': 0.1,
          'h': 0.03,
          'confidence': 0.98,
        },
      ],
    );

    final lines = await recognizer.recognize('/tmp/label.jpg');

    expect(lastCall!.method, 'recognizeText');
    expect(lastCall!.arguments, {'path': '/tmp/label.jpg'});
    expect(lines.single.text, 'Fett');
    expect(lines.single.y, 0.31);
    expect(lines.single.confidence, 0.98);
  });

  test('a photo without text gives no lines', () async {
    answer((_) async => <Object?>[]);

    expect(await recognizer.recognize('/tmp/blank.jpg'), isEmpty);
  });

  test('an unreadable photo is reported as such', () async {
    answer((_) async => throw PlatformException(code: 'unreadable_image'));

    await expectLater(
      recognizer.recognize('/tmp/broken.jpg'),
      throwsA(
        isA<TextRecognitionException>().having(
          (e) => e.failure,
          'failure',
          TextRecognitionFailure.unreadableImage,
        ),
      ),
    );
  });

  test('a failing recognizer is reported as failed', () async {
    answer((_) async => throw PlatformException(code: 'recognition_failed'));

    await expectLater(
      recognizer.recognize('/tmp/x.jpg'),
      throwsA(
        isA<TextRecognitionException>().having(
          (e) => e.failure,
          'failure',
          TextRecognitionFailure.failed,
        ),
      ),
    );
  });

  test('a platform without the handler is reported as unavailable', () async {
    await expectLater(
      recognizer.recognize('/tmp/x.jpg'),
      throwsA(
        isA<TextRecognitionException>().having(
          (e) => e.failure,
          'failure',
          TextRecognitionFailure.unavailable,
        ),
      ),
    );
  });
}
