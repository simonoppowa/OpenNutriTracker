import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Where the user supplies, pauses and removes their own model-provider key.
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
  /// Not barrier-dismissible: the switch and the remove button write
  /// immediately, so a tap outside would drop the "something changed" answer
  /// on the floor and leave the settings tile describing the old state.
  /// Leaving is via Cancel, which reports honestly.
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
  bool _hasKey = false;
  bool _enabled = false;
  bool _changed = false;

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

  Future<void> _load() async {
    final hasKey = await widget.storage.hasApiKey();
    final enabled = await widget.storage.isEnabled();
    if (!mounted) return;
    setState(() {
      _hasKey = hasKey;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final typed = _controller.text.trim();
    if (typed.isEmpty) {
      Navigator.of(context).pop(_changed);
      return;
    }
    await widget.storage.writeApiKey(typed);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    await widget.storage.clear();
    if (!mounted) return;
    setState(() {
      _hasKey = false;
      _enabled = false;
      _changed = true;
      _controller.clear();
    });
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
                  Text(
                    s.aiAssistDisclosureLabel,
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
                  ] else
                    Semantics(
                      identifier: 'ai-assist-key-field',
                      child: TextField(
                        controller: _controller,
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: s.aiAssistKeyFieldLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
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
}
