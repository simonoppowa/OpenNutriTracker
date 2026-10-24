import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/hive_storage_integrity_exception.dart';
import 'package:path_provider/path_provider.dart';

class SecureAppStorageProvider {
  // The SharedPreferences file every release up to 2.3.0 wrote to, under
  // flutter_secure_storage's deprecated `sharedPreferencesName`.
  static const _legacySharedPrefsName = "SharedPrefs";

  // The namespace the app writes to from the bridge release on. It must
  // differ from [_legacySharedPrefsName]: the plugin treats a namespace that
  // matches an old preferences name as the same store and runs its own
  // key-relocation and re-encryption over it, and that path deleted the
  // entries without re-encrypting them when it was tried (10.3.4, storage
  // cipher change only). A distinct name keeps the two stores independent
  // so the copy below is the only thing that touches either.
  static const _storageNamespace = "OpenNutriTracker";
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
  //
  // `migrateWithBackup` is not here for a migration — the cipher markers the
  // plugin writes on this store's first use never change, so none can run.
  // It is the only switch that stops the plugin from probing Jetpack's
  // EncryptedSharedPreferences on every launch: on a store that never had
  // ESP data it skips the probe only under this flag (10.3.4), and without
  // it the probe opens ESP over the same preferences file, fails to decrypt
  // the plugin's own entries and logs a caught SecurityException each start.
  static const _androidOptions = AndroidOptions(
    storageNamespace: _storageNamespace,
    migrateWithBackup: true,
    resetOnError: false,
  );

  // Exactly the configuration every release up to 2.3.0 used, kept so the
  // bridge can still read what those releases wrote. flutter_secure_storage
  // 11 removes both the AES-CBC cipher and `sharedPreferencesName`, so this
  // instance — and [_migrateLegacyAndroidEntries] with it — can only exist
  // on a 10.x build; the v11 bump has to wait until this bridge has shipped.
  // Nothing may change here: any difference from the shipped options makes
  // the plugin start a migration of its own over the legacy store.
  static const _legacyAndroidOptions = AndroidOptions(
    // ignore: deprecated_member_use
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
    // ignore: deprecated_member_use
    sharedPreferencesName: _legacySharedPrefsName,
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

  final _legacySecureStorage = const FlutterSecureStorage(
    aOptions: _legacyAndroidOptions,
    iOptions: _iOSOptions,
  );

  /// Copies everything a pre-bridge release stored under the legacy Android
  /// options into the namespaced store, once. Bootstrap reads the Hive key
  /// before anything else touches secure storage, so by the time
  /// [secureAppStorage] is used for AI credentials the copy has happened.
  ///
  /// Order of operations is what makes this safe to interrupt at any point:
  ///
  /// 1. If the namespaced store already holds the Hive key, nothing to do.
  ///    This is the marker; no separate flag that could disagree with it.
  /// 2. Read every legacy entry. An empty result is a fresh install.
  /// 3. Write each entry to the namespaced store and read the whole store
  ///    back; every legacy entry must come back byte-identical.
  /// 4. Only then clear the legacy entries.
  ///
  /// A kill between 3 and 4 leaves both copies and the next launch skips at
  /// step 1. A verification failure at 3 removes the partial copy and
  /// throws a typed integrity error, so the legacy entries stay untouched
  /// and the user sees the recovery screen instead of a wiped diary.
  Future<void> _migrateLegacyAndroidEntries() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    // This read is also what initialises the namespaced store, and it has to
    // happen while the store is still empty. Installs that began on 2.0.2
    // carry the plugin's global config file, which a namespace without
    // markers of its own falls back to; its AES-CBC markers make the plugin
    // run a "migration" over the new store on first use. Over an empty store
    // that is a no-op that writes the namespace's own markers (verified on
    // device); over a store that already held the copied entries it would
    // be the same path that deleted them without re-encrypting.
    if (await _secureStorage.containsKey(key: _hiveEncryptionTag)) return;

    final legacy = await _legacySecureStorage.readAll();
    if (legacy.isEmpty) return;

    for (final entry in legacy.entries) {
      await _secureStorage.write(key: entry.key, value: entry.value);
    }
    final copied = await _secureStorage.readAll();
    final mismatched = legacy.keys
        .where((key) => copied[key] != legacy[key])
        .toList(growable: false);
    if (mismatched.isNotEmpty) {
      for (final key in legacy.keys) {
        await _secureStorage.delete(key: key);
      }
      throw HiveStorageIntegrityException.legacyCopyMismatch(mismatched);
    }

    await _legacySecureStorage.deleteAll();
  }

  Future<Uint8List> getHiveEncryptionKey() async {
    await _migrateLegacyAndroidEntries();

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
    await _migrateLegacyAndroidEntries();
    return _secureStorage.read(key: _activeProfileTag);
  }

  Future<void> setActiveProfileId(String profileId) async {
    await _migrateLegacyAndroidEntries();
    await _secureStorage.write(key: _activeProfileTag, value: profileId);
  }
}
