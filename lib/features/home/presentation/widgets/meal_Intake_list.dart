import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_intake_card.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealIntakeList extends StatelessWidget {
  final HomeBloc homeBloc;
  final String title;
  final IconData listIcon;
  final List<IntakeEntity> intakeList;

  const MealIntakeList(
      {Key? key,
      required this.homeBloc,
      required this.title,
      required this.listIcon,
      required this.intakeList})
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
        intakeList.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: PlaceholderIntakeCard(
                  icon: listIcon,
                ))
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: intakeList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final intakeEntity = intakeList[index];
                    return IntakeCard(
                        key: ValueKey(intakeEntity.product.code),
                        intake: intakeEntity,
                        onItemLongPressed: onItemLongPressed);
                  },
                ),
              ),
      ],
    );
  }

  void onItemLongPressed(
      BuildContext context, IntakeEntity intakeEntity) async {
    final deleteIntake = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (deleteIntake != null) {
      homeBloc.deleteIntakeItem(context, intakeEntity);
      homeBloc.add(LoadItemsEvent(context: context));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
    }
  }
}
