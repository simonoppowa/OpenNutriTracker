import 'dart:io';

/// Double-checks that a file FilePicker.saveFile claims to have written
/// actually has bytes on disk.
///
/// FilePicker.saveFile reports success as soon as its Android platform
/// channel call returns a path - but the path can come from a content://
/// URI handed out by a document provider (this is the normal case for the
/// Downloads folder). The plugin's own write silently no-ops if the
/// provider's output stream can't be opened, and still hands back that
/// path as if all was well. See simonoppowa/OpenNutriTracker#504, where
/// exporting to Downloads reported success over a 0-byte zip.
///
/// [savedPath] isn't always something dart:io can open - content:// URIs
/// aren't real filesystem paths, so reading them back this way is a
/// best-effort check, not a guarantee. Where we can read the file back, an
/// empty or truncated result is treated as a real failure. A genuine
/// content:// URI can't be statted at all, so there we can't tell the
/// difference between "wrote nothing" and "wrote fine, just not a path we
/// can open" and stay silent rather than reporting a false failure.
/// Stat failures on a normal filesystem path (permission denied, parent
/// missing, ...) mean the write did not land and are reported.
class ExportWriteVerifier {
  const ExportWriteVerifier._();

  /// Throws a [StateError] if [savedPath] can be statted and its length
  /// differs from [expectedByteLength], or if a non-content:// path cannot
  /// be statted at all.
  static void verify(String savedPath, int expectedByteLength) {
    if (savedPath.startsWith('content://')) {
      // Not a path dart:io can stat - nothing more we can check.
      return;
    }

    final int writtenLength;
    try {
      writtenLength = File(savedPath).lengthSync();
    } on FileSystemException catch (error) {
      throw StateError(
        'Export reported success but the saved file cannot be read '
        '($savedPath: ${error.message})',
      );
    }

    if (writtenLength != expectedByteLength) {
      throw StateError(
        'Export reported success but the saved file has $writtenLength '
        'bytes instead of the expected $expectedByteLength '
        '($savedPath)',
      );
    }
  }
}
