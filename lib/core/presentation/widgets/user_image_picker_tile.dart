import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Shared picker tile used by both the recipe builder and the Edit
/// Meal screen so the affordance feels the same in either place: a
/// circular preview with a small overlay icon at the bottom-right,
/// and a single line of text underneath. Tapping anywhere on the
/// tile opens a bottom sheet with Take photo / Choose from gallery
/// (and Remove when the user already has an image).
///
/// Callers pass the `UserImageKind` they're picking for; the tile
/// resolves the right localised strings (`recipeImage*` vs
/// `mealImage*`), the right fallback icon, and the right Semantics
/// identifier from that single value. The two namespaces stay
/// distinct in code even though the English surface text happens to
/// be the same in both places — see the i18n keys.
class UserImagePickerTile extends StatelessWidget {
  final UserImageKind kind;
  final String? imagePath;
  final Future<void> Function() onPickFromGallery;
  final Future<void> Function() onTakePhoto;
  final Future<void> Function() onRemove;

  const UserImagePickerTile({
    super.key,
    required this.kind,
    required this.imagePath,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.onRemove,
  });

  IconData get _fallbackIcon => switch (kind) {
        UserImageKind.recipe => Icons.restaurant_menu,
        UserImageKind.meal => Icons.restaurant_outlined,
      };

  String get _semanticsIdentifier => switch (kind) {
        UserImageKind.recipe => 'recipe-builder-image-picker',
        UserImageKind.meal => 'edit-meal-image-picker',
      };

  _Strings _stringsFor(BuildContext context) {
    final s = S.of(context);
    return switch (kind) {
      UserImageKind.recipe => _Strings(
          add: s.recipeImageLabel,
          replace: s.recipeImageReplace,
          takePhoto: s.recipeImageTakePhoto,
          pickFromGallery: s.recipeImagePickFromGallery,
          remove: s.recipeImageRemove,
        ),
      UserImageKind.meal => _Strings(
          add: s.mealImageLabel,
          replace: s.mealImageReplace,
          takePhoto: s.mealImageTakePhoto,
          pickFromGallery: s.mealImagePickFromGallery,
          remove: s.mealImageRemove,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imagePath != null;
    final strings = _stringsFor(context);
    return Semantics(
      identifier: _semanticsIdentifier,
      child: InkWell(
        borderRadius: BorderRadius.circular(64),
        onTap: () => _showActionSheet(context, strings, hasImage: hasImage),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: hasImage
                          ? FutureBuilder<String>(
                              future:
                                  UserImageStorage.absolutePath(imagePath!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    color: theme.colorScheme.primaryContainer,
                                  );
                                }
                                return Image.file(
                                  File(snapshot.data!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) => Container(
                                    color: theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      _fallbackIcon,
                                      color: theme
                                          .colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: theme.colorScheme.primaryContainer,
                              child: Icon(
                                _fallbackIcon,
                                size: 36,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      hasImage ? Icons.edit : Icons.camera_alt,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasImage ? strings.replace : strings.add,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActionSheet(
    BuildContext context,
    _Strings strings, {
    required bool hasImage,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(strings.takePhoto),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onTakePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(strings.pickFromGallery),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onPickFromGallery();
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(strings.remove),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onRemove();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Strings {
  final String add;
  final String replace;
  final String takePhoto;
  final String pickFromGallery;
  final String remove;

  const _Strings({
    required this.add,
    required this.replace,
    required this.takePhoto,
    required this.pickFromGallery,
    required this.remove,
  });
}
