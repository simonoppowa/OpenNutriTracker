import 'dart:io';

/// Double-checks that a file FilePicker.saveFile claims to have written
/// actually has bytes on disk.
///
/// FilePicker.saveFile reports success as soon as its Android platform
/// channel call returns a URI - but the URI can use the content scheme
/// URI handed out by a document provider (this is the normal case for the
/// Downloads folder). The plugin's own write silently no-ops if the
/// provider's output stream can't be opened, and still hands back that
/// path as if all was well. See simonoppowa/OpenNutriTracker#504, where
/// exporting to Downloads reported success over a 0-byte zip.
///
/// [savedUri] isn't always something dart:io can open - content:// URIs
/// aren't filesystem locations, so reading them back this way is a
/// best-effort check, not a guarantee. Where we can read the file back, an
/// empty or truncated result is treated as a real failure. A genuine
/// content:// URI can't be statted at all, so there we can't tell the
/// difference between "wrote nothing" and "wrote fine, just not a path we
/// can open" and stay silent rather than reporting a false failure.
/// Stat failures on a normal filesystem path (permission denied, parent
/// missing, ...) mean the write did not land and are reported.
class ExportWriteVerifier {
  const ExportWriteVerifier._();

  /// Throws a [StateError] if a file [savedUri] can be statted and its length
  /// differs from [expectedByteLength], or if that file cannot be statted.
  static void verify(Uri savedUri, int expectedByteLength) {
    if (!savedUri.isScheme('file')) {
      // Document-provider URIs are not locations dart:io can stat.
      return;
    }

    final int writtenLength;
    try {
      writtenLength = File.fromUri(savedUri).lengthSync();
    } on FileSystemException catch (error) {
      throw StateError(
        'Export reported success but the saved file cannot be read '
        '($savedUri: ${error.message})',
      );
    }

    if (writtenLength != expectedByteLength) {
      throw StateError(
        'Export reported success but the saved file has $writtenLength '
        'bytes instead of the expected $expectedByteLength '
        '($savedUri)',
      );
    }
  }
}
