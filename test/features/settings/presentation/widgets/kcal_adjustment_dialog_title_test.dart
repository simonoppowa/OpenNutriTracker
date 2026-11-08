import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_adjustment_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  @override
  Future<double> getKcalAdjustment() async => 300;
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  @override
  Future<UserEntity> getUser() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
}

class _FakeHomeBloc extends Fake implements HomeBloc {}

Future<void> _pumpDialog(WidgetTester tester, {required bool usesKj}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: usesKj),
      child: MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: KcalAdjustmentDialog(
            settingsBloc: _FakeSettingsBloc(),
            profileBloc: _FakeProfileBloc(),
            homeBloc: _FakeHomeBloc(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the title names kJ when energy is shown in kJ (#1368)', (
    tester,
  ) async {
    await _pumpDialog(tester, usesKj: true);

    expect(find.text(l10nEn.settingsKjAdjustmentLabel), findsOneWidget);
    expect(find.text(l10nEn.settingsKcalAdjustmentLabel), findsNothing);
  });

  testWidgets('the title names kcal otherwise', (tester) async {
    await _pumpDialog(tester, usesKj: false);

    expect(find.text(l10nEn.settingsKcalAdjustmentLabel), findsOneWidget);
    expect(find.text(l10nEn.settingsKjAdjustmentLabel), findsNothing);
  });
}
