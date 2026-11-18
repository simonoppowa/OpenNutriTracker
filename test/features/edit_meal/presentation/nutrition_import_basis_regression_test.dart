import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/edit_meal/domain/nutrition_import_parser.dart';
import 'package:opennutritracker/features/edit_meal/presentation/nutrition_import_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

final class _PickedFile extends PlatformFile {
  _PickedFile(this.file);
  final File file;
  @override
  String get name => file.uri.pathSegments.last;
  @override
  Uri get uri => file.uri;
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => null;
  @override
  Future<int> length() => file.length();
  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() => file.openRead().cast();
}

class _Picker extends FilePickerPlatform {
  _Picker(this.files);
  final List<PlatformFile> files;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => files;
}

void main() {
  Future<void> open(
    WidgetTester tester, {
    Future<String> Function(List<NutritionEntry>)? saveAll,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: NutritionImportDialog(saveAll: saveAll)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder input(String id) => find.descendant(
    of: find.bySemanticsIdentifier('nutrition-$id'),
    matching: find.byType(TextField),
  );

  Future<void> show(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> changeBasis(
    WidgetTester tester,
    NutritionBasis current,
    String choice,
  ) async {
    final selector = find.byKey(ValueKey('basis-$current'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await show(tester, selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text(choice).last);
    await tester.pumpAndSettle();
  }

  testWidgets('changing basis uses its size and preserves size edits', (
    tester,
  ) async {
    List<NutritionEntry>? saved;
    await open(tester, saveAll: (entries) async {
      saved = entries;
      return 'Saved';
    });
    await tester.enterText(
      find.bySemanticsIdentifier('nutrition-paste-text'),
      'Crackers\nServing size: 50 g\nPackage size: 200 g\n'
      'Nutrient\tPer 100 g\tPer package\nEnergy\t100 kcal\t200 kcal',
    );
    await tester.tap(find.bySemanticsIdentifier('nutrition-parse-paste'));
    await tester.pumpAndSettle();
    await changeBasis(tester, NutritionBasis.per100g, 'Package');
    await show(tester, input('serving-size'));
    expect(tester.widget<TextField>(input('serving-size')).controller!.text, '200.0');
    await tester.tap(find.bySemanticsIdentifier('nutrition-save-all'));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved!.single.toPer100()['kcal'], 100);
    await tester.enterText(input('serving-size'), '225');
    await changeBasis(tester, NutritionBasis.package, '100 g');
    await changeBasis(tester, NutritionBasis.per100g, 'Package');
    await show(tester, input('serving-size'));
    expect(tester.widget<TextField>(input('serving-size')).controller!.text, '225');
    await show(tester, input('kcal'));
    expect(tester.widget<TextField>(input('kcal')).controller!.text, '200.0');
  });

  for (final files in [
    {'foods.csv': 'Name,Energy per 100 g\nOats,370'},
    {'foods.json': '[{"name":"Oats","energy per 100 g":370}]'},
    {
      'first.csv': 'Name,Energy per 100 g\nBread,250',
      'second.json': '[{"name":"Oats","energy per 100 g":370}]',
    },
  ]) {
    testWidgets('empty basis retains the row for ${files.keys.join(', ')}', (
      tester,
    ) async {
      final directory = Directory.systemTemp.createTempSync('nutrition-import-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final picked = <PlatformFile>[];
      for (final entry in files.entries) {
        final file = File('${directory.path}/${entry.key}');
        file.writeAsStringSync(entry.value);
        picked.add(_PickedFile(file));
      }
      final previous = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _Picker(picked);
      addTearDown(() => FilePickerPlatform.instance = previous);
      await open(tester);
      await tester.tap(find.bySemanticsIdentifier('nutrition-pick-file'));
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
        if (find.byKey(const ValueKey('basis-NutritionBasis.per100g')).evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();
      if (files.length > 1) {
        final tab = find.bySemanticsIdentifier('nutrition-entry-tab-1');
        await show(tester, tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
      }
      await changeBasis(tester, NutritionBasis.per100g, 'Serving');
      await changeBasis(tester, NutritionBasis.serving, '100 g');
      await show(tester, input('kcal'));
      expect(tester.widget<TextField>(input('kcal')).controller!.text, '370.0');
    });
  }
}
