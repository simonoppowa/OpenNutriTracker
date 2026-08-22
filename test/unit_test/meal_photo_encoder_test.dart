import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/util/meal_photo_encoder.dart';

/// Only the decisions that need no platform channel. The compression itself
/// runs in the device encoder and is covered by driving the real flow.
void main() {
  group('the container each destination gets (#747)', () {
    test('a server the user runs gets JPEG', () {
      // The one runtime that cannot decode WebP is llama.cpp, whose
      // `stb_image` format list has no entry for it — and the app cannot
      // tell which runtime is behind a user-supplied address. All four
      // decode JPEG, so the incompatibility is removed rather than detected.
      expect(
        MealPhotoFormat.forProvider(AiProvider.ownServer),
        MealPhotoFormat.jpeg,
      );
    });

    test('the hosted three keep WebP', () {
      // Anthropic accepts it natively so nothing transcodes on arrival, and
      // these payloads cross the internet rather than a LAN.
      for (final provider in const [
        AiProvider.anthropic,
        AiProvider.openrouter,
        AiProvider.openai,
      ]) {
        expect(
          MealPhotoFormat.forProvider(provider),
          MealPhotoFormat.webp,
          reason: '$provider must not have moved off WebP',
        );
      }
    });

    test('every provider is answered, so a fifth cannot inherit one', () {
      // The switch is exhaustive in the source; this is the runtime half of
      // the same guarantee, and it fails the moment a member is added
      // without the format question being asked.
      for (final provider in AiProvider.values) {
        expect(
          () => MealPhotoFormat.forProvider(provider),
          returnsNormally,
          reason: '$provider has no format',
        );
      }
    });

    test('each container declares the media type it actually is', () {
      // The declared type is what Ollama's decodeImageURL checks the data URI
      // prefix against, so a mismatch here is a 400 rather than a wrong-looking
      // image.
      expect(MealPhotoFormat.webp.mediaType, 'image/webp');
      expect(MealPhotoFormat.jpeg.mediaType, 'image/jpeg');
      expect(MealPhotoFormat.webp.compress, CompressFormat.webp);
      expect(MealPhotoFormat.jpeg.compress, CompressFormat.jpeg);
    });
  });

  group('mediaTypeForPath', () {
    test('maps the formats the provider accepts', () {
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.webp'), 'image/webp');
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.jpg'), 'image/jpeg');
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.jpeg'), 'image/jpeg');
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.png'), 'image/png');
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.gif'), 'image/gif');
    });

    test('is case-insensitive, because cameras shout', () {
      expect(
        MealPhotoEncoder.mediaTypeForPath('/tmp/IMG_0001.JPG'),
        'image/jpeg',
      );
    });

    test('rejects a format the provider would refuse', () {
      // An iPhone .heic straight off the filesystem. Better to say "try
      // another photo" than to send bytes the API will reject.
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.heic'), isNull);
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/a.bmp'), isNull);
    });

    test('rejects a path with no usable extension', () {
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/photo'), isNull);
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/photo.'), isNull);
      expect(MealPhotoEncoder.mediaTypeForPath(''), isNull);
    });

    test('reads the last dot, not the first', () {
      expect(
        MealPhotoEncoder.mediaTypeForPath('/tmp/my.meal.photo.png'),
        'image/png',
      );
    });

    test('a directory containing a dot does not become the extension', () {
      expect(MealPhotoEncoder.mediaTypeForPath('/tmp/v1.2/photo'), isNull);
    });
  });

  group('encodeAndDiscardSource', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('ont_photo_test');
    });
    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('deletes the source, whichever container was asked for', () async {
      // `image_picker` returns a copy it made in the app cache and never
      // cleans it up — on a Pixel 6 the full JPEG was still there after a
      // pick. Leaving it makes the settings disclosure false, and that is
      // true of a photo headed for the user's own machine too.
      for (final format in MealPhotoFormat.values) {
        final file = File('${dir.path}/picked_${format.name}.jpg')
          ..writeAsBytesSync(List.filled(2000, 0));

        await MealPhotoEncoder.encodeAndDiscardSource(
          file.path,
          format: format,
        );

        expect(file.existsSync(), isFalse, reason: format.name);
      }
    });

    test('an oversized source is rejected without being read', () async {
      // The fallback path exists for a device whose encoder failed, where the
      // file is the camera's raw output. Reading eight megabytes into memory
      // only to discard it is a burst of allocation on the device least able
      // to absorb one, so the length is checked first.
      final file = File('${dir.path}/huge.jpg')
        ..writeAsBytesSync(List.filled(MealPhotoEncoder.maxBytes + 1, 0));

      for (final format in MealPhotoFormat.values) {
        expect(
          await MealPhotoEncoder.encode(file.path, format: format),
          isNull,
          reason: '${format.name} must respect the ceiling too',
        );
      }
    });

    test('the fallback declares the file it sent, not the one asked for', () async {
      // There is no platform channel in a unit test, so the compressor fails
      // and `encode` takes the raw-bytes path — which is the real behaviour
      // on a device whose encoder is missing. What it sends is the original
      // file, so the media type has to describe *that*, not the container
      // that was requested and never produced. Declaring `image/webp` over
      // JPEG bytes is a 400 from Ollama, whose decodeImageURL checks the
      // data-URI prefix.
      final file = File('${dir.path}/original.jpg')
        ..writeAsBytesSync(List.filled(2000, 0));

      final photo = await MealPhotoEncoder.encode(
        file.path,
        format: MealPhotoFormat.webp,
      );

      expect(photo?.mediaType, 'image/jpeg');
    });

    test('a missing source is not an error', () async {
      await expectLater(
        MealPhotoEncoder.encodeAndDiscardSource(
          '${dir.path}/gone.jpg',
          format: MealPhotoFormat.jpeg,
        ),
        completion(isNull),
      );
    });
  });

  test('the size cap leaves room for base64 inside a 5 MB limit', () {
    // base64 inflates by 4/3, so the encoded form of a maximum-size payload
    // has to stay under the provider's per-image limit with room to spare.
    expect(MealPhotoEncoder.maxBytes * 4 / 3, lessThan(5 * 1024 * 1024));
  });
}
