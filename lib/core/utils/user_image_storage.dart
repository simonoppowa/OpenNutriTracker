import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Two flavours of user-attached photo the app persists on disk.
///
/// Recipes live under `recipe_images/`, custom meals live under
/// `meal_images/`. The subdirectory split keeps the two namespaces
/// distinct on disk (so export zips can label them clearly and a
/// runaway filename collision on one side can't quietly overwrite the
/// other) while sharing one compression pipeline. The two are different
/// kinds of thing in the domain model — a recipe is a composition of
/// meals — and the storage layer now reflects that distinction.
enum UserImageKind {
  recipe('recipe_images'),
  meal('meal_images'),
  profile('profile_images');

  const UserImageKind(this.subdir);

  final String subdir;
}

/// Resolves the on-disk location of user-attached photos for either a
/// recipe (#64) or a custom meal (#64 follow-up). Only the *relative*
/// slug (e.g. `meal_images/<code>.webp`) is persisted on the matching
/// DBO; the absolute path is recomposed on demand so the data survives
/// across app reinstalls and iOS sandbox refreshes, where the documents
/// directory's parent prefix can change between launches.
///
/// Photos are stored as WebP at quality 80, capped at 1024px on the
/// longest edge — small enough that an export zip of a few dozen
/// recipes and meals stays in the low-megabyte range, while still
/// being plenty crisp for a list thumbnail and the detail-screen
/// header. WebP roughly halves the bytes of an equivalent-quality JPEG
/// and is supported natively on every Android and iOS version the app
/// targets.
class UserImageStorage {
  static const String _extension = 'webp';

  /// The relative slug stored on the DBO for a given owner id.
  static String relativePathFor(UserImageKind kind, String ownerId) =>
      '${kind.subdir}/$ownerId.$_extension';

  /// Splits a relative slug back into its parts. Returns null for any
  /// path that doesn't sit inside one of the known image
  /// subdirectories. Defensive so that a malformed value from an old
  /// export can't escape its images directory.
  static String? sanitizeRelative(String relative) {
    final parts = relative.split('/');
    if (parts.length != 2) return null;
    final knownDirs = {for (final k in UserImageKind.values) k.subdir};
    if (!knownDirs.contains(parts[0])) return null;
    if (parts[1].isEmpty || parts[1].contains('..')) return null;
    return '${parts[0]}/${parts[1]}';
  }

  /// True when `relative` is one of our user-image slugs. Used by
  /// import to decide whether a zip entry should be restored into
  /// the documents directory or skipped.
  static bool isUserImagePath(String relative) =>
      sanitizeRelative(relative) != null;

  /// Absolute path that corresponds to `relativePath` inside the
  /// app's private documents directory. Use this for `File(...)`
  /// operations.
  static Future<String> absolutePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$relativePath';
  }

  /// Absolute path to the relevant images directory itself. Created
  /// if missing.
  static Future<Directory> ensureDirectory(UserImageKind kind) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/${kind.subdir}');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Reads `sourcePath`, re-encodes it to WebP (quality 80, longest
  /// edge 1024px), writes the result to the matching images directory
  /// under `<ownerId>.webp`, and returns the relative slug to persist.
  /// The source file is left untouched.
  ///
  /// If the on-device WebP encoder is unavailable for some reason
  /// (very old hardware, simulator quirks), `FlutterImageCompress`
  /// returns `null` and we fall back to copying the source bytes
  /// verbatim — the file extension stays `.webp` either way so callers
  /// don't have to branch on it.
  static Future<String> importFrom({
    required UserImageKind kind,
    required String ownerId,
    required String sourcePath,
  }) async {
    final imagesDir = await ensureDirectory(kind);
    final destPath = '${imagesDir.path}/$ownerId.$_extension';
    final compressed = await _compressToWebP(sourcePath);
    if (compressed != null) {
      await File(destPath).writeAsBytes(compressed, flush: true);
    } else {
      await File(sourcePath).copy(destPath);
    }
    return relativePathFor(kind, ownerId);
  }

  /// Removes the file at `relativePath` if it exists. Silent no-op
  /// when the file is already gone — callers don't need to
  /// special-case that.
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
        // `minWidth`/`minHeight` are upper bounds for the *longest*
        // edge when the source exceeds them; the compressor preserves
        // aspect ratio. Shorter-edge images pass through untouched.
      );
    } catch (_) {
      return null;
    }
  }
}
