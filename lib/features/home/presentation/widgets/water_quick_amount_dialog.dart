import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/features/home/domain/water_quick_amount.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Sets the amount of the third water quick-add button (#29).
class WaterQuickAmountDialog extends StatefulWidget {
  final WaterQuickAmount quickAmount;

  const WaterQuickAmountDialog({super.key, required this.quickAmount});

  @override
  State<WaterQuickAmountDialog> createState() => _WaterQuickAmountDialogState();
}

class _WaterQuickAmountDialogState extends State<WaterQuickAmountDialog> {
  final _controller = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String? _error;

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

  /// Reads the stored amount rather than the last one shown, so a restore
  /// in the meantime is not overwritten.
  Future<void> _load() async {
    final amount = await widget.quickAmount.load();
    if (!mounted) return;
    setState(() {
      _controller.text = amount.toString();
      _loaded = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final parsed = int.tryParse(_controller.text);
    if (parsed == null ||
        parsed < WaterQuickAmount.minMl ||
        parsed > WaterQuickAmount.maxMl) {
      setState(
        () => _error = S
            .of(context)
            .waterQuickAmountRangeError(
              WaterQuickAmount.minMl,
              WaterQuickAmount.maxMl,
            ),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.quickAmount.save(parsed);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.waterQuickAmountLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.waterQuickAmountDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Semantics(
            identifier: 'water-quick-amount-input',
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              enabled: _loaded,
              decoration: InputDecoration(
                suffixText: s.mlLabel,
                helperText:
                    '${WaterQuickAmount.minMl}–${WaterQuickAmount.maxMl} '
                    '${s.mlLabel}',
                errorText: _error,
                isDense: true,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'water-quick-amount-save',
          child: TextButton(
            onPressed: _loaded && !_saving ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}
