import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/hive_storage_integrity_exception.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const _legacyName = 'SharedPrefs';
const _namespace = 'OpenNutriTracker';
const _hiveTag = 'HiveEncryptionTag';
const _profileTag = 'ActiveProfileTag';

/// Stands in for the Android plugin, which keeps one store per
/// `storageNamespace` (or, for pre-bridge builds, per `sharedPreferencesName`).
/// Every call is recorded with the options it carried, so a test can assert
/// both what ended up where and which store was even touched.
class _StoresByNamePlatform extends FlutterSecureStoragePlatform {
  final stores = <String, Map<String, String>>{};
  final calls = <({String method, Map<String, String> options})>[];

  /// Set when a namespace's read-back should come back altered, to simulate
  /// a copy that did not land.
  String? corruptReadsIn;

  Map<String, String> _store(Map<String, String> options) {
    final namespace = options['storageNamespace'] ?? '';
    final name = namespace.isNotEmpty
        ? namespace
        : (options['sharedPreferencesName'] ?? '');
    return stores.putIfAbsent(name, () => {});
  }

  void _record(String method, Map<String, String> options) =>
      calls.add((method: method, options: options));

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    _record('containsKey', options);
    return _store(options).containsKey(key);
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    _record('read', options);
    return _store(options)[key];
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    _record('readAll', options);
    final store = Map<String, String>.of(_store(options));
    if (corruptReadsIn == options['storageNamespace']) {
      return store.map((k, v) => MapEntry(k, '$v-corrupt'));
    }
    return store;
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _record('write', options);
    _store(options)[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _record('delete', options);
    _store(options).remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _record('deleteAll', options);
    _store(options).clear();
  }
}

/// Points the documents directory at an empty temp dir so the "existing
/// Hive files" check sees a fresh install.
class _EmptyDocsPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _EmptyDocsPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  late _StoresByNamePlatform platform;
  final validKey = base64UrlEncode(List<int>.generate(32, (i) => i));

  Map<String, String> legacyStore() => platform.stores[_legacyName] ?? {};
  Map<String, String> namespacedStore() => platform.stores[_namespace] ?? {};
  Iterable<String> storesTouched() => platform.calls.map((c) {
    final ns = c.options['storageNamespace'] ?? '';
    return ns.isNotEmpty ? ns : (c.options['sharedPreferencesName'] ?? '');
  }).toSet();

  setUp(() {
    platform = _StoresByNamePlatform();
    FlutterSecureStoragePlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  // Every release up to 2.3.0 stored the Hive key AES-CBC-encrypted under
  // `sharedPreferencesName: "SharedPrefs"`; flutter_secure_storage 11 removes
  // both. The bridge copies those entries into a separately named namespace
  // on first launch. These pin the copy and the two option sets it depends
  // on, so a later edit cannot quietly strand the key.
  group('Android options', () {
    test(
      'the namespaced store is not the legacy name and never resets',
      () async {
        platform.stores[_namespace] = {_hiveTag: validKey};

        await SecureAppStorageProvider().getActiveProfileId();

        final options = platform.calls.last.options;
        expect(options['storageNamespace'], _namespace);
        expect(
          options['storageNamespace'],
          isNot(_legacyName),
          reason:
              'a namespace matching the old name makes the plugin run '
              'its own migration over the legacy store',
        );
        expect(options['sharedPreferencesName'], isEmpty);
        expect(options['resetOnError'], 'false');
        expect(
          options['migrateWithBackup'],
          'true',
          reason: 'the only switch that stops the per-launch ESP probe',
        );
      },
    );

    test(
      'the legacy store is read with exactly the pre-bridge options',
      () async {
        platform.stores[_legacyName] = {_hiveTag: validKey};

        await SecureAppStorageProvider().getActiveProfileId();

        final legacyRead = platform.calls.firstWhere(
          (c) => c.method == 'readAll' && c.options['storageNamespace'] == '',
        );
        expect(legacyRead.options['sharedPreferencesName'], _legacyName);
        expect(
          legacyRead.options['storageCipherAlgorithm'],
          'AES_CBC_PKCS7Padding',
        );
        expect(legacyRead.options['resetOnError'], 'false');
      },
    );

    test('the shared static instance writes to the namespaced store', () async {
      await SecureAppStorageProvider.secureAppStorage.write(
        key: 'k',
        value: 'v',
      );

      expect(namespacedStore(), {'k': 'v'});
      expect(legacyStore(), isEmpty);
    });
  });

  group('legacy copy', () {
    test(
      'moves every legacy entry into the namespace and returns the key',
      () async {
        platform.stores[_legacyName] = {
          _hiveTag: validKey,
          _profileTag: 'profile-1',
          'ai_api_key_openai': 'sk-secret',
        };

        final key = await SecureAppStorageProvider().getHiveEncryptionKey();

        expect(key, base64Url.decode(validKey));
        expect(namespacedStore(), {
          _hiveTag: validKey,
          _profileTag: 'profile-1',
          'ai_api_key_openai': 'sk-secret',
        });
        expect(
          legacyStore(),
          isEmpty,
          reason: 'the legacy entries are cleared once the copy verified',
        );
      },
    );

    test('is a no-op once the namespace holds the key', () async {
      platform.stores[_namespace] = {_hiveTag: validKey};
      platform.stores[_legacyName] = {_hiveTag: 'stale', _profileTag: 'p'};

      await SecureAppStorageProvider().getHiveEncryptionKey();

      expect(
        storesTouched(),
        [_namespace],
        reason: 'the legacy instance must not even be initialised',
      );
      expect(legacyStore(), {_hiveTag: 'stale', _profileTag: 'p'});
    });

    test(
      'a second launch after an interrupted copy finishes cleanly',
      () async {
        // Both copies exist: the app died between the copy and the clear.
        platform.stores[_namespace] = {_hiveTag: validKey, _profileTag: 'p'};
        platform.stores[_legacyName] = {_hiveTag: validKey, _profileTag: 'p'};

        final key = await SecureAppStorageProvider().getHiveEncryptionKey();

        expect(key, base64Url.decode(validKey));
        expect(namespacedStore(), {_hiveTag: validKey, _profileTag: 'p'});
      },
    );

    test('a copy that does not read back identically is rolled back and '
        'reported, leaving the legacy entries intact', () async {
      platform.stores[_legacyName] = {_hiveTag: validKey, _profileTag: 'p'};
      platform.corruptReadsIn = _namespace;

      await expectLater(
        SecureAppStorageProvider().getHiveEncryptionKey(),
        throwsA(
          isA<HiveStorageIntegrityException>().having(
            (e) => e.code,
            'code',
            'secure_storage_legacy_copy_mismatch',
          ),
        ),
      );

      expect(legacyStore(), {_hiveTag: validKey, _profileTag: 'p'});
      expect(namespacedStore(), isEmpty);
      expect(
        platform.calls.where((c) => c.method == 'deleteAll'),
        isEmpty,
        reason: 'nothing may be cleared when the copy did not verify',
      );
    });

    test('a fresh install mints the key straight into the namespace', () async {
      final docs = await Directory.systemTemp.createTemp('ont-docs-');
      addTearDown(() => docs.delete(recursive: true));
      PathProviderPlatform.instance = _EmptyDocsPathProvider(docs.path);

      final key = await SecureAppStorageProvider().getHiveEncryptionKey();

      expect(key, hasLength(32));
      expect(namespacedStore().keys, [_hiveTag]);
      expect(legacyStore(), isEmpty);
    });

    test('does nothing off Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      platform.stores[''] = {_hiveTag: validKey};

      await SecureAppStorageProvider().getHiveEncryptionKey();

      expect(
        platform.calls.where((c) => c.method == 'readAll'),
        isEmpty,
        reason: 'the copy is an Android-only concern; iOS uses the Keychain',
      );
    });
  });
}
