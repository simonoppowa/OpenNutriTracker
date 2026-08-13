import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';

/// In-memory stand-in for the platform keystore.
class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MemoryStorage backing;
  late AiCredentialStorage storage;

  setUp(() {
    backing = _MemoryStorage();
    storage = AiCredentialStorage(backing);
  });

  test('starts with nothing stored and the feature off', () async {
    expect(await storage.readApiKey(), isNull);
    expect(await storage.hasApiKey(), isFalse);
    expect(await storage.isEnabled(), isFalse);
  });

  test('saving a key turns the feature on', () async {
    // Requiring a second switch after saving a key is a step that exists
    // only to be forgotten.
    await storage.writeApiKey('sk-test');

    expect(await storage.readApiKey(), 'sk-test');
    expect(await storage.isEnabled(), isTrue);
  });

  test('trims surrounding whitespace from a pasted key', () async {
    await storage.writeApiKey('  sk-test\n');

    expect(await storage.readApiKey(), 'sk-test');
  });

  test('a blank key clears rather than storing an empty credential', () async {
    // An empty string would be stored happily and then fail later as a
    // puzzling 401.
    await storage.writeApiKey('sk-test');
    await storage.writeApiKey('   ');

    expect(await storage.hasApiKey(), isFalse);
    expect(await storage.isEnabled(), isFalse);
  });

  test('disabling keeps the key so re-enabling is one tap', () async {
    await storage.writeApiKey('sk-test');
    await storage.setEnabled(false);

    expect(await storage.isEnabled(), isFalse);
    expect(await storage.readApiKey(), 'sk-test');

    await storage.setEnabled(true);
    expect(await storage.isEnabled(), isTrue);
  });

  test('clearing forgets the key and the intent together', () async {
    await storage.writeApiKey('sk-test');
    await storage.clear();

    expect(await storage.hasApiKey(), isFalse);
    expect(await storage.isEnabled(), isFalse);
    expect(backing.store, isEmpty);
  });

  test('cannot be enabled with no key stored', () async {
    // Otherwise the app could believe the feature is on while the credential
    // it needs is gone.
    await storage.setEnabled(true);

    expect(await storage.isEnabled(), isFalse);
  });

  test('a cleared key leaves the feature off even if it was on', () async {
    await storage.writeApiKey('sk-test');
    await storage.clear();
    // Directly re-asserting the old intent must not resurrect the feature.
    await storage.setEnabled(true);

    expect(await storage.isEnabled(), isFalse);
  });

  test('the mask never reveals the key or its length', () async {
    await storage.writeApiKey('sk-a-very-long-key-value');

    expect(AiCredentialStorage.maskedPlaceholder, isNot(contains('sk-')));
    expect(
      AiCredentialStorage.maskedPlaceholder.length,
      isNot('sk-a-very-long-key-value'.length),
    );
  });
}
