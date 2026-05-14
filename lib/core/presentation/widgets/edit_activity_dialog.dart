import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditActivityDialog extends StatefulWidget {
  final UserActivityEntity activityEntity;

  const EditActivityDialog({super.key, required this.activityEntity});

  @override
  State<EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<EditActivityDialog> {
  late TextEditingController _quantityController;

  bool get _isCustom => widget.activityEntity.physicalActivityEntity.isCustom;

  @override
  void initState() {
    super.initState();
    // For Custom activities the editable quantity is kcal — and we prefer
    // the user's originally-entered figure (userKcal) when it's available
    // so a re-edit shows the exact number they typed last time, not a
    // rounded computed figure.
    final initialValue = _isCustom
        ? (widget.activityEntity.userKcal ?? widget.activityEntity.burnedKcal)
            .toInt()
            .toString()
        : widget.activityEntity.duration.toInt().toString();
    _quantityController = TextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).editItemDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: 'edit-activity-quantity-input',
            child: TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isCustom
                    ? S.of(context).customActivityKcalLabel
                    : S.of(context).quantityLabel,
                suffixText: _isCustom ? 'kcal' : 'min',
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final parsed = double.tryParse(_quantityController.text);
            if (parsed != null && parsed > 0) {
              Navigator.of(context).pop(parsed);
            }
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
      ],
    );
  }
}
