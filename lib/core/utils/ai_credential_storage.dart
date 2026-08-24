import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:synchronized/synchronized.dart';

/// A model provider the user can point the AI features at.
///
/// The name is persisted, so these identifiers are storage format: renaming
/// one silently orphans every key stored under the old spelling.
enum AiProvider {
  anthropic,
  openrouter,
  openai,

  /// A server the user runs — Ollama, LM Studio, llama.cpp, vLLM — reached at
  /// an address they supply.
  ///
  /// The odd one out in this store: its credential is an **address**, not a
  /// key, and a key is optional. Everything below that treats "has a key" as
  /// the test of usability had to learn a broader question. #755.
  ownServer;

  /// **Nothing stored** reads as Anthropic; **a name this build does not
  /// know** reads as null.
  ///
  /// The first half is what makes an existing install valid without writing
  /// to it: before providers existed every key was an Anthropic key, so the
  /// absence of a pointer already means the right thing and no migration has
  /// to run.
  ///
  /// The second half used to be the same as the first, and that was the
  /// defect #688 resolved and #753 fixed. A newer build writes a provider
  /// name, the user downgrades, and this build reads a word it does not know
  /// — reading that as Anthropic **silently redirects their requests to a
  /// company they did not choose**, which in an app that enumerates its
  /// destinations and names the serving vendor as a guarantee is the one
  /// failure that cannot be quiet. It sends for real, too: the person most
  /// likely to be here tried a hosted provider first and moved away from it,
  /// so their Anthropic key is still in the slot.
  ///
  /// Null makes the feature quietly unavailable instead, which is not a new
  /// state to design — it is what a provider with no key already does.
  static AiProvider? fromTag(String? value) {
    if (value == null || value.isEmpty) return AiProvider.anthropic;
    for (final provider in AiProvider.values) {
      if (provider.name == value) return provider;
    }
    return null;
  }
}

/// Everything one request needs in order to be addressed: who is answering,
/// with which credential, using which model.
///
/// Read as a unit rather than field by field, so a provider switch that
/// lands between two reads cannot produce a request that sends one
/// provider's key to another provider's endpoint.
class AiSelection {
  final AiProvider provider;

  /// Null for a destination that wants no credential, which is the normal
  /// state for a server the user runs. #755.
  final String? apiKey;

  /// Where the request goes, for the one provider whose address the user
  /// supplies. Null for the three reached at a compiled-in endpoint.
  final String? endpoint;

  /// Null means "this provider's default". Resolved by `AiModelCatalogue`
  /// rather than here, so retiring a model is a change in one file.
  final String? modelId;

  const AiSelection({
    required this.provider,
    this.apiKey,
    this.endpoint,
    this.modelId,
  });
}

/// What a probe established about one capability of one destination.
///
/// Three-valued rather than a bool, because "we asked and it cannot" and "we
/// never got an answer" call for different words in front of the user, and
/// collapsing them would make a sleeping server read as a broken model.
enum AiCapability {
  /// The endpoint answered with a parseable tool call carrying at least one
  /// item. The only state that opens a capability up.
  passed,

  /// The endpoint answered, and the answer was not usable — refused the
  /// request, would not call the tool, or reported nothing at all in a
  /// picture of food. Will not change on its own.
  failed,

  /// Nothing conclusive. Never probed, or probed and the answer said more
  /// about the network than about the model.
  ///
  /// **The default in every ambiguous case**, on purpose: recording a
  /// verdict that cannot be justified is worse than recording none, because
  /// a wrong `failed` hides a working camera and a wrong `passed` offers a
  /// dead end.
  unknown,
}

/// What the last probe found for a destination.
///
/// Stored per `(endpoint, model)` by construction rather than by carrying a
/// composite key: [AiCredentialStorage.writeEndpoint] and
/// [AiCredentialStorage.writeModel] each discard it when their value changes,
/// so a stored record can only ever describe the pair currently configured.
class AiEndpointProbe {
  /// Whether a meal line came back as usable items.
  final AiCapability text;

  /// Whether a photograph did. This is the one that gates a camera.
  final AiCapability photo;

  const AiEndpointProbe({required this.text, required this.photo});

  static const unknown = AiEndpointProbe(
    text: AiCapability.unknown,
    photo: AiCapability.unknown,
  );

  /// `text` and `photo` as one character each — `p`, `f`, or absent as `-`.
  ///
  /// A fixed two-character form rather than JSON. This is a *storage format*
  /// like [AiProvider] is, so it is worth being explicit that widening it
  /// later means handling what an older build wrote; two positions with a
  /// documented alphabet make that obvious, where a JSON blob invites fields
  /// to be added as though nothing were reading the old ones.
  String encode() => '${_code(text)}${_code(photo)}';

  static String _code(AiCapability capability) => switch (capability) {
    AiCapability.passed => 'p',
    AiCapability.failed => 'f',
    AiCapability.unknown => '-',
  };

  /// Anything unrecognised reads as [unknown] rather than raising. A keystore
  /// value the app cannot parse is not worth failing a settings screen over,
  /// and the safe reading of "I do not know what this says" is "I do not
  /// know what this endpoint can do".
  static AiEndpointProbe decode(String? value) {
    if (value == null || value.length != 2) return unknown;
    return AiEndpointProbe(
      text: _capability(value[0]),
      photo: _capability(value[1]),
    );
  }

  static AiCapability _capability(String code) => switch (code) {
    'p' => AiCapability.passed,
    'f' => AiCapability.failed,
    _ => AiCapability.unknown,
  };
}

/// What a row needs to describe the feature without opening it: who would
/// answer, whether a credential exists for them, and whether the user
/// currently wants it used.
///
/// Deliberately carries no key. Three screens show this and none of them
/// sends a request, so the credential is read to test its existence and
/// dropped — the same thing [AiCredentialStorage.hasApiKey] has always done,
/// kept that way now that the read is shared.
class AiAssistSummary {
  /// Null when the stored provider name is one this build does not know, so
  /// a row can report the feature unavailable without naming a company that
  /// was never chosen. #753.
  final AiProvider? provider;

  /// Whether this provider has what it needs — a key for the hosted three, an
  /// address for a server the user runs. Named for the question rather than
  /// for one provider's answer to it. #755.
  final bool configured;

  /// False whenever [configured] is false, so a caller never has to check
  /// both.
  final bool enabled;

  /// The address, for the one provider whose destination has no brand name to
  /// print. #736 settled that this row must name where the data goes, and for
  /// a server the user runs the only honest answer is the host they typed.
  final String? endpoint;

  const AiAssistSummary({
    required this.provider,
    required this.configured,
    required this.enabled,
    this.endpoint,
  });
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
  static const _modelTag = 'AiModelTag';

  /// Where [AiProvider.ownServer] points. Slot-shaped like the others for
  /// consistency, though only one provider will ever hold one.
  static const _endpointTag = 'AiEndpointTag';

  /// What a setup-time probe found this destination could do (#735).
  static const _probeTag = 'AiProbeTag';

  static String _slotTag(AiProvider provider) =>
      '$_legacyApiKeyTag.${provider.name}';

  static String _modelSlotTag(AiProvider provider) =>
      '$_modelTag.${provider.name}';

  static String _endpointSlotTag(AiProvider provider) =>
      '$_endpointTag.${provider.name}';

  static String _probeSlotTag(AiProvider provider) =>
      '$_probeTag.${provider.name}';

  final FlutterSecureStorage _storage;
  final _probeConfigurationLock = Lock();

  AiCredentialStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? SecureAppStorageProvider.secureAppStorage;

  /// Which provider the AI features currently use, or **null when the stored
  /// name is one this build does not know** — see [AiProvider.fromTag].
  ///
  /// Null is not "none selected". It is "a selection this build cannot
  /// honour", and every read below treats it as unusable rather than
  /// substituting a default.
  Future<AiProvider?> activeProvider() async =>
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

  /// Resolves the active provider **once** and answers everything that hangs
  /// off it, for the callers that want more than one of these values.
  ///
  /// The public getters are each other's dependencies — [isEnabled] begins by
  /// calling [hasApiKey], which resolves [activeProvider] before it can name a
  /// slot — so asking all three separately resolved the provider three times
  /// and re-read the key slot twice, for 6-8 platform-channel round trips
  /// against four distinct keys. Nothing was wrong with any answer; the cost
  /// was simply invisible from the call site, because each method reads like
  /// one lookup. #730.
  ///
  /// Not fixable by running the three concurrently: they are not independent,
  /// so overlapping them hides the duplicate reads rather than removing them.
  /// A null provider short-circuits the whole thing: there is no slot to read
  /// a key from, so there is nothing to enable. #753.
  ///
  /// Naming a [provider] skips the resolution and answers about that one
  /// instead. The pause flag is not per provider, so it still applies.
  Future<
    ({
      AiProvider? provider,
      String? apiKey,
      String? endpoint,
      String? modelId,
      bool enabled,
    })
  >
  _readState({AiProvider? provider}) async {
    provider ??= await activeProvider();
    if (provider == null) {
      return (
        provider: null,
        apiKey: null,
        endpoint: null,
        modelId: null,
        enabled: false,
      );
    }
    final apiKey = await readApiKey(provider: provider);
    final endpoint = await readEndpoint(provider: provider);
    // Read here rather than only in `readSelection`, because usability now
    // depends on it for one provider. That call gets no more expensive — it
    // was reading the model separately anyway — and a summary costs one more
    // round trip than it did, which is the price of the row and the request
    // agreeing about whether this provider can answer.
    final modelId = await readModel(provider: provider);
    // The invariant, stated here once: the flag alone never means "on" — a
    // provider that is not usable is off whatever the tag says.
    final enabled =
        _isUsable(
          provider,
          apiKey: apiKey,
          endpoint: endpoint,
          modelId: modelId,
        ) &&
        await _storage.read(key: _enabledTag) != 'false';
    return (
      provider: provider,
      apiKey: apiKey,
      endpoint: endpoint,
      modelId: modelId,
      enabled: enabled,
    );
  }

  /// The route every OpenAI-compatible runtime answers on. Fixed by the
  /// protocol this provider is named for, not chosen by the app.
  static const _chatCompletionsPath = '/v1$_chatCompletionsSuffix';

  /// What [endpoint] will actually be requested as, or **null when what was
  /// typed cannot be requested at all**.
  ///
  /// Public so the dialog validates against exactly what the store accepts,
  /// rather than keeping a second opinion about what a usable address is.
  ///
  /// **Rejects** anything without an `http`/`https` scheme and a host. A bare
  /// `192.168.1.5:11434` is the form Ollama's own documentation shows and is
  /// not a URL: `Uri.parse` throws on it, and that landed as a
  /// `FormatException` inside the request builder, where the use case's
  /// catch-all swallowed it — so the row said the feature was on while every
  /// meal quietly went to the parser instead. The scheme is deliberately
  /// **not** guessed on the user's behalf: the disclosure derives its
  /// encryption clause from it (#736), and picking plaintext for someone is
  /// the one thing that sentence must never say without them having said it.
  ///
  /// **Completes** a base address to the chat route. Ollama, llama.cpp, vLLM
  /// and LM Studio all answer at [_chatCompletionsPath] and 404 at the root,
  /// and a base URL plus a fixed route is the OpenAI-compatible contract
  /// itself — so this is the protocol rather than a guess about it, which is
  /// what separates it from the scheme above. The field's own hint is a base
  /// address, and it has to work. A path the user typed is kept as typed.
  ///
  /// **The model-list route names a base too.** `…/v1/models` is the URL these
  /// runtimes print in their own docs and the one a user checking their server
  /// is alive has in the clipboard, so it is an easy thing to paste into a
  /// field asking for an address — and it is not a chat route. Left as typed
  /// it was stored as the destination every meal request would be POSTed to,
  /// and #757's Load models then appended a second `/models` to it and asked
  /// `…/v1/models/models`. Both halves of that come from the same wrong
  /// premise, and both are fixed by reading the segment for what it is: the
  /// list route, sitting on the base this address really names.
  static Uri? resolveEndpoint(String endpoint) {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;

    final typed = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    // Safe to strip before anything else looks at the path: `/models` is
    // fixed by the protocol as the list route, so no OpenAI-compatible server
    // serves chat on a path ending in it.
    final path = typed.endsWith(_modelsSuffix)
        ? typed.substring(0, typed.length - _modelsSuffix.length)
        : typed;
    if (path.isEmpty) return uri.replace(path: _chatCompletionsPath);
    // `http://host:11434/v1` is what LM Studio prints and what the OpenAI
    // SDKs call the base URL, so it is a base rather than a route.
    if (path.endsWith('/v1')) {
      return uri.replace(path: '$path/chat/completions');
    }
    return uri.replace(path: path);
  }

  /// The suffix [resolveEndpoint] completes a base address to.
  static const _chatCompletionsSuffix = '/chat/completions';

  /// The other half of the OpenAI-compatible pair, and the segment
  /// [resolveEndpoint] reads as naming a base rather than a route.
  static const _modelsSuffix = '/models';

  /// Where to ask [endpoint] what models it serves, or null when what was
  /// typed cannot be requested at all.
  ///
  /// Derived from [resolveEndpoint] rather than resolved a second time, so the
  /// two routes can never disagree about what the user typed. Whatever
  /// completion, trimming or pass-through that function applied has already
  /// happened; this only swaps the last segment of the OpenAI-compatible pair.
  ///
  /// `/v1/models` is fixed by the protocol in the same way `/v1/chat/
  /// completions` is — Ollama, LM Studio, llama.cpp and vLLM all answer on
  /// it — so this is the contract rather than a guess about it.
  ///
  /// An address whose path is neither the chat route nor a base gets `/models`
  /// appended. That is a best effort over something already unusual, and the
  /// worst case is the same 404 the user would get from typing it themselves —
  /// reported as `AiModelListFailure.rejected`, which says the server answered
  /// with something else rather than that it could not be reached.
  static Uri? resolveModelsEndpoint(String endpoint) {
    final chat = resolveEndpoint(endpoint);
    if (chat == null) return null;
    final path = chat.path;
    return chat.replace(
      path: path.endsWith(_chatCompletionsSuffix)
          ? '${path.substring(0, path.length - _chatCompletionsSuffix.length)}'
                '$_modelsSuffix'
          : '$path$_modelsSuffix',
    );
  }

  /// The part of [endpoint] that names the destination, and **nothing else** —
  /// or null when there is no host in it to name.
  ///
  /// Host and port, deliberately not `Uri.authority`. Authority carries
  /// `userInfo`, so a reverse-proxied server entered as
  /// `http://ollama:hunter2@192.168.1.5:11434` printed the password: in the
  /// disclosure paragraph the user is agreeing to, and on the settings row,
  /// in an app that masks the API key precisely so a stored credential is not
  /// readable off a screen someone else can see. Naming where the data goes
  /// never needed the credential that gets it in.
  ///
  /// The path is dropped too. `/v1/chat/completions` is on every one of these
  /// addresses and distinguishes none of them, and the row and the disclosure
  /// exist to be read at a glance.
  ///
  /// Null rather than a best effort when nothing parses: a caller showing
  /// this is naming a destination, and text that is not yet an address names
  /// none — echoing it back is how a half-typed credential would reach the
  /// screen anyway.
  ///
  /// **An IPv6 literal is bracketed once a port is shown.** `Uri.host` hands
  /// back `2001:db8::1` with the brackets stripped, so pasting a port onto it
  /// produced `2001:db8::1:11434` — an address a reader cannot separate into
  /// host and port and cannot type back in. This is not a hypothetical shape
  /// in a dual-stack home network: #758 measured `example-server.home.arpa`
  /// resolving to a ULA `fd00:1234:5678:…` alongside a private v4, and the
  /// plaintext guard deliberately accepts whichever private answer it finds,
  /// v6 included. A string whose whole job is to name the destination at the
  /// moment the user decides whether to send a photograph fails at it if the
  /// address cannot be read back.
  ///
  /// Bracketed **only** when there is a port, because that is the only case
  /// that is ambiguous — the brackets exist in a URI to separate the address
  /// from the port colon, and with no port there is nothing to separate. A
  /// bare `fd00:1234:5678::22` reads better in a sentence than a bracketed one.
  ///
  /// Not `Uri.authority`, which brackets correctly and would have been the
  /// short way to fix this: it also carries the `userInfo` this function
  /// exists to strip.
  static String? displayHost(String endpoint) {
    final uri = Uri.tryParse(endpoint.trim());
    if (uri == null || uri.host.isEmpty) return null;
    // `Uri` canonicalizes an explicitly typed scheme-default port (`:80` for
    // http, `:443` for https), so `hasPort` is false and the redundant port is
    // omitted here too. Non-default ports remain explicit.
    if (!uri.hasPort) return uri.host;
    // A registered name can never contain a colon, so this identifies an
    // IPv6 literal without a second parse of it.
    final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
    return '$host:${uri.port}';
  }

  /// Whether [provider] has what it needs to be used at all.
  ///
  /// The generalisation #755 exists for. The rule was never really about
  /// keys — it is *a provider that is not usable is off whatever the flag
  /// says* — and what makes one usable differs: a key for the three hosted
  /// ones, an **address** for a server the user runs, whose key is optional
  /// and usually absent.
  ///
  /// Exhaustive on purpose. A fifth provider must answer this question
  /// deliberately rather than inherit "has a key" by default.
  static bool _isUsable(
    AiProvider provider, {
    required String? apiKey,
    required String? endpoint,
    required String? modelId,
  }) => switch (provider) {
    AiProvider.anthropic ||
    AiProvider.openrouter ||
    AiProvider.openai => apiKey != null,
    // **And the model**, which is where #738's "the model is part of what
    // configured means here" is finally enforced rather than asserted. The
    // three hosted providers fall back to a curated default; this one has no
    // list, so a missing id leaves the request builder with nothing to name
    // and it throws — silently, one layer below anything the user can see.
    AiProvider.ownServer =>
      endpoint != null && resolveEndpoint(endpoint) != null && modelId != null,
  };

  /// Where [AiProvider.ownServer] points, or null when nothing is stored.
  Future<String?> readEndpoint({AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return null;
    final value = await _storage.read(key: _endpointSlotTag(target));
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Points [provider] at [endpoint] with [model], **as one act**, and
  /// reports whether anything actually changed.
  ///
  /// An address and a model are one configuration for this provider rather
  /// than two settings that happen to sit together: neither is usable without
  /// the other ([_isUsable]), and writing a *changed* address deliberately
  /// forgets the stored model (#738). That makes the order load-bearing —
  /// model last, or it is wiped by the address it belongs to — and until this
  /// existed the order lived in the settings dialog, one caller away from
  /// somebody writing them the other way round and watching the model
  /// disappear.
  ///
  /// **Both or neither.** A pair that cannot be stored is refused here rather
  /// than half-written; the dialog checks the same two things first so it can
  /// name the field at fault, and this is the floor under that, not the
  /// message.
  ///
  /// **Nothing is written when nothing differs.** Supplying an address is how
  /// a user asks for the feature ([writeEndpoint] sets the flag), so an
  /// unconditional write would silently resume a provider they had just
  /// paused. The comparison is against the **resolved** form, because what
  /// they typed is a base and what is stored carries the chat route.
  Future<bool> writeOwnServerConfiguration({
    required String endpoint,
    required String model,
    AiProvider? provider,
  }) async {
    final target = await _target(provider);
    if (target == null) return false;

    final resolved = resolveEndpoint(endpoint);
    final trimmedModel = model.trim();
    if (resolved == null || trimmedModel.isEmpty) return false;

    var changed = false;
    if (resolved.toString() != await readEndpoint(provider: target)) {
      await writeEndpoint(endpoint, provider: target);
      changed = true;
    }
    if (trimmedModel != await readModel(provider: target)) {
      await writeModel(trimmedModel, provider: target);
      changed = true;
    }
    return changed;
  }

  /// Points [provider] at [endpoint], and **forgets the stored model when the
  /// address changes**.
  ///
  /// The primitive under [writeOwnServerConfiguration], which is what a
  /// caller configuring this provider should reach for — this one on its own
  /// leaves it unusable until a model follows.
  ///
  /// A model id is a statement about a server: `llama3.2:8b` means something
  /// only relative to the machine answering, and this provider has no curated
  /// list to fall back to when the id names nothing there. Keeping it would
  /// carry a claim that is no longer known to be true into the next request —
  /// the same reason #688 refused to let an unknown provider tag keep meaning
  /// Anthropic.
  ///
  /// Per-endpoint model slots were the consistent-looking alternative and were
  /// refused: they accumulate one keystore entry per address the user ever
  /// typed, kept forever, which is a durable record of every machine on their
  /// network. #738.
  Future<void> writeEndpoint(String endpoint, {AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return;
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) {
      await clear(provider: target);
      return;
    }

    // Refused rather than stored, because the write below also turns the
    // feature on — keeping an address that can never be requested would leave
    // the flag set over a provider that cannot answer, which is the state
    // this class exists to make unrepresentable. The dialog checks the same
    // function first and says why; this is the floor under it, not the
    // message.
    final resolved = resolveEndpoint(trimmed);
    if (resolved == null) return;
    // Stored as it will be requested. The row and the dialog then show the
    // address the app will really use, which is the point of naming a
    // destination at all.
    final value = resolved.toString();

    await _probeConfigurationLock.synchronized(() async {
      final previous = await _storage.read(key: _endpointSlotTag(target));
      if (previous != value) {
        await _storage.delete(key: _modelSlotTag(target));
        // And what the probe found, for the same reason and one step further:
        // "photos work here" was a fact about a machine, and this is a
        // different machine. #779.
        await _storage.delete(key: _probeSlotTag(target));
      }
      await _storage.write(key: _endpointSlotTag(target), value: value);

      // Same reasoning as `writeApiKey`: supplying the thing that makes the
      // provider usable is the user asking for the feature.
      await _storage.write(key: _enabledTag, value: 'true');
    });
  }

  /// The provider these per-provider methods should act on: the one named,
  /// or the active one — and **null when the active one is a name this build
  /// does not know**.
  ///
  /// Every read below then answers "nothing" rather than substituting a
  /// default, which is the whole point of #753: an unknown selection must not
  /// resolve to somebody. The writes answer nothing too, and that path is
  /// unreachable in practice — choosing a provider in the dialog passes one
  /// explicitly and clears the unknown state on the way.
  Future<AiProvider?> _target(AiProvider? provider) async =>
      provider ?? await activeProvider();

  /// What a row shows for the feature, in one read of the store.
  Future<AiAssistSummary> readSummary() async {
    final state = await _readState();
    final provider = state.provider;
    return AiAssistSummary(
      provider: provider,
      configured:
          provider != null &&
          _isUsable(
            provider,
            apiKey: state.apiKey,
            endpoint: state.endpoint,
            modelId: state.modelId,
          ),
      enabled: state.enabled,
      endpoint: state.endpoint,
    );
  }

  /// What the AI features should do right now, or null when they should do
  /// nothing — the feature is off, or the active provider has no key.
  ///
  /// One method rather than three calls at each site: both use cases used to
  /// ask `isEnabled()` then `readApiKey()`, and adding a provider and a model
  /// would have made that four questions asked separately in two places.
  Future<AiSelection?> readSelection() async =>
      _selectionFrom(await _readState());

  /// The same question asked about a **named** provider rather than whichever
  /// one is selected right now.
  ///
  /// For work that outlives the moment it was started: the setup check runs
  /// for about 66 seconds against a dialog whose provider selector stays
  /// live, and it is a check of the configuration it was started for. Asking
  /// [readSelection] instead made a two-tap switch during the run silently
  /// cancel it — the check would read back a provider nobody had asked it
  /// about and conclude there was nothing to do. #780.
  ///
  /// The pause flag is shared, so pausing still answers null here: pause
  /// means nothing is sent, and a check is a request like any other.
  Future<AiSelection?> selectionFor(AiProvider provider) async =>
      _selectionFrom(await _readState(provider: provider));

  AiSelection? _selectionFrom(
    ({
      AiProvider? provider,
      String? apiKey,
      String? endpoint,
      String? modelId,
      bool enabled,
    })
    state,
  ) {
    if (!state.enabled) return null;
    final provider = state.provider;
    // Implied by `enabled`, which is false without a usable provider. Stated
    // so the types carry it too. The **key** is no longer implied: a server
    // the user runs is usable without one.
    if (provider == null) return null;
    return AiSelection(
      provider: provider,
      apiKey: state.apiKey,
      endpoint: state.endpoint,
      modelId: state.modelId,
    );
  }

  /// Which model [provider] should use, or null for its default.
  ///
  /// Kept here rather than in `ConfigDBO` for the same reason as the provider
  /// tag: it is meaningless apart from the provider it belongs to, and one
  /// store means one place where the three can disagree instead of two. It
  /// is deliberately *not* validated on read — [AiModelCatalogue.resolve]
  /// decides what an unknown id means, so retiring a model is a change in
  /// one file rather than a migration here.
  Future<String?> readModel({AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return null;
    final value = await _storage.read(key: _modelSlotTag(target));
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Stores the model, and **forgets what the probe found when the model
  /// changes**.
  ///
  /// The mirror of the rule in [writeEndpoint], and the other half of what
  /// makes a probe result a fact about `(endpoint, model)` rather than about
  /// an address. Without it, pulling a text-only model under the same tag
  /// leaves a camera that passed once and now fails on every photograph —
  /// the resurrection trap #688 closed, reopened under a different key.
  Future<void> writeModel(String modelId, {AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return;

    await _probeConfigurationLock.synchronized(() async {
      final previous = await _storage.read(key: _modelSlotTag(target));
      if (previous != modelId) {
        await _storage.delete(key: _probeSlotTag(target));
      }
      await _storage.write(key: _modelSlotTag(target), value: modelId);
    });
  }

  /// What the last probe found for [provider], or [AiEndpointProbe.unknown]
  /// when none has run against this `(endpoint, model)` pair.
  ///
  /// Never throws on a value it cannot read. A corrupt or unrecognised record
  /// reads as unknown, which is the same conservative direction as everything
  /// else here: an unproven capability is not offered.
  Future<AiEndpointProbe> readProbe({AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return AiEndpointProbe.unknown;
    return AiEndpointProbe.decode(
      await _storage.read(key: _probeSlotTag(target)),
    );
  }

  /// Records what a probe found. **Only conclusive verdicts are written.**
  ///
  /// An [AiCapability.unknown] result leaves whatever was already known
  /// alone, per capability. Without that, a retry against a sleeping server
  /// would revoke a pass that is still perfectly true: nothing about the
  /// `(endpoint, model)` changed, and the only thing that learned anything
  /// was the network. The rule this store already applies to a wrong
  /// `failed` — it hides a working camera — applies just as much to an
  /// inconclusive one overwriting a good answer.
  ///
  /// A conclusive verdict does overwrite, in both directions, which is what
  /// lets a use-time capability refusal retract a stale pass (#782).
  ///
  /// With nothing conclusive on either side the slot is **deleted** rather
  /// than written as `"--"`, so "we could not tell" and "nobody has asked
  /// yet" really are one state rather than two that merely read alike.
  Future<void> writeProbe(AiEndpointProbe probe, {AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return;

    await _probeConfigurationLock.synchronized(
      () => _writeProbe(probe, target),
    );
  }

  /// Records [probe] only while [endpoint] and [modelId] still identify
  /// [provider]'s current destination.
  ///
  /// The comparison and write share the same lock as [writeEndpoint] and
  /// [writeModel]. Keeping the check here is load-bearing: a request can
  /// finish after settings move, and a check in its caller leaves a window
  /// where the configuration write clears the slot before the stale result
  /// recreates it. The lock makes either ordering safe — an older verdict is
  /// written before the move and then cleared, or observes the move and is
  /// dropped.
  Future<bool> writeProbeIfConfigurationMatches(
    AiEndpointProbe probe, {
    required AiProvider provider,
    required String? endpoint,
    required String? modelId,
  }) => _probeConfigurationLock.synchronized(() async {
    final currentEndpoint = await readEndpoint(provider: provider);
    final currentModel = await readModel(provider: provider);
    if (currentEndpoint != endpoint || currentModel != modelId) return false;

    await _writeProbe(probe, provider);
    return true;
  });

  Future<void> _writeProbe(AiEndpointProbe probe, AiProvider target) async {
    final stored = AiEndpointProbe.decode(
      await _storage.read(key: _probeSlotTag(target)),
    );
    final merged = AiEndpointProbe(
      text: probe.text == AiCapability.unknown ? stored.text : probe.text,
      photo: probe.photo == AiCapability.unknown ? stored.photo : probe.photo,
    );

    if (merged.text == AiCapability.unknown &&
        merged.photo == AiCapability.unknown) {
      await _storage.delete(key: _probeSlotTag(target));
      return;
    }
    await _storage.write(key: _probeSlotTag(target), value: merged.encode());
  }

  /// The stored key for [provider], defaulting to the active one, or null
  /// when none is set. Read at call time rather than cached — nothing should
  /// hold a credential in memory longer than the request that needs it.
  ///
  /// The Anthropic slot falls back to [_legacyApiKeyTag]. That fallback is
  /// the whole migration strategy: nothing is ever copied, so there is no
  /// moment where a credential exists half-moved, and an older build rolled
  /// back onto the same device still finds the key where it expects it.
  Future<String?> readApiKey({AiProvider? provider}) async {
    final target = await _target(provider);
    if (target == null) return null;

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
    final target = await _target(provider);
    if (target == null) return;
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
    final target = await _target(provider);
    if (target == null) return;

    await _probeConfigurationLock.synchronized(() async {
      await _storage.delete(key: _slotTag(target));
      await _storage.delete(key: _endpointSlotTag(target));
      await _storage.delete(key: _modelSlotTag(target));
      await _storage.delete(key: _probeSlotTag(target));
      await _retireLegacyTagFor(target);

      // Only once nothing is left: with two slots, clearing one key is often
      // "I am dropping this provider", not "I am done with the feature". The
      // invariant that matters is narrower — the flag may never be on with no
      // credential behind it at all.
      if (!await _hasAnyKey()) {
        await _storage.delete(key: _enabledTag);
      }
    });
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
  Future<bool> isEnabled() async => (await _readState()).enabled;

  /// Turns the feature off without forgetting the keys, so switching it back
  /// on does not mean finding a credential again. Enabling an **unusable**
  /// provider is a no-op rather than a state the UI would have to explain.
  ///
  /// The guard asks [_isUsable] rather than [hasApiKey], which is the same
  /// generalisation #755 made everywhere else and missed here. A server the
  /// user runs is usable on an address and a model, so the key test made the
  /// pause switch a one-way door: it turned off, and then refused to turn
  /// back on for the one provider whose credential is not a key.
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      final provider = await activeProvider();
      if (provider == null) return;
      if (!_isUsable(
        provider,
        apiKey: await readApiKey(provider: provider),
        endpoint: await readEndpoint(provider: provider),
        modelId: await readModel(provider: provider),
      )) {
        return;
      }
    }
    await _storage.write(key: _enabledTag, value: enabled ? 'true' : 'false');
  }

  /// A fixed-length stand-in for a stored key, for a UI that must never show
  /// the value. Fixed-length on purpose: rendering the real length would
  /// leak which provider's key format is in use.
  static const maskedPlaceholder = '••••••••••••';
}
