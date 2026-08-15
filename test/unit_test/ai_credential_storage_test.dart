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

  group('two providers', () {
    test('defaults to Anthropic with nothing stored', () async {
      expect(await storage.activeProvider(), AiProvider.anthropic);
    });

    test('holds a key per provider rather than one reassigned', () async {
      // Switching provider is the same act setEnabled(false) exists to make
      // cheap. Comparing two providers means switching repeatedly, and
      // re-finding an API key each time taxes exactly that.
      await storage.writeApiKey('sk-ant', provider: AiProvider.anthropic);
      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);

      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        'sk-ant',
      );
      expect(
        await storage.readApiKey(provider: AiProvider.openrouter),
        'sk-or',
      );
    });

    test('reads and writes the active provider by default', () async {
      await storage.setActiveProvider(AiProvider.openrouter);
      await storage.writeApiKey('sk-or');

      expect(await storage.readApiKey(), 'sk-or');
      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        isNull,
        reason: 'the other slot must not be written by an unqualified save',
      );
    });

    test('switching back finds the key still there', () async {
      await storage.writeApiKey('sk-ant');
      await storage.setActiveProvider(AiProvider.openrouter);
      await storage.writeApiKey('sk-or');
      await storage.setActiveProvider(AiProvider.anthropic);

      expect(await storage.readApiKey(), 'sk-ant');
      expect(await storage.isEnabled(), isTrue);
    });

    test('selecting a provider with no key goes quietly unavailable', () async {
      // A setting, not a fault: the same state MealPhotoUnavailable already
      // describes, arriving by a new route.
      await storage.writeApiKey('sk-ant');
      await storage.setActiveProvider(AiProvider.openrouter);

      expect(await storage.isEnabled(), isFalse);
      expect(await storage.hasApiKey(), isFalse);
      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        'sk-ant',
        reason: 'and the key it is not using is untouched',
      );
    });

    test('cannot be enabled for a provider with no key', () async {
      await storage.writeApiKey('sk-ant');
      await storage.setActiveProvider(AiProvider.openrouter);
      await storage.setEnabled(true);

      expect(await storage.isEnabled(), isFalse);
    });

    test('clearing one provider leaves the other alone', () async {
      await storage.writeApiKey('sk-ant', provider: AiProvider.anthropic);
      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);

      await storage.clear(provider: AiProvider.openrouter);

      expect(await storage.readApiKey(provider: AiProvider.openrouter), isNull);
      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        'sk-ant',
      );
      // Dropping one provider is not the same as being done with the
      // feature, and a credential is still there to back the intent.
      expect(await storage.isEnabled(), isTrue);
    });

    test('clearing one provider does not silently un-pause', () async {
      // An absent flag reads as on, so deleting it is not a neutral act.
      // If clear() forgot the intent whenever any key went away, a paused
      // user who dropped one provider would find the feature running again
      // without having asked for it.
      await storage.writeApiKey('sk-ant', provider: AiProvider.anthropic);
      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);
      await storage.setEnabled(false);

      await storage.clear(provider: AiProvider.openrouter);

      expect(await storage.isEnabled(), isFalse);
    });

    test('clearing the last key also forgets the intent', () async {
      await storage.writeApiKey('sk-ant', provider: AiProvider.anthropic);
      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);

      await storage.clear(provider: AiProvider.openrouter);
      await storage.clear(provider: AiProvider.anthropic);

      expect(await storage.isEnabled(), isFalse);
      expect(backing.store, isEmpty);
    });
  });

  group('a key stored before providers existed', () {
    // The single tag every install used before this. Spelled out rather than
    // referenced so the test still fails if the constant is renamed — the
    // point is the bytes on the device, not the identifier in the source.
    const legacyTag = 'AiApiKeyTag';

    test('keeps working untouched, with no migration written', () async {
      backing.store[legacyTag] = 'sk-old';
      backing.store['AiAssistEnabledTag'] = 'true';

      expect(await storage.readApiKey(), 'sk-old');
      expect(await storage.isEnabled(), isTrue);
      expect(backing.store.keys.toSet(), {
        legacyTag,
        'AiAssistEnabledTag',
      }, reason: 'reading must not write anything back');
    });

    test('is Anthropic\'s, and not visible to the other provider', () async {
      backing.store[legacyTag] = 'sk-old';

      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        'sk-old',
      );
      expect(await storage.readApiKey(provider: AiProvider.openrouter), isNull);
    });

    test('is retired the next time an Anthropic key is saved', () async {
      backing.store[legacyTag] = 'sk-old';

      await storage.writeApiKey('sk-new');

      expect(await storage.readApiKey(), 'sk-new');
      expect(backing.store.containsKey(legacyTag), isFalse);
    });

    test('survives saving a key for the other provider', () async {
      // Retiring the legacy tag on any write would destroy an Anthropic
      // credential the user never touched.
      backing.store[legacyTag] = 'sk-old';

      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);

      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        'sk-old',
      );
    });

    test('is deleted by clear, so it cannot resurrect the key', () async {
      // The trap the fallback creates. Suppose the legacy delete failed once
      // on a keystore hiccup — the exact fault resetOnError: false exists
      // for — leaving a stale value behind a newer slot. If clear() does not
      // remove it too, the user presses "remove key" and still has a working
      // key afterwards, which is the worst thing this class can do.
      backing.store[legacyTag] = 'sk-stale';
      backing.store['AiApiKeyTag.anthropic'] = 'sk-current';

      await storage.clear();

      expect(await storage.readApiKey(), isNull);
      expect(await storage.hasApiKey(), isFalse);
      expect(await storage.isEnabled(), isFalse);
    });

    test('clearing the other provider does not delete it', () async {
      backing.store[legacyTag] = 'sk-old';

      await storage.clear(provider: AiProvider.openrouter);

      expect(await storage.readApiKey(), 'sk-old');
    });
  });

  group('the provider tag', () {
    test('is stored as a stable name, not an index', () async {
      // Persisted format: an ordinal would silently repoint every install at
      // a different provider the day the enum gains a member.
      await storage.setActiveProvider(AiProvider.openrouter);

      expect(backing.store['AiProviderTag'], 'openrouter');
    });

    test('reads as Anthropic when it holds something unrecognised', () async {
      // A downgrade, or a provider removed in a later build. Falling back to
      // the default beats refusing to start.
      backing.store['AiProviderTag'] = 'some-provider-we-dropped';

      expect(await storage.activeProvider(), AiProvider.anthropic);
    });
  });
}
