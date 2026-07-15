import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/energy_display.dart';

/// A logged activity, rendered as a full-width row to match the meal rows: an
/// accent icon chip, the activity name and duration, and the burned energy.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(Dimens.radiusM);

    final card = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onItemTapped != null
              ? () => onItemTapped!(context, activityEntity)
              : null,
          onLongPress: onItemDragCallback == null
              ? () => onItemLongPressed(context, activityEntity)
              : null,
          child: AppCard(
            borderRadius: Dimens.radiusM,
            padding: const EdgeInsets.all(Dimens.spacing12),
            child: Row(
              children: [
                Container(
                  width: IntakeThumb.size,
                  height: IntakeThumb.size,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Dimens.radiusS),
                  ),
                  child: Icon(
                    activityEntity.physicalActivityEntity.displayIcon,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Dimens.spacing12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityEntity.physicalActivityEntity.getName(context),
                        style: textTheme.titleSmall?.copyWith(color: palette.textStrong),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activityEntity.duration.toInt()} min',
                        style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimens.spacing8),
                Text(
                  "🔥${EnergyDisplay.formatWithUnit(context, activityEntity.burnedKcal)}",
                  style: textTheme.labelMedium?.copyWith(
                    color: palette.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onItemDragCallback == null) return card;

    return LongPressDraggable<UserActivityEntity>(
      data: activityEntity,
      onDragStarted: () => onItemDragCallback!.call(true),
      onDragEnd: (_) => onItemDragCallback!.call(false),
      onDraggableCanceled: (velocity, offset) => onItemDragCallback!.call(false),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Opacity(opacity: 0.85, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

/// Shared thumbnail size so meal and activity rows line up.
abstract final class IntakeThumb {
  static const double size = 52;
}
