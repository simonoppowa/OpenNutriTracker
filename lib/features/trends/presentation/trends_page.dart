import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/weight_trend_chart.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  // The bloc is a GetIt singleton, so provide it by value rather than letting
  // BlocProvider close it on dispose. Settings holds the same instance and
  // pokes it with LoadTrendsEvent when the body-weight unit changes.
  final TrendsBloc _trendsBloc = locator<TrendsBloc>();

  @override
  void initState() {
    super.initState();
    _trendsBloc.add(const LoadTrendsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrendsBloc>.value(
      value: _trendsBloc,
      child: const _TrendsView(),
    );
  }
}

class _TrendsView extends StatelessWidget {
  const _TrendsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return BlocBuilder<TrendsBloc, TrendsState>(
      builder: (context, state) {
        if (state is! TrendsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              Dimens.spacing16, Dimens.spacing8, Dimens.spacing16, Dimens.spacing32),
          children: [
            _StreakCard(
              days: state.days,
              priorWeek: state.priorWeek,
              rangeDays: state.windowDays,
              palette: palette,
            ),
            const SizedBox(height: Dimens.spacing16),
            _RangeSelector(rangeDays: state.rangeDays),
            const SizedBox(height: Dimens.spacing16),
            _CaloriesTrendCard(
                days: state.days, rangeDays: state.windowDays, palette: palette),
            const SizedBox(height: Dimens.spacing16),
            _MacrosTrendCard(
                days: state.days, rangeDays: state.windowDays, palette: palette),
            const SizedBox(height: Dimens.spacing16),
            _WaterTrendCard(
              waterByDay: state.waterByDay,
              goalMl: state.waterGoalMl,
              rangeDays: state.windowDays,
              palette: palette,
            ),
            const SizedBox(height: Dimens.spacing16),
            _WeightCard(
              entries: state.weight,
              bodyWeightUnit: state.bodyWeightUnit,
              targetWeightKg: state.targetWeightKg,
              rangeDays: state.windowDays,
              palette: palette,
            ),
          ],
        );
      },
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final int rangeDays;
  const _RangeSelector({required this.rangeDays});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        identifier: 'trends-range-selector',
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(value: 7, label: Text('7d')),
            const ButtonSegment(value: 30, label: Text('30d')),
            const ButtonSegment(value: 90, label: Text('90d')),
            // 0 is the "All" sentinel; the bloc resolves it to the full span.
            ButtonSegment(value: 0, label: Text(S.of(context).allItemsLabel)),
          ],
          selected: {rangeDays},
          onSelectionChanged: (s) => context
              .read<TrendsBloc>()
              .add(LoadTrendsEvent(rangeDays: s.first)),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final List<TrackedDayEntity> days;
  final List<TrackedDayEntity> priorWeek;
  final int rangeDays;
  final AppPalette palette;
  const _StreakCard({
    required this.days,
    required this.priorWeek,
    required this.rangeDays,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart =
        DateTime(today.year, today.month, today.day - (rangeDays - 1));
    final weekEnd = today;
    final weekStart = weekEnd.subtract(const Duration(days: 6));

    bool onTrack(TrackedDayEntity d) =>
        d.getCalendarDayRatingColor(context) != errorColor;

    final onTrackDays = <DateTime>{
      for (final d in days)
        if (onTrack(d)) DateTime(d.day.year, d.day.month, d.day.day),
    };
    final stats = streakStats(onTrackDays, windowStart, today);

    // Week-over-week on-track delta (this week vs the prior week).
    // Suppress the chip when the prior week is empty — a new user with
    // no baseline would otherwise see a large green delta against 0.
    final priorOnTrack = priorWeek.where(onTrack).toList();
    final thisWeek = onTrackDays
        .where((day) =>
            day.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            day.isBefore(weekEnd.add(const Duration(days: 1))))
        .length;
    final delta = priorOnTrack.isNotEmpty
        ? thisWeek - priorOnTrack.length
        : 0;

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimens.spacing12),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(Icons.local_fire_department_rounded,
                color: accent, size: 28),
          ),
          const SizedBox(width: Dimens.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${stats.current}', style: text.headlineSmall),
                Text(S.of(context).trendsDayStreakLabel,
                    style: text.bodyMedium?.copyWith(color: palette.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (delta != 0) ...[
                _WeekDeltaChip(delta: delta, palette: palette),
                const SizedBox(height: 6),
              ],
              Text(
                '${S.of(context).trendsBestStreakLabel} ${stats.longest}',
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Week-over-week change in on-track days, shown as a coloured arrow + number
/// (locale-neutral — no wording needed).
class _WeekDeltaChip extends StatelessWidget {
  final int delta;
  final AppPalette palette;
  const _WeekDeltaChip({required this.delta, required this.palette});

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? palette.proteinColor : palette.fatColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.spacing12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: Dimens.borderRadiusS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 16),
          const SizedBox(width: 2),
          Text('${delta.abs()}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _CaloriesTrendCard extends StatelessWidget {
  final List<TrackedDayEntity> days;
  final int rangeDays;
  final AppPalette palette;
  const _CaloriesTrendCard({required this.days, required this.rangeDays, required this.palette});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = {for (final d in days) DateTime(d.day.year, d.day.month, d.day.day): d};
    // Full per-day series across the window; missing days contribute 0 tracked.
    final spots = <FlSpot>[];
    final goals = <double>[];
    for (int i = 0; i < rangeDays; i++) {
      final day = today.subtract(Duration(days: rangeDays - 1 - i));
      final d = byDay[DateTime(day.year, day.month, day.day)];
      spots.add(FlSpot(i.toDouble(), d?.caloriesTracked ?? 0));
      if (d != null && d.calorieGoal > 0) goals.add(d.calorieGoal);
    }
    final avgGoal = goals.isEmpty ? 0.0 : goals.reduce((a, b) => a + b) / goals.length;
    final maxTracked = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final maxY = [maxTracked, avgGoal].reduce((a, b) => a > b ? a : b) * 1.15 + 1;

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).trendsCaloriesLabel, style: text.titleMedium),
          const SizedBox(height: Dimens.spacing20),
          Semantics(
            label: S.of(context).trendsCaloriesLabel,
            child: SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (rangeDays - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          s.y.toInt().toString(),
                          text.labelMedium ?? const TextStyle(),
                        ),
                    ],
                  ),
                ),
                // Dashed average-goal reference: the line above/below it reads
                // as days over / under goal at a glance.
                extraLinesData: avgGoal <= 0
                    ? const ExtraLinesData()
                    : ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: avgGoal,
                          color: palette.textMuted,
                          strokeWidth: 1.2,
                          dashArray: const [6, 4],
                        ),
                      ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: accent,
                    barWidth: 3,
                    dotData: FlDotData(show: rangeDays <= 7),
                    belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.12)),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _WaterTrendCard extends StatelessWidget {
  final Map<DateTime, int> waterByDay;
  final int goalMl;
  final int rangeDays;
  final AppPalette palette;
  const _WaterTrendCard({
    required this.waterByDay,
    required this.goalMl,
    required this.rangeDays,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = palette.proteinColor;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final spots = <FlSpot>[];
    var sum = 0;
    var loggedDays = 0;
    for (int i = 0; i < rangeDays; i++) {
      final day = today.subtract(Duration(days: rangeDays - 1 - i));
      final ml = waterByDay[DateTime(day.year, day.month, day.day)] ?? 0;
      spots.add(FlSpot(i.toDouble(), ml.toDouble()));
      if (ml > 0) {
        sum += ml;
        loggedDays++;
      }
    }
    final avg = loggedDays == 0 ? 0 : (sum / rangeDays).round();
    final maxWater = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final maxY =
        [maxWater, goalMl.toDouble()].reduce((a, b) => a > b ? a : b) * 1.15 + 1;

    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(S.of(context).trendsWaterLabel,
                    style: text.titleMedium),
              ),
              Text(
                S.of(context).waterChipLabel(avg, goalMl),
                style: text.bodySmall?.copyWith(
                    color: palette.textMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: Dimens.spacing20),
          Semantics(
            label: S.of(context).trendsWaterLabel,
            child: SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (rangeDays - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            s.y.toInt().toString(),
                            text.labelMedium ?? const TextStyle(),
                          ),
                      ],
                    ),
                  ),
                  extraLinesData: goalMl <= 0
                      ? const ExtraLinesData()
                      : ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: goalMl.toDouble(),
                            color: palette.textMuted,
                            strokeWidth: 1.2,
                            dashArray: const [6, 4],
                          ),
                        ]),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: rangeDays <= 7),
                      belowBarData: BarAreaData(
                          show: true, color: color.withValues(alpha: 0.12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrosTrendCard extends StatelessWidget {
  final List<TrackedDayEntity> days;
  final AppPalette palette;
  final int rangeDays;
  const _MacrosTrendCard({
    required this.days,
    required this.palette,
    required this.rangeDays,
  });

  double _avg(Iterable<double?> values) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return 0;
    return present.reduce((a, b) => a + b) / rangeDays;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = [
      (S.of(context).carbsLabel, _avg(days.map((d) => d.carbsTracked)),
          _avg(days.map((d) => d.carbsGoal)), palette.carbs),
      (S.of(context).fatLabel, _avg(days.map((d) => d.fatTracked)),
          _avg(days.map((d) => d.fatGoal)), palette.fat),
      (S.of(context).proteinLabel, _avg(days.map((d) => d.proteinTracked)),
          _avg(days.map((d) => d.proteinGoal)), palette.protein),
    ];
    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average intake vs goal over the window — daily-average macros.
          Text(S.of(context).trendsDailyAverageLabel, style: text.titleMedium),
          const SizedBox(height: Dimens.spacing16),
          for (final (label, intake, goal, color) in rows) ...[
            Row(
              children: [
                Text(label, style: text.labelMedium),
                const Spacer(),
                Text('${intake.toInt()} / ${goal.toInt()} g',
                    style: text.bodySmall?.copyWith(color: palette.textStrong, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal <= 0 ? 0 : (intake / goal).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: palette.surfaceMuted,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: Dimens.spacing16),
          ],
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final List<WeightLogEntity> entries;
  final BodyWeightUnit bodyWeightUnit;
  final double? targetWeightKg;
  final int rangeDays;
  final AppPalette palette;
  const _WeightCard({
    required this.entries,
    required this.bodyWeightUnit,
    required this.targetWeightKg,
    required this.rangeDays,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final projection = weightProjection(
      [for (final e in entries) (date: e.date, kg: e.weightKg)],
      targetWeightKg,
    );
    return AppCard(
      padding: const EdgeInsets.all(Dimens.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(S.of(context).weightHistoryWeightLabel,
                    style: text.titleMedium),
              ),
              Semantics(
                identifier: 'trends-log-weight',
                // Tight bounds: without this the node inherits the whole
                // card's box (the container gotcha) and coordinate taps miss.
                container: true,
                child: IconButton(
                  tooltip: S.of(context).weightHistoryAddEntry,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _logWeight(context),
                ),
              ),
            ],
          ),
          if (projection != null)
            Text(
              _projectionLabel(context, projection),
              style: text.bodySmall?.copyWith(color: palette.textMuted),
            ),
          const SizedBox(height: Dimens.spacing12),
          WeightTrendChart(
            entries: entries,
            bodyWeightUnit: bodyWeightUnit,
            targetWeightKg: targetWeightKg,
            windowDays: rangeDays,
          ),
        ],
      ),
    );
  }

  /// One-line weight outlook: the weekly rate of change (in the user's unit),
  /// plus a rough number of weeks to the target when one is set and the trend
  /// is heading toward it.
  String _projectionLabel(
    BuildContext context,
    ({double ratePerWeek, int? weeksToTarget}) projection,
  ) {
    final String rateStr;
    switch (bodyWeightUnit) {
      case BodyWeightUnit.kg:
        final rate = projection.ratePerWeek;
        final sign = rate >= 0 ? '+' : '';
        rateStr = '$sign${rate.toStringAsFixed(1)} ${S.of(context).kgLabel}';
      case BodyWeightUnit.lb:
        final rate = projection.ratePerWeek * 2.20462;
        final sign = rate >= 0 ? '+' : '';
        rateStr = '$sign${rate.toStringAsFixed(1)} ${S.of(context).lbsLabel}';
      case BodyWeightUnit.st:
        // Decimal stones for rate display.
        final rate = projection.ratePerWeek * 2.20462 / 14;
        final sign = rate >= 0 ? '+' : '';
        rateStr = '$sign${rate.toStringAsFixed(2)} ${S.of(context).stLabel}';
    }
    var label = '$rateStr${S.of(context).trendsPerWeekSuffix}';
    if (projection.weeksToTarget != null) {
      label += ' · ~${projection.weeksToTarget} '
          '${S.of(context).trendsWeeksToGoalLabel}';
    }
    return label;
  }

  /// Logs a weight entry from the trends view, reusing the same dialog and
  /// persistence path as the home weight chip, then reloads the trend so the
  /// chart reflects the new point. Keeping weight editable here means it no
  /// longer lives only behind the home widget.
  Future<void> _logWeight(BuildContext context) async {
    final trendsBloc = context.read<TrendsBloc>();
    final rangeDays = trendsBloc.state is TrendsLoaded
        ? (trendsBloc.state as TrendsLoaded).rangeDays
        : 7;
    final user = await locator<GetUserUsecase>().getUserData();
    if (!context.mounted) return;
    final entered = await showDialog<({double weight, DateTime date})>(
      context: context,
      builder: (_) => SetWeightDialog(
        initialKg: user.weightKG,
        unit: bodyWeightUnit,
        allowDateSelection: true,
      ),
    );
    if (entered == null) return;
    // The dialog now always returns kg in the weight slot.
    final kg = entered.weight;
    final d = entered.date;
    await locator<AddWeightLogUsecase>().addEntry(
      WeightLogEntity(
        date: DateTime(d.year, d.month, d.day),
        weightKg: kg,
      ),
    );
    final updated = await locator<GetUserUsecase>().getUserData();
    await locator<ProfileBloc>().updateUser(updated);
    if (context.mounted) {
      trendsBloc.add(LoadTrendsEvent(rangeDays: rangeDays));
    }
  }
}
