import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';

/// Resolves the stored relative slug inside the current app sandbox.
class LocalUserImage extends StatelessWidget {
  const LocalUserImage({
    super.key,
    required this.relativePath,
    required this.width,
    required this.height,
    required this.placeholder,
  });

  final String relativePath;
  final double width;
  final double height;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: FutureBuilder<String>(
      future: UserImageStorage.absolutePath(relativePath),
      builder: (context, snapshot) => snapshot.hasData
          ? Image.file(
              File(snapshot.data!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    ),
  );
}
