import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/edit_meal/domain/usecase/read_nutrition_label_usecase.dart';
import 'package:opennutritracker/features/edit_meal/presentation/widgets/label_scan_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/test_l10n.dart';

class _MapStorage implements FlutterSecureStorage {
  final Map<String, String> values;

  _MapStorage(this.values);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// An Anthropic reply calling the tool with [queries] as its items.
http.Response _toolReply(List<String> queries) => http.Response(
  jsonEncode({
    'id': 'msg_1',
    'type': 'message',
    'role': 'assistant',
    'content': [
      {
        'type': 'tool_use',
        'id': 'tu_1',
        'name': 'log_meal_items',
        'input': {
          'items': [
            for (final query in queries) {'query': query},
          ],
        },
      },
    ],
  }),
  200,
);

final _photo = MealPhoto(
  bytes: Uint8List.fromList([1, 2, 3, 4]),
  mediaType: 'image/webp',
);

void main() {
  late List<http.Request> sent;
  late List<NutritionLabelReading> read;

  setUp(() {
    sent = [];
    read = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    required http.Response reply,
    TakeLabelPhoto? takePhoto,
  }) async {
    final useCase = ReadNutritionLabelUseCase(
      AiCredentialStorage(
        _MapStorage({
          'AiProviderTag': 'anthropic',
          'AiApiKeyTag.anthropic': 'sk-ant',
          'AiTermsAcceptedTag': 'true',
        }),
      ),
      MockClient((request) async {
        sent.add(request);
        return reply;
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: [
              LabelScanButton(
                useCase: useCase,
                takePhoto: takePhoto ?? (_) async => _photo,
                onRead: read.add,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester) async {
    await tester.tap(find.byTooltip(l10nEn.customMealLabelScanButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.mealImageTakePhoto));
    await tester.pumpAndSettle();
  }

  testWidgets('names where the photo goes, then hands on what it read', (
    tester,
  ) async {
    await pump(
      tester,
      reply: _toolReply(['name=Rye crispbread', 'energyKcal=350']),
    );

    await tester.tap(find.byTooltip(l10nEn.customMealLabelScanButton));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(l10nEn.customMealLabelScanDisclosure('Anthropic')),
      findsOneWidget,
    );
    await tester.tap(find.text(l10nEn.mealImageTakePhoto));
    await tester.pumpAndSettle();

    expect(read.single.name, 'Rye crispbread');
    expect(read.single.per100, {'energyKcal': 350});
    expect(sent, hasLength(1));
  });

  testWidgets('declining the sheet sends nothing', (tester) async {
    await pump(tester, reply: _toolReply(['name=Rye crispbread']));

    await tester.tap(find.byTooltip(l10nEn.customMealLabelScanButton));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(sent, isEmpty);
    expect(read, isEmpty);
  });

  testWidgets('a cancelled camera sends nothing', (tester) async {
    await pump(
      tester,
      reply: _toolReply(['name=Rye crispbread']),
      takePhoto: (_) async => null,
    );
    await scan(tester);

    expect(sent, isEmpty);
    expect(read, isEmpty);
  });

  testWidgets('a photo with no label says so', (tester) async {
    await pump(tester, reply: _toolReply([]));
    await scan(tester);

    expect(read, isEmpty);
    expect(find.text(l10nEn.customMealLabelScanNothingRead), findsOneWidget);
  });

  testWidgets('a failed read says so', (tester) async {
    await pump(tester, reply: http.Response('', 500));
    await scan(tester);

    expect(read, isEmpty);
    expect(find.text(l10nEn.bulkAddPhotoFailedLabel), findsOneWidget);
  });

  testWidgets('a photo that cannot be used says so', (tester) async {
    await pump(
      tester,
      reply: _toolReply(['name=Rye crispbread']),
      takePhoto: (_) async => throw StateError('no encoder'),
    );
    await scan(tester);

    expect(sent, isEmpty);
    expect(find.text(l10nEn.bulkAddPhotoUnreadableLabel), findsOneWidget);
  });
}
