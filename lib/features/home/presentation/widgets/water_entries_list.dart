import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/features/home/domain/day_water_log.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The water entries of [day] (the current logical day when null) with
/// their time and amount, each deletable after a confirmation (#30).
/// Renders nothing for a day without entries.
class WaterEntriesList extends StatefulWidget {
  final DayWaterLog log;
  final DateTime? day;

  /// Shows a "Water" heading above the entries, as the diary does.
  final bool showTitle;

  const WaterEntriesList({
    super.key,
    required this.log,
    this.day,
    this.showTitle = false,
  });

  @override
  State<WaterEntriesList> createState() => _WaterEntriesListState();
}

class _WaterEntriesListState extends State<WaterEntriesList> {
  List<WaterIntakeEntity> _entries = const [];
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.log.revision.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(WaterEntriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.log != widget.log) {
      oldWidget.log.revision.removeListener(_load);
      widget.log.revision.addListener(_load);
    }
    if (oldWidget.day != widget.day || oldWidget.log != widget.log) _load();
  }

  @override
  void dispose() {
    widget.log.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final day = widget.day;
    final entries = day == null
        ? await widget.log.entriesForToday()
        : await widget.log.entriesFor(day);
    if (mounted && generation == _loadGeneration) {
      setState(() => _entries = entries);
    }
  }

  Future<void> _confirmDelete(WaterIntakeEntity entry) async {
    final s = S.of(context);
    final time = DateFormat.Hm().format(entry.dateTime);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.waterEntryDeleteTitle),
        content: Text(s.waterEntryDeleteContent(entry.amountMl, time)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.dialogCancelLabel),
          ),
          Semantics(
            identifier: 'water-entry-delete-confirm',
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(s.dialogDeleteLabel),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.log.delete(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final total = _entries.fold(0, (sum, entry) => sum + entry.amountMl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimens.spacing4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.waterEntriesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('$total ${s.mlLabel}', style: textTheme.titleSmall),
              ],
            ),
          ),
        for (final (index, entry) in _entries.indexed)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat.Hm().format(entry.dateTime)} · '
                  '${entry.amountMl} ${s.mlLabel}',
                  style: textTheme.bodyMedium,
                ),
              ),
              Semantics(
                identifier: 'water-entry-delete-$index',
                child: IconButton(
                  tooltip: s.waterEntryDeleteTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDelete(entry),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
