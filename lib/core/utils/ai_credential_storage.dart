import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';

/// Holds the user's own model-provider API key, and whether they currently
/// want it used.
///
/// The key is a credential the project never sees, never proxies and never
/// pays for, so it lives in the platform keystore rather than Hive or
/// preferences — reusing the hardened options on
/// [SecureAppStorageProvider.secureAppStorage], including `resetOnError:
/// false`, so a keystore hiccup cannot silently wipe it.
///
/// The enabled flag is stored beside the key rather than in `ConfigDBO` on
/// purpose. It is not a secret, but keeping both in one place means they
/// cannot disagree: there is no state where the app believes the feature is
/// on while the key it needs has been cleared, and clearing the credential
/// clears the intent with it. It also avoids a Hive schema migration for a
/// single bool.
class AiCredentialStorage {
  static const _apiKeyTag = 'AiApiKeyTag';
  static const _enabledTag = 'AiAssistEnabledTag';

  final FlutterSecureStorage _storage;

  AiCredentialStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? SecureAppStorageProvider.secureAppStorage;

  /// The stored key, or null when none is set. Read at call time rather than
  /// cached — nothing should hold a credential in memory longer than the
  /// request that needs it.
  Future<String?> readApiKey() async {
    final value = await _storage.read(key: _apiKeyTag);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Stores [apiKey]. A blank value clears instead of writing an empty
  /// credential that would later fail as a puzzling 401.
  Future<void> writeApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(key: _apiKeyTag, value: trimmed);
    // Saving a key is the user asking for the feature. Requiring a second
    // switch afterwards is a step that only exists to be forgotten.
    await _storage.write(key: _enabledTag, value: 'true');
  }

  /// Forgets the key and the intent together.
  Future<void> clear() async {
    await _storage.delete(key: _apiKeyTag);
    await _storage.delete(key: _enabledTag);
  }

  Future<bool> hasApiKey() async => await readApiKey() != null;

  /// Whether the user currently wants the key used. False whenever no key is
  /// stored, so a caller never has to check both.
  Future<bool> isEnabled() async {
    if (!await hasApiKey()) return false;
    return await _storage.read(key: _enabledTag) != 'false';
  }

  /// Turns the feature off without forgetting the key, so switching it back
  /// on does not mean finding the credential again. Enabling with no key
  /// stored is a no-op rather than a state the UI would have to explain.
  Future<void> setEnabled(bool enabled) async {
    if (enabled && !await hasApiKey()) return;
    await _storage.write(key: _enabledTag, value: enabled ? 'true' : 'false');
  }

  /// A fixed-length stand-in for the stored key, for a UI that must never
  /// show the value. Fixed-length on purpose: rendering the real length
  /// would leak which provider's key format is in use.
  static const maskedPlaceholder = '••••••••••••';
}
