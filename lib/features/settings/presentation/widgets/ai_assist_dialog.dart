import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/ai_assist_summary.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/core/utils/ai_model_list_api.dart';
import 'package:opennutritracker/core/utils/plaintext_destination_guard.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_consent_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Where the user chooses a provider, supplies a key for it, picks a model,
/// and pauses or removes any of it.
///
/// **Provider first, everything else beneath it.** The key, the model list
/// and the disclosure all mean different things depending on who is
/// answering, so they are shown as consequences of one choice rather than as
/// four independent settings. Splitting them across separate rows would let
/// a user set a key for a provider they are not using and see nothing wrong.
///
/// The disclosure sits above the field rather than behind a link, because it
/// is the thing that changes what leaves the device: with no key saved the
/// app talks to exactly the destinations the README lists, and saving one
/// adds another. Someone should not have to go looking for that.
///
/// The key is write-only here. Once saved, the field shows a fixed-length
/// mask and never the value — a stored credential should not be readable off
/// a screen someone else can see.
class AiAssistDialog extends StatefulWidget {
  final AiCredentialStorage storage;

  /// Asks a server the user runs what models it has. Injected so a test can
  /// answer without a network, and — more to the point — so a test can assert
  /// that **nothing was asked**: opening this dialog must send no request,
  /// and the only way to pin that is to hand it something that would notice.
  ///
  /// Null builds one over a client this dialog owns and closes.
  final AiModelListApi? modelList;

  /// Starts the setup check and remembers what it found (#780).
  ///
  /// Injected rather than pulled from the locator, matching how [storage]
  /// arrives — and null in the tests that predate the check and do not
  /// exercise it, which is also what keeps them from firing a real request at
  /// `192.168.1.5` the moment they press OK. Null means the section is not
  /// shown at all rather than shown inert: an affordance that cannot act is
  /// worse than none.
  final AiEndpointProbeRunner? probeRunner;

  const AiAssistDialog({
    super.key,
    required this.storage,
    this.modelList,
    this.probeRunner,
  });

  /// Returns true when the stored state changed, so the caller can refresh
  /// its subtitle.
  ///
  /// Not barrier-dismissible: the switch, the provider selector and the
  /// remove button write immediately, so a tap outside would drop the
  /// "something changed" answer on the floor and leave the settings tile
  /// describing the old state. Leaving is via Cancel, which reports honestly.
  static Future<bool> show(
    BuildContext context,
    AiCredentialStorage storage, {
    AiModelListApi? modelList,
    AiEndpointProbeRunner? probeRunner,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AiAssistDialog(
      storage: storage,
      modelList: modelList,
      probeRunner: probeRunner,
    ),
  ).then((changed) => changed ?? false);

  /// The accessibility identifier for a model row.
  ///
  /// A model id is not kebab-case — `anthropic/claude-haiku-4.5` carries a
  /// slash and a dot — and AGENTS.md asks these identifiers to be, so the id
  /// is folded rather than pasted in. Not cosmetic: these are what the adb
  /// verifier matches on, and a slash inside a value it greps and quotes is
  /// a footgun waiting for whoever writes the next driver.
  ///
  /// Public so a test can pin that the curated catalogue folds to distinct
  /// identifiers. Two models colliding here would make the driver tap a row
  /// it was not asked for and report success.
  static String modelIdentifier(String modelId) =>
      'ai-assist-model-${modelId.replaceAll(RegExp('[^a-z0-9]+'), '-')}';

  /// The accessibility identifier for a provider row.
  ///
  /// `AiProvider.name` is Dart-cased, and for three of the four that happens
  /// to be kebab-case already — which is why nothing caught `ownServer`
  /// shipping as `ai-assist-provider-ownServer`. Folded rather than mapped,
  /// so a fifth provider is named right without anyone remembering to.
  ///
  /// Not the same fold as [modelIdentifier]: that one replaces runs of
  /// non-alphanumerics in an already-lowercase id, and applied here it eats
  /// the capital rather than splitting on it — `own-erver`.
  static String providerIdentifier(AiProvider provider) =>
      'ai-assist-provider-'
      '${provider.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '-${m[0]!.toLowerCase()}')}';

  @override
  State<AiAssistDialog> createState() => _AiAssistDialogState();
}

class _AiAssistDialogState extends State<AiAssistDialog> {
  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _modelController = TextEditingController();
  final _scrollController = ScrollController();

  /// Watched so that finishing with the address is a moment the app can act
  /// on. See [_endpointCommitted] for why that moment and no other.
  final _endpointFocus = FocusNode();

  bool _loading = true;
  bool _changed = false;

  AiProvider _provider = AiProvider.anthropic;

  /// A key is really stored, so the field is replaced by a mask.
  bool _hasKey = false;

  /// This provider has what it needs to be used — a key for the hosted three,
  /// an **address** for a server the user runs.
  ///
  /// One flag used to answer both questions, which held only while every
  /// provider's credential was a key. For a server the user runs it made the
  /// dialog say *"Key saved"* over a slot that holds none, and — because the
  /// OK button hangs off it — left the address and model fields rendered,
  /// editable, and with nothing to commit them.
  bool _configured = false;

  bool _enabled = false;
  AiModel? _model = AiModelCatalogue.defaultFor(AiProvider.anthropic);

  /// Set when OK was pressed on something that cannot be stored, and cleared
  /// as soon as the user touches the field again.
  ///
  /// Both refusals are silent failures brought up to where they can be acted
  /// on: an address the request builder cannot parse, and a server with no
  /// model to ask for, each of which used to be accepted here and then throw
  /// two layers down into a catch-all that turned it into "the parser
  /// answered".
  String? _endpointError;
  String? _modelError;

  /// What the server last said it has, or **null when nothing has been
  /// asked** — which is the state this dialog opens in and stays in until the
  /// user asks. An empty list is not the same thing: it means a server
  /// answered and has nothing, and the two get different sentences.
  List<String>? _modelIds;

  /// Why the last ask did not produce a list, or null when it did.
  AiModelListFailure? _modelListFailure;

  /// The host the message is about, frozen at the moment of the ask. Read off
  /// the field instead, a message would rename itself as the user edits the
  /// address underneath it and end up blaming a machine nobody contacted.
  String? _modelListHost;

  bool _fetchingModels = false;

  /// Which model-list request is the current one.
  ///
  /// The same job [_loadGeneration] does for the keystore reads, for the same
  /// reason one level out: a request to a machine on someone's network can
  /// take as long as it likes, and what it answers about is the address that
  /// was in the field when it left — not whatever is there when it lands.
  int _modelsGeneration = 0;

  /// The address the model on screen belongs to: what was stored when the
  /// dialog opened, then whatever was last asked.
  ///
  /// Kept so that "the URL changed" is a question with an answer. Without it
  /// every unfocus of the address field would be a fresh request to a machine
  /// on someone's home network, which is the behaviour #738 ruled out.
  Uri? _lastEndpoint;

  /// Built lazily and only if [AiAssistDialog.modelList] was not supplied, so
  /// a dialog nobody asks for models in never constructs an HTTP client.
  AiModelListApi? _ownedModelList;

  AiModelListApi get _modelList =>
      widget.modelList ?? (_ownedModelList ??= AiModelListApi());

  /// What the setup check last established about this `(endpoint, model)`,
  /// **per capability**. #735: two independent results collapsed into one
  /// sentence cannot express "text works, photos do not", which is the common
  /// case for a small local model.
  AiEndpointProbe _probe = AiEndpointProbe.unknown;

  /// A check is running right now — either one this dialog started, or one a
  /// previous visit started and which is still going. The user is expected to
  /// have left: 66 seconds is longer than anyone waits at a settings screen.
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    // **Deliberately only this.** No fetch here, and none in
    // [_selectProvider]: for the three hosted providers opening AI settings
    // sends nothing anywhere, and the README's promise is about what leaves
    // the device *and when*. A fourth provider whose address is on the user's
    // own LAN does not get to quietly break that from a screen they may have
    // opened to change the theme. #738.
    _load();
    _endpointFocus.addListener(_onEndpointFocusChanged);
  }

  void _onEndpointFocusChanged() {
    if (!_endpointFocus.hasFocus) _endpointCommitted();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _scrollController.dispose();
    // Removed before the node goes, or tearing the dialog down unfocuses the
    // field and the listener answers by calling setState on a dead State.
    _endpointFocus.removeListener(_onEndpointFocusChanged);
    _endpointFocus.dispose();
    _ownedModelList?.close();
    super.dispose();
  }

  /// Which read is the current one.
  ///
  /// Every field below the provider selector is read from the keystore across
  /// four awaits, and a second provider switch can start a second read before
  /// the first has finished. The keystore is a platform channel, so the two
  /// are free to land in either order — and the loser used to win, repainting
  /// the dialog with the provider the user had already moved off.
  int _loadGeneration = 0;

  /// Reads everything for whichever provider is active. Called again after a
  /// provider switch, because every field below the selector belongs to the
  /// provider rather than to the dialog.
  Future<void> _load() async {
    final generation = ++_loadGeneration;
    // Bumped here rather than with the clears below, because the four reads
    // that follow are platform channels and a model list can land while they
    // are still out. Superseding the request at the moment the reload starts
    // is what stops that answer being written at all; done further down it is
    // written first and cleared a frame later, which is the same end state
    // reached the long way round.
    _modelsGeneration++;
    final summary = await widget.storage.readSummary();
    // A stored name this build does not know leaves nothing to select, so the
    // radios fall back to the first provider **for display only**. Nothing is
    // written here — `_load` only reads — so the unrecognised tag survives
    // until the user chooses, and re-upgrading restores what they picked.
    // Meanwhile the feature stays unavailable, because `readSelection()`
    // refuses independently of what this dialog is showing. #753.
    final provider = summary.provider ?? AiProvider.anthropic;
    final modelId = await widget.storage.readModel(provider: provider);
    // Asked separately from `configured`, because for a server the user runs
    // they are different questions and only this one may mask a field.
    final hasKey = summary.provider == null
        ? false
        : await widget.storage.hasApiKey(provider: provider);
    // Read, not run. Opening settings must not start a 66-second request at
    // somebody's server; what lands here is whatever the last check found,
    // which is the whole point of storing it.
    final probe = await widget.storage.readProbe(provider: provider);
    // A check this dialog is too late to have started, from a save the user
    // has already walked away from. Without this it would read "not checked
    // yet" over a request that is in flight, and offer a button that joins it
    // and looks like it did nothing.
    final running = widget.probeRunner?.current(provider);
    // A newer read has started since this one did, and it is reading the
    // provider the user actually chose. Dropping this snapshot loses nothing:
    // the newer one writes every field this one would have.
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _provider = provider;
      _hasKey = hasKey;
      _configured = summary.provider == null ? false : summary.configured;
      _enabled = summary.enabled;
      _model = AiModelCatalogue.resolve(provider, modelId);
      _endpointController.text = summary.endpoint ?? '';
      _modelController.text = modelId ?? '';
      // The stored address counts as already asked-about, so returning to a
      // configured server and leaving the field alone is not a URL change.
      _lastEndpoint = summary.endpoint == null
          ? null
          : AiCredentialStorage.resolveEndpoint(summary.endpoint!);
      // A provider switch reloads through here, so this is also what stops a
      // list fetched from one server being offered as another server's.
      _modelIds = null;
      _modelListFailure = null;
      _modelListHost = null;
      // The other half of the supersede above, and easy to leave out: a
      // request abandoned across the reload no longer turns this off itself,
      // and left set it disables the button for the rest of the dialog's
      // life over an answer nobody wants any more.
      _fetchingModels = false;
      _probe = probe;
      _probing = running != null;
      _loading = false;
    });
    if (running != null) unawaited(_showWhenItLands(provider, running));
  }

  /// Starts a check and shows the answer if the user is still here.
  ///
  /// Nothing is announced when it lands — no snackbar, no dialog reopening.
  /// #735 settled that the user has moved on long before a probe finishes, so
  /// the result has to be *readable when they come back* rather than shouted
  /// at whatever screen they are on by then.
  void _runProbe() {
    final runner = widget.probeRunner;
    if (runner == null) return;
    final provider = _provider;
    setState(() => _probing = true);
    unawaited(
      _showWhenItLands(
        provider,
        runner.start(
          provider,
          localeCode: Localizations.localeOf(context).languageCode,
        ),
      ),
    );
  }

  /// Shows what a check found, **for the provider it was started against**.
  ///
  /// The longest await in this dialog by two orders of magnitude — about 66
  /// seconds — against a selector that takes two taps to move. So a completion
  /// has to prove it still belongs before it writes: [_probe] is a verdict
  /// about one destination, and [_probing] is a claim that *this* provider has
  /// a request outstanding. Neither is true of whoever the user picked in the
  /// meantime.
  ///
  /// Today the section is only rendered for a server the user runs, so a stale
  /// write lands where nothing displays it and `_load` overwrites it on the way
  /// back. That makes this a guard on an invariant rather than a fix for a
  /// visible symptom — which is the moment to add it, not a reason to skip it:
  /// the invariant is what the next reader will assume, and the containment is
  /// a coincidence of the current layout.
  Future<void> _showWhenItLands(
    AiProvider provider,
    Future<AiEndpointProbe> probe,
  ) async {
    final found = await probe;
    if (!mounted || provider != _provider) return;
    setState(() {
      _probe = found;
      _probing = false;
    });
  }

  /// The user has finished with the address field.
  ///
  /// **A URL change is the second of the two moments a fetch may happen**
  /// (#738), because typing an address and moving on is the user unambiguously
  /// pointing the app at that machine. Every other moment — opening the
  /// dialog, switching provider, coming back to a configured server — is
  /// silent, and the guard that keeps it silent is [_lastEndpoint]: unchanged
  /// text asks nothing, however many times focus crosses this field.
  ///
  /// Not on every keystroke, which would send a request to `http://h`,
  /// `http://ht`, and every other prefix of what someone is typing.
  void _endpointCommitted() {
    if (!mounted || _provider != AiProvider.ownServer) return;
    // **Leaving is not an explicit ask.** Tearing this route down takes focus
    // off the address field, and answering that with a request would contact
    // a machine on the user's network at the one moment they cannot see the
    // answer. A route stops being current the moment `pop` is called, which
    // is before it moves focus — so this catches every way out at once:
    // Cancel, OK, and the system back button, which runs no handler of ours
    // at all.
    //
    // One check rather than a flag set on each exit. A flag was tried first
    // and could not see the back button; adding this made every one of its
    // own writes dead, and a fifth exit would have had to remember it.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final resolved = AiCredentialStorage.resolveEndpoint(
      _endpointController.text.trim(),
    );
    if (resolved == null || resolved == _lastEndpoint) return;
    // The model belonged to the address that just changed. #755 drops the
    // stored one on write for the same reason — `llama3.2:8b` is a claim
    // about one machine and says nothing about the next — and this is that
    // rule where the user can see it happen rather than discover it later.
    setState(() {
      _modelController.text = '';
      _modelError = null;
    });
    _loadModels();
  }

  /// Asks the configured server what it has.
  ///
  /// **A picker's contents and nothing else.** `/v1/models` reports an `id`,
  /// and none of the four runtimes flags vision or tool support there — so
  /// appearing in this list says a model exists on that machine and never
  /// that it works for this app. Whether it works is #735's probe, which
  /// finds out by sending a real request.
  Future<void> _loadModels() async {
    final s = S.of(context);
    final typed = _endpointController.text.trim();
    final url = AiCredentialStorage.resolveModelsEndpoint(typed);
    if (url == null) {
      // The same refusal OK gives, on the same field, for the same text.
      setState(() => _endpointError = s.aiAssistEndpointInvalidLabel);
      return;
    }
    final asking = AiCredentialStorage.resolveEndpoint(typed);

    // **One request per address, not one at a time.** Finishing with the
    // address field and pressing the button can land in the same gesture —
    // tapping a control moves focus off the field — and two requests to
    // somebody's server for one act is one too many. That is a statement
    // about *this* address, though, and reading it as "busy" swallowed the
    // next one: typing a second address while the first was still out
    // cleared the model field, sent nothing, and then filled the picker with
    // the first server's models under the second server's address.
    if (_fetchingModels && asking == _lastEndpoint) return;

    final generation = ++_modelsGeneration;
    // Captured for the read below rather than for the guard: a key belongs to
    // the provider that was selected when the request was built, and
    // re-reading `_provider` after an await is how one provider's credential
    // reaches another's endpoint.
    final provider = _provider;

    setState(() {
      _fetchingModels = true;
      _modelIds = null;
      _modelListFailure = null;
      _modelListHost = AiCredentialStorage.displayHost(typed);
      _lastEndpoint = asking;
    });

    // None of the four runtimes wants one by default; a reverse proxy in
    // front of one will. Typed beats stored, so a key entered in this dialog
    // is usable before OK commits it.
    final typedKey = _apiKeyController.text.trim();
    final result = await _modelList.list(
      url,
      apiKey: typedKey.isNotEmpty
          ? typedKey
          : await widget.storage.readApiKey(provider: provider),
    );

    // Dropping this one loses nothing: a newer request writes every field it
    // would have, and a provider switch has already cleared them.
    if (!mounted || generation != _modelsGeneration) return;
    setState(() {
      _fetchingModels = false;
      _modelIds = result.failure == null ? result.ids : null;
      _modelListFailure = result.failure;
    });
  }

  Future<void> _selectProvider(AiProvider provider) async {
    if (provider == _provider) return;
    // Written before the reload so the reload sees the new active provider.
    // Selecting one with no key is allowed: the feature goes quietly
    // unavailable, which is a setting rather than a fault.
    await widget.storage.setActiveProvider(provider);
    _apiKeyController.clear();
    _changed = true;
    await _load();
  }

  /// The write names the provider explicitly, so it always lands in the right
  /// slot. What needed guarding is the *display*: the selected radio is a
  /// statement about whoever is on screen now, and a switch during the write
  /// would leave one provider's model ticked under another's list.
  Future<void> _selectModel(AiModel model) async {
    final provider = _provider;
    await widget.storage.writeModel(model.id, provider: provider);
    if (!mounted || provider != _provider) return;
    setState(() {
      _model = model;
      _changed = true;
    });
  }

  /// Picking from the fetched list fills the field the user could have typed
  /// into, rather than writing straight to the store.
  ///
  /// **One commit point for this provider, and it is OK.** The address is
  /// typed text that commits there (#756), and a model belongs to an address:
  /// writing one against an address that has not been stored yet is exactly
  /// the ordering hazard [AiCredentialStorage.writeOwnServerConfiguration]
  /// exists to prevent — the model would be wiped by the endpoint write that
  /// followed it. It also keeps the picker and the free text as one value
  /// rather than two that can disagree.
  void _pickModel(String id) => setState(() {
    _modelController.text = id;
    _modelError = null;
  });

  Future<void> _save() async {
    final s = S.of(context);
    // Read before the first `await`, because the check below is started after
    // one and `context` may no longer be usable by then.
    final localeCode = Localizations.localeOf(context).languageCode;
    // Captured for the same reason, and it matters more here than anywhere
    // else in this dialog: the radios stay live while these writes are in
    // flight, and re-reading `_provider` after an await is how a typed API key
    // would end up in the slot of a provider the user tapped on the way past.
    final provider = _provider;
    var changed = _changed;

    if (provider == AiProvider.ownServer) {
      // The address is this provider's credential, and the model is part of
      // what "configured" means for it (#738) — so both are saved here, and
      // neither alone turns the feature on.
      final endpoint = _endpointController.text.trim();
      final model = _modelController.text.trim();

      // Asked against the store's own rule rather than a second opinion about
      // what an address is. The store refuses the pair too; the reason to ask
      // again here is that a refusal has to land on a field, and only this
      // side knows which one the user is looking at.
      final resolved = endpoint.isEmpty
          ? null
          : AiCredentialStorage.resolveEndpoint(endpoint);

      // Two empty fields mean different things depending on whether there is
      // anything behind them.
      //
      // On an unconfigured provider it is "I am not setting this up right
      // now" — the same as an empty key field for the hosted three — and
      // erroring would make OK a trap for someone who opened the dialog to
      // read the disclosure.
      //
      // On a **configured** one it is someone clearing the address to get rid
      // of it, and that used to fall straight through this branch: nothing
      // written, dialog closed, row still reading "On — 192.168.1.5:11434".
      // Refused rather than obeyed, because Remove is on screen and is the
      // deliberate way to delete an address, a model and any key together —
      // two paths to a destructive act, one of them a side effect of blanking
      // a text field, is worse than one that says what it does.
      if (endpoint.isNotEmpty || model.isNotEmpty || _configured) {
        final endpointError = resolved == null
            ? s.aiAssistEndpointInvalidLabel
            : _refusedBeforeItLeaves(resolved)
            ? s.aiAssistEndpointPublicPlaintextLabel
            : null;
        final modelError = model.isEmpty ? s.aiAssistModelRequiredLabel : null;
        if (endpointError != null || modelError != null) {
          setState(() {
            _endpointError = endpointError;
            _modelError = modelError;
          });
          return;
        }

        // Everything above this point validates; nothing above it writes.
        // The agreement goes here, between the two, so a refusal leaves the
        // device exactly as it found it.
        if (!await _agreedBeforeAnythingIsStored(provider)) return;

        // One act, and the store's act. The order the two writes have to go
        // in, the both-or-neither rule, and whether any of it differs from
        // what is already stored are all facts about the storage format —
        // this widget knowing them is how the order came to be documented in
        // a comment beside a button.
        if (await widget.storage.writeOwnServerConfiguration(
          endpoint: endpoint,
          model: model,
          provider: provider,
        )) {
          changed = true;
        }

        // **Started, never awaited.** #735: saving succeeds on syntax exactly
        // as it did before this existed, and the check runs behind it — so
        // someone configuring the app on a train, away from their server,
        // saves fine and the camera turns up later once a check has passed
        // against a reachable box. Awaiting it here would make the server's
        // availability a precondition for saving an address, which would also
        // stop them configuring the text path that would have worked.
        //
        // On every valid save rather than only on a changed one. The address
        // and the model can be identical and the machine behind them
        // different — a runtime restarted with another model pulled under the
        // same tag is the ordinary case — and the runner joins a check
        // already running, so pressing OK twice costs nothing.
        final runner = widget.probeRunner;
        if (runner != null) {
          unawaited(runner.start(provider, localeCode: localeCode));
        }
      }
    }

    final typed = _apiKeyController.text.trim();
    if (typed.isNotEmpty) {
      // The own-server branch above has already asked, and asking is
      // idempotent: it returns true without a screen once the agreement is on
      // file, so a server configured with a key does not answer twice.
      if (!await _agreedBeforeAnythingIsStored(provider)) return;
      await widget.storage.writeApiKey(typed, provider: provider);
      changed = true;
    }

    if (!mounted) return;
    Navigator.of(context).pop(changed);
  }

  /// True when the user has agreed to what leaving the device means, asking
  /// them if they have not.
  ///
  /// Called on every path that writes a credential, and only after validation
  /// has passed — a refusal must leave nothing behind, and an invalid address
  /// should be corrected before anyone is asked to agree to sending anything
  /// to it.
  ///
  /// Declining clears the typed key as well as declining to store it. Leaving
  /// it in the field would show a credential the app has not saved, which is
  /// the same lie the dialog already refuses to tell elsewhere.
  Future<bool> _agreedBeforeAnythingIsStored(AiProvider provider) async {
    if (await widget.storage.hasAcceptedTerms()) return true;
    if (!mounted) return false;

    final agreed = await AiConsentScreen.show(
      context,
      provider: provider,
      typedEndpoint: _endpointController.text,
    );
    if (!agreed) {
      if (mounted) _apiKeyController.clear();
      return false;
    }
    // Written only once the answer is yes, so a dismissed screen leaves no
    // trace of having been shown.
    await widget.storage.setTermsAccepted(true);
    return true;
  }

  /// Already safe, and worth saying so: `_provider` is read to build the call
  /// rather than after it, so the destructive act names the provider the user
  /// was looking at when they pressed it. Everything this writes afterwards
  /// goes through [_load], which carries its own guard.
  Future<void> _remove() async {
    await widget.storage.clear(provider: _provider);
    if (!mounted) return;
    _apiKeyController.clear();
    _changed = true;
    await _load();
  }

  /// The flag itself is not per provider, so the *write* is safe whoever is
  /// selected. The read-back is not: `isEnabled` is false for a provider with
  /// nothing configured, so a switch landing between the two turns this into
  /// one provider's answer painted onto another's switch.
  Future<void> _setEnabled(bool value) async {
    final provider = _provider;
    await widget.storage.setEnabled(value);
    final enabled = await widget.storage.isEnabled();
    if (!mounted || provider != _provider) return;
    setState(() {
      _enabled = enabled;
      _changed = true;
    });
  }

  /// Whether every request to [resolved] will be refused before it leaves the
  /// phone, and the user can be told that now rather than after saving.
  ///
  /// **Ergonomics only.** The guarantee is [PlaintextDestinationGuard], which
  /// refuses per request, resolves names, and pins the connection to the
  /// address it approved — #758 shipped that and nothing here weakens or
  /// duplicates it. What this adds is that a literal address needs no lookup
  /// to judge, so the one refusal that *can* be shown at save time is, instead
  /// of storing a configuration the user only discovers is dead when their
  /// meals come back from the offline parser forever.
  ///
  /// Literals only, deliberately. A name is what DNS says today, which is a
  /// question with a network round trip in it, and #735's whole rule is that
  /// saving never waits on the network. `http://ollama.lan` is saved, and the
  /// guard refuses it per request if it turns out to point somewhere public.
  bool _refusedBeforeItLeaves(Uri resolved) {
    if (resolved.scheme != 'http') return false;
    final literal = InternetAddress.tryParse(resolved.host);
    return literal != null && !isPrivateDestination(literal);
  }

  String _providerName(BuildContext context, AiProvider provider) =>
      switch (provider) {
    // Brand names, deliberately not localized.
    AiProvider.anthropic => 'Anthropic',
    AiProvider.openrouter => 'OpenRouter',
    AiProvider.openai => 'OpenAI',
    // The only one that is not a brand, so the only one that is localized.
    // **Never "local"**: that word is simultaneously what the ecosystem calls
    // Ollama and what a user reads as *on my phone* — the claim reserved for
    // on-device inference, which this app does not do. #736.
    AiProvider.ownServer => S.of(context).aiAssistProviderOwnServerLabel,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      // The Experimental marker is deliberately *not* appended here. At a 2x
      // text scale on a 320px phone it makes this title tall enough to squeeze
      // the content area and overflow the dialog by 48px — the bound the
      // model-row test pins. Nothing is lost: the tile that opens this dialog
      // carries the badge, and the note below states what it means.
      title: Text(s.settingsAiAssistLabel),
      content: _loading
          ? const SizedBox(
              height: 64,
              child: Center(child: CircularProgressIndicator()),
            )
          // The content is taller than a phone dialog and cannot be made to
          // fit: the OpenRouter disclosure alone runs past the fold, and
          // every sentence in it is load-bearing. So rather than pretend,
          // show the scrollbar permanently. Without it the last paragraph
          // is clipped mid-word against the bottom edge and reads as the
          // end of the text.
          : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                // The thumb is drawn over the content, so the text needs a
                // gutter or it is clipped by the very affordance added to
                // stop it being clipped.
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(theme, s.aiAssistProviderLabel),
                    // Per-tile groupValue/onChanged rather than a RadioGroup
                    // ancestor, matching CaloriesProfileInfoDialog: inside a
                    // dialog the ancestor form does not reliably propagate
                    // taps to RadioListTile children, and the bug it produced
                    // there was a selection that silently stayed on its
                    // initial value. Deprecated, and still the form that works
                    // here.
                    ...AiProvider.values.map(
                      (provider) => Semantics(
                        identifier: AiAssistDialog.providerIdentifier(provider),
                        // ignore: deprecated_member_use
                        child: RadioListTile<AiProvider>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(_providerName(context, provider)),
                          value: provider,
                          // ignore: deprecated_member_use
                          groupValue: _provider,
                          // ignore: deprecated_member_use
                          onChanged: (value) =>
                              value == null ? null : _selectProvider(value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_provider == AiProvider.ownServer) ...[
                      _label(theme, s.aiAssistEndpointFieldLabel),
                      Semantics(
                        identifier: 'ai-assist-endpoint-field',
                        child: TextField(
                          controller: _endpointController,
                          focusNode: _endpointFocus,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          // Finishing with the address is the second of the
                          // two moments a fetch may happen (#738). The focus
                          // node covers moving on to another field; this
                          // covers the keyboard's own done key, which never
                          // moves focus anywhere.
                          onSubmitted: (_) => _endpointCommitted(),
                          decoration: InputDecoration(
                            labelText: s.aiAssistEndpointFieldLabel,
                            // A base address, which the store completes to
                            // the chat route the runtimes actually answer on.
                            hintText: 'http://192.168.1.5:11434',
                            errorText: _endpointError,
                            border: const OutlineInputBorder(),
                          ),
                          // The disclosure below names this host and derives
                          // its encryption clause from the scheme, so it has
                          // to follow the field as it is typed. A refusal
                          // clears with the same keystroke, because it was
                          // about text that no longer exists.
                          onChanged: (_) =>
                              setState(() => _endpointError = null),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // The credential block sits above the disclosure, which
                    // reverses what this dialog originally did. On a Pixel 6
                    // the other way round put the key field *entirely below
                    // the fold* on the OpenRouter path: the disclosure there
                    // is three sentences longer, and the dialog ended with a
                    // paragraph cut off mid-word and no scroll affordance. A
                    // first-time user saw a wall of text and an OK button and
                    // no way to enter anything.
                    //
                    // The original reasoning — that the disclosure must not be
                    // behind a link, because saving a key adds a destination —
                    // survives this. It is still in the dialog, unavoidable,
                    // and still above the OK button, which is the act that
                    // actually enables the feature. What it is no longer above
                    // is a text field the user could not see.
                    //
                    // Keyed on **whether a key is stored**, which is not the
                    // same question as whether the provider is usable. A
                    // server the user runs is usable on an address alone, and
                    // its key stays optional afterwards — so the field has to
                    // remain reachable there rather than being replaced by a
                    // mask over an empty slot.
                    if (_hasKey)
                      Row(
                        children: [
                          const Icon(Icons.key_rounded, size: 18),
                          const SizedBox(width: 8),
                          // Flex-constrained per AGENTS.md: "Ключ збережено"
                          // and a large system font both run much wider than
                          // the English label.
                          Expanded(
                            child: Text(
                              '${s.aiAssistKeySavedLabel}  '
                              '${AiCredentialStorage.maskedPlaceholder}',
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Text(
                        s.aiAssistNoKeyForProviderLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        identifier: 'ai-assist-key-field',
                        child: TextField(
                          controller: _apiKeyController,
                          autocorrect: false,
                          enableSuggestions: false,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: s.aiAssistKeyFieldLabel(
                              _providerName(context, _provider),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                    // Pausing and removing act on the provider as a whole, so
                    // they follow "is it usable" rather than "is there a key".
                    // Identical for the hosted three, where the two are the
                    // same fact.
                    if (_configured) ...[
                      Semantics(
                        identifier: 'ai-assist-enabled',
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.settingsAiAssistEnabledLabel),
                          value: _enabled,
                          onChanged: _setEnabled,
                        ),
                      ),
                      Semantics(
                        identifier: 'ai-assist-remove-key',
                        child: TextButton.icon(
                          onPressed: _remove,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(s.aiAssistRemoveKeyLabel),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // **Model below the credential**, which is new and is a
                    // fix rather than a preference. A fourth provider added a
                    // radio row and pushed the key field 17.7dp below the
                    // fold on a Pixel 6 — the same defect the "key field is
                    // on screen" test above was written for, returning for a
                    // different reason. The credential is what this dialog
                    // exists for, so it sits directly under the choice of who
                    // to send to; picking a model is the step after deciding
                    // you can talk to them at all.
                    _buildModelSection(context, s, theme),
                    // Directly under the pair it is a fact about. A stored
                    // verdict describes `(endpoint, model)` and is discarded
                    // when either changes, so reading it anywhere further from
                    // those two fields would invite it to be read as a
                    // property of the provider.
                    //
                    // Only for a server the user runs. The other three were
                    // screened behaviourally over live calls before they were
                    // ever offered (#735), so there is nothing here a check
                    // would establish that the curated list does not already
                    // carry — and an inert "not checked yet" on the Anthropic
                    // path would imply otherwise.
                    if (_provider == AiProvider.ownServer && _configured) ...[
                      const SizedBox(height: 16),
                      _buildProbeSection(s, theme),
                    ],
                    const SizedBox(height: 16),
                    // Provider paragraph first — it names the destination,
                    // which is the fact that changes — then the sentences that
                    // are true whichever provider is chosen.
                    Text(
                      '${aiDisclosureFor(s, provider: _provider, typedEndpoint: _endpointController.text)}\n\n${s.aiAssistDisclosureCommon}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    // What the badge in the title means, spelled out once
                    // where the user is deciding whether to turn this on. It
                    // is a statement about the feature's stability, not about
                    // the model's accuracy — that caution already appears
                    // above the rows a model produced, where it can be acted
                    // on.
                    Text(
                      s.aiAssistExperimentalNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_changed),
          child: Text(s.dialogCancelLabel),
        ),
        // Offered whenever something on screen can still be typed into. For
        // the hosted three that is exactly "before a key exists", which is
        // what this used to say. A server the user runs keeps an address and
        // a model name editable for as long as the dialog is open, and
        // hanging OK off the credential left both fields rendered with no way
        // to commit a change — the only exit was Remove, which discards the
        // address as well.
        if (!_loading && (!_hasKey || _provider == AiProvider.ownServer))
          Semantics(
            identifier: 'ai-assist-save-key',
            child: TextButton(onPressed: _save, child: Text(s.dialogOKLabel)),
          ),
      ],
    );
  }

  /// What the row below the default says.
  ///
  /// OpenRouter's second entry genuinely is cheaper and weaker — #668
  /// measured haiku at 12/16 against sonnet's 16/16 on hard photos, at half
  /// the price. **OpenAI's is neither.** #686 measured no price at all and no
  /// quality gap between luna and terra; the one difference it did find is
  /// that terra splits a plate into more rows. Reusing the cheaper label here
  /// would assert two things nobody measured, in nine languages.
  ///
  /// Anthropic never reaches this: a single-entry list has no second row.
  /// Keyed on the model, not on the provider it is reached through.
  ///
  /// It used to be the latter, which held only while every list was two
  /// entries differing the same way. The OpenRouter list is four, and the
  /// per-provider string reached `openai/gpt-5.6-terra` claiming it was
  /// cheaper — it matches `claude-sonnet-5` on input and is dearer on output.
  /// #726.
  String _noteLabel(S s, AiModelNote note) => switch (note) {
    AiModelNote.cheaper => s.aiAssistModelCheaperLabel,
    AiModelNote.moreItems => s.aiAssistModelMoreItemsLabel,
    AiModelNote.cheapest => s.aiAssistModelCheapestLabel,
  };

  /// What to say about the last ask, or null when there is nothing to say —
  /// nothing asked yet, or a list came back with something in it.
  ///
  /// **Four outcomes, four sentences, and the point is that they differ.** An
  /// unreachable server and a server with nothing pulled produce the same
  /// empty picker and want opposite fixes: wake the machine, or pull a model.
  /// A message that covered both with "no models found" would send half its
  /// readers to the wrong place. The app refusing to send is a third thing
  /// again — the server was never contacted and may be perfectly healthy —
  /// and something answering with a 404 is a fourth.
  ///
  /// Every one of them ends by pointing at the field above, because none of
  /// them stops the user configuring this provider.
  String? _modelListMessage(S s) {
    final host = _modelListHost ?? '';
    return switch (_modelListFailure) {
      AiModelListFailure.unreachable => s.aiAssistModelsUnreachableLabel(host),
      AiModelListFailure.insecureDestination => s.aiAssistModelsInsecureLabel,
      AiModelListFailure.rejected => s.aiAssistModelsRejectedLabel(host),
      // A list did come back. Only its being empty is worth a sentence — a
      // list with entries in it speaks for itself, in the picker below.
      null => _modelIds != null && _modelIds!.isEmpty
          ? s.aiAssistModelsEmptyLabel(host)
          : null,
    };
  }

  /// What the setup check found, **one row per capability**.
  ///
  /// #735 settled that this reports per capability rather than as one combined
  /// verdict, and the reason is not tidiness: "text works, photos do not" is
  /// the common case for a small local model, and one sentence cannot say it.
  /// It is also the only place a hidden camera becomes explainable rather than
  /// mysterious, and the only home the text-path warning has — the alternative
  /// is the silent-parser-forever trap this project has already been bitten
  /// by, where a mistyped key produced a plausible screen of parser rows on a
  /// Pixel 6 and no indication whatsoever outside `adb logcat`.
  Widget _buildProbeSection(S s, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(theme, s.aiAssistProbeSectionLabel),
      if (_probing)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          // Words rather than a spinner. A progress indicator promises
          // something worth waiting for, and this is measured at about 66
          // seconds against a cold Ollama — 29s text, 37s photo — so the
          // honest affordance says how long it takes and that leaving is
          // fine.
          child: Text(
            s.aiAssistProbeRunningLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      _probeRow(
        theme,
        s.aiAssistProbeTextLabel,
        _probe.text,
        // A failed text check is **reported and disables nothing.** The
        // deterministic parser still produces the rows, one sample line is
        // thin evidence about a real meal, and taking the feature away over
        // it would remove something that costs nothing. #735.
        switch (_probe.text) {
          AiCapability.passed => s.aiAssistProbePassedLabel,
          AiCapability.failed => s.aiAssistProbeTextFailedLabel,
          AiCapability.unknown => s.aiAssistProbeUnknownLabel,
        },
      ),
      _probeRow(
        theme,
        s.aiAssistProbePhotoLabel,
        _probe.photo,
        // The asymmetric half: a failed photo check hides the camera, because
        // there is nothing underneath it the way the parser is underneath the
        // text path, and offering a dead end is worse than not offering it.
        switch (_probe.photo) {
          AiCapability.passed => s.aiAssistProbePassedLabel,
          AiCapability.failed => s.aiAssistProbePhotoFailedLabel,
          AiCapability.unknown => s.aiAssistProbeUnknownLabel,
        },
      ),
      // Offered while the feature is on, and not while it is paused: paused
      // means nothing is sent, and a check is a request like any other. The
      // switch is directly above, so the way to get the button back is on
      // screen.
      if (widget.probeRunner != null && _enabled)
        Semantics(
          identifier: 'ai-assist-probe-run',
          child: TextButton.icon(
            // Disabled only while one is running. Re-running from here
            // updates what is shown **without a re-save**, which is what
            // makes an unreachable server a state the user can act on rather
            // than a verdict they are stuck with.
            onPressed: _probing ? null : _runProbe,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.aiAssistProbeCheckLabel),
          ),
        ),
    ],
  );

  /// One capability, its verdict, and what that verdict means for the user.
  ///
  /// Name above status rather than `"$name: $status"`. The separator would be
  /// a punctuation mark chosen in English and pasted into nine locales — `：`
  /// in Chinese, spaced differently in French-influenced typography — for a
  /// join the layout already expresses.
  Widget _probeRow(
    ThemeData theme,
    String name,
    AiCapability capability,
    String status,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          // **Never `failed`'s icon for `unknown`.** "We have not asked" and
          // "we asked and it cannot" are different states, and the first is
          // not an error: nothing went wrong, there is nothing to dismiss,
          // and the answer is the button below rather than a fix.
          switch (capability) {
            AiCapability.passed => Icons.check_circle_outline_rounded,
            AiCapability.failed => Icons.error_outline_rounded,
            AiCapability.unknown => Icons.help_outline_rounded,
          },
          size: 18,
          color: switch (capability) {
            AiCapability.passed => theme.colorScheme.primary,
            AiCapability.failed => theme.colorScheme.error,
            AiCapability.unknown => theme.colorScheme.onSurfaceVariant,
          },
        ),
        const SizedBox(width: 8),
        // Flex-constrained per AGENTS.md. The status sentences are the
        // longest strings this dialog renders after the disclosure, and this
        // row sits beside a fixed-width icon.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  /// The model list, or a single stated model where there is no choice.
  ///
  /// The direct path offers one model and says so rather than rendering a
  /// list of one, which would imply a choice that does not exist. Either way
  /// the serving vendor is named here — beside the model — rather than on
  /// every batch, because a curated entry is pinned and so the vendor is
  /// guaranteed rather than likely.
  ///
  /// When every model on the list is served by the same vendor, that is said
  /// once for the group instead of repeated on each row. Repeating it cost
  /// two wrapped lines in German and pushed the disclosure further past the
  /// fold, for a fact that did not change between the rows.
  ///
  /// This comment used to add that the shared-vendor case was "while #656
  /// holds, the only case there can be". #679 reversed #656, and #726 put two
  /// OpenAI-served entries on the OpenRouter list — so the per-row branch
  /// below is reachable in production for the first time, and the grouped
  /// line is now the special case rather than the rule.
  Widget _buildModelSection(BuildContext context, S s, ThemeData theme) {
    final models = AiModelCatalogue.forProvider(_provider);
    if (models.isEmpty) {
      // No curated list, so nothing measured to say about what the user
      // pulled. #738: no *Recommended*, no row notes, and no `servedBy` —
      // that line asserts a guarantee about a third party, and the whole
      // point here is that there is not one.
      //
      // **The field comes first and never goes away.** #757 adds a fetch, and
      // the fetch has a real failure mode — settings opened while the server
      // is asleep, on another network, or behind a VPN that is off. A dialog
      // that could only offer what it can reach would be unconfigurable
      // exactly when someone is setting it up ahead of time, so the list
      // fills this field in rather than replacing it: one value, typed or
      // picked, and the picker is an input method for it rather than a rival.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(theme, s.aiAssistModelLabel),
          Semantics(
            identifier: 'ai-assist-model-field',
            child: TextField(
              controller: _modelController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: s.aiAssistModelFieldLabel,
                hintText: 'gemma3:4b',
                errorText: _modelError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _modelError = null),
            ),
          ),
          // The **only** control that starts a fetch, alongside finishing with
          // the address field. Never on open, never on a provider switch,
          // never on a timer. #738.
          Semantics(
            identifier: 'ai-assist-load-models',
            child: TextButton.icon(
              onPressed: _fetchingModels ? null : _loadModels,
              // The spinner replaces the icon rather than sitting beside it,
              // so waiting does not add a widget to a Row that already has to
              // survive 2x German on a 320px phone.
              icon: _fetchingModels
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(s.aiAssistLoadModelsLabel),
            ),
          ),
          if (_modelListMessage(s) case final message?)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          // A **dropdown**, not a row per model: an Ollama host with twenty
          // pulled models would otherwise push the disclosure and the OK
          // button off a phone screen, and this dialog has already overflowed
          // once for less. One entry is an ordinary list here rather than a
          // special case — llama.cpp serves exactly the one file it was
          // started with, so a single-element reply is the normal shape and
          // gets the ordinary picker.
          if (_modelIds case final ids? when ids.isNotEmpty)
            Semantics(
              identifier: 'ai-assist-model-picker',
              child: DropdownButton<String>(
                // Long ids ellipsize instead of overflowing the dialog.
                isExpanded: true,
                hint: Text(s.aiAssistPickModelLabel),
                // Null rather than a guess when the field holds something the
                // server did not offer: a typed id is still a valid answer,
                // and `DropdownButton` asserts on a value that is not in its
                // items.
                value: ids.contains(_modelController.text)
                    ? _modelController.text
                    : null,
                items: [
                  for (final id in ids)
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        id,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => id == null ? null : _pickModel(id),
              ),
            ),
        ],
      );
    }
    final single = models.length == 1;
    final vendors = {for (final m in models) m.servedBy};
    final sharedVendor = vendors.length == 1 ? vendors.single : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, s.aiAssistModelLabel),
        if (!single && sharedVendor != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              s.aiAssistServedByLabel(sharedVendor),
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (single)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${models.single.id} — '
              '${s.aiAssistServedByLabel(models.single.servedBy)}',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...models.map(
            // Same deprecated-but-working form as the provider radios above.
            (model) => Semantics(
              identifier: AiAssistDialog.modelIdentifier(model.id),
              // ignore: deprecated_member_use
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                // Reclaimed from the gap between the radio and the text, all
                // of it. The title is a model id; the longest wants 228dp on
                // a Pixel 6 and the default gap leaves it 215.4, so the row
                // showed `claude-haiku-4.…` for want of thirteen points.
                // Radio draws its own padding, so the gap was buying nothing
                // the eye can see, and the id is the one thing in this row
                // the user has to be able to read.
                horizontalTitleGap: 0,
                // Two lines, not the usual one, and the id keeps its vendor
                // prefix — both for the same measured reason. `/` is the
                // only line-break opportunity a model id has: on its own,
                // `claude-sonnet-5` reports an identical 423.75 for minimum
                // and maximum intrinsic width, meaning nothing in it can
                // break. Shortening the title to it would look like it was
                // buying room and would instead remove the only place the
                // text can wrap, so a one-line bound would ellipsize
                // `anthropic/claude-…` — and the curated ids differ only
                // after that point, leaving two rows reading the same.
                //
                // `AutoSizeText`, which AGENTS.md would prefer for a title
                // like this, is not available: it builds a `LayoutBuilder`,
                // the dialog asks this row for an intrinsic height, and
                // `LayoutBuilder` throws rather than answering one.
                title: Text(
                  model.id,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (sharedVendor == null)
                      s.aiAssistServedByLabel(model.servedBy),
                    if (model.id == models.first.id)
                      s.aiAssistModelRecommendedLabel
                    else if (model.note case final note?)
                      _noteLabel(s, note),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                value: model.id,
                // ignore: deprecated_member_use
                groupValue: _model?.id,
                // ignore: deprecated_member_use
                onChanged: (value) => value == null
                    ? null
                    : _selectModel(models.firstWhere((m) => m.id == value)),
              ),
            ),
          ),
      ],
    );
  }
}
