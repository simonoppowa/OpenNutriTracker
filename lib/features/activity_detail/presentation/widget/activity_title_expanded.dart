import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class ActivityTitleExpanded extends StatelessWidget {
  final PhysicalActivityEntity activity;

  const ActivityTitleExpanded({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AutoSizeText.rich(
                minFontSize: 6,
                maxFontSize: 16,
                TextSpan(
                    text: activity.getName(context),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground),
                    children: [
                      TextSpan(
                        text: ' ${activity.getDescription(context)} ',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7)),
                      )
                    ]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
