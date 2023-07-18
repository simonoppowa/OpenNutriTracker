import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

class ActivityCard extends StatelessWidget {
  final UserActivityEntity activityEntity;
  final Function(BuildContext, UserActivityEntity) onItemLongPressed;
  final bool firstListElement;

  const ActivityCard(
      {super.key,
      required this.activityEntity,
      required this.onItemLongPressed,
      required this.firstListElement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: firstListElement ? 16 : 0, // Add leading padding
        ),
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  child: InkWell(
                    onLongPress: () {
                      onLongPressedItem(context);
                    },
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer
                                  .withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            "🔥${activityEntity.burnedKcal.toInt()} kcal",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer),
                          ),
                        ),
                        Center(
                          child: Icon(
                            activityEntity.physicalActivityEntity.displayIcon,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  activityEntity.physicalActivityEntity.getName(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${activityEntity.duration.toInt()} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.8)),
                    maxLines: 1,
                  ))
            ],
          ),
        ),
      ],
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed(context, activityEntity);
  }
}
