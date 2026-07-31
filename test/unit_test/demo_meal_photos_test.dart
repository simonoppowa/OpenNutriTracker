import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/demo/demo_content.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Points both the documents and temp directories at a per-test temp dir,
/// the way `user_image_storage_test.dart` does — `buildDemoFoods` needs
/// both, since it stages each bundled asset in temp before importing it
/// into the documents-backed image store.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ont_demo_photo_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('demo meal photos', () {
    test('every food resolves to a bundled photo and never a remote URL',
        () async {
      final foods = await buildDemoFoods();
      final all = <(String, dynamic)>[
        ('oatmeal', foods.oatmeal),
        ('brownRice', foods.brownRice),
        ('wholegrainBread', foods.wholegrainBread),
        ('chickenBreast', foods.chickenBreast),
        ('greekYogurt', foods.greekYogurt),
        ('salmon', foods.salmon),
        ('oliveOil', foods.oliveOil),
        ('almonds', foods.almonds),
        ('banana', foods.banana),
        ('apple', foods.apple),
        ('broccoli', foods.broccoli),
      ];

      for (final (label, meal) in all) {
        // The whole point of bundling: a seeded demo meal must never carry
        // a CDN URL, because CachedNetworkImage would fetch it at render
        // time and put Unsplash back on the list of hosts the app talks to.
        expect(meal.thumbnailImageUrl, isNull,
            reason: '$label must not hotlink a thumbnail');
        expect(meal.mainImageUrl, isNull,
            reason: '$label must not hotlink a main image');

        expect(meal.localImagePath, isNotNull,
            reason: '$label lost its bundled photo — check that its photoId '
                'has a matching file in assets/demo/meals/');

        final absolute =
            await UserImageStorage.absolutePath(meal.localImagePath as String);
        expect(File(absolute).existsSync(), isTrue,
            reason: '$label points at $absolute, which was never written');
      }
    });
  });
}
