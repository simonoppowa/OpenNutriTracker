import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailNutrimentsTable extends StatelessWidget {
  final MealEntity product;

  const MealDetailNutrimentsTable({Key? key, required this.product})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyleNormal =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textStyleBold = Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).nutritionInfoLabel,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16.0),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
          children: <TableRow>[
            _getNutrimentsTableRow(
                "", S.of(context).per100gLabel, textStyleBold),
            _getNutrimentsTableRow(
                S.of(context).energyLabel,
                "${product.nutriments.energyKcal100?.toInt() ?? "?"} ${S.of(context).kcalLabel}",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).fatLabel,
                "${product.nutriments.fat100?.roundToPrecision(2) ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                '   ${S.of(context).saturatedFatLabel}',
                "${product.nutriments.saturatedFat100?.roundToPrecision(2) ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).carbohydrateLabel,
                "${product.nutriments.carbohydrates100?.roundToPrecision(2) ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                '    ${S.of(context).sugarLabel}',
                "${product.nutriments.sugars100?.roundToPrecision(2) ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).fiberLabel,
                "${product.nutriments.fiber100?.roundToPrecision(2) ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).proteinLabel,
                "${product.nutriments.proteins100?.roundToPrecision(2) ?? "?"}g",
                textStyleNormal)
          ],
        )
      ],
    );
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
