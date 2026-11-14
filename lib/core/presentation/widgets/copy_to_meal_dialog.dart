import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Picks the meal "Copy to other meal" copies into (#842): every meal type
/// but [source], the one being copied. Pops the chosen [AddMealType], or
/// null on Cancel.
class CopyToMealDialog extends StatelessWidget {
  final AddMealType source;

  const CopyToMealDialog({super.key, required this.source});

  /// The Semantics identifier of the option for [type].
  static String semanticsIdFor(AddMealType type) =>
      'copy-to-meal-${type.getIntakeType().name}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Title and options scroll together: at a large font on a small
      // phone the title alone can take most of the height.
      scrollable: true,
      title: Text(S.of(context).copyDialogTitle),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in AddMealType.values)
            if (type != source)
              Semantics(
                identifier: semanticsIdFor(type),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(type.getIntakeType().getIconData()),
                  title: Text(type.getTypeName(context)),
                  onTap: () => Navigator.of(context).pop(type),
                ),
              ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
      ],
    );
  }
}
