import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ItemDetailNutrimentsTable extends StatelessWidget {
  const ItemDetailNutrimentsTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyleNormal =
        Theme.of(context).textTheme.bodyText2 ?? const TextStyle();
    final textStyleBold = Theme.of(context)
            .textTheme
            .bodyText2
            ?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context).nutritionInfoLabel,
            style: Theme.of(context).textTheme.headline6),
        const SizedBox(height: 8.0),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(),
          children: <TableRow>[
            _getNutrimentsTableRow(
                "", S.of(context).per100gLabel, textStyleBold),
            _getNutrimentsTableRow(
                S.of(context).energyLabel, "241 kcal", textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).fatLabel, "13g", textStyleNormal),
            _getNutrimentsTableRow('   ${S.of(context).saturatedFatLabel}',
                "10.7g", textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).carbohydrateLabel, "12.0g", textStyleNormal),
            _getNutrimentsTableRow(
                '    ${S.of(context).sugarLabel}', "8.3g", textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).fiberLabel, "0g", textStyleNormal),
            _getNutrimentsTableRow(
                S.of(context).proteinLabel, "2.4g", textStyleNormal)
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
