import 'package:auto_size_text/auto_size_text.dart';
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
        elevation: 1,
        margin: const EdgeInsets.only(right: 8.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        child: InkWell(
          onLongPress: () {
            onLongPressedItem(context);
          },
          child: Stack(
            children: [
              Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiaryContainer
                          .withOpacity(0.5),
                      shape: BoxShape.circle),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      activityEntity.physicalActivityEntity.displayIcon,
                      size: 26,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      activityEntity.physicalActivityEntity.getName(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                          height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                    AutoSizeText("🔥${activityEntity.burnedKcal.toInt()} kcal",
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer
                                .withOpacity(0.6)))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed(context, activityEntity);
  }
}
