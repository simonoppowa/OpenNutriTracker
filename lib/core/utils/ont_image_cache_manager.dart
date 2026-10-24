import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class OntImageCacheManager {
  static const _cacheDuration = Duration(days: 30);
  static const _maxNrOfCacheObjects = 200;

  static const key = 'imageCacheManager';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: _cacheDuration,
      maxNrOfCacheObjects: _maxNrOfCacheObjects,
      repo: SelfHealingJsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// A [JsonCacheInfoRepository] that deletes its index file when it cannot be
/// parsed, before the plugin reads it.
///
/// The index is rewritten in place (`writeAsString` truncates first), so a
/// process killed mid-save leaves an empty or half-written file. The plugin
/// copes — it catches the `FormatException`, starts with an empty index and
/// overwrites the file on the next save — but it also hands the exception to
/// `FlutterError.reportError`, so every such launch files a crash report for a
/// cache that was already recovering on its own (Sentry OPENNUTRITRACKER-K).
/// Removing the unreadable file first gives the same empty index without the
/// report.
class SelfHealingJsonCacheInfoRepository extends JsonCacheInfoRepository {
  static final _log = Logger('SelfHealingJsonCacheInfoRepository');

  /// Either [path] or [databaseName], as for [JsonCacheInfoRepository].
  SelfHealingJsonCacheInfoRepository({super.path, super.databaseName});

  bool _checked = false;

  @override
  Future<bool> open() async {
    if (!_checked) {
      _checked = true;
      await _discardUnreadableIndex();
    }
    return super.open();
  }

  Future<void> _discardUnreadableIndex() async {
    try {
      final file = File(await _indexPath());
      if (!await file.exists()) return;
      try {
        jsonDecode(await file.readAsString()) as List<dynamic>;
      } on Object catch (error) {
        _log.warning('Discarding the unreadable image cache index: $error');
        await file.delete();
      }
    } on Object catch (error, stackTrace) {
      // Best effort: whatever went wrong, the plugin's own read follows and
      // reports it as it always did.
      _log.warning('Could not check the image cache index', error, stackTrace);
    }
  }

  /// Where the plugin will look, resolved the way it resolves it.
  Future<String> _indexPath() async {
    final explicit = path;
    if (explicit != null && explicit.endsWith('.json')) return explicit;
    final folder =
        directory ??
        (explicit != null
            ? File(explicit).parent
            : await getApplicationSupportDirectory());
    return '${folder.path}${Platform.pathSeparator}$databaseName.json';
  }
}
