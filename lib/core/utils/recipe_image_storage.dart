import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves the on-disk location of user-attached recipe photos.
///
/// Only the *relative* slug (e.g. `recipe_images/<id>.webp`) is persisted on
/// the RecipeDBO. The absolute path is recomposed on demand so the data
/// survives across app reinstalls and iOS sandbox refreshes, where the
/// documents directory's parent prefix can change between launches.
///
/// Photos are stored as WebP at quality 80, capped at 1024px on the longest
/// edge — small enough that an export zip of a few dozen recipes stays in
/// the low-megabyte range, while still being plenty crisp for a list
/// thumbnail and the recipe-detail header. The original branch used JPEG;
/// WebP halves the bytes for visually-equivalent quality and is supported
/// natively on every Android and iOS version the app targets.
class RecipeImageStorage {
  static const String _subdir = 'recipe_images';
  static const String _extension = 'webp';

  /// The relative slug stored on RecipeDBO.imagePath for a given recipe id.
  static String relativePathFor(String recipeId) =>
      '$_subdir/$recipeId.$_extension';

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

  /// Reads `sourcePath`, re-encodes it to WebP (quality 80, longest edge
  /// 1024px), writes the result to the recipe-images directory under
  /// `<recipeId>.webp`, and returns the relative slug to persist. The
  /// source file is left untouched.
  ///
  /// If the on-device WebP encoder is unavailable for some reason (very
  /// old hardware, simulator quirks), `FlutterImageCompress` returns
  /// `null` and we fall back to copying the source bytes verbatim — the
  /// file extension stays `.webp` either way so callers don't have to
  /// branch on it.
  static Future<String> importFrom({
    required String recipeId,
    required String sourcePath,
  }) async {
    final imagesDir = await ensureDirectory();
    final destPath = '${imagesDir.path}/$recipeId.$_extension';
    final compressed = await _compressToWebP(sourcePath);
    if (compressed != null) {
      await File(destPath).writeAsBytes(compressed, flush: true);
    } else {
      await File(sourcePath).copy(destPath);
    }
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

  static Future<Uint8List?> _compressToWebP(String sourcePath) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        sourcePath,
        format: CompressFormat.webp,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
        // `minWidth`/`minHeight` are upper bounds for the *longest* edge
        // when the source exceeds them; the compressor preserves aspect
        // ratio. Shorter-edge images pass through untouched.
      );
    } catch (_) {
      return null;
    }
  }
}
