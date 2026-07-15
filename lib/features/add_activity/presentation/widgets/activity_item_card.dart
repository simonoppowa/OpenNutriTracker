import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';

class ActivityItemCard extends StatelessWidget {
  final PhysicalActivityEntity physicalActivityEntity;
  final DateTime day;

  const ActivityItemCard({
    super.key,
    required this.physicalActivityEntity,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing4,
        vertical: Dimens.spacing8,
      ),
      child: AppCard(
        onTap: () => _onItemPressed(context),
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                physicalActivityEntity.displayIcon,
                color: accent,
                size: 26,
              ),
            ),
            const SizedBox(width: Dimens.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    physicalActivityEntity.getName(context),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimens.spacing4),
                  AutoSizeText(
                    physicalActivityEntity.getDescription(context),
                    style: text.bodyMedium?.copyWith(color: palette.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Dimens.spacing8),
            IconButton(
              style: IconButton.styleFrom(
                foregroundColor: accent,
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _onItemPressed(context),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemPressed(BuildContext context) {
    Navigator.of(context).pushNamed(
      NavigationOptions.activityDetailRoute,
      arguments: ActivityDetailScreenArguments(physicalActivityEntity, day),
    );
  }
}
