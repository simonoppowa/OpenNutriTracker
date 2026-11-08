import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ont_image_cache_manager.dart';

/// The image cache's JSON index is rewritten in place, so a process killed
/// mid-save leaves an empty or truncated file. The plugin recovers from that
/// by itself but reports the parse error as a crash; these pin that the app's
/// repository removes the file first, and leaves a good one alone.
void main() {
  late Directory directory;
  late File indexFile;
  late List<FlutterErrorDetails> reported;
  late FlutterExceptionHandler? originalOnError;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ont_image_cache_test');
    indexFile = File('${directory.path}/imageCacheManager.json');
    reported = [];
    originalOnError = FlutterError.onError;
    FlutterError.onError = reported.add;
  });

  tearDown(() async {
    FlutterError.onError = originalOnError;
    await directory.delete(recursive: true);
  });

  test('the stock repository reports an empty index, which is the noise '
      'this guards against', () async {
    await indexFile.writeAsString('');

    await JsonCacheInfoRepository(path: indexFile.path).open();

    expect(reported, hasLength(1));
    expect(reported.single.exception, isA<FormatException>());
  });

  test('an empty index is discarded without a report', () async {
    await indexFile.writeAsString('');
    final repo = SelfHealingJsonCacheInfoRepository(path: indexFile.path);

    expect(await repo.open(), isTrue);

    expect(reported, isEmpty);
    expect(await indexFile.exists(), isFalse);
    expect(await repo.getAllObjects(), isEmpty);
  });

  test('a truncated index is discarded without a report', () async {
    await indexFile.writeAsString('[{"id":1,"url":"https://example.com/a.jp');
    final repo = SelfHealingJsonCacheInfoRepository(path: indexFile.path);

    await repo.open();

    expect(reported, isEmpty);
    expect(await indexFile.exists(), isFalse);
  });

  test('the repository still caches after recovering', () async {
    await indexFile.writeAsString('');
    final repo = SelfHealingJsonCacheInfoRepository(path: indexFile.path);
    await repo.open();

    final inserted = await repo.insert(
      CacheObject(
        'https://example.com/a.jpg',
        key: 'a',
        relativePath: 'a.jpg',
        validTill: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await repo.close();

    expect(inserted.id, isNotNull);
    expect((await repo.get('a'))?.relativePath, 'a.jpg');
    expect(await indexFile.readAsString(), contains('a.jpg'));
    expect(reported, isEmpty);
  });

  test('a readable index is left alone and its entries are kept', () async {
    final writer = JsonCacheInfoRepository(path: indexFile.path);
    await writer.open();
    await writer.insert(
      CacheObject(
        'https://example.com/b.jpg',
        key: 'b',
        relativePath: 'b.jpg',
        validTill: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    await writer.close();

    final repo = SelfHealingJsonCacheInfoRepository(path: indexFile.path);
    await repo.open();

    expect(reported, isEmpty);
    expect(await indexFile.exists(), isTrue);
    expect((await repo.get('b'))?.relativePath, 'b.jpg');
  });

  test('a missing index is not an error', () async {
    final repo = SelfHealingJsonCacheInfoRepository(path: indexFile.path);

    expect(await repo.open(), isTrue);
    expect(reported, isEmpty);
  });
}
