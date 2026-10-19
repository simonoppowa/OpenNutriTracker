import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/copy_target.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// What "Copy day" should copy (#40).
typedef CopyDayChoice = ({DateTime day, bool activities, bool water});

/// Asks for the target day of a whole-day copy and whether its activities
/// and water go along. Pops a [CopyDayChoice], or null on cancel.
class CopyDayDialog extends StatefulWidget {
  /// The target day preselected in the date step.
  final DateTime? initialDay;

  const CopyDayDialog({super.key, this.initialDay});

  @override
  State<CopyDayDialog> createState() => _CopyDayDialogState();
}

class _CopyDayDialogState extends State<CopyDayDialog> {
  bool _activities = false;
  bool _water = false;

  Future<void> _chooseDay() async {
    final navigator = Navigator.of(context);
    final target = await showDialog<CopyTarget>(
      context: context,
      builder: (_) => CopyDialog(initialDay: widget.initialDay),
    );
    if (target != null) {
      navigator.pop<CopyDayChoice>((
        day: target.day,
        activities: _activities,
        water: _water,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.copyDayDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: 'copy-day-activities',
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.copyDayActivitiesLabel),
              value: _activities,
              onChanged: (value) => setState(() => _activities = value!),
            ),
          ),
          Semantics(
            identifier: 'copy-day-water',
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.copyDayWaterLabel),
              value: _water,
              onChanged: (value) => setState(() => _water = value!),
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
          identifier: 'copy-day-next',
          child: TextButton(
            onPressed: _chooseDay,
            child: Text(s.copyDialogDayLabel),
          ),
        ),
      ],
    );
  }
}
