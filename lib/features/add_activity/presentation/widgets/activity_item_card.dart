import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';

class ActivityItemCard extends StatelessWidget {
  final PhysicalActivityEntity physicalActivityEntity;

  const ActivityItemCard({Key? key, required this.physicalActivityEntity})
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
              title: Text(
                physicalActivityEntity.getName(context),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
              subtitle: Text('${physicalActivityEntity.mets} METs'),
              trailing: IconButton(
                style: IconButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer),
                icon: const Icon(Icons.add_outlined),
                onPressed: () {},
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
        arguments: ActivityDetailScreenArguments(physicalActivityEntity));
  }
}
