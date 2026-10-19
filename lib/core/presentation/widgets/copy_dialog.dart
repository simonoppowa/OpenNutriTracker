import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/copy_target.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Asks where to copy diary entries: the target day (#40) and, when
/// [initialValue] is given, the meal. Pops a [CopyTarget], or null on
/// cancel.
class CopyDialog extends StatefulWidget {
  final AddMealType? initialValue;

  /// The day preselected as the target; the calendar today when null.
  /// Callers that know the configured day start pass the logical today.
  final DateTime? initialDay;

  const CopyDialog({super.key, this.initialValue, this.initialDay});

  @override
  State<StatefulWidget> createState() {
    return CopyDialogState();
  }
}

class CopyDialogState extends State<CopyDialog> {
  late AddMealType? _selectedValue;
  late DateTime _day;

  AddMealType? get selectedMealType => _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    final day = widget.initialDay ?? DateTime.now();
    _day = DateTime(day.year, day.month, day.day);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    final mealType = _selectedValue;
    return AlertDialog(
      title: Text(
        mealType != null
            ? S.of(context).copyDialogTitle
            : S.of(context).copyTargetTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            identifier: 'copy-dialog-day',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(S.of(context).copyDialogDayLabel),
              subtitle: Text(DateFormat.yMMMEd().format(_day)),
              onTap: _pickDay,
            ),
          ),
          if (mealType != null)
            DropdownButton<AddMealType>(
              value: mealType,
              itemHeight: null,
              onChanged: (AddMealType? addMealType) {
                if (addMealType != null) {
                  setState(() {
                    _selectedValue = addMealType;
                  });
                }
              },
              items: AddMealType.values.map((AddMealType addMealType) {
                return DropdownMenuItem(
                  value: addMealType,
                  child: Text(addMealType.getTypeName(context)),
                );
              }).toList(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(CopyTarget(day: _day, type: mealType?.getIntakeType()));
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
      ],
    );
  }
}
