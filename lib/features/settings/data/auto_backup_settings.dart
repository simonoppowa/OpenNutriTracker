import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the automatic backup goes: the WebDAV server (#77) or a folder
/// picked in the Files app (#99).
enum AutoBackupTarget { server, folder }

/// Where and how often the automatic backup goes, and how the last attempt
/// ended. Lives in secure storage as a whole: the token and the password are
/// secrets, and none of it belongs in the exported config.
class AutoBackupSettings {
  static const defaultIntervalHours = 24;
  static const defaultKeepCount = 14;

  final bool enabled;
  final AutoBackupTarget target;

  /// The WebDAV folder, e.g. `https://files.example.org/dav/backups/nutri/`.
  final String folderUrl;
  final String token;

  /// Encrypts the uploaded zip (AES) when set.
  final String? password;
  final int intervalHours;
  final int keepCount;
  final DateTime? lastSuccessAt;
  final DateTime? lastErrorAt;
  final String? lastError;

  /// The security-scoped bookmark of the picked Files-app folder (base64)
  /// and the folder's name to show.
  final String? folderBookmark;
  final String? folderName;

  const AutoBackupSettings({
    this.enabled = false,
    this.target = AutoBackupTarget.server,
    this.folderUrl = '',
    this.token = '',
    this.password,
    this.intervalHours = defaultIntervalHours,
    this.keepCount = defaultKeepCount,
    this.lastSuccessAt,
    this.lastErrorAt,
    this.lastError,
    this.folderBookmark,
    this.folderName,
  });

  /// Whether the chosen target is set up well enough to try.
  bool get isConfigured => switch (target) {
    AutoBackupTarget.server => folderUrl.isNotEmpty && token.isNotEmpty,
    AutoBackupTarget.folder => folderBookmark != null,
  };

  AutoBackupSettings copyWith({
    bool? enabled,
    AutoBackupTarget? target,
    String? folderBookmark,
    String? folderName,
    String? folderUrl,
    String? token,
    String? password,
    bool clearPassword = false,
    int? intervalHours,
    int? keepCount,
    DateTime? lastSuccessAt,
    DateTime? lastErrorAt,
    String? lastError,
    bool clearLastError = false,
  }) => AutoBackupSettings(
    enabled: enabled ?? this.enabled,
    target: target ?? this.target,
    folderBookmark: folderBookmark ?? this.folderBookmark,
    folderName: folderName ?? this.folderName,
    folderUrl: folderUrl ?? this.folderUrl,
    token: token ?? this.token,
    password: clearPassword ? null : (password ?? this.password),
    intervalHours: intervalHours ?? this.intervalHours,
    keepCount: keepCount ?? this.keepCount,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    lastErrorAt: clearLastError ? null : (lastErrorAt ?? this.lastErrorAt),
    lastError: clearLastError ? null : (lastError ?? this.lastError),
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'target': target.name,
    'folderBookmark': folderBookmark,
    'folderName': folderName,
    'folderUrl': folderUrl,
    'token': token,
    'password': password,
    'intervalHours': intervalHours,
    'keepCount': keepCount,
    'lastSuccessAt': lastSuccessAt?.toIso8601String(),
    'lastErrorAt': lastErrorAt?.toIso8601String(),
    'lastError': lastError,
  };

  factory AutoBackupSettings.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return AutoBackupSettings(
      enabled: json['enabled'] as bool? ?? false,
      target:
          AutoBackupTarget.values.asNameMap()[json['target']] ??
          AutoBackupTarget.server,
      folderBookmark: json['folderBookmark'] as String?,
      folderName: json['folderName'] as String?,
      folderUrl: json['folderUrl'] as String? ?? '',
      token: json['token'] as String? ?? '',
      password: json['password'] as String?,
      intervalHours: json['intervalHours'] as int? ?? defaultIntervalHours,
      keepCount: json['keepCount'] as int? ?? defaultKeepCount,
      lastSuccessAt: date('lastSuccessAt'),
      lastErrorAt: date('lastErrorAt'),
      lastError: json['lastError'] as String?,
    );
  }
}

/// Reads and writes [AutoBackupSettings] in the platform keychain.
class AutoBackupSettingsStore {
  static const _key = 'AutoBackupSettings';

  final FlutterSecureStorage _storage;

  AutoBackupSettingsStore(this._storage);

  Future<AutoBackupSettings> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return const AutoBackupSettings();
    try {
      return AutoBackupSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return const AutoBackupSettings();
    }
  }

  Future<void> save(AutoBackupSettings settings) =>
      _storage.write(key: _key, value: jsonEncode(settings.toJson()));
}
