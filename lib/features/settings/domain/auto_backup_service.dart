import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/settings/data/auto_backup_settings.dart';
import 'package:opennutritracker/features/settings/data/webdav_client.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';

/// How a backup attempt ended.
enum AutoBackupOutcome { disabled, notDue, uploaded, failed }

/// Uploads the JSON backup to a WebDAV folder (the user's FileBrowser
/// Quantum) and keeps the newest [AutoBackupSettings.keepCount] there.
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
  final DateTime Function() _clock;
  Future<AutoBackupOutcome>? _running;

  AutoBackupService(
    this._store,
    this._assembleBackup,
    this._reminder, {
    http.Client Function()? httpClient,
    DateTime Function()? clock,
  }) : _httpClient = httpClient ?? http.Client.new,
       _clock = clock ?? DateTime.now;

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
    final client = _httpClient();
    try {
      final webDav = _webDav(client, settings);
      final archive = await _assembleBackup();
      final bytes = ZipEncoder(password: settings.password).encode(archive);
      final now = _clock();
      await webDav.ensureFolder();
      await webDav.put('nutritracker-backup-${_stamp.format(now)}.zip', bytes);
      await _rotate(webDav, settings.keepCount);
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
      client.close();
    }
  }

  /// Writes the outcome into the settings as they are now, not as they were
  /// when the upload started, so a change made meanwhile survives.
  Future<void> _saveStatus(
    AutoBackupSettings Function(AutoBackupSettings fresh) update,
  ) async => _store.save(update(await _store.load()));

  Future<void> _rotate(WebDavClient webDav, int keepCount) async {
    final backups =
        (await webDav.list()).where(backupFileName.hasMatch).toList()
          ..sort((a, b) => b.compareTo(a));
    for (final old in backups.skip(keepCount)) {
      await webDav.delete(old);
    }
  }

  /// Checks that [settings] reach a folder the token may use, creating the
  /// folder when it is missing. Throws on failure.
  Future<void> testConnection(AutoBackupSettings settings) async {
    final client = _httpClient();
    try {
      final webDav = _webDav(client, settings);
      await webDav.ensureFolder();
      await webDav.list();
    } finally {
      client.close();
    }
  }

  /// The backups in the folder, newest first.
  Future<List<String>> listBackups() async {
    final settings = await _store.load();
    final client = _httpClient();
    try {
      return (await _webDav(
          client,
          settings,
        ).list()).where(backupFileName.hasMatch).toList()
        ..sort((a, b) => b.compareTo(a));
    } finally {
      client.close();
    }
  }

  /// Downloads and opens backup [name], with the stored password.
  Future<Archive> download(String name) async {
    final settings = await _store.load();
    final client = _httpClient();
    try {
      final bytes = await _webDav(client, settings).get(name);
      return ZipDecoder().decodeBytes(bytes, password: settings.password);
    } finally {
      client.close();
    }
  }

  static WebDavClient _webDav(
    http.Client client,
    AutoBackupSettings settings,
  ) => WebDavClient(
    client,
    folder: Uri.parse(settings.folderUrl.trim()),
    token: settings.token,
  );

  /// A short, secret-free text for the backup screen.
  static String describe(Object error) {
    if (error is WebDavException) {
      return error.isUnauthorized
          ? 'unauthorized'
          : 'server error ${error.statusCode}';
    }
    if (error is ArgumentError) return 'invalid address';
    return 'unreachable';
  }
}
