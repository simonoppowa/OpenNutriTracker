import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

/// A photo the user attached to a recipe or a custom meal, read from the
/// app's documents directory, with [fallback] in its place while the path
/// resolves and whenever the photo can't be shown: the file was deleted,
/// the stored value is not a user-image slug, or the bytes don't decode.
///
/// [storedPath] is the value as persisted (`recipe_images/<id>.webp`); see
/// [UserImageStorage.existingFile] for how it is resolved.
class UserImage extends StatefulWidget {
  final String storedPath;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  const UserImage({
    super.key,
    required this.storedPath,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<UserImage> createState() => _UserImageState();
}

class _UserImageState extends State<UserImage> {
  late Future<File?> _file;

  @override
  void initState() {
    super.initState();
    _file = UserImageStorage.existingFile(widget.storedPath);
  }

  @override
  void didUpdateWidget(UserImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedPath != widget.storedPath) {
      _file = UserImageStorage.existingFile(widget.storedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return widget.fallback;
        return Image.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}
