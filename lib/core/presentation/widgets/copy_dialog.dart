import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CopyDialog extends StatefulWidget {
  final AddMealType initialValue;

  /// A meal not offered: the one being copied, when the copy would land on
  /// the same day, where picking it would only log the meal a second time.
  final AddMealType? excluded;

  const CopyDialog({super.key, required this.initialValue, this.excluded});
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
    _selectedValue = widget.initialValue != widget.excluded
        ? widget.initialValue
        : AddMealType.values.firstWhere((type) => type != widget.excluded);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).copyDialogTitle),
      content: DropdownButton<AddMealType>(
        value: _selectedValue,
        itemHeight: null,
        onChanged: (AddMealType? addMealType) {
          if (addMealType != null) {
            setState(() {
              _selectedValue = addMealType;
            });
          }
        },
        items: AddMealType.values
            .where((type) => type != widget.excluded)
            .map((AddMealType addMealType) {
          return DropdownMenuItem(
            value: addMealType,
            child: Text(addMealType.getTypeName(context)),
          );
        }).toList(),
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
