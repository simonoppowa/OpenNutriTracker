import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';

class ActivityCard extends StatelessWidget {
  final UserActivityEntity activityEntity;
  final Function(BuildContext, UserActivityEntity) onItemLongPressed;
  final Function(BuildContext, UserActivityEntity)? onItemTapped;
  final Function(bool isDragging)? onItemDragCallback;
  final bool firstListElement;

  const ActivityCard({
    super.key,
    required this.activityEntity,
    required this.onItemLongPressed,
    required this.firstListElement,
    this.onItemTapped,
    this.onItemDragCallback,
  });

  @override
  Widget build(BuildContext context) {
    final card = Row(
      children: [
        SizedBox(
          width: firstListElement ? 16 : 0,
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
                    onTap: onItemTapped != null
                        ? () => onItemTapped!(context, activityEntity)
                        : null,
                    onLongPress: onItemDragCallback == null
                        ? () => onItemLongPressed(context, activityEntity)
                        : null,
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "🔥${EnergyDisplay.formatWithUnit(context, activityEntity.burnedKcal)}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                            .onSurface
                            .withValues(alpha: 0.8),
                      ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onItemDragCallback == null) return card;

    return LongPressDraggable<UserActivityEntity>(
      data: activityEntity,
      onDragStarted: () => onItemDragCallback!.call(true),
      onDragEnd: (_) => onItemDragCallback!.call(false),
      onDraggableCanceled: (velocity, offset) => onItemDragCallback!.call(false),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(
            activityEntity.physicalActivityEntity.displayIcon,
            size: 36,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }
}
