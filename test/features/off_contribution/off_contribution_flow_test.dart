import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_client.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/features/off_contribution/presentation/off_contribution_flow.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 480,
  carbohydrates100: 40,
  fat100: 30,
  proteins100: 12,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

class _MemoryStore extends OffContributionSettingsStore {
  OffContributionSettings settings;

  _MemoryStore(this.settings) : super(const FlutterSecureStorage());

  @override
  Future<OffContributionSettings> load() async => settings;
}

void main() {
  late List<http.Request> requests;
  late List<http.Response Function(http.Request)> answers;

  OffContributionFlow flow(OffContributionSettings settings) {
    requests = [];
    return OffContributionFlow(
      _MemoryStore(settings),
      OffContributionClient(
        userAgent: 'test',
        client: MockClient((request) async {
          requests.add(request);
          return answers.removeAt(0)(request);
        }),
      ),
    );
  }

  const ready = OffContributionSettings(
    enabled: true,
    userId: 'theo',
    password: 's3cret',
  );

  http.Response unknownProduct(http.Request _) =>
      http.Response(jsonEncode({'status': 0}), 404);
  http.Response saved(http.Request _) =>
      http.Response(jsonEncode({'status': 1}), 200);

  Future<void> pumpAndOffer(WidgetTester tester, OffContributionFlow f) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => f.offer(context, '20697112', _nutriments),
              child: const Text('saved'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('saved'));
    await tester.pumpAndSettle();
  }

  testWidgets('switched off, nothing is offered', (tester) async {
    answers = [];
    await pumpAndOffer(tester, flow(const OffContributionSettings()));

    expect(find.text(l10nEn.offUploadDialogTitle), findsNothing);
    expect(requests, isEmpty);
  });

  testWidgets('the preview shows what goes out and the licence', (
    tester,
  ) async {
    answers = [];
    await pumpAndOffer(tester, flow(ready));

    expect(find.text(l10nEn.offUploadDialogTitle), findsOneWidget);
    expect(
      find.text(
        l10nEn.offUploadDialogBody('20697112', 'world.openfoodfacts.net'),
      ),
      findsOneWidget,
    );
    expect(find.text('480 kcal'), findsOneWidget);
    expect(find.text('30 g'), findsOneWidget);
    expect(find.text(l10nEn.offUploadLicense), findsOneWidget);
  });

  testWidgets('not confirming sends nothing', (tester) async {
    answers = [];
    await pumpAndOffer(tester, flow(ready));

    await tester.tap(find.text(l10nEn.offUploadSkip));
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
  });

  testWidgets('confirming sends the values', (tester) async {
    answers = [unknownProduct, saved];
    await pumpAndOffer(tester, flow(ready));

    await tester.tap(find.text(l10nEn.offUploadSend));
    await tester.pumpAndSettle();

    expect(requests.map((r) => r.method), ['GET', 'POST']);
    expect(requests.last.bodyFields['nutriment_energy-kcal'], '480');
    expect(find.text(l10nEn.offUploadDone), findsOneWidget);
  });

  testWidgets('values already in Open Food Facts are not overwritten', (
    tester,
  ) async {
    answers = [
      (_) => http.Response(
        jsonEncode({
          'status': 1,
          'product': {
            'nutriments': {'energy-kcal_100g': 540},
          },
        }),
        200,
      ),
    ];
    await pumpAndOffer(tester, flow(ready));

    await tester.tap(find.text(l10nEn.offUploadSend));
    await tester.pumpAndSettle();

    expect(requests.map((r) => r.method), ['GET']);
    expect(find.text(l10nEn.offUploadAlreadyThere), findsOneWidget);
  });

  testWidgets('a failed upload can be retried', (tester) async {
    answers = [unknownProduct, (_) => http.Response('', 503)];
    await pumpAndOffer(tester, flow(ready));

    await tester.tap(find.text(l10nEn.offUploadSend));
    await tester.pumpAndSettle();
    expect(find.text(l10nEn.offUploadBusy), findsOneWidget);

    answers = [unknownProduct, saved];
    await tester.tap(find.text(l10nEn.offUploadRetry));
    await tester.pumpAndSettle();

    expect(requests.where((r) => r.method == 'POST'), hasLength(2));
    expect(find.text(l10nEn.offUploadDone), findsOneWidget);
  });
}
