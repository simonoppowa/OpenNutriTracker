import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DiaryTransferChoice {
  final DateTime date;
  final IntakeTypeEntity? mealType;
  final bool move;

  const DiaryTransferChoice(this.date, this.mealType, this.move);
}

class DiaryTransferDialog extends StatefulWidget {
  final DateTime initialDate;
  final IntakeTypeEntity? initialMealType;
  final bool includesFoods;

  const DiaryTransferDialog({
    super.key,
    required this.initialDate,
    this.initialMealType,
    this.includesFoods = true,
  });

  @override
  State<DiaryTransferDialog> createState() => _DiaryTransferDialogState();
}

class _DiaryTransferDialogState extends State<DiaryTransferDialog> {
  late DateTime _date = widget.initialDate;
  late IntakeTypeEntity? _mealType = widget.initialMealType;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.diaryTransferTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            identifier: 'diary-transfer-date',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat.yMMMd().format(_date)),
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) setState(() => _date = selected);
              },
            ),
          ),
          if (widget.includesFoods) ...[
            const SizedBox(height: 12),
            Semantics(
              identifier: 'diary-transfer-meal',
              child: DropdownButtonFormField<IntakeTypeEntity?>(
                initialValue: _mealType,
                decoration: InputDecoration(
                  labelText: s.diaryTransferMealLabel,
                ),
                items: [
                  DropdownMenuItem<IntakeTypeEntity?>(
                    value: null,
                    child: Text(s.diaryKeepOriginalMealsLabel),
                  ),
                  for (final type in IntakeTypeEntity.values)
                    DropdownMenuItem<IntakeTypeEntity?>(
                      value: type,
                      child: Text(switch (type) {
                        IntakeTypeEntity.breakfast => s.breakfastLabel,
                        IntakeTypeEntity.lunch => s.lunchLabel,
                        IntakeTypeEntity.dinner => s.dinnerLabel,
                        IntakeTypeEntity.snack => s.snackLabel,
                      }),
                    ),
                ],
                onChanged: (value) => setState(() => _mealType = value),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            DiaryTransferChoice(_date, _mealType, false),
          ),
          child: Text(s.copyActionLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            DiaryTransferChoice(_date, _mealType, true),
          ),
          child: Text(s.diaryMoveLabel),
        ),
      ],
    );
  }
}
