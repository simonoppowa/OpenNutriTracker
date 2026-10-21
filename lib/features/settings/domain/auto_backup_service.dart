import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/settings/data/auto_backup_settings.dart';
import 'package:opennutritracker/features/settings/data/backup_folder.dart';
import 'package:opennutritracker/features/settings/data/webdav_client.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';

/// How a backup attempt ended.
enum AutoBackupOutcome { disabled, notDue, uploaded, failed }

/// Uploads the JSON backup to a WebDAV folder (the user's FileBrowser
/// Quantum, #77) or a folder picked in the Files app (#99) and keeps the
/// newest [AutoBackupSettings.keepCount] there.
///
/// iOS does not run background tasks reliably, so [runIfDue] is called on
/// app start and resume and backs up when the last success is older than
/// the interval. A failure never reaches the caller: it is stored in the
/// settings and shown in the backup screen, and the next start tries again.
class AutoBackupService {
  static final backupFileName = RegExp(
    r'^nutritracker-backup-\d{8}-\d{6}\.zip$',
  );
  static final _stamp = DateFormat('yyyyMMdd-HHmmss');

  final _log = Logger('AutoBackupService');
  final AutoBackupSettingsStore _store;
  final Future<Archive> Function() _assembleBackup;
  final BackupReminder _reminder;
  final http.Client Function() _httpClient;
  final BackupFolder _folder;
  final DateTime Function() _clock;
  Future<AutoBackupOutcome>? _running;

  AutoBackupService(
    this._store,
    this._assembleBackup,
    this._reminder, {
    http.Client Function()? httpClient,
    BackupFolder? folder,
    DateTime Function()? clock,
  }) : _httpClient = httpClient ?? http.Client.new,
       _folder = folder ?? const ChannelBackupFolder(),
       _clock = clock ?? DateTime.now;

  /// Lets the user pick a Files-app folder and makes it the backup target;
  /// its name, or null when they cancelled.
  Future<String?> chooseFolder() async {
    final picked = await _folder.pick();
    if (picked == null) return null;
    await _saveStatus(
      (fresh) => fresh.copyWith(
        target: AutoBackupTarget.folder,
        folderBookmark: picked.bookmark,
        folderName: picked.name,
      ),
    );
    return picked.name;
  }

  _BackupTarget _targetFor(AutoBackupSettings settings) =>
      switch (settings.target) {
        AutoBackupTarget.server => _ServerTarget(
          _httpClient(),
          folder: Uri.parse(settings.folderUrl.trim()),
          token: settings.token,
        ),
        AutoBackupTarget.folder => _FolderTarget(
          _folder,
          settings.folderBookmark ??
              (throw const BackupFolderException('not_found')),
          onRenewed: (bookmark) =>
              _saveStatus((fresh) => fresh.copyWith(folderBookmark: bookmark)),
        ),
      };

  /// Backs up when the automatic backup is on and the last success is at
  /// least the interval old.
  Future<AutoBackupOutcome> runIfDue() async {
    final settings = await _store.load();
    if (!settings.enabled || !settings.isConfigured) {
      return AutoBackupOutcome.disabled;
    }
    final last = settings.lastSuccessAt;
    if (last != null &&
        _clock().difference(last) < Duration(hours: settings.intervalHours)) {
      return AutoBackupOutcome.notDue;
    }
    return runNow();
  }

  /// Backs up right away (the "Back up now" button, or a due [runIfDue]).
  /// Concurrent calls share one upload.
  Future<AutoBackupOutcome> runNow() =>
      _running ??= _upload().whenComplete(() => _running = null);

  Future<AutoBackupOutcome> _upload() async {
    final settings = await _store.load();
    if (!settings.isConfigured) return AutoBackupOutcome.disabled;
    _BackupTarget? target;
    try {
      target = _targetFor(settings);
      final archive = await _assembleBackup();
      final bytes = ZipEncoder(password: settings.password).encode(archive);
      final now = _clock();
      await target.prepare();
      await target.put('nutritracker-backup-${_stamp.format(now)}.zip', bytes);
      await _rotate(target, settings.keepCount);
      await _saveStatus(
        (fresh) => fresh.copyWith(lastSuccessAt: now, clearLastError: true),
      );
      await _reminder.markBackedUp();
      return AutoBackupOutcome.uploaded;
    } catch (error, stackTrace) {
      _log.warning('Automatic backup failed', error, stackTrace);
      await _saveStatus(
        (fresh) =>
            fresh.copyWith(lastErrorAt: _clock(), lastError: describe(error)),
      );
      return AutoBackupOutcome.failed;
    } finally {
      target?.close();
    }
  }

  /// Writes the outcome into the settings as they are now, not as they were
  /// when the upload started, so a change made meanwhile survives.
  Future<void> _saveStatus(
    AutoBackupSettings Function(AutoBackupSettings fresh) update,
  ) async => _store.save(update(await _store.load()));

  Future<void> _rotate(_BackupTarget target, int keepCount) async {
    final backups =
        (await target.list()).where(backupFileName.hasMatch).toList()
          ..sort((a, b) => b.compareTo(a));
    for (final old in backups.skip(keepCount)) {
      await target.delete(old);
    }
  }

  /// Checks that [settings] reach their folder (on the server: one the token
  /// may use, created when missing). Throws on failure.
  Future<void> testConnection(AutoBackupSettings settings) async {
    final target = _targetFor(settings);
    try {
      await target.prepare();
      await target.list();
    } finally {
      target.close();
    }
  }

  /// The backups in the folder, newest first.
  Future<List<String>> listBackups() async {
    final target = _targetFor(await _store.load());
    try {
      return (await target.list()).where(backupFileName.hasMatch).toList()
        ..sort((a, b) => b.compareTo(a));
    } finally {
      target.close();
    }
  }

  /// Downloads and opens backup [name], with the stored password.
  Future<Archive> download(String name) async {
    final settings = await _store.load();
    final target = _targetFor(settings);
    try {
      final bytes = await target.get(name);
      return ZipDecoder().decodeBytes(bytes, password: settings.password);
    } finally {
      target.close();
    }
  }

  /// A short, secret-free text for the backup screen.
  static String describe(Object error) {
    if (error is BackupFolderException) return 'folder ${error.code}';
    if (error is WebDavException) {
      return error.isUnauthorized
          ? 'unauthorized'
          : 'server error ${error.statusCode}';
    }
    if (error is ArgumentError) return 'invalid address';
    return 'unreachable';
  }
}

/// Where a backup is written: the WebDAV server or a picked folder.
abstract class _BackupTarget {
  Future<void> prepare();
  Future<List<String>> list();
  Future<void> put(String name, List<int> bytes);
  Future<List<int>> get(String name);
  Future<void> delete(String name);
  void close();
}

class _ServerTarget implements _BackupTarget {
  final http.Client _client;
  final WebDavClient _webDav;

  _ServerTarget(this._client, {required Uri folder, required String token})
    : _webDav = WebDavClient(_client, folder: folder, token: token);

  @override
  Future<void> prepare() => _webDav.ensureFolder();

  @override
  Future<List<String>> list() => _webDav.list();

  @override
  Future<void> put(String name, List<int> bytes) => _webDav.put(name, bytes);

  @override
  Future<List<int>> get(String name) => _webDav.get(name);

  @override
  Future<void> delete(String name) => _webDav.delete(name);

  @override
  void close() => _client.close();
}

/// A picked folder; keeps using a bookmark iOS renewed and reports it to
/// [onRenewed] so it is stored for the next time.
class _FolderTarget implements _BackupTarget {
  final BackupFolder _folder;
  String _bookmark;
  final Future<void> Function(String bookmark) _onRenewed;

  _FolderTarget(
    this._folder,
    this._bookmark, {
    required Future<void> Function(String bookmark) onRenewed,
  }) : _onRenewed = onRenewed;

  Future<void> _keep(String? renewed) async {
    if (renewed == null || renewed == _bookmark) return;
    _bookmark = renewed;
    await _onRenewed(renewed);
  }

  @override
  Future<void> prepare() async {}

  @override
  Future<List<String>> list() async {
    final result = await _folder.list(_bookmark);
    await _keep(result.bookmark);
    return result.names;
  }

  @override
  Future<void> put(String name, List<int> bytes) async =>
      _keep(await _folder.write(_bookmark, name, bytes));

  @override
  Future<List<int>> get(String name) async {
    final result = await _folder.read(_bookmark, name);
    await _keep(result.bookmark);
    return result.bytes;
  }

  @override
  Future<void> delete(String name) async =>
      _keep(await _folder.delete(_bookmark, name));

  @override
  void close() {}
}
