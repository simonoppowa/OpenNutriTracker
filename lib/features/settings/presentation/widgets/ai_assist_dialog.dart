import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
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

  const AiAssistDialog({super.key, required this.storage});

  /// Returns true when the stored state changed, so the caller can refresh
  /// its subtitle.
  ///
  /// Not barrier-dismissible: the switch, the provider selector and the
  /// remove button write immediately, so a tap outside would drop the
  /// "something changed" answer on the floor and leave the settings tile
  /// describing the old state. Leaving is via Cancel, which reports honestly.
  static Future<bool> show(BuildContext context, AiCredentialStorage storage) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AiAssistDialog(storage: storage),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Reads everything for whichever provider is active. Called again after a
  /// provider switch, because every field below the selector belongs to the
  /// provider rather than to the dialog.
  Future<void> _load() async {
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
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _hasKey = hasKey;
      _configured = summary.provider == null ? false : summary.configured;
      _enabled = summary.enabled;
      _model = AiModelCatalogue.resolve(provider, modelId);
      _endpointController.text = summary.endpoint ?? '';
      _modelController.text = modelId ?? '';
      _loading = false;
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

  Future<void> _selectModel(AiModel model) async {
    await widget.storage.writeModel(model.id, provider: _provider);
    if (!mounted) return;
    setState(() {
      _model = model;
      _changed = true;
    });
  }

  Future<void> _save() async {
    final s = S.of(context);
    var changed = _changed;

    if (_provider == AiProvider.ownServer) {
      // The address is this provider's credential, and the model is part of
      // what "configured" means for it (#738) — so both are saved here, and
      // neither alone turns the feature on.
      final endpoint = _endpointController.text.trim();
      final model = _modelController.text.trim();

      // Checked against the store's own rule rather than a second opinion
      // about what an address is, and checked *before* either is written, so
      // a rejected pair never leaves the provider half-configured.
      final resolved = endpoint.isEmpty
          ? null
          : AiCredentialStorage.resolveEndpoint(endpoint);

      // Nothing typed at all is not an error. It is the same "I am not
      // setting this up right now" that an empty key field means for the
      // hosted three, and the provider is already selected either way.
      if (endpoint.isNotEmpty || model.isNotEmpty) {
        if (resolved == null || model.isEmpty) {
          setState(() {
            _endpointError = resolved == null
                ? s.aiAssistEndpointInvalidLabel
                : null;
            _modelError = model.isEmpty ? s.aiAssistModelRequiredLabel : null;
          });
          return;
        }

        // Compared in its **resolved** form, which is what the store holds:
        // the address as typed is a base and the stored one carries the chat
        // route, so comparing the raw text would call every unchanged address
        // a change. That matters because OK now sits beside the pause switch
        // and `writeEndpoint` reads an address as asking for the feature —
        // re-saving an untouched setting would undo a pause made seconds
        // earlier.
        final stored = await widget.storage.readEndpoint(provider: _provider);
        if (resolved.toString() != stored) {
          await widget.storage.writeEndpoint(endpoint, provider: _provider);
          changed = true;
        }
        // After the address, never before: writing a *changed* address
        // forgets the stored model (#755), so the order is what keeps an edit
        // to both from wiping the half it just saved. Read back rather than
        // compared to what was loaded, for the same reason.
        if (model != await widget.storage.readModel(provider: _provider)) {
          await widget.storage.writeModel(model, provider: _provider);
          changed = true;
        }
      }
    }

    final typed = _apiKeyController.text.trim();
    if (typed.isNotEmpty) {
      await widget.storage.writeApiKey(typed, provider: _provider);
      changed = true;
    }

    if (!mounted) return;
    Navigator.of(context).pop(changed);
  }

  Future<void> _remove() async {
    await widget.storage.clear(provider: _provider);
    if (!mounted) return;
    _apiKeyController.clear();
    _changed = true;
    await _load();
  }

  Future<void> _setEnabled(bool value) async {
    await widget.storage.setEnabled(value);
    final enabled = await widget.storage.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _changed = true;
    });
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
                          keyboardType: TextInputType.url,
                          autocorrect: false,
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
                    const SizedBox(height: 16),
                    // Provider paragraph first — it names the destination,
                    // which is the fact that changes — then the sentences that
                    // are true whichever provider is chosen.
                    Text(
                      '${_disclosureFor(s)}\n\n${s.aiAssistDisclosureCommon}',
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

  String _disclosureFor(S s) => switch (_provider) {
    AiProvider.anthropic => s.aiAssistDisclosureAnthropic,
    AiProvider.openrouter => s.aiAssistDisclosureOpenRouter,
    AiProvider.openai => s.aiAssistDisclosureOpenAI,
    // Named host, and an encryption clause derived from the scheme rather
    // than guessed. #736: "sent to the server you configured" is not
    // checkable at the moment a user is agreeing to it, where
    // `sent to 192.168.1.5:11434` is verifiable on sight — and it catches a
    // stale address pointing somewhere they had forgotten.
    AiProvider.ownServer => _ownServerDisclosure(s),
  };

  /// Empty while no address is stored: there is no destination to name yet,
  /// and a sentence naming nothing would be worse than none.
  String _ownServerDisclosure(S s) {
    final typed = _endpointController.text.trim();
    if (typed.isEmpty) return '';
    final host = Uri.tryParse(typed)?.authority;
    final display = (host == null || host.isEmpty) ? typed : host;
    // `https` is permitted anywhere; plain `http` only reaches here for a
    // private address (#758), and this is the only place the user can learn
    // which of the two their own address is.
    return Uri.tryParse(typed)?.scheme == 'https'
        ? s.aiAssistDisclosureOwnServerSecure(display)
        : s.aiAssistDisclosureOwnServerPlaintext(display);
  }

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
      // No curated list, so nothing to pick from and nothing measured to say
      // about what the user pulled. #738: no *Recommended*, no row notes, and
      // no `servedBy` — that line asserts a guarantee about a third party,
      // and the whole point here is that there is not one. #757 adds a fetch
      // from the server; typing the name is what works until then.
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
