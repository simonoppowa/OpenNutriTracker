import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/voice/dictation_service.dart';
import 'package:opennutritracker/features/add_meal/presentation/voice/voice_input_button.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Stands in for the platform recognizer. The test drives each segment.
class FakeDictationService implements DictationService {
  DictationUnavailable? unavailable;
  final languages = <DictationLanguage>[];
  int segments = 0;
  void Function(DictationResult)? _onResult;
  void Function()? _onEnd;

  @override
  Future<void> ensureReady() async {
    if (unavailable != null) throw DictationUnavailableException(unavailable!);
  }

  @override
  Future<void> startSegment({
    required DictationLanguage language,
    required void Function(DictationResult result) onResult,
    required void Function() onSegmentEnd,
  }) async {
    segments++;
    languages.add(language);
    _onResult = onResult;
    _onEnd = onSegmentEnd;
  }

  void hear(String words, {bool isFinal = false}) =>
      _onResult!(DictationResult(words, isFinal: isFinal));

  void endSegment() {
    final end = _onEnd;
    _onEnd = null;
    end?.call();
  }

  @override
  Future<void> stop() async => endSegment();

  @override
  Future<void> cancel() async => _onEnd = null;
}

void main() {
  late FakeDictationService service;
  late TextEditingController controller;
  late List<String> dictated;

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('es')}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: TextField(
            controller: controller,
            decoration: InputDecoration(
              suffixIcon: VoiceInputButton(
                controller: controller,
                onDictated: dictated.add,
                service: service,
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    service = FakeDictationService();
    controller = TextEditingController();
    dictated = [];
  });

  testWidgets('segments are joined and submitted once after a pause', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('ES'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    expect(service.languages.single, const DictationLanguage('es'));
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    service.hear('dos huevos');
    await tester.pump();
    expect(controller.text, 'dos huevos');

    // Android ends the segment on a short pause; the session restarts it.
    service
      ..hear('dos huevos', isFinal: true)
      ..endSegment();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.segments, 2);

    service.hear('y una tostada', isFinal: true);
    await tester.pump();
    expect(controller.text, 'dos huevos y una tostada');
    expect(dictated, isEmpty);

    // Quiet long enough: the session stops and submits.
    await tester.pump(const Duration(seconds: 3));
    expect(dictated, ['dos huevos y una tostada']);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('tapping stop submits what was heard so far', (tester) async {
    controller.text = 'black coffee';
    await pump(tester, locale: const Locale('en'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    service.hear('two eggs');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    expect(dictated, ['black coffee two eggs']);
  });

  testWidgets('nothing said submits nothing', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();

    service.endSegment();
    await tester.pump(const Duration(seconds: 1));
    expect(dictated, isEmpty);
    expect(service.segments, 1);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('the language chip switches the recognizer language', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ES'));
    await tester.pumpAndSettle();
    expect(find.text('EN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    expect(service.languages.single, DictationLanguage.english);
    service.endSegment();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('offers the app language beside English, not a fixed list', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('de'));
    await tester.pumpAndSettle();
    expect(find.text('DE'), findsOneWidget);
    await tester.tap(find.text('DE'));
    await tester.pumpAndSettle();
    expect(find.text('EN'), findsOneWidget);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    // The test device is en_US, so German and English are the whole cycle.
    expect(find.text('DE'), findsOneWidget);
  });

  testWidgets('a denied permission is explained', (tester) async {
    service.unavailable = DictationUnavailable.permission;
    await pump(tester, locale: const Locale('en'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    expect(
      find.text(
        'Allow microphone and speech recognition access to dictate a meal.',
      ),
      findsOneWidget,
    );
  });
}
