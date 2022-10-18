import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealIntakeList extends StatelessWidget {
  final String title;
  final List<IntakeEntity> intakeList;

  const MealIntakeList(
      {Key? key, required this.title, required this.intakeList})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: intakeList.length,
            itemBuilder: (BuildContext context, int index) {
              final intakeEntity = intakeList[index];
              return IntakeCard(
                  key: ValueKey(intakeEntity.product.code),
                  intakeName: intakeEntity.product.productName ?? "",
                  subtitle:
                      '${intakeEntity.amount.toString()}${intakeEntity.unit}',
                  kcalText:
                      '${intakeEntity.product.nutriments.energyKcal100?.toInt()} kcal',
                  intakeImageUrl: intakeEntity.product.mainImageUrl);
            },
          ),
        ),
      ],
    );
  }
}
