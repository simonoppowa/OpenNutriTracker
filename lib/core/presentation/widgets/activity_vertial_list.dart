import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_card.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_intake_card.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ActivityVerticalList extends StatelessWidget {
  final String title;
  final List<UserActivityEntity> userActivityList;
  final HomeBloc homeBloc;

  const ActivityVerticalList(
      {Key? key,
      required this.title,
      required this.userActivityList,
      required this.homeBloc})
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
        userActivityList.isEmpty
            ? const Align(
                alignment: Alignment.centerLeft,
                child:
                    PlaceholderIntakeCard(icon: Icons.directions_run_outlined))
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: userActivityList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final userActivity = userActivityList[index];
                    return ActivityCard(
                      activityEntity: userActivity,
                      onItemLongPressed: onItemLongPressed,
                    );
                  },
                ),
              ),
      ],
    );
  }

  void onItemLongPressed(
      BuildContext context, UserActivityEntity activityEntity) async {
    final deleteIntake = await showDialog<bool>(
        context: context, builder: (context) => const DeleteDialog());

    if (deleteIntake != null) {
      homeBloc.deleteUserActivityItem(context, activityEntity);
      homeBloc.add(LoadItemsEvent(context: context));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)));
    }
  }
}
