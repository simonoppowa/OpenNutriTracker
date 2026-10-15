import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../fixture/user_entity_fixtures.dart';

class _FakeProfileBloc extends Bloc<ProfileEvent, ProfileState>
    implements ProfileBloc {
  _FakeProfileBloc(super.initialState) {
    on<LoadProfileEvent>((event, emit) => emit(state));
  }

  @override
  Future<UserEntity> getUser() async =>
      (state as ProfileLoadedState).userEntity;

  @override
  Future<void> setCaloriesTaperEnabled(bool enabled) async {}

  @override
  Future<void> updateUser(UserEntity userEntity) async {}
}

class _SingleProfileGetProfilesUsecase implements GetProfilesUsecase {
  static final _profile = ProfileEntity(
    id: 'p1',
    name: 'Me',
    createdAt: DateTime(2026, 1, 1),
    boxSuffix: '',
  );

  @override
  List<ProfileEntity> getProfiles() => [_profile];

  @override
  String get activeProfileId => 'p1';

  @override
  ProfileEntity? getActiveProfile() => _profile;
}

/// The You tab as MainScreen hosts it: under a centre-docked Add button
/// that rides half above a notched bottom bar.
Widget _hostedLikeMainScreen() => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  home: Scaffold(
    body: const ProfilePage(),
    floatingActionButton: FloatingActionButton(
      onPressed: () {},
      child: const Icon(Icons.add, size: 30),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: const BottomAppBar(
      height: 78,
      padding: EdgeInsets.zero,
      shape: CircularNotchedRectangle(),
      notchMargin: 8,
    ),
  ),
);

void main() {
  late _FakeProfileBloc profileBloc;

  setUp(() {
    profileBloc = _FakeProfileBloc(
      ProfileLoadedState(
        userBMI: const UserBMIEntity(
          bmiValue: 24.7,
          nutritionalStatus: UserNutritionalStatus.normalWeight,
        ),
        userEntity:
            UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
        bodyWeightUnit: BodyWeightUnit.kg,
        usesImperialHeightUnits: false,
        effectiveWaterGoalMl: 2000,
      ),
    );
    locator.registerSingleton<ProfileBloc>(profileBloc);
    locator.registerSingleton<GetProfilesUsecase>(
      _SingleProfileGetProfilesUsecase(),
    );
  });

  tearDown(() async {
    await profileBloc.close();
    await GetIt.instance.reset();
  });

  testWidgets('the last row of the You list scrolls clear of the Add button '
      '(#1368)', (tester) async {
    // A Pixel 6 in logical pixels, the device the overlap was seen on.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_hostedLikeMainScreen());
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(list).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();

    // Collapsed, the Settings row is the last thing in the list.
    final lastRow = tester.getRect(find.byType(ExpansionTile));
    final fab = tester.getRect(find.byType(FloatingActionButton));

    expect(
      fab.top - lastRow.bottom,
      greaterThanOrEqualTo(24),
      reason:
          'a tap on the bottom edge of the last row must not land on, or '
          'next to, the Add button',
    );
  });
}
