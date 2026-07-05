import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/export_write_verifier.dart';

void main() {
  group('ExportWriteVerifier', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('export_write_verifier_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('does not throw when the saved file has the expected bytes', () {
      final file = File('${tempDir.path}/export.zip')..writeAsBytesSync([1, 2, 3, 4]);

      expect(
        () => ExportWriteVerifier.verify(file.path, 4),
        returnsNormally,
      );
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

      expect(
        () => ExportWriteVerifier.verify(file.path, 0),
        returnsNormally,
      );
    });

    test('does not throw when the path cannot be statted at all', () {
      // Mirrors an Android content:// URI path segment, which dart:io
      // can't open. We can't confirm success there, but we also
      // shouldn't report a false failure.
      final unreadablePath = '${tempDir.path}/does-not-exist/export.zip';

      expect(
        () => ExportWriteVerifier.verify(unreadablePath, 4),
        returnsNormally,
      );
    });
  });
}
