import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_display_format.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/body_weight_input.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/weight_trend_chart.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Screen for browsing and adding weight log entries.
///
/// Renders a 30-day trend chart above the date-sorted list of readings.
/// The list remains the source of truth — the chart is a complementary
/// visualisation. When the user has logged fewer than two days the chart
/// area gives way to a gentle nudge to log more data, because a single
/// point doesn't yet describe a trend.
///
/// Dependencies are resolved from the locator by default; the optional
/// constructor parameters exist so widget tests can inject fakes without
/// standing up the whole DI graph.
class WeightHistoryScreen extends StatefulWidget {
  final GetWeightLogUsecase? getUsecase;
  final AddWeightLogUsecase? addUsecase;
  final DeleteWeightLogUsecase? deleteUsecase;
  final ConfigRepository? configRepository;
  final GetUserUsecase? getUserUsecase;

  const WeightHistoryScreen({
    super.key,
    this.getUsecase,
    this.addUsecase,
    this.deleteUsecase,
    this.configRepository,
    this.getUserUsecase,
  });

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  late final GetWeightLogUsecase _getUsecase =
      widget.getUsecase ?? locator<GetWeightLogUsecase>();
  late final AddWeightLogUsecase _addUsecase =
      widget.addUsecase ?? locator<AddWeightLogUsecase>();
  late final DeleteWeightLogUsecase _deleteUsecase =
      widget.deleteUsecase ?? locator<DeleteWeightLogUsecase>();
  late final ConfigRepository _configRepository =
      widget.configRepository ?? locator<ConfigRepository>();
  // Optional in tests so the harness doesn't need to register the
  // user usecase in the locator just to render the chart.
  late final GetUserUsecase? _getUserUsecase = widget.getUserUsecase ??
      (locator.isRegistered<GetUserUsecase>()
          ? locator<GetUserUsecase>()
          : null);

  bool _loading = true;
  BodyWeightUnit _bodyWeightUnit = BodyWeightUnit.kg;
  List<WeightLogEntity> _entries = const [];
  // Loaded once at mount time so the chart can draw a dashed reference
  // line for the user's #119 target weight. Null when unset.
  double? _targetWeightKg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _configRepository.getConfig();
    final unit = config.bodyWeightUnit;
    final entries = await _getUsecase.getAllEntries();
    // Newest first so the most recent reading sits at the top.
    entries.sort((a, b) => b.date.compareTo(a.date));
    final user = await _getUserUsecase?.getUserData();
    if (!mounted) return;
    setState(() {
      _bodyWeightUnit = unit;
      _entries = entries;
      _targetWeightKg = user?.targetWeightKg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).profileWeightHistoryTitle),
      ),
      floatingActionButton: Semantics(
        identifier: 'weight-history-add',
        child: FloatingActionButton.extended(
          onPressed: _onAddEntry,
          icon: const Icon(Icons.add),
          label: Text(S.of(context).weightHistoryAddEntry),
        ),
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
                  itemCount: _entries.length + 1,
                  separatorBuilder: (context, index) {
                    // No divider between the chart card and the first list tile.
                    if (index == 0) return const SizedBox.shrink();
                    return const Divider(height: 1);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return WeightTrendChart(
                        entries: _entries,
                        bodyWeightUnit: _bodyWeightUnit,
                        targetWeightKg: _targetWeightKg,
                      );
                    }
                    return _buildEntryTile(_entries[index - 1]);
                  },
                ),
    );
  }

  Widget _buildEntryTile(WeightLogEntity entry) {
    final displayStr = formatBodyWeight(
      entry.weightKg,
      _bodyWeightUnit,
      kgLabel: S.of(context).kgLabel,
      lbLabel: S.of(context).lbsLabel,
      stLabel: S.of(context).stLabel,
    );
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(entry.date);

    return ListTile(
      title: Text(displayStr),
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
    final initialWeightKg = _entries.isNotEmpty ? _entries.first.weightKg : 70.0;
    final result = await showDialog<_NewWeightEntry>(
      context: context,
      builder: (context) => _AddWeightEntryDialog(
        initialDate: DateTime.now(),
        initialWeightKg: initialWeightKg,
        bodyWeightUnit: _bodyWeightUnit,
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
  final BodyWeightUnit bodyWeightUnit;

  const _AddWeightEntryDialog({
    required this.initialDate,
    required this.initialWeightKg,
    required this.bodyWeightUnit,
  });

  @override
  State<_AddWeightEntryDialog> createState() => _AddWeightEntryDialogState();
}

class _AddWeightEntryDialogState extends State<_AddWeightEntryDialog> {
  late DateTime _date;
  late TextEditingController _noteController;

  // The kg value from BodyWeightInput; null means invalid / empty.
  double? _weightKg;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _weightKg = widget.initialWeightKg;
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
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
    final kg = _weightKg;
    if (kg == null || kg <= 0) {
      Navigator.of(context).pop();
      return;
    }
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
            BodyWeightInput(
              initialKg: widget.initialWeightKg,
              unit: widget.bodyWeightUnit,
              identifierPrefix: 'weight-history',
              autofocus: true,
              onChangedKg: (kg) => setState(() => _weightKg = kg),
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
