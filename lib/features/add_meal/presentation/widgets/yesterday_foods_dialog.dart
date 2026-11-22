import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

class YesterdayFoodsDialog extends StatefulWidget {
  final DateTime day;
  final Map<AddMealType, List<IntakeEntity>> intakes;
  final bool usesImperialUnits;

  const YesterdayFoodsDialog({
    super.key,
    required this.day,
    required this.intakes,
    required this.usesImperialUnits,
  });

  @override
  State<YesterdayFoodsDialog> createState() => _YesterdayFoodsDialogState();
}

class _YesterdayFoodsDialogState extends State<YesterdayFoodsDialog> {
  AddMealType? _source;
  final _selected = <IntakeEntity>{};

  @override
  Widget build(BuildContext context) {
    final empty = widget.intakes.values.every((intakes) => intakes.isEmpty);
    final intakes = widget.intakes[_source] ?? const <IntakeEntity>[];
    return AlertDialog(
      title: Text(S.of(context).reuseYesterdayLabel),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(DateFormat.yMMMMEEEEd().format(widget.day)),
            if (!empty)
              Semantics(
                identifier: 'yesterday-source-meal',
                child: DropdownButton<AddMealType>(
                  value: _source,
                  isExpanded: true,
                  itemHeight: null,
                  hint: Text(
                    S.of(context).reuseYesterdaySourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  items: AddMealType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.getTypeName(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (type) => setState(() {
                    _source = type;
                    _selected.clear();
                  }),
                ),
              ),
            if (empty || (_source != null && intakes.isEmpty))
              Text(S.of(context).nothingAddedLabel),
            if (intakes.isNotEmpty)
              Flexible(
                child: Semantics(
                  identifier: 'yesterday-foods-list',
                  container: true,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: intakes.length,
                    itemBuilder: (context, index) {
                      final intake = intakes[index];
                      return CheckboxListTile(
                        value: _selected.contains(intake),
                        title: Text(intake.meal.name ?? '?'),
                        subtitle: MealValueUnitText(
                          value: intake.amount,
                          meal: intake.meal,
                          usesImperialUnits: widget.usesImperialUnits,
                        ),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selected.add(intake);
                          } else {
                            _selected.remove(intake);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
