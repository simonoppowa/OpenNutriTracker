import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';

/// A model provider the user can point the AI features at.
///
/// The name is persisted, so these identifiers are storage format: renaming
/// one silently orphans every key stored under the old spelling.
enum AiProvider {
  anthropic,
  openrouter;

  /// Anything unrecognised — including nothing at all — reads as Anthropic.
  ///
  /// That is what makes an existing install valid without writing to it:
  /// before this existed every key was an Anthropic key, so the absence of a
  /// pointer already means the right thing and no migration has to run.
  static AiProvider fromTag(String? value) => AiProvider.values.firstWhere(
    (provider) => provider.name == value,
    orElse: () => AiProvider.anthropic,
  );
}

/// Holds the user's own model-provider API keys, which one is in use, and
/// whether they currently want it used.
///
/// The keys are credentials the project never sees, never proxies and never
/// pays for, so they live in the platform keystore rather than Hive or
/// preferences — reusing the hardened options on
/// [SecureAppStorageProvider.secureAppStorage], including `resetOnError:
/// false`, so a keystore hiccup cannot silently wipe them.
///
/// **A slot per provider, not one slot reassigned.** Switching provider is
/// the same act [setEnabled] already exists to make cheap: pausing and then
/// hunting for an API key again is friction worth engineering around, and
/// comparing two providers — the whole reason to offer a second one — means
/// switching repeatedly. The cost is accepted knowingly: the app now holds
/// two billing credentials at rest instead of one, in the same hardened
/// store, but a larger prize inside it.
///
/// The active provider and the enabled flag are stored beside the keys
/// rather than in `ConfigDBO`. Neither is a secret, but keeping all of it in
/// one place means they cannot disagree: there is no state where the app
/// believes the feature is on while the credential it would actually use has
/// been cleared, and no state where it points at a provider whose slot was
/// emptied by something that did not update the pointer. It also avoids a
/// Hive schema migration for a bool and a string.
class AiCredentialStorage {
  /// The single tag every key used before providers existed. Still read as
  /// the Anthropic slot's fallback — see [readApiKey] — so an existing
  /// install is bit-for-bit untouched until the user does something.
  static const _legacyApiKeyTag = 'AiApiKeyTag';

  static const _enabledTag = 'AiAssistEnabledTag';
  static const _providerTag = 'AiProviderTag';

  static String _slotTag(AiProvider provider) =>
      '$_legacyApiKeyTag.${provider.name}';

  final FlutterSecureStorage _storage;

  AiCredentialStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? SecureAppStorageProvider.secureAppStorage;

  /// Which provider the AI features currently use.
  Future<AiProvider> activeProvider() async =>
      AiProvider.fromTag(await _storage.read(key: _providerTag));

  /// Points the AI features at [provider].
  ///
  /// Selecting one with no key stored is allowed, and the feature simply
  /// goes quietly unavailable — the camera action hides itself and the text
  /// path falls back to the deterministic parser, which is the state
  /// `MealPhotoUnavailable` already describes and already handles. Gating
  /// the choice to providers that hold a key would make the state
  /// unrepresentable rather than merely handled, but it collapses "switch
  /// provider" and "enter a key" into one action to prevent something that
  /// is not a fault.
  Future<void> setActiveProvider(AiProvider provider) =>
      _storage.write(key: _providerTag, value: provider.name);

  /// The stored key for [provider], defaulting to the active one, or null
  /// when none is set. Read at call time rather than cached — nothing should
  /// hold a credential in memory longer than the request that needs it.
  ///
  /// The Anthropic slot falls back to [_legacyApiKeyTag]. That fallback is
  /// the whole migration strategy: nothing is ever copied, so there is no
  /// moment where a credential exists half-moved, and an older build rolled
  /// back onto the same device still finds the key where it expects it.
  Future<String?> readApiKey({AiProvider? provider}) async {
    final target = provider ?? await activeProvider();

    final value = await _storage.read(key: _slotTag(target));
    if (value != null && value.isNotEmpty) return value;

    if (target != AiProvider.anthropic) return null;

    final legacy = await _storage.read(key: _legacyApiKeyTag);
    if (legacy == null || legacy.isEmpty) return null;
    return legacy;
  }

  /// Stores [apiKey] for [provider], defaulting to the active one. A blank
  /// value clears instead of writing an empty credential that would later
  /// fail as a puzzling 401.
  Future<void> writeApiKey(String apiKey, {AiProvider? provider}) async {
    final target = provider ?? await activeProvider();
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await clear(provider: target);
      return;
    }

    await _storage.write(key: _slotTag(target), value: trimmed);
    await _retireLegacyTagFor(target);

    // Saving a key is the user asking for the feature. Requiring a second
    // switch afterwards is a step that only exists to be forgotten.
    await _storage.write(key: _enabledTag, value: 'true');
  }

  /// Forgets [provider]'s key, defaulting to the active one, and the intent
  /// along with it once no key is left anywhere.
  ///
  /// **The legacy deletion is load-bearing, not tidiness.** Because
  /// [readApiKey] falls back, a stale legacy value can resurrect: suppose a
  /// user replaces their Anthropic key, the new slot is written but the
  /// legacy delete fails on a keystore hiccup — the exact fault
  /// `resetOnError: false` exists for — and then they remove their
  /// credential. Without this, the next read falls back and hands back the
  /// key they just deleted. Pressing "remove key" and still having a working
  /// key afterwards is the worst failure this class can produce.
  Future<void> clear({AiProvider? provider}) async {
    final target = provider ?? await activeProvider();

    await _storage.delete(key: _slotTag(target));
    await _retireLegacyTagFor(target);

    // Only once nothing is left: with two slots, clearing one key is often
    // "I am dropping this provider", not "I am done with the feature". The
    // invariant that matters is narrower — the flag may never be on with no
    // credential behind it at all.
    if (!await _hasAnyKey()) {
      await _storage.delete(key: _enabledTag);
    }
  }

  /// The legacy tag is the Anthropic slot under an older name, so it is
  /// retired only when Anthropic's own slot is written or cleared. Deleting
  /// it while acting on another provider would destroy an Anthropic
  /// credential the user never touched.
  Future<void> _retireLegacyTagFor(AiProvider provider) async {
    if (provider != AiProvider.anthropic) return;
    await _storage.delete(key: _legacyApiKeyTag);
  }

  Future<bool> _hasAnyKey() async {
    for (final provider in AiProvider.values) {
      if (await readApiKey(provider: provider) != null) return true;
    }
    return false;
  }

  Future<bool> hasApiKey({AiProvider? provider}) async =>
      await readApiKey(provider: provider) != null;

  /// Whether the user currently wants the key used. False whenever the
  /// *active* provider has no key, so a caller never has to check both — the
  /// same invariant as before providers existed, restated for two slots.
  Future<bool> isEnabled() async {
    if (!await hasApiKey()) return false;
    return await _storage.read(key: _enabledTag) != 'false';
  }

  /// Turns the feature off without forgetting the keys, so switching it back
  /// on does not mean finding a credential again. Enabling with no key for
  /// the active provider is a no-op rather than a state the UI would have to
  /// explain.
  Future<void> setEnabled(bool enabled) async {
    if (enabled && !await hasApiKey()) return;
    await _storage.write(key: _enabledTag, value: enabled ? 'true' : 'false');
  }

  /// A fixed-length stand-in for a stored key, for a UI that must never show
  /// the value. Fixed-length on purpose: rendering the real length would
  /// leak which provider's key format is in use.
  static const maskedPlaceholder = '••••••••••••';
}
