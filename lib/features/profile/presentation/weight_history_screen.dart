import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
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
  bool _usesImperialUnits = false;
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
    final imperial = config.usesImperialUnits;
    final entries = await _getUsecase.getAllEntries();
    // Newest first so the most recent reading sits at the top.
    entries.sort((a, b) => b.date.compareTo(a.date));
    final user = await _getUserUsecase?.getUserData();
    if (!mounted) return;
    setState(() {
      _usesImperialUnits = imperial;
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
                      return _WeightTrendChart(
                        entries: _entries,
                        usesImperialUnits: _usesImperialUnits,
                        targetWeightKg: _targetWeightKg,
                      );
                    }
                    return _buildEntryTile(_entries[index - 1]);
                  },
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

/// 30-day line chart of weight readings, or a friendly nudge to log more
/// data when there's nothing to plot yet.
///
/// Entries are passed in newest-first (the order the list view uses); the
/// chart re-sorts oldest-first internally so the x-axis reads left-to-right
/// from earliest to most recent. Weights are displayed in the user's
/// chosen unit but stored in kg, so we convert on the fly.
class _WeightTrendChart extends StatelessWidget {
  static const int _windowDays = 30;
  static const double _chartHeight = 220;

  final List<WeightLogEntity> entries;
  final bool usesImperialUnits;
  // Target weight in kg as stored on UserEntity. Null when the user
  // hasn't set one; otherwise drawn as a dashed reference line so
  // the user can see how close they are. The y-range is still
  // computed from the recorded weights so a far-away target doesn't
  // squash the trend visually.
  final double? targetWeightKg;

  const _WeightTrendChart({
    required this.entries,
    required this.usesImperialUnits,
    required this.targetWeightKg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.primary;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: _windowDays));

    final inWindow = entries
        .where((e) => !e.date.isBefore(windowStart) && !e.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (inWindow.length < 2) {
      return Padding(
        key: const Key('weightHistoryChartEmptyState'),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SizedBox(
          height: _chartHeight,
          child: Center(
            child: Text(
              S.of(context).weightHistoryChartEmptyState,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (final entry in inWindow)
        FlSpot(
          // x = days since the window start, so today is at x = 30.
          entry.date.difference(windowStart).inDays.toDouble(),
          usesImperialUnits ? UnitCalc.kgToLbs(entry.weightKg) : entry.weightKg,
        ),
    ];

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Add a small padding so points don't sit on the chart edges. When all
    // weights are identical we still need a non-zero range or fl_chart will
    // throw.
    final yPadding = ((maxY - minY) * 0.15).clamp(0.5, 5.0);

    final targetY = targetWeightKg == null
        ? null
        : (usesImperialUnits
            ? UnitCalc.kgToLbs(targetWeightKg!)
            : targetWeightKg!);
    // Only draw the dashed reference line when the target sits inside
    // (or just adjacent to) the chart's auto y-range, so a wildly
    // off-screen target doesn't force the chart to autoscale away
    // from the recorded weights. A small fudge-factor lets the line
    // sit just at the edge of the chart, which is when users care
    // about it most ("nearly there").
    final showTargetLine = targetY != null &&
        targetY >= (minY - yPadding) &&
        targetY <= (maxY + yPadding);

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMd(localeTag);

    return Padding(
      key: const Key('weightHistoryChart'),
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      child: SizedBox(
        height: _chartHeight,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: _windowDays.toDouble(),
            minY: minY - yPadding,
            maxY: maxY + yPadding,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  // ~5 evenly spaced labels: today, -7, -14, -21, -30.
                  interval: 7,
                  getTitlesWidget: (value, meta) {
                    final day =
                        windowStart.add(Duration(days: value.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dateFormat.format(day),
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (showTargetLine)
                  HorizontalLine(
                    y: targetY,
                    color: theme.colorScheme.outline,
                    strokeWidth: 1.2,
                    dashArray: const [6, 4],
                  ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: lineColor,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            Semantics(
              identifier: 'weight-history-weight-input',
              child: TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      '${S.of(context).weightHistoryWeightLabel} ($unit)',
                ),
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
