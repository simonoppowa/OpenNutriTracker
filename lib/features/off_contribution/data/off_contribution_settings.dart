import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether and as whom scanned nutrition values may be sent to Open Food
/// Facts (#81). Kept in the keychain only: the password is a secret, and
/// none of it belongs in an export.
class OffContributionSettings {
  final bool enabled;

  /// The Open Food Facts user name (not the e-mail address).
  final String userId;
  final String password;

  /// Sends to `world.openfoodfacts.net` instead of the real database, until
  /// the upload has been tried there by hand.
  final bool useTestServer;

  const OffContributionSettings({
    this.enabled = false,
    this.userId = '',
    this.password = '',
    this.useTestServer = true,
  });

  /// Whether the app may offer an upload.
  bool get isReady => enabled && userId.isNotEmpty && password.isNotEmpty;

  OffContributionSettings copyWith({
    bool? enabled,
    String? userId,
    String? password,
    bool? useTestServer,
  }) => OffContributionSettings(
    enabled: enabled ?? this.enabled,
    userId: userId ?? this.userId,
    password: password ?? this.password,
    useTestServer: useTestServer ?? this.useTestServer,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'userId': userId,
    'password': password,
    'useTestServer': useTestServer,
  };

  factory OffContributionSettings.fromJson(Map<String, dynamic> json) =>
      OffContributionSettings(
        enabled: json['enabled'] as bool? ?? false,
        userId: json['userId'] as String? ?? '',
        password: json['password'] as String? ?? '',
        useTestServer: json['useTestServer'] as bool? ?? true,
      );
}

/// Reads and writes [OffContributionSettings] in the platform keychain.
class OffContributionSettingsStore {
  static const _key = 'OffContributionSettings';

  final FlutterSecureStorage _storage;

  OffContributionSettingsStore(this._storage);

  Future<OffContributionSettings> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return const OffContributionSettings();
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic>
          ? OffContributionSettings.fromJson(json)
          : const OffContributionSettings();
    } on FormatException {
      return const OffContributionSettings();
    }
  }

  Future<void> save(OffContributionSettings settings) =>
      _storage.write(key: _key, value: jsonEncode(settings.toJson()));
}
