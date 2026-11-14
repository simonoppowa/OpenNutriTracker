import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/activity_detail/presentation/widget/activity_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_reload_blocs.dart';

/// Records what the screen logs, and stays in the loading state so the
/// test needs no user or goals.
class _RecordingActivityDetailBloc extends Fake implements ActivityDetailBloc {
  final logged = <PhysicalActivityEntity>[];
  final templates = <CustomActivityTemplateEntity>[];

  @override
  ActivityDetailState get state => ActivityDetailLoadingState();

  @override
  Stream<ActivityDetailState> get stream => const Stream.empty();

  @override
  void add(ActivityDetailEvent event) {}

  @override
  Future<void> persistActivity(
    String quantityText,
    double totalKcalBurned,
    PhysicalActivityEntity activityEntity,
    DateTime day,
  ) async {
    logged.add(activityEntity);
  }

  @override
  Future<void> saveCustomActivityTemplate(
    CustomActivityTemplateEntity template,
  ) async {
    templates.add(template);
  }
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

/// The sheet's "Save as template" CheckboxListTile sits on the sheet's
/// coloured container, which trips a debug-only ink assertion that
/// predates #512. Drop that one report so the tests check the name.
void _ignoreListTileInkAssertion() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Finder _nameField() => find.descendant(
  of: find.bySemanticsIdentifier('activity-detail-template-name-input'),
  matching: find.byType(EditableText),
);

Finder _quantityField() => find.descendant(
  of: find.bySemanticsIdentifier('activity-detail-quantity-input'),
  matching: find.byType(EditableText),
);

/// #512: the name field on the Custom activity screen names the logged
/// entry, whether or not the template box is ticked.
void main() {
  group('ActivityDetailBottomSheet', () {
    final names = <String?>[];
    final templateFlags = <bool>[];

    Future<void> pumpSheet(WidgetTester tester) async {
      names.clear();
      templateFlags.clear();
      _ignoreListTileInkAssertion();
      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [S.delegate],
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: ActivityDetailBottomSheet(
                activityEntity: PhysicalActivityEntity.custom,
                quantityTextController: TextEditingController(text: '250'),
                activityDetailBloc: _RecordingActivityDetailBloc(),
                onAddButtonPressed: (_, {customName, saveAsTemplate = false}) {
                  names.add(customName);
                  templateFlags.add(saveAsTemplate);
                  return Future.value();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a typed name is handed over without ticking the template', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(_nameField(), '  Evening ride  ');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(names, ['Evening ride']);
      expect(templateFlags, [false]);
    });

    testWidgets('a whitespace-only name is handed over as no name', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(_nameField(), '   ');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(names, [null]);
    });
  });

  group('ActivityDetailScreen', () {
    late _RecordingActivityDetailBloc bloc;

    setUp(() {
      bloc = _RecordingActivityDetailBloc();
      locator.registerSingleton<ActivityDetailBloc>(bloc);
      locator.registerSingleton<HomeBloc>(_FakeHomeBloc());
      ReloadRecorder().register();
    });

    tearDown(() async => locator.reset());

    Future<void> pumpScreen(WidgetTester tester) async {
      _ignoreListTileInkAssertion();
      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [S.delegate],
            supportedLocales: S.supportedLocales,
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: RouteSettings(
                arguments: ActivityDetailScreenArguments(
                  PhysicalActivityEntity.custom,
                  DateTime(2026, 11, 9),
                ),
              ),
              builder: (_) => const ActivityDetailScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> logWith(WidgetTester tester, String name) async {
      await pumpScreen(tester);
      await tester.enterText(_quantityField(), '250');
      await tester.enterText(_nameField(), name);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
    }

    testWidgets('the typed name labels the logged entry', (tester) async {
      await logWith(tester, 'Evening ride');

      expect(bloc.logged, hasLength(1));
      expect(bloc.logged.single.isCustom, isTrue);
      expect(bloc.logged.single.specificActivity, 'Evening ride');
      // The template box was not ticked, so no template is saved.
      expect(bloc.templates, isEmpty);
    });

    testWidgets('a blank name logs the plain Custom activity', (tester) async {
      await logWith(tester, '   ');

      expect(bloc.logged.single, same(PhysicalActivityEntity.custom));
    });
  });
}
