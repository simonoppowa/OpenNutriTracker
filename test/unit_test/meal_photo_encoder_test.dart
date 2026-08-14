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

  test('the size cap leaves room for base64 inside a 5 MB limit', () {
    // base64 inflates by 4/3, so the encoded form of a maximum-size payload
    // has to stay under the provider's per-image limit with room to spare.
    expect(MealPhotoEncoder.maxBytes * 4 / 3, lessThan(5 * 1024 * 1024));
  });
}
