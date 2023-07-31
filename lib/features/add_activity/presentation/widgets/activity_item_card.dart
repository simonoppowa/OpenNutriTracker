import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';

class ActivityItemCard extends StatelessWidget {
  final PhysicalActivityEntity physicalActivityEntity;
  final DateTime day;

  const ActivityItemCard(
      {Key? key, required this.physicalActivityEntity, required this.day})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        child: SizedBox(
          height: 100,
          child: Center(
            child: ListTile(
              leading: CircleAvatar(
                radius: 40,
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(physicalActivityEntity.displayIcon,
                    color: Theme.of(context).colorScheme.onSecondaryContainer),
              ),
              title: AutoSizeText(
                physicalActivityEntity.getName(context),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: AutoSizeText(
                physicalActivityEntity.getDescription(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface),
                icon: const Icon(Icons.add_outlined),
                onPressed: () => _onItemPressed(context),
              ),
              onTap: () => _onItemPressed(context),
            ),
          ),
        ),
      ),
    );
  }

  void _onItemPressed(BuildContext context) {
    Navigator.of(context).pushNamed(NavigationOptions.activityDetailRoute,
        arguments: ActivityDetailScreenArguments(physicalActivityEntity, day));
  }
}
