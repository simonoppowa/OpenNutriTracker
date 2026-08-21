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
        lessThanOrEqualTo(4),
        reason: 'four distinct keys exist; asking the three getters '
            'separately took 6-8 round trips. Got: ${backing.reads}',
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

    test('an endpoint round-trips and makes the provider usable', () async {
      await storage.writeEndpoint('http://192.168.1.5:11434');

      expect(await storage.readEndpoint(), 'http://192.168.1.5:11434');

      final summary = await storage.readSummary();
      expect(summary.provider, AiProvider.ownServer);
      expect(
        summary.configured,
        isTrue,
        reason: 'an address is what makes this one usable, not a key',
      );
      expect(summary.enabled, isTrue);
    });

    test('no key is needed, and none is invented', () async {
      await storage.writeEndpoint('http://192.168.1.5:11434');
      await storage.writeModel('gemma3:4b');

      final selection = await storage.readSelection();

      expect(selection!.apiKey, isNull);
      expect(selection.endpoint, 'http://192.168.1.5:11434');
      expect(selection.modelId, 'gemma3:4b');
    });

    test('an optional key is carried when the user supplied one', () async {
      // vLLM and llama.cpp both take an optional `--api-key`.
      await storage.writeEndpoint('http://192.168.1.5:8000');
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
      // host the user typed.
      await storage.writeEndpoint('http://192.168.1.5:11434');

      expect(
        (await storage.readSummary()).endpoint,
        'http://192.168.1.5:11434',
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
}
