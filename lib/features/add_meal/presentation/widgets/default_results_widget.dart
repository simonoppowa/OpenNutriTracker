import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DefaultsResultsWidget extends StatelessWidget {
  const DefaultsResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(S.of(context).searchDefaultLabel),
    );
  }
}
