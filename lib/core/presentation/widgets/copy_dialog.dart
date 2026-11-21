import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CopyDialog extends StatefulWidget {
  final AddMealType initialValue;

  final DateTime? destinationDay;

  const CopyDialog({
    super.key,
    required this.initialValue,
    this.destinationDay,
  });
  @override
  State<StatefulWidget> createState() {
    return CopyDialogState();
  }
}

class CopyDialogState extends State<CopyDialog> {
  late AddMealType _selectedValue;

  AddMealType get selectedMealType => _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).copyDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.destinationDay != null)
            Text(
              S
                  .of(context)
                  .copyToDateLabel(
                    DateFormat.yMMMMEEEEd().format(widget.destinationDay!),
                  ),
            ),
          Semantics(
            identifier: 'copy-destination-meal',
            child: DropdownButton<AddMealType>(
              value: _selectedValue,
              isExpanded: true,
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
                  child: Text(
                    addMealType.getTypeName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedValue);
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
