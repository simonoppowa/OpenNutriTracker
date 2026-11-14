import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/app_theme.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

// #589: text in the Home macro tiles and the Trends cards lost its first
// glyph ("Calories" -> "alories", "89/79 g" -> "39/79 g"). The cause was
// AppCard's rounded clip sitting on the padded content box instead of the
// card (fixed in #591). These tests guard the visible surfaces themselves,
// with the app's real font, across the sizes and strings that push text into
// the card corners: English and German, text scale 1.0 and 1.3, a 320 dp
// phone, large values, and kJ.

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeGetWaterIntakeUsecase extends Fake
    implements GetWaterIntakeUsecase {}

class _SeededTrendsBloc extends TrendsBloc {
  _SeededTrendsBloc(TrendsLoaded seeded)
    : super(
        _FakeGetTrackedDayUsecase(),
        _FakeGetWeightLogUsecase(),
        _FakeGetUserUsecase(),
        _FakeGetConfigUsecase(),
        _FakeGetWaterIntakeUsecase(),
      ) {
    emit(seeded);
  }

  @override
  void add(TrendsEvent event) {}
}

class _Case {
  final Locale locale;
  final double textScale;
  final double width;
  final bool kilojoules;
  final bool largeValues;

  const _Case(
    this.locale,
    this.textScale,
    this.width, {
    this.kilojoules = false,
    this.largeValues = false,
  });

  @override
  String toString() =>
      '${locale.languageCode}, ${textScale}x, ${width.toInt()} dp'
      '${kilojoules ? ', kJ' : ''}${largeValues ? ', large values' : ''}';
}

const _en = Locale('en');
const _de = Locale('de');

final _cases = <_Case>[
  for (final locale in [_en, _de])
    for (final scale in [1.0, 1.3])
      for (final width in [320.0, 411.0]) ...[
        _Case(locale, scale, width),
        _Case(locale, scale, width, largeValues: true),
        _Case(locale, scale, width, largeValues: true, kilojoules: true),
      ],
];

Future<void> _pumpApp(WidgetTester tester, _Case c, Widget body) async {
  tester.view.devicePixelRatio = 1;
  // Tall enough for the lazy Trends list to build every card.
  tester.view.physicalSize = Size(c.width, 4000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: c.kilojoules),
      child: MaterialApp(
        theme: buildAppTheme(AppPalette.light),
        locale: c.locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(c.textScale)),
          child: child!,
        ),
        home: Scaffold(body: body),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The clip a render object applies to its children, in its own
/// coordinates, or null when it doesn't clip to a rounded shape.
Path? _roundedClipOf(RenderObject node) {
  if (node is RenderClipRRect && node.clipBehavior != Clip.none) {
    final rect = Offset.zero & node.size;
    final rrect =
        node.clipper?.getClip(node.size) ??
        node.borderRadius.resolve(node.textDirection).toRRect(rect);
    return Path()..addRRect(rrect);
  }
  if (node is RenderClipPath && node.clipBehavior != Clip.none) {
    return node.clipper?.getClip(node.size);
  }
  if (node is RenderPhysicalShape && node.clipBehavior != Clip.none) {
    return node.clipper?.getClip(node.size);
  }
  return null;
}

/// Every text under [scope] keeps all four corners of its box inside every
/// rounded clip above it. Before #591 the AppCard clip hugged the content
/// box, so the corner arc sat over the first glyph of corner text.
void _expectNoTextCutByRoundedClip(WidgetTester tester, Finder scope) {
  final paragraphs = find.descendant(
    of: scope,
    matching: find.byType(RichText),
  );
  expect(paragraphs, findsWidgets);
  for (final element in paragraphs.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final text = paragraph.text.toPlainText();
    if (text.trim().isEmpty) continue;
    final box = (Offset.zero & paragraph.size).deflate(0.5);
    for (
      RenderObject? node = paragraph.parent;
      node != null;
      node = node.parent
    ) {
      final clip = _roundedClipOf(node);
      if (clip == null) continue;
      final toClip = paragraph.getTransformTo(node);
      for (final corner in [
        box.topLeft,
        box.topRight,
        box.bottomLeft,
        box.bottomRight,
      ]) {
        expect(
          clip.contains(MatrixUtils.transformPoint(toClip, corner)),
          isTrue,
          reason:
              '"$text" has its corner $corner cut off by the rounded clip '
              'of ${node.runtimeType}',
        );
      }
    }
  }
}

/// Every card text equal to [text] stays on one line. Unless
/// [mayEllipsize], it also renders whole: no ellipsis, nothing cut.
void _expectOnOneLine(
  WidgetTester tester,
  String text, {
  bool mayEllipsize = false,
}) {
  final finder = find.descendant(
    of: find.byType(AppCard),
    matching: find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText() == text,
    ),
  );
  expect(finder, findsWidgets, reason: '"$text" is not in a card');
  for (final element in finder.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (mayEllipsize) {
      expect(
        paragraph.maxLines,
        1,
        reason: '"$text" can wrap onto a second line',
      );
      continue;
    }
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '"$text" is truncated',
    );
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
    )..layout(maxWidth: paragraph.size.width);
    addTearDown(painter.dispose);
    expect(
      painter.computeLineMetrics(),
      hasLength(1),
      reason: '"$text" wraps at ${paragraph.size.width} px',
    );
  }
}

void main() {
  setUpAll(() async {
    // The test font draws every glyph as a square; the real Nunito metrics
    // decide how close a glyph sits to the card corner.
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('fonts/Nunito.ttf'));
    await loader.load();
  });

  group('Home macro tiles (#589)', () {
    for (final c in _cases) {
      testWidgets('text is not clipped or overflowing: $c', (tester) async {
        final intake = c.largeValues ? 1234.0 : 89.0;
        final goal = c.largeValues ? 1234.0 : 79.0;
        await _pumpApp(
          tester,
          c,
          SingleChildScrollView(
            child: DashboardWidget(
              totalKcalSupplied: c.largeValues ? 12345 : 1479,
              totalKcalBurned: c.largeValues ? 12345 : 0,
              totalKcalDaily: 2500,
              totalKcalLeft: c.largeValues ? -12345 : 1021,
              totalCarbsIntake: intake,
              totalFatsIntake: intake,
              totalProteinsIntake: intake,
              totalCarbsGoal: goal,
              totalFatsGoal: goal,
              totalProteinsGoal: goal,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        _expectNoTextCutByRoundedClip(tester, find.byType(DashboardWidget));
        // The totals must never wrap or ellipsize: "1234/12…" or a lone
        // "g" on its own line misreads the same way a clipped digit does.
        _expectOnOneLine(tester, '${intake.toInt()}/${goal.toInt()} g');
        expect(
          find.text('${intake.toInt()}/${goal.toInt()} g'),
          findsNWidgets(3),
        );
        // The labels shrink to one line; only "Kohlenhydrate" in a 320 dp
        // tile may need an ellipsis, and the colour dot still names it.
        final s = lookupS(c.locale);
        for (final label in [s.carbsLabel, s.fatLabel, s.proteinLabel]) {
          _expectOnOneLine(tester, label, mayEllipsize: true);
        }
      });
    }
  });

  group('Trends cards (#589)', () {
    tearDown(() async => locator.reset());

    for (final c in _cases) {
      testWidgets('text is not clipped or overflowing: $c', (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final macro = c.largeValues ? 1234.0 : 176.0;
        final days = [
          for (var i = 0; i < 7; i++)
            TrackedDayEntity(
              day: DateUtils.dateOnly(today.subtract(Duration(days: i))),
              calorieGoal: c.largeValues ? 12345 : 2000,
              caloriesTracked: c.largeValues ? 12345 : 1800,
              carbsGoal: macro,
              carbsTracked: macro,
              fatGoal: macro,
              fatTracked: macro,
              proteinGoal: macro,
              proteinTracked: macro,
            ),
        ];
        final waterMl = c.largeValues ? 12345 : 1900;
        locator.registerSingleton<TrendsBloc>(
          _SeededTrendsBloc(
            TrendsLoaded(
              rangeDays: 7,
              windowDays: 7,
              days: days,
              priorWeek: const [],
              weight: const [],
              bodyWeightUnit: BodyWeightUnit.kg,
              targetWeightKg: null,
              waterByDay: {
                for (var i = 0; i < 7; i++)
                  DateUtils.dateOnly(today.subtract(Duration(days: i))):
                      waterMl,
              },
              waterGoalMl: waterMl,
              usesImperialFoodUnits: false,
            ),
          ),
        );
        await _pumpApp(tester, c, const TrendsPage());

        expect(tester.takeException(), isNull);
        _expectNoTextCutByRoundedClip(tester, find.byType(TrendsPage));

        final s = lookupS(c.locale);
        _expectOnOneLine(tester, s.trendsCaloriesLabel);
        _expectOnOneLine(tester, s.trendsDailyAverageLabel);
        _expectOnOneLine(tester, s.trendsWaterLabel);
        _expectOnOneLine(tester, s.waterChipLabel(waterMl, waterMl));
        expect(
          find.text('${macro.toInt()} / ${macro.toInt()} g'),
          findsNWidgets(3),
        );
      });
    }
  });
}
