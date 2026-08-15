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

  @override
  State<AiAssistDialog> createState() => _AiAssistDialogState();
}

class _AiAssistDialogState extends State<AiAssistDialog> {
  final _controller = TextEditingController();

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
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(s.settingsAiAssistLabel),
      content: _loading
          ? const SizedBox(
              height: 64,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
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
                  // Provider paragraph first — it names the destination,
                  // which is the fact that changes — then the sentences that
                  // are true whichever provider is chosen.
                  Text(
                    '${_disclosureFor(s)}\n\n${s.aiAssistDisclosureCommon}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
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
                ],
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

  String _disclosureFor(S s) => switch (_provider) {
    AiProvider.anthropic => s.aiAssistDisclosureAnthropic,
    AiProvider.openrouter => s.aiAssistDisclosureOpenRouter,
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
  /// the serving vendor is named here — once, beside the model — rather than
  /// on every batch, because a curated entry is pinned and so the vendor is
  /// guaranteed rather than likely.
  Widget _buildModelSection(BuildContext context, S s, ThemeData theme) {
    final models = AiModelCatalogue.forProvider(_provider);
    final single = models.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(theme, s.aiAssistModelLabel),
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
              identifier: 'ai-assist-model-${model.id}',
              // ignore: deprecated_member_use
              child: RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(model.id, style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  '${s.aiAssistServedByLabel(model.servedBy)} · '
                  '${model.id == models.first.id ? s.aiAssistModelRecommendedLabel : s.aiAssistModelCheaperLabel}',
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
