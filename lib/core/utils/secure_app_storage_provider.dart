import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class SecureAppStorageProvider {
  static const _sharedPrefsName = "SharedPrefs";
  static const _hiveEncryptionTag = "HiveEncryptionTag";

  static const _androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
      sharedPreferencesName: _sharedPrefsName);
  static const _iOSOptions = IOSOptions();

  static const FlutterSecureStorage secureAppStorage =
      FlutterSecureStorage(iOptions: _iOSOptions, aOptions: _androidOptions);

  final _secureStorage = const FlutterSecureStorage(
      aOptions: _androidOptions, iOptions: _iOSOptions);

  Future<Uint8List> getHiveEncryptionKey() async {
    Uint8List encryptionKey;
    if (await _secureStorage.containsKey(key: _hiveEncryptionTag)) {
      encryptionKey = base64Url
          .decode(await _secureStorage.read(key: _hiveEncryptionTag) ?? "");
    } else {
      final newKeyList = HiveDBProvider.generateNewHiveEncryptionKey();
      encryptionKey = Uint8List.fromList(newKeyList);
      await _secureStorage.write(
          key: _hiveEncryptionTag, value: base64UrlEncode(newKeyList));
    }
    return encryptionKey;
  }
}
