import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves the on-disk location of user-attached recipe photos.
///
/// Only the *relative* slug (e.g. `recipe_images/<id>.jpg`) is persisted on
/// the RecipeDBO. The absolute path is recomposed on demand so the data
/// survives across app reinstalls and iOS sandbox refreshes, where the
/// documents directory's parent prefix can change between launches.
class RecipeImageStorage {
  static const String _subdir = 'recipe_images';

  /// The relative slug stored on RecipeDBO.imagePath for a given recipe id.
  static String relativePathFor(String recipeId) => '$_subdir/$recipeId.jpg';

  /// Splits a relative slug back into its parts. Returns null for any
  /// path that isn't of the form `recipe_images/<file>`. Defensive so that
  /// a malformed value from an old export can't escape the recipe-images
  /// directory.
  static String? sanitizeRelative(String relative) {
    final parts = relative.split('/');
    if (parts.length != 2) return null;
    if (parts[0] != _subdir) return null;
    if (parts[1].isEmpty || parts[1].contains('..')) return null;
    return '$_subdir/${parts[1]}';
  }

  /// Absolute path that corresponds to `relativePath` inside the app's
  /// private documents directory. Use this for `File(...)` operations.
  static Future<String> absolutePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$relativePath';
  }

  /// Absolute path to the `recipe_images` directory itself. Created if
  /// missing.
  static Future<Directory> ensureDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/$_subdir');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Copies `sourcePath` into the recipe-images directory under
  /// `<recipeId>.jpg` and returns the relative slug to persist.
  /// The source file is left untouched.
  static Future<String> importFrom({
    required String recipeId,
    required String sourcePath,
  }) async {
    final imagesDir = await ensureDirectory();
    final destPath = '${imagesDir.path}/$recipeId.jpg';
    final source = File(sourcePath);
    await source.copy(destPath);
    return relativePathFor(recipeId);
  }

  /// Removes the file at `relativePath` if it exists. Silent no-op when
  /// the file is already gone — callers don't need to special-case that.
  static Future<void> delete(String relativePath) async {
    final sanitized = sanitizeRelative(relativePath);
    if (sanitized == null) return;
    final absolute = await absolutePath(sanitized);
    final file = File(absolute);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
