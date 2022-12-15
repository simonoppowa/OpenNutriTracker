import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

class ActivityCard extends StatelessWidget {
  final UserActivityEntity activityEntity;
  final Function(BuildContext, UserActivityEntity) onItemLongPressed;

  const ActivityCard(
      {Key? key, required this.activityEntity, required this.onItemLongPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Card(
        margin: const EdgeInsets.only(right: 8.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        child: InkWell(
          onLongPress: () {
            onLongPressedItem(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(activityEntity
                              .physicalActivityEntity.displayIcon),
                        ))
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityEntity.physicalActivityEntity.getName(context),
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                    ),
                    Text("🔥${activityEntity.burnedKcal.toInt()} kcal",
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.subtitle2?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.7)))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed(context, activityEntity);
  }
}
