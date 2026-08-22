import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';

/// In-memory stand-in for the platform keystore.
///
/// [reads] counts round trips, because on a real device each one is a
/// platform channel call and the cost is invisible from the call site — the
/// defect #730 recorded.
class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};
  final reads = <String>[];

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads.add(key);
    return store[key];
  }

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

    test('reads as unknown when it holds something unrecognised', () async {
      // **This is a deliberate reversal of shipped behaviour, not a bug fix.**
      // This test used to assert the opposite — "reads as Anthropic" — with
      // the reasoning "falling back to the default beats refusing to start".
      // #688 rejected exactly that and was never implemented; #753 implements
      // it. A newer build writes a provider name, the user downgrades, and
      // reading that word as Anthropic sends their meals to a company they
      // did not choose.
      backing.store['AiProviderTag'] = 'some-provider-we-dropped';

      expect(await storage.activeProvider(), isNull);
    });

    test('reads as Anthropic when nothing is stored at all', () async {
      // The other half of #688, unchanged: absent still defaults. That is what
      // keeps an install from before providers existed valid without writing
      // to it, and it is not what this reversal touches.
      expect(await storage.activeProvider(), AiProvider.anthropic);
    });
  });

  group('a provider name this build does not know', () {
    // The scenario is a downgrade after picking a provider a later build
    // added. The person most likely to be in it tried a hosted provider
    // first and moved away from it, so the old key is still in its slot —
    // which is what makes the redirect send for real rather than fail.

    setUp(() async {
      await storage.writeApiKey('sk-anthropic', provider: AiProvider.anthropic);
      await storage.setEnabled(true);
      backing.store['AiProviderTag'] = 'a-provider-from-a-later-build';
    });

    test('sends nothing, rather than sending to Anthropic', () async {
      expect(
        await storage.readSelection(),
        isNull,
        reason: 'the one failure #688 said cannot be allowed to be quiet',
      );
    });

    test('reports the feature unavailable rather than configured', () async {
      final summary = await storage.readSummary();

      expect(summary.provider, isNull);
      expect(summary.enabled, isFalse);
      expect(
        summary.configured,
        isFalse,
        reason: 'there is no active provider whose key this could be',
      );
      expect(await storage.isEnabled(), isFalse);
    });

    test('does not hand back the stranded key through the default path', () async {
      // `readApiKey()` with no argument resolves the active provider. With
      // that unknown there is no slot to read, and answering with Anthropic's
      // key would be the same defect wearing a different method name.
      expect(await storage.readApiKey(), isNull);
      expect(await storage.readModel(), isNull);
    });

    test('leaves the tag in place, so re-upgrading restores the choice', () async {
      await storage.readSelection();
      await storage.readSummary();

      expect(
        backing.store['AiProviderTag'],
        'a-provider-from-a-later-build',
        reason: 'destroying the selection makes re-upgrading a second surprise',
      );
    });

    test('the key itself survives, and is reachable when named', () async {
      // Nothing is deleted — only refused while the selection is unreadable.
      expect(
        await storage.readApiKey(provider: AiProvider.anthropic),
        'sk-anthropic',
      );
    });
  });

  group('the model slot', () {
    test('is per provider, like the key', () async {
      await storage.writeModel('a/one', provider: AiProvider.anthropic);
      await storage.writeModel('b/two', provider: AiProvider.openrouter);

      expect(await storage.readModel(provider: AiProvider.anthropic), 'a/one');
      expect(await storage.readModel(provider: AiProvider.openrouter), 'b/two');
    });

    test('defaults to the active provider when none is named', () async {
      await storage.setActiveProvider(AiProvider.openrouter);
      await storage.writeModel('b/two');

      expect(await storage.readModel(), 'b/two');
      expect(await storage.readModel(provider: AiProvider.anthropic), isNull);
    });

    test('reads as null when unset or blank', () async {
      // Null is "use the default", which `AiModelCatalogue.resolve` decides.
      // An empty string reaching it would resolve to the default anyway, but
      // only by accident — collapsing it here means the absent case has one
      // representation instead of two.
      expect(await storage.readModel(), isNull);

      backing.store['AiModelTag.anthropic'] = '';
      expect(await storage.readModel(provider: AiProvider.anthropic), isNull);
    });

    test('is stored under a tag of its own, not beside the key', () async {
      await storage.writeModel('a/one', provider: AiProvider.anthropic);

      expect(backing.store['AiModelTag.anthropic'], 'a/one');
      expect(backing.store.containsKey('AiApiKeyTag.anthropic'), isFalse);
    });
  });

  group('readSummary', () {
    // Everything a row shows about the feature, resolved in one pass. The
    // three getters it replaces are each other's dependencies — `isEnabled`
    // opens by calling `hasApiKey`, which resolves `activeProvider` before it
    // can name a slot — so asking them separately resolved the provider three
    // times over. #730.

    test('reports the provider, the key and the flag together', () async {
      await storage.setActiveProvider(AiProvider.openai);
      await storage.writeApiKey('sk-test', provider: AiProvider.openai);
      await storage.setEnabled(true);

      final summary = await storage.readSummary();

      expect(summary.provider, AiProvider.openai);
      expect(summary.configured, isTrue);
      expect(summary.enabled, isTrue);
    });

    test('a key with the flag off reads as paused, not as absent', () async {
      // The distinction the settings row is built on: "Paused — key saved"
      // against "Off — no key saved".
      await storage.writeApiKey('sk-test');
      await storage.setEnabled(false);

      final summary = await storage.readSummary();

      expect(summary.configured, isTrue);
      expect(summary.enabled, isFalse);
    });

    test('enabled is never true without a key for the active provider', () async {
      // The invariant `isEnabled` has always enforced, now stated in one
      // place: the flag alone never means "on". Set the flag against a
      // provider that holds a key, then switch to one that does not.
      await storage.writeApiKey('sk-test', provider: AiProvider.anthropic);
      await storage.setEnabled(true);
      await storage.setActiveProvider(AiProvider.openai);

      final summary = await storage.readSummary();

      expect(summary.provider, AiProvider.openai);
      expect(summary.configured, isFalse);
      expect(summary.enabled, isFalse);
    });

    test('resolves the active provider once, not once per value', () async {
      await storage.setActiveProvider(AiProvider.openai);
      await storage.writeApiKey('sk-test', provider: AiProvider.openai);
      backing.reads.clear();

      await storage.readSummary();

      expect(
        backing.reads.where((k) => k == 'AiProviderTag').length,
        1,
        reason: 'the provider decides which slot to read; it is not per value',
      );
      expect(
        backing.reads.length,
        lessThanOrEqualTo(5),
        reason: 'five distinct keys exist; asking the three getters '
            'separately took 6-8 round trips. The model joined them when it '
            'became part of what "configured" means for a server the user '
            'runs, and `readSelection` stopped reading it a second time in '
            'exchange. Got: ${backing.reads}',
      );
    });

    test('agrees with the getters it replaces', () async {
      // The refactor is only safe if it is not a behaviour change. Checked
      // across the states the row distinguishes rather than on one happy
      // path.
      for (final (provider, key, enabled) in [
        (AiProvider.anthropic, null, true),
        (AiProvider.anthropic, 'sk-a', true),
        (AiProvider.anthropic, 'sk-a', false),
        (AiProvider.openai, 'sk-o', true),
        (AiProvider.openrouter, null, false),
      ]) {
        final fresh = _MemoryStorage();
        final store = AiCredentialStorage(fresh);
        await store.setActiveProvider(provider);
        if (key != null) await store.writeApiKey(key, provider: provider);
        await store.setEnabled(enabled);

        final summary = await store.readSummary();

        expect(summary.provider, await store.activeProvider());
        expect(summary.configured, await store.hasApiKey());
        expect(summary.enabled, await store.isEnabled());
      }
    });
  });

  group('a server the user runs', () {
    // The provider whose credential is an address. Everything here exists
    // because "has a key" stopped being the test of usability. #755.

    setUp(() => storage.setActiveProvider(AiProvider.ownServer));

    test('an endpoint and a model round-trip and make it usable', () async {
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');

      expect(
        await storage.readEndpoint(),
        'http://192.168.1.5:11434/v1/chat/completions',
        reason: 'stored as it will be requested, not as it was typed',
      );

      final summary = await storage.readSummary();
      expect(summary.provider, AiProvider.ownServer);
      expect(
        summary.configured,
        isTrue,
        reason: 'an address and a model are what make this one usable, '
            'not a key',
      );
      expect(summary.enabled, isTrue);
    });

    test('an address with no model is not configured', () async {
      // #738 said the model is part of what "configured" means here, and
      // nothing enforced it: the address alone flipped the flag, and then the
      // request builder had no model to name and threw — into a catch-all
      // that reports "the parser answered". The row said On and every meal
      // silently took the offline path.
      await storage.writeEndpoint('http://192.168.1.5:11434');

      final summary = await storage.readSummary();
      expect(summary.configured, isFalse);
      expect(summary.enabled, isFalse);
      expect(await storage.readSelection(), isNull);
    });

    test('an address that cannot be requested is refused outright', () async {
      // `192.168.1.5:11434` is the form Ollama's own documentation shows and
      // is not a URL. Stored, it reached `Uri.parse` inside the request
      // builder as a FormatException and was swallowed the same way.
      await storage.writeEndpoint('192.168.1.5:11434');

      expect(await storage.readEndpoint(), isNull);
      expect(
        await storage.isEnabled(),
        isFalse,
        reason: 'writing an address is what turns the feature on, so a '
            'refused one must not',
      );
    });

    group('written as one configuration', () {
      test('stores both and reports the change', () async {
        final changed = await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
        );

        expect(changed, isTrue);
        expect(
          await storage.readEndpoint(),
          'http://192.168.1.5:11434/v1/chat/completions',
        );
        expect(await storage.readModel(), 'gemma3:4b');
        expect((await storage.readSummary()).configured, isTrue);
      });

      test('changing the address keeps the model that came with it', () async {
        // The invariant this method exists to own. A changed address forgets
        // the stored model on purpose (#738), so the two writes have an order
        // — model last — and getting it backwards silently drops the model
        // the user just typed. It used to be a comment beside a button.
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
        );

        final changed = await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.9:11434',
          model: 'qwen3:8b',
        );

        expect(changed, isTrue);
        expect(
          await storage.readEndpoint(),
          'http://192.168.1.9:11434/v1/chat/completions',
        );
        expect(await storage.readModel(), 'qwen3:8b');
      });

      test('refuses a pair rather than storing half of it', () async {
        expect(
          await storage.writeOwnServerConfiguration(
            endpoint: 'http://192.168.1.5:11434',
            model: '  ',
          ),
          isFalse,
        );
        expect(
          await storage.writeOwnServerConfiguration(
            endpoint: '192.168.1.5:11434',
            model: 'gemma3:4b',
          ),
          isFalse,
        );

        expect(await storage.readEndpoint(), isNull);
        expect(await storage.readModel(), isNull);
        expect(
          await storage.isEnabled(),
          isFalse,
          reason: 'a refused pair must not have turned anything on',
        );
      });

      test('re-saving an untouched configuration resumes nothing', () async {
        // The settings dialog offers OK beside the pause switch, and
        // supplying an address is how a user asks for the feature — so
        // confirming a dialog they only paused in would undo the pause.
        await storage.writeOwnServerConfiguration(
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
        );
        await storage.setEnabled(false);

        final changed = await storage.writeOwnServerConfiguration(
          // The base form, as it would be typed; the store holds the resolved
          // one, so a raw-text comparison would call this a change.
          endpoint: 'http://192.168.1.5:11434',
          model: 'gemma3:4b',
        );

        expect(changed, isFalse);
        expect(await storage.isEnabled(), isFalse);
      });
    });

    test('an address stored before it was checked stays refused', () async {
      // Not hypothetical: the earlier commits on this branch stored whatever
      // was typed, so an install that saved `192.168.1.5:11434` already holds
      // it. Nothing rewrites the keystore on upgrade, so the read side has to
      // refuse it independently — otherwise that install is exactly where it
      // started, reported on and throwing a FormatException one layer below
      // anything the user can see.
      backing.store['AiEndpointTag.ownServer'] = '192.168.1.5:11434';
      backing.store['AiModelTag.ownServer'] = 'gemma3:4b';
      backing.store['AiAssistEnabledTag'] = 'true';

      final summary = await storage.readSummary();
      expect(summary.configured, isFalse);
      expect(summary.enabled, isFalse);
      expect(await storage.readSelection(), isNull);
    });

    test('a base address is completed to the chat route', () async {
      // Ollama, llama.cpp, vLLM and LM Studio all answer at
      // /v1/chat/completions and 404 at the root, and the field's hint is a
      // base address. Completing it is the OpenAI-compatible contract rather
      // than a guess about the server.
      for (final (typed, expected) in [
        ('http://192.168.1.5:11434', 'http://192.168.1.5:11434/v1/chat/completions'),
        ('http://192.168.1.5:11434/', 'http://192.168.1.5:11434/v1/chat/completions'),
        ('http://192.168.1.5:11434/v1', 'http://192.168.1.5:11434/v1/chat/completions'),
        ('http://192.168.1.5:11434/v1/', 'http://192.168.1.5:11434/v1/chat/completions'),
        // Already a route: left exactly as typed.
        ('https://ollama.example.com/v1/chat/completions',
            'https://ollama.example.com/v1/chat/completions'),
        // Something else entirely is the user's business, not ours.
        ('https://ollama.example.com/proxy/chat',
            'https://ollama.example.com/proxy/chat'),
      ]) {
        expect(
          AiCredentialStorage.resolveEndpoint(typed).toString(),
          expected,
          reason: typed,
        );
      }
    });

    test('the destination is named without the credential in it', () async {
      // `Uri.authority` is `userInfo@host:port`, so a server behind basic
      // auth put the password into the disclosure paragraph and onto the
      // settings row — in an app that masks the API key so that a stored
      // credential is not readable off a screen someone else can see.
      const withPassword = 'http://ollama:hunter2@192.168.1.5:11434';

      expect(
        AiCredentialStorage.displayHost(withPassword),
        '192.168.1.5:11434',
      );
      expect(
        AiCredentialStorage.displayHost(withPassword),
        isNot(contains('hunter2')),
      );
      expect(
        Uri.parse(withPassword).authority,
        contains('hunter2'),
        reason: 'the trap this exists to avoid, stated so it stays visible',
      );
    });

    test('the destination is host and port, without the route', () async {
      for (final (endpoint, expected) in [
        ('http://192.168.1.5:11434', '192.168.1.5:11434'),
        ('http://192.168.1.5:11434/v1/chat/completions', '192.168.1.5:11434'),
        // No port typed is no port shown, rather than the scheme's default.
        ('https://ollama.example.com/v1/chat/completions', 'ollama.example.com'),
      ]) {
        expect(
          AiCredentialStorage.displayHost(endpoint),
          expected,
          reason: endpoint,
        );
      }
    });

    test('an IPv6 destination is bracketed once it carries a port', () async {
      // `Uri.host` strips the brackets, so the old concatenation produced
      // `2001:db8::1:11434` — which a reader cannot split into an address and
      // a port, and cannot type back into a browser or a curl. The one string
      // whose entire job is to name the destination truthfully at the moment
      // the user decides whether to send a photograph.
      //
      // Seen in a measured dual-stack setup rather than only in theory: #758
      // used `example-server.home.arpa` resolving to a ULA
      // `fd00:1234:5678:…`
      // beside a private v4, and the plaintext guard accepts whichever
      // private answer it finds.
      for (final (endpoint, expected) in [
        ('http://[2001:db8::1]:11434', '[2001:db8::1]:11434'),
        (
          'http://[fd00:1234:5678::22]:11434/v1/chat/completions',
          '[fd00:1234:5678::22]:11434',
        ),
        ('http://[::1]:11434', '[::1]:11434'),
        // No port, nothing to separate: the brackets are there to keep the
        // address away from the port colon, and a bare literal reads better
        // in a sentence.
        ('http://[2001:db8::1]', '2001:db8::1'),
        // A default port is not a typed port, for v6 as for everything else.
        ('https://[2001:db8::1]:443', '2001:db8::1'),
        // v4 and a hostname are untouched by the bracketing rule.
        ('http://192.168.1.5:11434', '192.168.1.5:11434'),
        ('http://192.168.1.5', '192.168.1.5'),
        ('https://ollama.example.com:8443/v1', 'ollama.example.com:8443'),
        ('https://ollama.example.com/v1/chat/completions', 'ollama.example.com'),
      ]) {
        expect(
          AiCredentialStorage.displayHost(endpoint),
          expected,
          reason: endpoint,
        );
      }
    });

    test('a bracketed IPv6 destination still hides the credential', () async {
      // `Uri.authority` brackets correctly and was the short way to fix the
      // above. It also carries `userInfo`, which is the whole reason this
      // function does not use it — so the two rules are checked together
      // rather than each on an address the other never sees.
      const withPassword =
          'http://ollama:hunter2@[fd00:1234:5678::22]:11434';

      expect(
        AiCredentialStorage.displayHost(withPassword),
        '[fd00:1234:5678::22]:11434',
      );
      expect(
        AiCredentialStorage.displayHost(withPassword),
        isNot(contains('hunter2')),
      );
    });

    test('text that is not yet an address names nothing', () async {
      // Echoing the field back is how a half-pasted credential reaches the
      // screen; a caller with nothing to name shows nothing.
      for (final typed in ['', 'htt', '192.168.1.5:11434', 'ollama:hunter2@']) {
        expect(
          AiCredentialStorage.displayHost(typed),
          isNull,
          reason: typed,
        );
      }
    });

    test('an address without a usable scheme and host is rejected', () async {
      // The scheme is never guessed: the disclosure derives its encryption
      // clause from it, so choosing plaintext on the user's behalf would put
      // a sentence on screen they never agreed to. #736.
      for (final typed in [
        '192.168.1.5:11434',
        'ollama.local:11434',
        'my server',
        'http://',
        'ftp://192.168.1.5',
        '',
      ]) {
        expect(
          AiCredentialStorage.resolveEndpoint(typed),
          isNull,
          reason: typed,
        );
      }
    });

    test('no key is needed, and none is invented', () async {
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');

      final selection = await storage.readSelection();

      expect(selection!.apiKey, isNull);
      expect(selection.endpoint, 'http://192.168.1.5:11434/v1/chat/completions');
      expect(selection.modelId, 'gemma3:4b');
    });

    test('pausing it is not a one-way door', () async {
      // `setEnabled` guarded on `hasApiKey`, which #755 replaced everywhere
      // else and missed here — so the switch turned this provider off and
      // then refused to turn it back on, for want of a key it never needs.
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');

      await storage.setEnabled(false);
      expect(await storage.isEnabled(), isFalse);

      await storage.setEnabled(true);
      expect(await storage.isEnabled(), isTrue);
    });

    test('a key alone still cannot enable it', () async {
      // The guard is generalised, not removed: what it asks is now "is this
      // provider usable", and for this one a key is not the answer.
      await storage.writeApiKey('sk-local');
      await storage.setEnabled(true);

      expect(await storage.isEnabled(), isFalse);
    });

    test('an optional key is carried when the user supplied one', () async {
      // vLLM and llama.cpp both take an optional `--api-key`.
      await storage.writeEndpoint('http://192.168.1.5:8000');
      await storage.writeModel('gemma3:4b');
      await storage.writeApiKey('sk-local');

      expect((await storage.readSelection())!.apiKey, 'sk-local');
    });

    test('a key alone never makes it usable', () async {
      // The mirror of the invariant for the hosted three: the thing that
      // makes this provider work is the address, so a key without one is not
      // a configured provider.
      await storage.writeApiKey('sk-local');

      final summary = await storage.readSummary();
      expect(summary.configured, isFalse);
      expect(summary.enabled, isFalse);
      expect(await storage.readSelection(), isNull);
    });

    test('the flag alone never means on', () async {
      await storage.setEnabled(true);

      expect(await storage.isEnabled(), isFalse);
      expect(await storage.readSelection(), isNull);
    });

    test('changing the address forgets the model', () async {
      // A model id is a statement about a server. `gemma3:4b` means something
      // only relative to the machine answering, and there is no curated list
      // to fall back to when it names nothing there. #738.
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');

      await storage.writeEndpoint('http://192.168.1.9:11434');

      expect(await storage.readModel(), isNull);
    });

    test('rewriting the same address keeps the model', () async {
      // Only a *change* invalidates the claim. Re-saving the same address is
      // not a change, and dropping the model there would be a papercut every
      // time the user re-opened settings.
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');

      await storage.writeEndpoint('http://192.168.1.5:11434');

      expect(await storage.readModel(), 'gemma3:4b');
    });

    test('clearing forgets the address, the model and the key together', () async {
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');
      await storage.writeApiKey('sk-local');

      await storage.clear();

      expect(await storage.readEndpoint(), isNull);
      expect(await storage.readModel(), isNull);
      expect(
        await storage.readApiKey(),
        isNull,
        reason: 'a key that outlives its endpoint means nothing',
      );
      expect(await storage.readSummary().then((s) => s.configured), isFalse);
    });

    test('the address is reported so a row can name the destination', () async {
      // #736: this destination has no brand, so the only honest name is the
      // address itself — reported as it will be requested, which is what the
      // row and the disclosure are for.
      await storage.writeEndpoint('http://192.168.1.5:11434');

      expect(
        (await storage.readSummary()).endpoint,
        'http://192.168.1.5:11434/v1/chat/completions',
      );
    });

    test('the hosted providers are untouched by any of this', () async {
      // The generalisation must not have loosened the rule for the three that
      // still need a key.
      for (final provider in [
        AiProvider.anthropic,
        AiProvider.openrouter,
        AiProvider.openai,
      ]) {
        final fresh = AiCredentialStorage(_MemoryStorage());
        await fresh.setActiveProvider(provider);
        await fresh.writeEndpoint('http://192.168.1.5:11434');

        expect(
          (await fresh.readSummary()).configured,
          isFalse,
          reason: '${provider.name} is not usable without a key',
        );
      }
    });
  });

  group('readSelection', () {
    test('is null while the feature is off, key or no key', () async {
      await storage.writeApiKey('sk-test');
      await storage.setEnabled(false);

      expect(await storage.readSelection(), isNull);
    });

    test('is null when the active provider has no key', () async {
      expect(await storage.readSelection(), isNull);
    });

    test('carries the active provider, its key and its model', () async {
      await storage.setActiveProvider(AiProvider.openrouter);
      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);
      await storage.writeModel('b/two', provider: AiProvider.openrouter);

      final selection = await storage.readSelection();

      expect(selection!.provider, AiProvider.openrouter);
      expect(selection.apiKey, 'sk-or');
      expect(selection.modelId, 'b/two');
    });

    test('hands over the active provider\'s key when both are stored', () async {
      // The reason this is read as a unit rather than field by field. A key
      // is scoped to the account that issued it: sending the Anthropic one
      // to OpenRouter would hand a working credential to a company the user
      // never gave it to, and it would come back as a puzzling 401 rather
      // than as anything that says what happened.
      //
      // Both slots are filled on purpose. With only one key stored the
      // wrong-key bug is unreachable — `isEnabled` is itself scoped to the
      // active provider, so it returns false and `readSelection` gives up
      // before it ever reads a key. A test written that way passes against
      // an implementation that always reads Anthropic's slot.
      await storage.writeApiKey('sk-anthropic', provider: AiProvider.anthropic);
      await storage.writeApiKey('sk-or', provider: AiProvider.openrouter);
      await storage.setActiveProvider(AiProvider.openrouter);

      final selection = await storage.readSelection();

      expect(selection!.apiKey, 'sk-or');
      expect(selection.provider, AiProvider.openrouter);
    });

    test('is null when only the other provider has a key', () async {
      // Via `isEnabled`, which asks `hasApiKey()` for the *active* provider.
      // Worth pinning because it is not obvious from the name: the feature
      // reads as off — not merely unconfigured — the moment the user selects
      // a provider they have no credential for.
      await storage.writeApiKey('sk-anthropic', provider: AiProvider.anthropic);
      await storage.setActiveProvider(AiProvider.openrouter);

      expect(await storage.isEnabled(), isFalse);
      expect(await storage.readSelection(), isNull);
    });

    test('leaves the model null when the provider has none stored', () async {
      // Not an error: the catalogue turns null into that provider's default,
      // so a user who never opened the model list still gets a request.
      await storage.writeApiKey('sk-test');

      final selection = await storage.readSelection();

      expect(selection!.modelId, isNull);
      expect(selection.provider, AiProvider.anthropic);
    });
  });

  group('what the probe found (#779)', () {
    const own = AiProvider.ownServer;
    const passed = AiEndpointProbe(
      text: AiCapability.passed,
      photo: AiCapability.passed,
    );

    Future<void> configure({
      String endpoint = 'http://192.168.1.5:11434',
      String model = 'gemma3:4b',
    }) async {
      await storage.setActiveProvider(own);
      await storage.writeEndpoint(endpoint, provider: own);
      await storage.writeModel(model, provider: own);
    }

    test('nothing has been established before anything is asked', () async {
      await configure();

      final probe = await storage.readProbe(provider: own);

      expect(probe.text, AiCapability.unknown);
      expect(probe.photo, AiCapability.unknown);
    });

    test('a verdict survives a round trip', () async {
      await configure();
      await storage.writeProbe(
        const AiEndpointProbe(
          text: AiCapability.passed,
          photo: AiCapability.failed,
        ),
        provider: own,
      );

      final probe = await storage.readProbe(provider: own);

      expect(probe.text, AiCapability.passed);
      expect(probe.photo, AiCapability.failed);
    });

    test('an inconclusive retry does not revoke what is known', () async {
      // Copilot caught this on #784: `writeProbe` wrote whatever it was
      // handed, so a retry against a sleeping server replaced "photos work
      // here" with "we could not tell" — revoking a pass that was still
      // perfectly true, because nothing about the endpoint or the model had
      // changed and the only thing that learned anything was the network.
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.writeProbe(AiEndpointProbe.unknown, provider: own);

      final probe = await storage.readProbe(provider: own);
      expect(probe.text, AiCapability.passed);
      expect(probe.photo, AiCapability.passed);
    });

    test('but a conclusive one does, in both directions', () async {
      // The half that has to keep working: a use-time capability refusal
      // retracts a stale pass (#782). Only `unknown` is inert.
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.writeProbe(
        const AiEndpointProbe(
          text: AiCapability.unknown,
          photo: AiCapability.failed,
        ),
        provider: own,
      );

      final probe = await storage.readProbe(provider: own);
      expect(probe.photo, AiCapability.failed, reason: 'retracted');
      expect(probe.text, AiCapability.passed, reason: 'untouched');
    });

    test('nothing conclusive leaves no record at all', () async {
      // "Stored as absence" is now literally true rather than a `"--"` that
      // merely reads like absence.
      await configure();

      await storage.writeProbe(AiEndpointProbe.unknown, provider: own);

      expect(
        backing.store.keys.where((k) => k.startsWith('AiProbeTag')),
        isEmpty,
      );
    });

    test('changing the address discards it', () async {
      // A pass was a fact about a machine. This is a different machine, and
      // "photos work here" has never been asked of it.
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.writeEndpoint('http://192.168.1.9:11434', provider: own);

      expect(
        (await storage.readProbe(provider: own)).photo,
        AiCapability.unknown,
      );
    });

    test('re-saving the same address keeps it', () async {
      // Otherwise every visit to settings costs the user their camera and a
      // two-minute re-probe to get it back.
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.writeEndpoint('http://192.168.1.5:11434', provider: own);

      expect(
        (await storage.readProbe(provider: own)).photo,
        AiCapability.passed,
      );
    });

    test('changing the model discards it too', () async {
      // The half that keeps this a fact about `(endpoint, model)` rather
      // than about an address. Without it, pulling a text-only model under
      // the same tag leaves a camera that passed once and now fails on
      // every photograph — #688's resurrection trap under another key.
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.writeModel('llama3.2:1b', provider: own);

      expect(
        (await storage.readProbe(provider: own)).photo,
        AiCapability.unknown,
      );
    });

    test('re-saving the same model keeps it', () async {
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.writeModel('gemma3:4b', provider: own);

      expect(
        (await storage.readProbe(provider: own)).photo,
        AiCapability.passed,
      );
    });

    test('clearing the provider takes it with everything else', () async {
      await configure();
      await storage.writeProbe(passed, provider: own);

      await storage.clear(provider: own);

      expect(
        (await storage.readProbe(provider: own)).photo,
        AiCapability.unknown,
      );
    });

    test('a value this build cannot read means "not established"', () async {
      // A keystore entry an older or newer build wrote is not worth failing
      // a settings screen over, and the safe reading of "I cannot parse
      // this" is "I do not know what this endpoint can do".
      for (final corrupt in ['', 'x', 'ppp', '{"text":true}', 'zz']) {
        expect(
          AiEndpointProbe.decode(corrupt).photo,
          AiCapability.unknown,
          reason: 'decoding "$corrupt"',
        );
      }
      expect(AiEndpointProbe.decode(null).text, AiCapability.unknown);
    });

    test('every verdict encodes to something the decoder reads back', () {
      for (final text in AiCapability.values) {
        for (final photo in AiCapability.values) {
          final probe = AiEndpointProbe(text: text, photo: photo);
          final round = AiEndpointProbe.decode(probe.encode());
          expect(round.text, text, reason: probe.encode());
          expect(round.photo, photo, reason: probe.encode());
        }
      }
    });
  });
}
