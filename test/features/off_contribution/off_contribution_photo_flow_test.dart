import 'dart:convert';
import 'dart:io';

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
import 'package:opennutritracker/features/scanner/data/nutrition_label_scanner.dart';
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
  final OffContributionSettings settings;

  _MemoryStore(this.settings) : super(const FlutterSecureStorage());

  @override
  Future<OffContributionSettings> load() async => settings;
}

void main() {
  late List<http.Request> requests;
  late List<http.Response Function(http.Request)> answers;
  late int deletions;

  LabelPhoto photo() => LabelPhoto(
    fileName: 'label.jpg',
    read: () async => const [1, 2, 3],
    delete: () async => deletions++,
  );

  OffContributionFlow flow(OffContributionSettings settings) {
    requests = [];
    deletions = 0;
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
  http.Response photoKept(http.Request _) =>
      http.Response(jsonEncode({'status': 'status ok', 'imgid': 4}), 200);

  bool isPhotoUpload(http.Request request) =>
      request.url.path == '/cgi/product_image_upload.pl';

  Future<void> pumpAndOffer(
    WidgetTester tester,
    OffContributionFlow f, {
    LabelPhoto? labelPhoto,
  }) async {
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
              onPressed: () =>
                  f.offer(context, '20697112', _nutriments, photo: labelPhoto),
              child: const Text('saved'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('saved'));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, {bool withPhoto = false}) async {
    if (withPhoto) {
      await tester.tap(find.text(l10nEn.offUploadPhotoCheckbox));
      await tester.pump();
    }
    await tester.tap(find.text(l10nEn.offUploadSend));
    await tester.pumpAndSettle();
  }

  testWidgets('without a photo there is no photo choice', (tester) async {
    answers = [];
    await pumpAndOffer(tester, flow(ready));

    expect(find.text(l10nEn.offUploadPhotoCheckbox), findsNothing);
    expect(find.text(l10nEn.offUploadPhotoLicense), findsNothing);
  });

  testWidgets('with a photo the choice starts off and names its licence', (
    tester,
  ) async {
    answers = [];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());

    expect(find.text(l10nEn.offUploadPhotoCheckbox), findsOneWidget);
    expect(find.text(l10nEn.offUploadPhotoLicense), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
  });

  testWidgets('sending without the photo leaves it out and deletes it', (
    tester,
  ) async {
    answers = [unknownProduct, saved];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());

    await send(tester);

    expect(requests.where(isPhotoUpload), isEmpty);
    expect(deletions, 1);
  });

  testWidgets('sending with the photo uploads and then deletes it', (
    tester,
  ) async {
    answers = [unknownProduct, saved, photoKept];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());

    await send(tester, withPhoto: true);

    expect(requests.map(isPhotoUpload), [false, false, true]);
    expect(find.text(l10nEn.offUploadDone), findsOneWidget);
    expect(deletions, 1);
  });

  testWidgets('not sending deletes the photo', (tester) async {
    answers = [];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());

    await tester.tap(find.text(l10nEn.offUploadSkip));
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
    expect(deletions, 1);
  });

  testWidgets('switched off, the photo is deleted without a dialog', (
    tester,
  ) async {
    answers = [];
    await pumpAndOffer(
      tester,
      flow(const OffContributionSettings()),
      labelPhoto: photo(),
    );

    expect(find.text(l10nEn.offUploadDialogTitle), findsNothing);
    expect(deletions, 1);
  });

  testWidgets('values already there: only the ticked photo goes out', (
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
      photoKept,
    ];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());

    await send(tester, withPhoto: true);

    expect(requests.map(isPhotoUpload), [false, true]);
    expect(find.text(l10nEn.offUploadOnlyPhoto), findsOneWidget);
    expect(deletions, 1);
  });

  testWidgets('values already there and no photo: nothing is sent', (
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
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());

    await send(tester);

    expect(requests, hasLength(1));
    expect(find.text(l10nEn.offUploadAlreadyThere), findsOneWidget);
    expect(deletions, 1);
  });

  testWidgets('a photo that can no longer be read is skipped', (tester) async {
    answers = [unknownProduct, saved];
    await pumpAndOffer(
      tester,
      flow(ready),
      labelPhoto: LabelPhoto(
        fileName: 'label.jpg',
        read: () async => throw const FileSystemException('gone'),
        delete: () async => deletions++,
      ),
    );

    await send(tester, withPhoto: true);

    expect(requests.where(isPhotoUpload), isEmpty);
    expect(find.text(l10nEn.offUploadDone), findsOneWidget);
    expect(deletions, 1);
  });

  testWidgets('a failed photo upload retries only the photo', (tester) async {
    answers = [unknownProduct, saved, (_) => http.Response('', 503)];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());
    await send(tester, withPhoto: true);
    expect(find.text(l10nEn.offUploadBusy), findsOneWidget);
    expect(deletions, 0);

    answers = [photoKept];
    await tester.tap(find.text(l10nEn.offUploadRetry));
    await tester.pumpAndSettle();

    expect(requests.map(isPhotoUpload), [false, false, true, true]);
    expect(find.text(l10nEn.offUploadDone), findsOneWidget);
    expect(deletions, 1);
  });

  testWidgets('a failure message closed without retrying deletes the photo', (
    tester,
  ) async {
    answers = [unknownProduct, saved, (_) => http.Response('', 503)];
    await pumpAndOffer(tester, flow(ready), labelPhoto: photo());
    await send(tester, withPhoto: true);

    ScaffoldMessenger.of(
      tester.element(find.text('saved')),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(deletions, 1);
  });

  testWidgets('it says whether uploads are set up', (tester) async {
    expect(await flow(ready).isReady(), isTrue);
    expect(await flow(const OffContributionSettings()).isReady(), isFalse);
  });
}
