import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stub for `getApplicationDocumentsDirectory` that points at a temp dir we
/// create per-test. Keeps the round-trip honest about the filesystem layout
/// without poisoning the developer's real documents directory.
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ont_user_img_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('UserImageStorage', () {
    test('relativePathFor builds a slug under the right subdir with .webp',
        () {
      expect(
        UserImageStorage.relativePathFor(UserImageKind.recipe, 'abc'),
        'recipe_images/abc.webp',
      );
      expect(
        UserImageStorage.relativePathFor(UserImageKind.meal, 'abc'),
        'meal_images/abc.webp',
      );
    });

    test('sanitizeRelative accepts canonical forms for both kinds', () {
      expect(UserImageStorage.sanitizeRelative('recipe_images/x.webp'),
          'recipe_images/x.webp');
      expect(UserImageStorage.sanitizeRelative('meal_images/x.webp'),
          'meal_images/x.webp');
    });

    test('sanitizeRelative rejects malformed and out-of-tree paths', () {
      // Traversal attempts and unknown subdirectories must not slip
      // through — the entire point of the sanitiser is to keep
      // imported zips from escaping the images directory via `..` or
      // absolute prefixes.
      expect(UserImageStorage.sanitizeRelative('recipe_images/../x.webp'),
          isNull);
      expect(UserImageStorage.sanitizeRelative('elsewhere/x.webp'), isNull);
      expect(UserImageStorage.sanitizeRelative('x.webp'), isNull);
      expect(UserImageStorage.sanitizeRelative('recipe_images/'), isNull);
      expect(UserImageStorage.sanitizeRelative('meal_images/'), isNull);
    });

    test('absolutePath composes against the documents directory', () async {
      final abs =
          await UserImageStorage.absolutePath('recipe_images/r1.webp');
      expect(abs, '${tempRoot.path}/recipe_images/r1.webp');
      final absMeal =
          await UserImageStorage.absolutePath('meal_images/m1.webp');
      expect(absMeal, '${tempRoot.path}/meal_images/m1.webp');
    });

    test(
        'importFrom writes a .webp file into the right images dir and '
        'returns the persisted relative slug', () async {
      // Use a non-image payload — the WebP encoder will reject it and
      // the storage layer falls back to copying the bytes verbatim,
      // which is exactly the behaviour we want to exercise in a
      // host-platform test where there's no real image codec available.
      final source = File('${tempRoot.path}/incoming.bin');
      await source.writeAsBytes([1, 2, 3, 4]);

      final relative = await UserImageStorage.importFrom(
        kind: UserImageKind.recipe,
        ownerId: 'recipe-42',
        sourcePath: source.path,
      );

      expect(relative, 'recipe_images/recipe-42.webp');
      final absolute = await UserImageStorage.absolutePath(relative);
      final destBytes = await File(absolute).readAsBytes();
      expect(destBytes, [1, 2, 3, 4]);
      expect(await source.exists(), isTrue);

      final mealRelative = await UserImageStorage.importFrom(
        kind: UserImageKind.meal,
        ownerId: 'meal-1',
        sourcePath: source.path,
      );
      expect(mealRelative, 'meal_images/meal-1.webp');
    });

    test(
        'delete removes the file at the relative slug and tolerates a '
        'missing file', () async {
      final source = File('${tempRoot.path}/incoming.bin');
      await source.writeAsBytes([9, 9, 9]);
      final relative = await UserImageStorage.importFrom(
        kind: UserImageKind.recipe,
        ownerId: 'r',
        sourcePath: source.path,
      );

      await UserImageStorage.delete(relative);
      final absolute = await UserImageStorage.absolutePath(relative);
      expect(await File(absolute).exists(), isFalse);

      // Second delete is a no-op — callers shouldn't have to guard
      // against a stale path that has already been cleaned up.
      await UserImageStorage.delete(relative);
    });

    test('delete refuses to follow malformed paths', () async {
      // Traversal attempts should be ignored rather than throwing or
      // touching anything outside the known images directories.
      await UserImageStorage.delete('../etc/passwd');
      await UserImageStorage.delete('recipe_images/../foo.webp');
      await UserImageStorage.delete('meal_images/../foo.webp');
      // Reaching this point without an exception is the assertion.
    });

    test('full round-trip: store, resolve, delete', () async {
      final source = File('${tempRoot.path}/round-trip.bin');
      await source.writeAsBytes([42]);

      final relative = await UserImageStorage.importFrom(
        kind: UserImageKind.meal,
        ownerId: 'round-trip-id',
        sourcePath: source.path,
      );

      // The path stored on the DBO is intentionally relative so that
      // an app reinstall (which would shift the documents-dir prefix
      // on iOS) can still resolve it against the new prefix.
      expect(relative.startsWith('meal_images/'), isTrue);
      expect(relative.endsWith('.webp'), isTrue);
      expect(relative.contains(tempRoot.path), isFalse);

      final absolute = await UserImageStorage.absolutePath(relative);
      expect(await File(absolute).exists(), isTrue);

      await UserImageStorage.delete(relative);
      expect(await File(absolute).exists(), isFalse);
    });
  });
}
