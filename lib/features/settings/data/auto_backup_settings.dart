import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where and how often the automatic backup goes, and how the last attempt
/// ended. Lives in secure storage as a whole: the token and the password are
/// secrets, and none of it belongs in the exported config.
class AutoBackupSettings {
  static const defaultIntervalHours = 24;
  static const defaultKeepCount = 14;

  final bool enabled;

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

  const AutoBackupSettings({
    this.enabled = false,
    this.folderUrl = '',
    this.token = '',
    this.password,
    this.intervalHours = defaultIntervalHours,
    this.keepCount = defaultKeepCount,
    this.lastSuccessAt,
    this.lastErrorAt,
    this.lastError,
  });

  /// Whether a server is set up well enough to try.
  bool get isConfigured => folderUrl.isNotEmpty && token.isNotEmpty;

  AutoBackupSettings copyWith({
    bool? enabled,
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
