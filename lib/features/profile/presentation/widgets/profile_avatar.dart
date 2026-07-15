import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

/// Round avatar for a profile: shows the profile picture when one is set,
/// otherwise the first letter of the name, falling back to a person icon
/// for an unnamed profile.
class ProfileAvatar extends StatelessWidget {
  final ProfileEntity profile;
  final double radius;

  const ProfileAvatar({super.key, required this.profile, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = profile.imagePath;

    if (imagePath != null) {
      return FutureBuilder<String>(
        future: UserImageStorage.absolutePath(imagePath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: theme.colorScheme.primaryContainer,
            );
          }
          return CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: FileImage(File(snapshot.data!)),
          );
        },
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      child: profile.name.trim().isEmpty
          ? Icon(Icons.person_outline, size: radius)
          : Text(
              profile.name.trim().characters.first.toUpperCase(),
              style: TextStyle(fontSize: radius * 0.9),
            ),
    );
  }
}
