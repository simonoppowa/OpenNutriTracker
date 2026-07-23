import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/export_write_verifier.dart';

void main() {
  group('ExportWriteVerifier', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'export_write_verifier_test',
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('does not throw when the saved file has the expected bytes', () {
      final file = File('${tempDir.path}/export.zip')
        ..writeAsBytesSync([1, 2, 3, 4]);

      expect(() => ExportWriteVerifier.verify(file.path, 4), returnsNormally);
    });

    test('throws when the saved file exists but is empty', () {
      // This is the simonoppowa/OpenNutriTracker#504 case: FilePicker.saveFile
      // reports a path back but nothing was actually written to it.
      final file = File('${tempDir.path}/export.zip')..writeAsBytesSync([]);

      expect(
        () => ExportWriteVerifier.verify(file.path, 4),
        throwsA(isA<StateError>()),
      );
    });

    test('does not throw when the expected length is also zero', () {
      final file = File('${tempDir.path}/export.zip')..writeAsBytesSync([]);

      expect(() => ExportWriteVerifier.verify(file.path, 0), returnsNormally);
    });

    test('does not throw for a content:// URI dart:io cannot stat', () {
      // The Android Downloads case from #504: FilePicker hands back a
      // document-provider URI, not a filesystem path. We can't confirm
      // success there, but we also shouldn't report a false failure.
      expect(
        () => ExportWriteVerifier.verify(
          'content://com.android.providers.downloads.documents/document/1234',
          4,
        ),
        returnsNormally,
      );
    });

    test('throws when a normal path cannot be statted at all', () {
      // A missing filesystem path means the write never landed — unlike a
      // content:// URI, there is no legitimate unreadable case to excuse.
      final missingPath = '${tempDir.path}/does-not-exist/export.zip';

      expect(
        () => ExportWriteVerifier.verify(missingPath, 4),
        throwsA(isA<StateError>()),
      );
    });

    test('throws on a partial write (length != expected)', () {
      final file = File('${tempDir.path}/export.zip')..writeAsBytesSync([1, 2]);

      expect(
        () => ExportWriteVerifier.verify(file.path, 4),
        throwsA(isA<StateError>()),
      );
    });
  });
}
