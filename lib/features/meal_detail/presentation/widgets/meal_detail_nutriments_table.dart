import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailNutrimentsTable extends StatelessWidget {
  final ProductEntity product;

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
        const SizedBox(height: 8.0),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(),
          children: <TableRow>[
            _getNutrimentsTableRow(
                "", S.of(context).per100gLabel, textStyleBold),
            _getNutrimentsTableRow(
                S.of(context).energyLabel,
                "${product.nutriments.energyKcal100?.toInt() ?? "?"} ${S.of(context).kcalLabel}",
                textStyleNormal),
            _getNutrimentsTableRow(S.of(context).fatLabel,
                "${product.nutriments.fat100g ?? "?"}g", textStyleNormal),
            _getNutrimentsTableRow(
                '   ${S.of(context).saturatedFatLabel}',
                "${product.nutriments.saturatedFat100g ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).carbohydrateLabel,
                "${product.nutriments.carbohydrates100g ?? "?"}g",
                textStyleNormal),
            _getNutrimentsTableRow('    ${S.of(context).sugarLabel}',
                "${product.nutriments.sugars100g ?? "?"}g", textStyleNormal),
            _getNutrimentsTableRow(S.of(context).fiberLabel,
                "${product.nutriments.fiber100g ?? "?"}g", textStyleNormal),
            _getNutrimentsTableRow(S.of(context).proteinLabel,
                "${product.nutriments.proteins100g ?? "?"}g", textStyleNormal)
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
