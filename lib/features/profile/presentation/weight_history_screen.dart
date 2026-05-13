import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Screen for browsing and adding weight log entries.
///
/// We deliberately render a simple list view rather than a chart: the
/// project has no chart dependency in `pubspec.yaml`, and the issue
/// reporters in #38 were happy with "see my weight history" as a first
/// step. A trend chart can land later without touching this data
/// pipeline.
class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  final _getUsecase = locator<GetWeightLogUsecase>();
  final _addUsecase = locator<AddWeightLogUsecase>();
  final _deleteUsecase = locator<DeleteWeightLogUsecase>();
  final _configRepository = locator<ConfigRepository>();

  bool _loading = true;
  bool _usesImperialUnits = false;
  List<WeightLogEntity> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _configRepository.getConfig();
    final imperial = config.usesImperialUnits;
    final entries = await _getUsecase.getAllEntries();
    // Newest first so the most recent reading sits at the top.
    entries.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _usesImperialUnits = imperial;
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).profileWeightHistoryTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddEntry,
        icon: const Icon(Icons.add),
        label: Text(S.of(context).weightHistoryAddEntry),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      S.of(context).weightHistoryNoEntries,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _buildEntryTile(_entries[index]),
                ),
    );
  }

  Widget _buildEntryTile(WeightLogEntity entry) {
    final displayWeight = _usesImperialUnits
        ? UnitCalc.kgToLbs(entry.weightKg)
        : entry.weightKg;
    final unit = _usesImperialUnits
        ? S.of(context).lbsLabel
        : S.of(context).kgLabel;
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(entry.date);

    return ListTile(
      title: Text('${displayWeight.toStringAsFixed(1)} $unit'),
      subtitle: Text(
        entry.note?.isNotEmpty == true ? '$dateLabel  •  ${entry.note}' : dateLabel,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _onDelete(entry),
      ),
    );
  }

  Future<void> _onAddEntry() async {
    final initialWeight = _entries.isNotEmpty ? _entries.first.weightKg : 70.0;
    final result = await showDialog<_NewWeightEntry>(
      context: context,
      builder: (context) => _AddWeightEntryDialog(
        initialDate: DateTime.now(),
        initialWeightKg: initialWeight,
        usesImperialUnits: _usesImperialUnits,
      ),
    );
    if (result == null) return;

    await _addUsecase.addEntry(
      WeightLogEntity(
        date: DateTime(result.date.year, result.date.month, result.date.day),
        weightKg: result.weightKg,
        note: result.note,
      ),
    );
    await _load();
  }

  Future<void> _onDelete(WeightLogEntity entry) async {
    await _deleteUsecase.deleteEntry(entry.date);
    await _load();
  }
}

class _NewWeightEntry {
  final DateTime date;
  final double weightKg;
  final String? note;

  _NewWeightEntry({required this.date, required this.weightKg, this.note});
}

class _AddWeightEntryDialog extends StatefulWidget {
  final DateTime initialDate;
  final double initialWeightKg;
  final bool usesImperialUnits;

  const _AddWeightEntryDialog({
    required this.initialDate,
    required this.initialWeightKg,
    required this.usesImperialUnits,
  });

  @override
  State<_AddWeightEntryDialog> createState() => _AddWeightEntryDialogState();
}

class _AddWeightEntryDialogState extends State<_AddWeightEntryDialog> {
  late DateTime _date;
  late TextEditingController _weightController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    final initialDisplay = widget.usesImperialUnits
        ? UnitCalc.kgToLbs(widget.initialWeightKg)
        : widget.initialWeightKg;
    _weightController =
        TextEditingController(text: initialDisplay.toStringAsFixed(1));
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    final raw = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (raw == null || raw <= 0) {
      Navigator.of(context).pop();
      return;
    }
    final kg = widget.usesImperialUnits ? UnitCalc.lbsToKg(raw) : raw;
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      _NewWeightEntry(
        date: _date,
        weightKg: kg,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.usesImperialUnits
        ? S.of(context).lbsLabel
        : S.of(context).kgLabel;
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(_date);

    return AlertDialog(
      title: Text(S.of(context).weightHistoryAddEntry),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(S.of(context).weightHistoryDateLabel),
              subtitle: Text(dateLabel),
              onTap: _pickDate,
            ),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    '${S.of(context).weightHistoryWeightLabel} ($unit)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: S.of(context).weightHistoryNoteLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
