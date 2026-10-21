import 'package:flutter/services.dart';

/// Why a picked backup folder could not be used, as a short code:
/// `unavailable` (no native side, e.g. not on iOS), `access_denied`,
/// `not_found` or `io`.
class BackupFolderException implements Exception {
  final String code;

  const BackupFolderException(this.code);

  @override
  String toString() => 'BackupFolderException($code)';
}

/// A folder the user picked in the Files app (iCloud Drive, another app's
/// folder, a file provider) as the target of the automatic backup (#99). It
/// is reached through a security-scoped bookmark; every call may hand back
/// a renewed bookmark when iOS reports the stored one as stale, which the
/// caller keeps instead. Throws a [BackupFolderException].
abstract class BackupFolder {
  /// Lets the user pick a folder; null when they cancelled.
  Future<({String bookmark, String name})?> pick();

  Future<({List<String> names, String? bookmark})> list(String bookmark);

  Future<String?> write(String bookmark, String name, List<int> bytes);

  Future<({List<int> bytes, String? bookmark})> read(
    String bookmark,
    String name,
  );

  Future<String?> delete(String bookmark, String name);
}

/// [BackupFolder] on the Runner's `BackupFolderAccess`
/// (ios/Runner/BackupFolderAccess.swift).
class ChannelBackupFolder implements BackupFolder {
  static const channel = MethodChannel(
    'dev.theocloud.nutritracker/backup_folder',
  );

  const ChannelBackupFolder();

  Future<Map<Object?, Object?>?> _call(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      return await channel.invokeMapMethod<Object?, Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw BackupFolderException(error.code);
    } on MissingPluginException {
      throw const BackupFolderException('unavailable');
    }
  }

  @override
  Future<({String bookmark, String name})?> pick() async {
    final result = await _call('pick', const {});
    if (result == null) return null;
    return (
      bookmark: result['bookmark'] as String,
      name: result['name'] as String,
    );
  }

  @override
  Future<({List<String> names, String? bookmark})> list(String bookmark) async {
    final result = await _call('list', {'bookmark': bookmark});
    return (
      names: [
        for (final name in result?['names'] as List? ?? []) name as String,
      ],
      bookmark: result?['bookmark'] as String?,
    );
  }

  @override
  Future<String?> write(String bookmark, String name, List<int> bytes) async =>
      (await _call('write', {
            'bookmark': bookmark,
            'name': name,
            'bytes': Uint8List.fromList(bytes),
          }))?['bookmark']
          as String?;

  @override
  Future<({List<int> bytes, String? bookmark})> read(
    String bookmark,
    String name,
  ) async {
    final result = await _call('read', {'bookmark': bookmark, 'name': name});
    return (
      bytes: result?['bytes'] as Uint8List? ?? Uint8List(0),
      bookmark: result?['bookmark'] as String?,
    );
  }

  @override
  Future<String?> delete(String bookmark, String name) async =>
      (await _call('delete', {'bookmark': bookmark, 'name': name}))?['bookmark']
          as String?;
}
