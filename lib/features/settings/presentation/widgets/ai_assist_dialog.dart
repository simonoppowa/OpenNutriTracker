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

  @override
  State<AiAssistDialog> createState() => _AiAssistDialogState();
}

class _AiAssistDialogState extends State<AiAssistDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _changed = false;

  AiProvider _provider = AiProvider.anthropic;
  bool _hasKey = false;
  bool _enabled = false;
  late AiModel _model = AiModelCatalogue.defaultFor(_provider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Reads everything for whichever provider is active. Called again after a
  /// provider switch, because every field below the selector belongs to the
  /// provider rather than to the dialog.
  Future<void> _load() async {
    final provider = await widget.storage.activeProvider();
    final hasKey = await widget.storage.hasApiKey(provider: provider);
    final enabled = await widget.storage.isEnabled();
    final modelId = await widget.storage.readModel(provider: provider);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _hasKey = hasKey;
      _enabled = enabled;
      _model = AiModelCatalogue.resolve(provider, modelId);
      _loading = false;
    });
  }

  Future<void> _selectProvider(AiProvider provider) async {
    if (provider == _provider) return;
    // Written before the reload so the reload sees the new active provider.
    // Selecting one with no key is allowed: the feature goes quietly
    // unavailable, which is a setting rather than a fault.
    await widget.storage.setActiveProvider(provider);
    _controller.clear();
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
    final typed = _controller.text.trim();
    if (typed.isEmpty) {
      Navigator.of(context).pop(_changed);
      return;
    }
    await widget.storage.writeApiKey(typed, provider: _provider);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    await widget.storage.clear(provider: _provider);
    if (!mounted) return;
    _controller.clear();
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

  String _providerName(AiProvider provider) => switch (provider) {
    // Brand names, deliberately not localized.
    AiProvider.anthropic => 'Anthropic',
    AiProvider.openrouter => 'OpenRouter',
    AiProvider.openai => 'OpenAI',
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
                        identifier: 'ai-assist-provider-${provider.name}',
                        // ignore: deprecated_member_use
                        child: RadioListTile<AiProvider>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(_providerName(provider)),
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
                    _buildModelSection(context, s, theme),
                    const SizedBox(height: 12),
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
                    if (_hasKey) ...[
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
                      ),
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
                    ] else ...[
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
                          controller: _controller,
                          autocorrect: false,
                          enableSuggestions: false,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: s.aiAssistKeyFieldLabel(
                              _providerName(_provider),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
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
        if (!_hasKey && !_loading)
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
  String _alternativeLabel(S s) => switch (_provider) {
    AiProvider.openai => s.aiAssistModelMoreItemsLabel,
    AiProvider.anthropic || AiProvider.openrouter => s.aiAssistModelCheaperLabel,
  };

  String _disclosureFor(S s) => switch (_provider) {
    AiProvider.anthropic => s.aiAssistDisclosureAnthropic,
    AiProvider.openrouter => s.aiAssistDisclosureOpenRouter,
    AiProvider.openai => s.aiAssistDisclosureOpenAI,
  };

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
  /// When every model on the list is served by the same vendor — which is
  /// the case today and, while #656 holds, the only case there can be — that
  /// is said once for the group instead of repeated on each row. Repeating
  /// it cost two wrapped lines in German and pushed the disclosure further
  /// past the fold, for a fact that did not change between the rows.
  Widget _buildModelSection(BuildContext context, S s, ThemeData theme) {
    final models = AiModelCatalogue.forProvider(_provider);
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
                    model.id == models.first.id
                        ? s.aiAssistModelRecommendedLabel
                        : _alternativeLabel(s),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                value: model.id,
                // ignore: deprecated_member_use
                groupValue: _model.id,
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
