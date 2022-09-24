import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAppStorage {
  static const _androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
      sharedPreferencesName: 'sharedPrefs');
  static const _iOSOptions = IOSOptions();

  static const FlutterSecureStorage secureAppStorage = FlutterSecureStorage(
      iOptions: _iOSOptions, aOptions: _androidOptions);
}
