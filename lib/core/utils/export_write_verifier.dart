import 'dart:io';

/// Double-checks that a file FilePicker.saveFile claims to have written
/// actually has bytes on disk.
///
/// FilePicker.saveFile reports success as soon as its Android platform
/// channel call returns a URI - but that URI can use the content scheme
/// handed out by a document provider (this is the normal case for the
/// Downloads folder). The plugin's own write silently no-ops if the
/// provider's output stream can't be opened, and still hands back that
/// URI as if all was well. See simonoppowa/OpenNutriTracker#504, where
/// exporting to Downloads reported success over a 0-byte zip.
///
/// [savedUri] isn't always something dart:io can open - content:// URIs
/// aren't filesystem locations, so reading them back this way is a
/// best-effort check, not a guarantee. Where we can read the file back, an
/// empty or truncated result is treated as a real failure. A genuine
/// content:// URI can't be statted at all, so there we can't tell the
/// difference between "wrote nothing" and "wrote fine, just not a location
/// we can open" and stay silent rather than reporting a false failure.
/// Stat failures on a file: URI (permission denied, parent missing, ...)
/// mean the write did not land and are reported.
class ExportWriteVerifier {
  const ExportWriteVerifier._();

  /// Checks the bytes behind [savedUri], where that is something dart:io can
  /// open.
  ///
  /// Returns without checking anything when [savedUri] is not a file: URI. A
  /// document provider's content:// URI is not a location that can be
  /// statted, so a failure reported there would be a false alarm rather than
  /// a caught bug.
  ///
  /// For a file: URI, throws a [StateError] if the file cannot be statted, or
  /// if its length differs from [expectedByteLength].
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
