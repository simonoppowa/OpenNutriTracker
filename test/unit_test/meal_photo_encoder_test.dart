import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/util/meal_photo_encoder.dart';

/// Only the decisions that need no platform channel. The compression itself
/// runs in the device encoder and is covered by driving the real flow.
void main() {
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

    test('deletes the source even though encoding fails in a unit test', () async {
      // `image_picker` returns a copy it made in the app cache and never
      // cleans it up — on a Pixel 6 the full JPEG was still there after a
      // pick. Leaving it makes the settings disclosure false.
      final file = File('${dir.path}/picked.jpg')
        ..writeAsBytesSync(List.filled(2000, 0));

      // No platform channel here, so the encode itself returns null. The
      // point is that the file goes regardless.
      await MealPhotoEncoder.encodeAndDiscardSource(file.path);

      expect(file.existsSync(), isFalse);
    });

    test('an oversized source is rejected without being read', () async {
      // The fallback path exists for devices with no WebP encoder, where the
      // file is the camera's raw output. Reading eight megabytes into memory
      // only to discard it is a burst of allocation on the device least able
      // to absorb one, so the length is checked first.
      final file = File('${dir.path}/huge.jpg')
        ..writeAsBytesSync(List.filled(MealPhotoEncoder.maxBytes + 1, 0));

      expect(await MealPhotoEncoder.encode(file.path), isNull);
    });

    test('a missing source is not an error', () async {
      await expectLater(
        MealPhotoEncoder.encodeAndDiscardSource('${dir.path}/gone.jpg'),
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
