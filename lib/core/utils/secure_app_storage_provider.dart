import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/hive_storage_integrity_exception.dart';
import 'package:path_provider/path_provider.dart';

class SecureAppStorageProvider {
  static const _sharedPrefsName = "SharedPrefs";
  static const _hiveEncryptionTag = "HiveEncryptionTag";

  // Pointer to the profile whose box-set is currently active. Lives in
  // secure storage (not a Hive box) because it has to be read at the very
  // start of boot, before any per-profile box is open, to decide which
  // boxes to open in the first place.
  static const _activeProfileTag = "ActiveProfileTag";

  // Flutter Secure Storage defaults resetOnError to true, which permanently
  // wipes every stored secret after a decrypt / keystore failure. Combined
  // with Hive crash recovery, that mints a new AES key over existing
  // encrypted boxes and silently truncates them to empty — the user sees a
  // "factory reset" into onboarding.
  static const _androidOptions = AndroidOptions(
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
    sharedPreferencesName: _sharedPrefsName,
    resetOnError: false,
  );
  static const _iOSOptions = IOSOptions();

  static const FlutterSecureStorage secureAppStorage = FlutterSecureStorage(
    iOptions: _iOSOptions,
    aOptions: _androidOptions,
  );

  final _secureStorage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iOSOptions,
  );

  Future<Uint8List> getHiveEncryptionKey() async {
    if (await _secureStorage.containsKey(key: _hiveEncryptionTag)) {
      final raw = await _secureStorage.read(key: _hiveEncryptionTag);
      if (raw == null || raw.isEmpty) {
        throw HiveStorageIntegrityException.emptyKey();
      }
      final Uint8List key;
      try {
        key = base64Url.decode(raw);
      } on FormatException catch (error, stackTrace) {
        // Malformed/partial secure-storage values must not bypass the typed
        // integrity path and crash bootstrap as an unrelated FormatException.
        Error.throwWithStackTrace(
          HiveStorageIntegrityException.malformedKey(error),
          stackTrace,
        );
      }
      // HiveAesCipher requires exactly 32 bytes; a truncated/corrupted
      // value would otherwise surface later as an untyped ArgumentError
      // or HiveError and bypass the bootstrap integrity path.
      if (key.length != 32) {
        throw HiveStorageIntegrityException.malformedKey(
          FormatException('expected 32 bytes, got ${key.length}'),
        );
      }
      return key;
    }

    // Key missing. Only mint a fresh key on a true first install. If any
    // encrypted Hive files already exist on disk, creating a new key would
    // open them under the wrong cipher; Hive's default crashRecovery then
    // truncates frames whose CRC no longer matches and the app boots into
    // onboarding with zeroed user data.
    if (await _hasExistingEncryptedHiveData()) {
      throw HiveStorageIntegrityException.missingKeyWithExistingData();
    }

    final newKeyList = HiveDBProvider.generateNewHiveEncryptionKey();
    final encryptionKey = Uint8List.fromList(newKeyList);
    await _secureStorage.write(
      key: _hiveEncryptionTag,
      value: base64UrlEncode(newKeyList),
    );
    return encryptionKey;
  }

  /// True when the app documents directory already has at least one
  /// non-empty `*.hive` file. Used to distinguish first install from a
  /// partial secure-storage loss.
  Future<bool> _hasExistingEncryptedHiveData() async {
    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) return false;

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.hive')) continue;
      if (await entity.length() > 0) return true;
    }
    return false;
  }

  Future<String?> getActiveProfileId() async {
    return _secureStorage.read(key: _activeProfileTag);
  }

  Future<void> setActiveProfileId(String profileId) async {
    await _secureStorage.write(key: _activeProfileTag, value: profileId);
  }
}
