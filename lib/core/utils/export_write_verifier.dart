import 'dart:io';

/// Double-checks that a file FilePicker.saveFile claims to have written
/// actually has bytes on disk.
///
/// FilePicker.saveFile reports success as soon as its Android platform
/// channel call returns a path — but the path can come from a content://
/// URI handed out by a document provider (this is the normal case for the
/// Downloads folder). The plugin's own write silently no-ops if the
/// provider's output stream can't be opened, and still hands back that
/// path as if all was well. See simonoppowa/OpenNutriTracker#504, where
/// exporting to Downloads reported success over a 0-byte zip.
///
/// [savedPath] isn't always something dart:io can open — content:// URIs
/// aren't real filesystem paths, so reading them back this way is a
/// best-effort check, not a guarantee. Where we can read the file back, an
/// empty result is treated as a real failure. Where we can't stat it at
/// all (the exact Downloads scenario from #504), this can't tell the
/// difference between "wrote nothing" and "wrote fine, just not a path we
/// can open" and stays silent rather than reporting a false failure.
class ExportWriteVerifier {
  const ExportWriteVerifier._();

  /// Throws a [StateError] if [savedPath] can be statted and turns out to
  /// be empty despite [expectedByteLength] being greater than zero.
  static void verify(String savedPath, int expectedByteLength) {
    late final int writtenLength;
    try {
      writtenLength = File(savedPath).lengthSync();
    } catch (_) {
      // Not a path we can stat from here - nothing more we can check.
      return;
    }

    if (writtenLength == 0 && expectedByteLength > 0) {
      throw StateError(
        'Export reported success but the saved file is empty '
        '(0 bytes written to $savedPath)',
      );
    }
  }
}
