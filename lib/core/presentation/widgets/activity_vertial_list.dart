import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_card.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_intake_card.dart';

class ActivityVerticalList extends StatelessWidget {
  final String title;
  final List<UserActivityEntity> userActivityList;
  final Function(BuildContext, UserActivityEntity) onItemLongPressedCallback;

  const ActivityVerticalList(
      {Key? key,
      required this.title,
      required this.userActivityList,
      required this.onItemLongPressedCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(UserActivityEntity.getIconData(),
                  size: 24, color: Theme.of(context).colorScheme.onBackground),
              const SizedBox(width: 4.0),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
            ],
          ),
        ),
        userActivityList.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PlaceholderIntakeCard(
                      icon: UserActivityEntity.getIconData()),
                ))
            : SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: userActivityList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final userActivity = userActivityList[index];
                    return ActivityCard(
                      activityEntity: userActivity,
                      onItemLongPressed: onItemLongPressedCallback,
                      firstListElement: index == 0 ? true : false,
                    );
                  },
                ),
              ),
      ],
    );
  }
}
