import 'package:flutter/material.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #139: Configurable diary day boundary with minute-level granularity.
///
/// Shift workers, late-eaters, and people whose subjective day spans
/// (say) 04:30 to 04:30 rather than midnight to midnight can shift the
/// rollover so meals and activities logged before their chosen time
/// roll into the previous day. (0, 0) keeps the wall-clock midnight
/// behaviour that everyone else expects.
class DiaryDayBoundaryDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final HomeBloc homeBloc;
  final CalendarDayBloc calendarDayBloc;

  const DiaryDayBoundaryDialog({
    super.key,
    required this.settingsBloc,
    required this.homeBloc,
    required this.calendarDayBloc,
  });

  @override
  State<DiaryDayBoundaryDialog> createState() => _DiaryDayBoundaryDialogState();
}

class _DiaryDayBoundaryDialogState extends State<DiaryDayBoundaryDialog> {
  int _hours = 0;
  int _minutes = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hours = await widget.settingsBloc.getDayStartOffsetHours();
    final minutes = await widget.settingsBloc.getDayStartOffsetMinutes();
    if (!mounted) return;
    setState(() {
      _hours = hours;
      _minutes = minutes;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await widget.settingsBloc.setDayStartOffsetHours(_hours);
    await widget.settingsBloc.setDayStartOffsetMinutes(_minutes);
    widget.settingsBloc.add(LoadSettingsEvent());
    // Refresh anywhere day rollover affects what's shown: the home
    // dashboard's totals and the calendar day view both partition
    // intake by day boundary.
    widget.homeBloc.add(const LoadItemsEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.settingsDayStartLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _loaded
                ? () => setState(() {
                      _hours = 0;
                      _minutes = 0;
                    })
                : null,
            child: Text(s.buttonResetLabel),
          ),
        ],
      ),
      content: !_loaded
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.settingsDayStartDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier: 'day-boundary-hours-slider',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.settingsDayStartHoursPickerLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Slider(
                              min: 0,
                              max: 23,
                              divisions: 23,
                              value: _hours.toDouble(),
                              label: '$_hours',
                              onChanged: (v) =>
                                  setState(() => _hours = v.round()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        identifier: 'day-boundary-minutes-slider',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.settingsDayStartMinutesPickerLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Slider(
                              min: 0,
                              max: 59,
                              divisions: 59,
                              value: _minutes.toDouble(),
                              label: _minutes.toString().padLeft(2, '0'),
                              onChanged: (v) =>
                                  setState(() => _minutes = v.round()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        s.settingsDayStartTimeLabel(
                          _hours,
                          _minutes.toString().padLeft(2, '0'),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'day-boundary-save',
          child: TextButton(
            onPressed: _loaded ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}
