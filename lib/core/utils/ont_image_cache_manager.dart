import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class OntImageCacheManager {
  static const _cacheDuration = Duration(days: 30);
  static const _maxNrOfCacheObjects = 200;

  static const key = 'imageCacheManager';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: _cacheDuration,
      maxNrOfCacheObjects: _maxNrOfCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
