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

  /// Set to make the n-th write into the namespace throw (1-based), to
  /// simulate the process dying part-way through the copy.
  int? failNamespaceWriteAt;
  int _namespaceWrites = 0;

  /// Set to make the n-th delete in the namespace throw (1-based), to
  /// simulate the process dying part-way through a rollback.
  int? failNamespaceDeleteAt;
  int _namespaceDeletes = 0;

  /// Set to alter only this key on a namespace read-back.
  String? corruptKeyInNamespace;

  /// Set to make a namespace `readAll` throw, as a keystore or decrypt
  /// failure does on device.
  bool throwOnNamespaceReadAll = false;

  /// Keys deleted from the namespace, in order.
  final namespaceDeletes = <String>[];

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
    final inNamespace = (options['storageNamespace'] ?? '').isNotEmpty;
    if (inNamespace && throwOnNamespaceReadAll) {
      throw Exception('BadPaddingException: decrypt failed');
    }
    final store = Map<String, String>.of(_store(options));
    final corruptKey = corruptKeyInNamespace;
    if (inNamespace && corruptKey != null && store.containsKey(corruptKey)) {
      store[corruptKey] = '${store[corruptKey]}-corrupt';
    }
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
    if ((options['storageNamespace'] ?? '').isNotEmpty &&
        ++_namespaceWrites == failNamespaceWriteAt) {
      throw StateError('killed during write #$_namespaceWrites');
    }
    _store(options)[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _record('delete', options);
    if ((options['storageNamespace'] ?? '').isNotEmpty) {
      if (++_namespaceDeletes == failNamespaceDeleteAt) {
        throw StateError('killed during delete #$_namespaceDeletes');
      }
      namespaceDeletes.add(key);
    }
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
    SecureAppStorageProvider.debugSimulateRestart();
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
    // The Hive key is the marker that the copy finished, so a launch that
    // dies part-way must leave it out of the namespace until every other
    // entry has landed, whatever order the legacy store lists them in.
    for (final failAt in [1, 2, 3]) {
      test('a launch killed at namespace write $failAt is finished by the '
          'next one', () async {
        platform.stores[_legacyName] = {
          _hiveTag: validKey,
          _profileTag: 'profile-1',
          'ai_api_key_openai': 'sk-secret',
        };
        platform.failNamespaceWriteAt = failAt;
        await expectLater(
          SecureAppStorageProvider().getHiveEncryptionKey(),
          throwsStateError,
        );
        expect(legacyStore(), hasLength(3), reason: 'nothing is cleared yet');

        platform.failNamespaceWriteAt = null;
        final key = await SecureAppStorageProvider().getHiveEncryptionKey();

        expect(key, base64Url.decode(validKey));
        expect(namespacedStore(), {
          _hiveTag: validKey,
          _profileTag: 'profile-1',
          'ai_api_key_openai': 'sk-secret',
        });
        expect(legacyStore(), hasLength(3), reason: 'cleared after a restart');

        SecureAppStorageProvider.debugSimulateRestart();
        await SecureAppStorageProvider().getHiveEncryptionKey();
        expect(legacyStore(), isEmpty);
      });
    }

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
        // The read-back only proves the copy in memory (the plugin writes
        // with SharedPreferences.apply()); the legacy copy stays until a
        // later launch, where the namespaced entries survived a restart.
        await SecureAppStorageProvider().getActiveProfileId();
        expect(legacyStore(), hasLength(3), reason: 'not in the same process');

        SecureAppStorageProvider.debugSimulateRestart();
        await SecureAppStorageProvider().getHiveEncryptionKey();
        expect(legacyStore(), isEmpty);
        expect(namespacedStore()['LegacyStoreCleared'], 'true');

        platform.calls.clear();
        SecureAppStorageProvider.debugSimulateRestart();
        await SecureAppStorageProvider().getHiveEncryptionKey();
        expect(
          storesTouched(),
          [_namespace],
          reason: 'once cleared, the legacy instance is never touched again',
        );
      },
    );

    test('is a no-op once copied and the legacy store cleared', () async {
      platform.stores[_namespace] = {
        _hiveTag: validKey,
        'LegacyStoreCleared': 'true',
      };
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
        expect(namespacedStore(), {
          _hiveTag: validKey,
          _profileTag: 'p',
          'LegacyStoreCleared': 'true',
        });
        expect(legacyStore(), isEmpty, reason: 'a later launch clears it');
      },
    );

    test('a failed final key check rolls back the marker first, so an '
        'interrupted rollback is finished by the next launch', () async {
      // Listed with the key last, so a rollback in this order would delete
      // the profile pointer before the marker.
      platform.stores[_legacyName] = {
        _profileTag: 'p',
        'ai_api_key_openai': 'sk-secret',
        _hiveTag: validKey,
      };
      platform
        ..corruptKeyInNamespace = _hiveTag
        ..failNamespaceDeleteAt = 2;

      await expectLater(
        SecureAppStorageProvider().getHiveEncryptionKey(),
        throwsStateError,
      );
      expect(platform.namespaceDeletes, [_hiveTag]);

      platform
        ..corruptKeyInNamespace = null
        ..failNamespaceDeleteAt = null;
      final key = await SecureAppStorageProvider().getHiveEncryptionKey();

      expect(key, base64Url.decode(validKey));
      expect(namespacedStore(), {
        _profileTag: 'p',
        'ai_api_key_openai': 'sk-secret',
        _hiveTag: validKey,
      });
    });

    test('a read-back that throws is rolled back and reported as the '
        'typed integrity error, leaving the legacy entries intact', () async {
      platform.stores[_legacyName] = {_hiveTag: validKey, _profileTag: 'p'};
      platform.throwOnNamespaceReadAll = true;

      await expectLater(
        SecureAppStorageProvider().getHiveEncryptionKey(),
        throwsA(
          isA<HiveStorageIntegrityException>()
              .having(
                (e) => e.code,
                'code',
                'secure_storage_legacy_copy_mismatch',
              )
              .having((e) => e.cause, 'cause', isNotNull),
        ),
      );

      expect(legacyStore(), {_hiveTag: validKey, _profileTag: 'p'});
      expect(namespacedStore(), isEmpty);
    });

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
