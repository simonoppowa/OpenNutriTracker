import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class IntakeCard extends StatelessWidget {
  final String intakeName;
  final String subtitle;
  final String kcalText;
  final String? intakeImageUrl;

  const IntakeCard(
      {Key? key,
      required this.intakeName,
      required this.subtitle,
      required this.kcalText,
      required this.intakeImageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      child: Card(
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: intakeImageUrl ?? "",
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                )),
              ),
            ),
            Container(
              // Add color shade
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(80),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                kcalText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
              ),
            ),
            Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(intakeName,
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary)),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.subtitle2?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.8))),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
