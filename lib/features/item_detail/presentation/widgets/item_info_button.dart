import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ItemInfoButton extends StatelessWidget {
  const ItemInfoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        S.of(context).additionalInfoLabelOFF,
        style: Theme.of(context)
            .textTheme
            .subtitle1
            ?.copyWith(decoration: TextDecoration.underline),
        textAlign: TextAlign.center,
      ),
    );
  }
}
