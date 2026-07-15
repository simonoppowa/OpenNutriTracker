import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class SecureAppStorageProvider {
  static const _sharedPrefsName = "SharedPrefs";
  static const _hiveEncryptionTag = "HiveEncryptionTag";

  // Pointer to the profile whose box-set is currently active. Lives in
  // secure storage (not a Hive box) because it has to be read at the very
  // start of boot, before any per-profile box is open, to decide which
  // boxes to open in the first place.
  static const _activeProfileTag = "ActiveProfileTag";

  static const _androidOptions = AndroidOptions(
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
    sharedPreferencesName: _sharedPrefsName,
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
    Uint8List encryptionKey;
    if (await _secureStorage.containsKey(key: _hiveEncryptionTag)) {
      encryptionKey = base64Url.decode(
        await _secureStorage.read(key: _hiveEncryptionTag) ?? "",
      );
    } else {
      final newKeyList = HiveDBProvider.generateNewHiveEncryptionKey();
      encryptionKey = Uint8List.fromList(newKeyList);
      await _secureStorage.write(
        key: _hiveEncryptionTag,
        value: base64UrlEncode(newKeyList),
      );
    }
    return encryptionKey;
  }

  Future<String?> getActiveProfileId() async {
    return _secureStorage.read(key: _activeProfileTag);
  }

  Future<void> setActiveProfileId(String profileId) async {
    await _secureStorage.write(key: _activeProfileTag, value: profileId);
  }
}
