import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/empty_hint.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_length_unit.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurement.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurements_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';

String bodyMeasureName(BuildContext context, BodyMeasureKind kind) {
  final s = S.of(context);
  return switch (kind) {
    BodyMeasureKind.waist => s.bodyMeasureWaist,
    BodyMeasureKind.chest => s.bodyMeasureChest,
    BodyMeasureKind.arm => s.bodyMeasureArm,
    BodyMeasureKind.thigh => s.bodyMeasureThigh,
    BodyMeasureKind.hip => s.bodyMeasureHip,
  };
}

/// Profile → Body measurements (#44): the chart of one measure, the list of
/// measurements with edit and delete, and adding new ones; cm or inches by
/// the height unit setting.
class BodyMeasurementsScreen extends StatefulWidget {
  final BodyMeasurementsUsecase? usecase;

  /// The unit to show; read from the height unit setting when null.
  final BodyLengthUnit? unit;

  const BodyMeasurementsScreen({super.key, this.usecase, this.unit});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  late final BodyMeasurementsUsecase _measurements =
      widget.usecase ?? locator<BodyMeasurementsUsecase>();
  BodyLengthUnit? _unit;
  BodyMeasureKind _chartKind = BodyMeasureKind.waist;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit;
    if (_unit == null) {
      locator<GetConfigUsecase>().getConfig().then((config) {
        if (mounted) {
          setState(
            () => _unit = BodyLengthUnit.fromImperial(
              config.usesImperialHeightUnits,
            ),
          );
        }
      });
    }
  }

  String _unitLabel(BuildContext context) => _unit == BodyLengthUnit.inch
      ? S.of(context).inLabel
      : S.of(context).cmLabel;

  Future<void> _edit([BodyMeasurement? existing]) async {
    final unit = _unit;
    if (unit == null) return;
    final result = await showDialog<BodyMeasurement>(
      context: context,
      builder: (_) => _MeasurementDialog(
        unit: unit,
        unitLabel: _unitLabel(context),
        existing: existing,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      await _measurements.add(
        date: result.date,
        valuesCm: result.valuesCm,
        note: result.note,
      );
    } else {
      await _measurements.update(result);
    }
  }

  Future<void> _delete(BodyMeasurement measurement) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.bodyMeasurementDeleteTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.dialogDeleteLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) await _measurements.delete(measurement.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final unit = _unit;
    return Scaffold(
      appBar: AppBar(title: Text(s.bodyMeasurementsTitle)),
      floatingActionButton: Semantics(
        identifier: 'body-measurement-add',
        child: FloatingActionButton.extended(
          onPressed: unit == null ? null : () => _edit(),
          icon: const Icon(Icons.add_rounded),
          label: Text(s.bodyMeasurementAdd),
        ),
      ),
      body: unit == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<int>(
              valueListenable: _measurements.changes,
              builder: (context, _, _) {
                final list = _measurements.list();
                if (list.isEmpty) {
                  return EmptyHint(
                    icon: Icons.straighten_rounded,
                    title: s.bodyMeasurementsEmpty,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Dimens.spacing16,
                    Dimens.spacing8,
                    Dimens.spacing16,
                    96,
                  ),
                  children: [
                    Wrap(
                      spacing: Dimens.spacing8,
                      children: [
                        for (final kind in BodyMeasureKind.values)
                          Semantics(
                            identifier: 'body-measurement-chart-${kind.name}',
                            child: ChoiceChip(
                              label: Text(bodyMeasureName(context, kind)),
                              selected: _chartKind == kind,
                              onSelected: (_) =>
                                  setState(() => _chartKind = kind),
                            ),
                          ),
                      ],
                    ),
                    _MeasureChart(
                      series: _measurements.seriesOf(_chartKind),
                      unit: unit,
                    ),
                    for (final measurement in list)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          DateFormat.yMMMd().format(measurement.date),
                        ),
                        subtitle: Text(
                          [
                            for (final kind in BodyMeasureKind.values)
                              if (measurement[kind] case final cm?)
                                '${bodyMeasureName(context, kind)} '
                                    '${unit.format(cm)} ${_unitLabel(context)}',
                            if (measurement.note case final note?
                                when note.isNotEmpty)
                              note,
                          ].join(' · '),
                        ),
                        onTap: () => _edit(measurement),
                        trailing: IconButton(
                          tooltip: s.dialogDeleteLabel,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _delete(measurement),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _MeasureChart extends StatelessWidget {
  final List<({DateTime date, double cm})> series;
  final BodyLengthUnit unit;

  const _MeasureChart({required this.series, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimens.spacing24),
        child: Text(
          S.of(context).bodyMeasurementsChartEmpty,
          textAlign: TextAlign.center,
        ),
      );
    }
    final first = series.first.date;
    final spots = [
      for (final point in series)
        FlSpot(
          point.date.difference(first).inDays.toDouble(),
          unit.fromCm(point.cm),
        ),
    ];
    final ys = spots.map((s) => s.y);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final padding = ((maxY - minY) * 0.2).clamp(1.0, 10.0);
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      key: const Key('bodyMeasurementChart'),
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: minY - padding,
            maxY: maxY + padding,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (spots.last.x / 4).clamp(1, double.infinity),
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat.MMMd().format(
                        first.add(Duration(days: value.toInt())),
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasurementDialog extends StatefulWidget {
  final BodyLengthUnit unit;
  final String unitLabel;
  final BodyMeasurement? existing;

  const _MeasurementDialog({
    required this.unit,
    required this.unitLabel,
    this.existing,
  });

  @override
  State<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<_MeasurementDialog> {
  late DateTime _date;
  late final Map<BodyMeasureKind, TextEditingController> _fields;
  late final TextEditingController _note;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _date = existing?.date ?? DateTime(now.year, now.month, now.day);
    _fields = {
      for (final kind in BodyMeasureKind.values)
        kind: TextEditingController(
          text: existing?[kind] == null
              ? ''
              : widget.unit.format(existing![kind]!),
        ),
    };
    _note = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final s = S.of(context);
    final values = <BodyMeasureKind, double>{};
    for (final MapEntry(key: kind, value: controller) in _fields.entries) {
      final text = controller.text.trim().replaceAll(',', '.');
      if (text.isEmpty) continue;
      final parsed = double.tryParse(text);
      final cm = parsed == null ? null : widget.unit.toCm(parsed);
      if (cm == null || !BodyMeasurement.isValidCm(cm)) {
        final range = widget.unit.range;
        setState(
          () => _error = s.bodyMeasurementRange(
            range.min,
            range.max,
            widget.unitLabel,
          ),
        );
        return;
      }
      values[kind] = cm;
    }
    if (values.isEmpty) {
      setState(() => _error = s.bodyMeasurementNeedOne);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      BodyMeasurement(
        id: widget.existing?.id ?? 'new',
        date: _date,
        valuesCm: values,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.existing == null ? s.bodyMeasurementAdd : s.bodyMeasurementEdit,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: Text(s.bodyMeasurementDateLabel),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            onTap: _pickDate,
          ),
          for (final kind in BodyMeasureKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spacing8),
              child: Semantics(
                identifier: 'body-measurement-${kind.name}',
                child: TextField(
                  controller: _fields[kind],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: bodyMeasureName(context, kind),
                    suffixText: widget.unitLabel,
                    isDense: true,
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ),
            ),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: s.bodyMeasurementNoteLabel,
              isDense: true,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Dimens.spacing8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
          identifier: 'body-measurement-save',
          child: TextButton(onPressed: _save, child: Text(s.buttonSaveLabel)),
        ),
      ],
    );
  }
}
