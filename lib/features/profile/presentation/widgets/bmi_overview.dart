import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/info_dialog.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/generated/l10n.dart';

class BMIOverview extends StatelessWidget {
  final double bmiValue;
  final UserNutritionalStatus nutritionalStatus;

  const BMIOverview(
      {Key? key, required this.bmiValue, required this.nutritionalStatus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(36.0),
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: getContainerColorTheme(context)),
          child: Column(
            children: [
              Text(
                '${bmiValue.roundToPrecision(1)}',
                style: getContainerTextStyle(
                    context,
                    Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ),
              Text(S.of(context).bmiLabel,
                  style: getContainerTextStyle(
                      context, Theme.of(context).textTheme.titleLarge))
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(nutritionalStatus.getName(context),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            InkWell(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => InfoDialog(
                            title: S.of(context).bmiLabel,
                            body: S.of(context).bmiInfo,
                          ));
                },
                child: const Icon(Icons.help_outline_outlined))
          ],
        ),
        Text(
          S.of(context).nutritionalStatusRiskLabel(
              nutritionalStatus.getRiskStatus(context)),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
        )
      ],
    );
  }

  Color getContainerColorTheme(BuildContext context) {
    Color theme;
    switch (nutritionalStatus) {
      case UserNutritionalStatus.underWeight:
        theme = Theme.of(context).colorScheme.errorContainer.withOpacity(0.1);
        break;
      case UserNutritionalStatus.normalWeight:
        theme = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6);
        break;
      case UserNutritionalStatus.preObesity:
        theme = Theme.of(context).colorScheme.errorContainer.withOpacity(0.2);
        break;
      case UserNutritionalStatus.obesityClassI:
        theme = Theme.of(context).colorScheme.errorContainer.withOpacity(0.4);
        break;
      case UserNutritionalStatus.obesityClassII:
        theme = Theme.of(context).colorScheme.errorContainer.withOpacity(0.7);
        break;
      case UserNutritionalStatus.obesityClassIII:
        theme = Theme.of(context).colorScheme.errorContainer;
        break;
    }
    return theme;
  }

  TextStyle? getContainerTextStyle(BuildContext context, TextStyle? style) {
    TextStyle? textStyle;
    switch (nutritionalStatus) {
      case UserNutritionalStatus.underWeight:
        textStyle = style?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer);
        break;
      case UserNutritionalStatus.normalWeight:
        textStyle = style?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer);
        break;
      case UserNutritionalStatus.preObesity:
        textStyle = style?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer);
        break;
      case UserNutritionalStatus.obesityClassI:
        textStyle = style?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer);
        break;
      case UserNutritionalStatus.obesityClassII:
        textStyle = style?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer);
        break;
      case UserNutritionalStatus.obesityClassIII:
        textStyle = style?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer);
        break;
    }
    return textStyle;
  }
}
