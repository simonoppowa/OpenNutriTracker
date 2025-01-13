import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailNutrimentsTable extends StatelessWidget {
  final MealEntity product;
  final bool usesImperialUnits;
  final double? servingQuantity;
  final String? servingUnit;

  const MealDetailNutrimentsTable(
      {super.key,
      required this.product,
      required this.usesImperialUnits,
      this.servingQuantity,
      this.servingUnit});

  @override
  Widget build(BuildContext context) {
    final textStyleNormal =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textStyleBold = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle();

    final headerText = usesImperialUnits && servingQuantity != null
        ? "${S.of(context).perServingLabel} (${servingQuantity!.roundToPrecision(1)}${servingUnit ?? 'g/ml'})"
        : S.of(context).per100gmlLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).nutritionInfoLabel,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16.0),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5)),
          children: <TableRow>[
            _getNutrimentsTableRow("", headerText, textStyleBold),
            _getNutrimentsTableRow(
                S.of(context).energyLabel,
                "${_adjustValueForServing(product.nutriments.energyKcal100?.toDouble() ?? 0).toInt()} ${S.of(context).kcalLabel}",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).fatLabel,
                "${_adjustValueForServing(product.nutriments.fat100 ?? 0).roundToPrecision(2)}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                '   ${S.of(context).saturatedFatLabel}',
                "${_adjustValueForServing(product.nutriments.saturatedFat100 ?? 0).roundToPrecision(2)}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).carbohydrateLabel,
                "${_adjustValueForServing(product.nutriments.carbohydrates100 ?? 0).roundToPrecision(2)}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                '    ${S.of(context).sugarLabel}',
                "${_adjustValueForServing(product.nutriments.sugars100 ?? 0).roundToPrecision(2)}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).fiberLabel,
                "${_adjustValueForServing(product.nutriments.fiber100 ?? 0).roundToPrecision(2)}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).proteinLabel,
                "${_adjustValueForServing(product.nutriments.proteins100 ?? 0).roundToPrecision(2)}g",
                textStyleNormal)
          ],
        )
      ],
    );
  }

  double _adjustValueForServing(double value) {
    if (!usesImperialUnits || servingQuantity == null) {
      return value;
    }
    // Calculate per serving value based on 100g reference
    return (value * servingQuantity!) / 100;
  }

  TableRow _getNutrimentsTableRow(
      String label, String quantityString, TextStyle textStyle) {
    return TableRow(children: <Widget>[
      Container(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(label, style: textStyle)),
      Container(
          padding: const EdgeInsets.only(right: 8.0),
          alignment: Alignment.centerRight,
          child: Text(quantityString, style: textStyle)),
    ]);
  }
}
