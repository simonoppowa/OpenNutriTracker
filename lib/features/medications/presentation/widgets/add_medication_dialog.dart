import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/medication_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_medication_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddMedicationDialog extends StatefulWidget {
  final DateTime day;
  final MedicationEntity? medication;
  final VoidCallback onSaved;

  const AddMedicationDialog({
    super.key,
    required this.day,
    this.medication,
    required this.onSaved,
  });

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String _selectedUnit = 'mL';

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _amountController = TextEditingController(
      text: med != null ? med.amount.toString() : '',
    );
    if (med != null) {
      _selectedUnit = med.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (name.isEmpty || amount <= 0) return;

    final id = widget.medication?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final entity = MedicationEntity(
      id: id,
      day: widget.day,
      name: name,
      amount: amount,
      unit: _selectedUnit,
      taken: widget.medication?.taken ?? false,
    );

    await locator<AddMedicationUsecase>().addEntry(entity);
    widget.onSaved();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AlertDialog(
      title: Text(widget.medication == null ? 'Adicionar Medicamento' : 'Editar Medicamento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Medicamento',
                hintText: 'Ex: Vitamina D, Dipirona',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedUnit,
                  items: const [
                    DropdownMenuItem(value: 'mL', child: Text('mL')),
                    DropdownMenuItem(value: 'mg', child: Text('mg')),
                    DropdownMenuItem(value: 'mcg', child: Text('mcg')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedUnit = v);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(s.dialogOKLabel),
        ),
      ],
    );
  }
}
