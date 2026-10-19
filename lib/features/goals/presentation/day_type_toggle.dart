import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Shows whether [day] is a training or a rest day and switches it with a
/// tap (#35). Renders nothing while training days have no goals of their
/// own.
class DayTypeToggle extends StatefulWidget {
  final DateTime day;
  final Future<TrainingPlan> Function() loadPlan;
  final Future<void> Function(DateTime day, DayType type) setDayType;

  /// Reloads the plan when it fires, e.g. after the goals were saved.
  final Listenable? changes;

  const DayTypeToggle({
    super.key,
    required this.day,
    required this.loadPlan,
    required this.setDayType,
    this.changes,
  });

  @override
  State<DayTypeToggle> createState() => _DayTypeToggleState();
}

class _DayTypeToggleState extends State<DayTypeToggle> {
  TrainingPlan? _plan;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.changes?.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(DayTypeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changes != widget.changes) {
      oldWidget.changes?.removeListener(_load);
      widget.changes?.addListener(_load);
    }
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final plan = await widget.loadPlan();
    if (mounted) setState(() => _plan = plan);
  }

  Future<void> _toggle(DayType current) async {
    setState(() => _busy = true);
    try {
      await widget.setDayType(
        widget.day,
        current == DayType.training ? DayType.rest : DayType.training,
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    if (plan == null || !plan.isEnabled) return const SizedBox.shrink();
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final type = plan.dayTypeOf(widget.day);
    final training = type == DayType.training;
    return Semantics(
      identifier: 'day-type-toggle',
      button: true,
      child: Tooltip(
        message: s.dayTypeSwitchTooltip,
        child: ActionChip(
          avatar: Icon(
            training
                ? Icons.fitness_center_rounded
                : Icons.self_improvement_rounded,
            size: 18,
            color: training
                ? Theme.of(context).colorScheme.primary
                : palette.textMuted,
          ),
          label: Text(
            training ? s.dayTypeTrainingLabel : s.dayTypeRestLabel,
            overflow: TextOverflow.ellipsis,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: Dimens.borderRadiusM,
          ),
          onPressed: _busy ? null : () => _toggle(type),
        ),
      ),
    );
  }
}
