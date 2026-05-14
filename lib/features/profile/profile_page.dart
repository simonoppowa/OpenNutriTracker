import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/bmi_overview.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_gender_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_goal_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_height_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weekly_weight_goal_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_pal_category_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileBloc _profileBloc;

  @override
  void initState() {
    _profileBloc = locator<ProfileBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      builder: (context, state) {
        if (state is ProfileInitial) {
          _profileBloc.add(LoadProfileEvent());
          return _getLoadingContent();
        } else if (state is ProfileLoadingState) {
          return _getLoadingContent();
        } else if (state is ProfileLoadedState) {
          return _getLoadedContent(
            context,
            state.userBMI,
            state.userEntity,
            state.usesImperialUnits,
          );
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  Widget _getLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _getLoadedContent(
    BuildContext context,
    UserBMIEntity userBMIEntity,
    UserEntity user,
    bool usesImperialUnits,
  ) {
    return ListView(
      children: [
        const SizedBox(height: 32.0),
        BMIOverview(
          bmiValue: userBMIEntity.bmiValue,
          nutritionalStatus: userBMIEntity.nutritionalStatus,
        ),
        const SizedBox(height: 32.0),
        Semantics(
          identifier: 'profile-activity',
          child: ListTile(
            title: Text(
              S.of(context).activityLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              user.pal.getName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.directions_walk_outlined),
            ),
            onTap: () => _showSetPALCategoryDialog(context, user),
          ),
        ),
        Semantics(
          identifier: 'profile-goal',
          child: ListTile(
            title: Text(
              S.of(context).goalLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              user.goal.getName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.flag_outlined),
            ),
            onTap: () => _showSetGoalDialog(context, user),
          ),
        ),
        Semantics(
          identifier: 'profile-weekly-goal',
          child: ListTile(
            title: Text(
              S.of(context).weeklyWeightGoalLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              _weeklyGoalSubtitle(context, user, usesImperialUnits),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.trending_down_outlined),
            ),
            onTap: () => _showSetWeeklyWeightGoalDialog(
                context, user, usesImperialUnits),
          ),
        ),
        Semantics(
          identifier: 'profile-weight',
          child: ListTile(
            title: Text(
              S.of(context).weightLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${_profileBloc.getDisplayWeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).lbsLabel : S.of(context).kgLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.monitor_weight_outlined),
            ),
            onTap: () {
              _showSetWeightDialog(context, user, usesImperialUnits);
            },
          ),
        ),
        Semantics(
          identifier: 'profile-height',
          child: ListTile(
            title: Text(
              S.of(context).heightLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${_profileBloc.getDisplayHeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).ftLabel : S.of(context).cmLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.height_outlined),
            ),
            onTap: () {
              _showSetHeightDialog(context, user, usesImperialUnits);
            },
          ),
        ),
        Semantics(
          identifier: 'profile-age',
          child: ListTile(
            title: Text(
              S.of(context).ageLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              S.of(context).yearsLabel(user.age),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.cake_outlined),
            ),
            onTap: () {
              _showSetBirthdayDialog(context, user);
            },
          ),
        ),
        Semantics(
          identifier: 'profile-gender',
          child: ListTile(
            title: Text(
              S.of(context).genderLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              user.gender.getName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: SizedBox(
              height: double.infinity,
              child: user.gender.getIcon(),
            ),
            onTap: () {
              _showSetGenderDialog(context, user);
            },
          ),
        ),
        if (user.gender == UserGenderEntity.nonBinary)
          Semantics(
            identifier: 'profile-calories-profile',
            child: ListTile(
              title: Text(
                S.of(context).caloriesProfileInfoTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                (user.caloriesProfile ?? CaloriesProfileEntity.averaged)
                    .getName(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              leading: const SizedBox(
                height: double.infinity,
                child: Icon(Icons.tune_outlined),
              ),
              onTap: () {
                _showCaloriesProfileDialog(context, user);
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showSetPALCategoryDialog(
    BuildContext context,
    UserEntity userEntity,
  ) async {
    final selectedPalCategory = await showDialog<UserPALEntity>(
      context: context,
      builder: (BuildContext context) => const SetPALCategoryDialog(),
    );
    if (selectedPalCategory != null) {
      userEntity.pal = selectedPalCategory;
      _profileBloc.updateUser(userEntity);
    }
  }

  String _weeklyGoalSubtitle(
      BuildContext context, UserEntity user, bool usesImperialUnits) {
    final goal = user.weeklyWeightGoalKg;
    if (goal == null) return S.of(context).weeklyWeightGoalNoneLabel;
    if (goal == 0.0) return S.of(context).goalMaintainWeight;
    final displayValue =
        usesImperialUnits ? goal * 2.20462 : goal;
    final sign = displayValue > 0 ? '+' : '';
    final formatted = '$sign${displayValue.toStringAsFixed(2)}';
    return usesImperialUnits
        ? S.of(context).weeklyWeightGoalLbsPerWeek(formatted)
        : S.of(context).weeklyWeightGoalKgPerWeek(formatted);
  }

  Future<void> _showSetWeeklyWeightGoalDialog(BuildContext context,
      UserEntity userEntity, bool usesImperialUnits) async {
    final result = await showDialog<WeeklyWeightGoalResult>(
      context: context,
      builder: (context) => SetWeeklyWeightGoalDialog(
        currentGoalKg: userEntity.weeklyWeightGoalKg,
        usesImperialUnits: usesImperialUnits,
      ),
    );
    switch (result) {
      // null when the framework returns from a back-button pop, treated
      // as cancellation alongside the explicit Cancel case.
      case null:
      case WeeklyWeightGoalCancelled():
        return;
      case WeeklyWeightGoalCleared():
        userEntity.weeklyWeightGoalKg = null;
      case WeeklyWeightGoalSet(:final kgPerWeek):
        userEntity.weeklyWeightGoalKg = kgPerWeek;
    }
    await _profileBloc.updateUser(userEntity);
  }

  Future<void> _showSetGoalDialog(
    BuildContext context,
    UserEntity userEntity,
  ) async {
    final selectedGoal = await showDialog<UserWeightGoalEntity>(
      context: context,
      builder: (BuildContext context) => const SetWeightGoalDialog(),
    );
    if (selectedGoal != null) {
      userEntity.goal = selectedGoal;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetHeightDialog(
    BuildContext context,
    UserEntity userEntity,
    bool usesImperialUnits,
  ) async {
    final selectedHeight = await showDialog<double>(
      context: context,
      builder: (context) => SetHeightDialog(
        userHeight: usesImperialUnits
            ? UnitCalc.cmToFeet(userEntity.heightCM)
            : userEntity.heightCM,
        usesImperialUnits: usesImperialUnits,
      ),
    );
    if (selectedHeight != null) {
      if (usesImperialUnits) {
        userEntity.heightCM = UnitCalc.feetToCm(selectedHeight);
      } else {
        userEntity.heightCM = selectedHeight;
      }

      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetWeightDialog(
    BuildContext context,
    UserEntity userEntity,
    bool usesImperialSystem,
  ) async {
    final selectedWeight = await showDialog<double>(
      context: context,
      builder: (context) => SetWeightDialog(
        userWeight: usesImperialSystem
            ? UnitCalc.kgToLbs(userEntity.weightKG)
            : userEntity.weightKG,
        usesImperialUnits: usesImperialSystem,
      ),
    );
    if (selectedWeight != null) {
      if (usesImperialSystem) {
        userEntity.weightKG = UnitCalc.lbsToKg(selectedWeight);
      } else {
        userEntity.weightKG = selectedWeight;
      }
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetBirthdayDialog(
    BuildContext context,
    UserEntity userEntity,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: userEntity.birthday,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      userEntity.birthday = selectedDate;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGenderDialog(
    BuildContext context,
    UserEntity userEntity,
  ) async {
    final selectedGender = await showDialog<UserGenderEntity>(
      context: context,
      builder: (BuildContext context) => const SetGenderDialog(),
    );
    if (selectedGender == null) return;
    userEntity.gender = selectedGender;

    // Switching to non-binary: prompt for hormone profile and persist BOTH
    // fields in a single updateUser call. Issuing two saves (one for the
    // gender, one for the profile) used to race — by the time the home
    // recomputed kcal, only the gender write had landed and the profile
    // was still null, so every choice rendered as "averaged".
    if (selectedGender == UserGenderEntity.nonBinary) {
      if (context.mounted) {
        final selected = await showDialog<CaloriesProfileEntity>(
          context: context,
          builder: (BuildContext context) => CaloriesProfileInfoDialog(
            initialProfile:
                userEntity.caloriesProfile ?? CaloriesProfileEntity.averaged,
          ),
        );
        if (selected != null) {
          userEntity.caloriesProfile = selected;
        } else {
          // User cancelled the picker but is now non-binary — store the
          // implicit default explicitly so reads don't keep falling back.
          userEntity.caloriesProfile ??= CaloriesProfileEntity.averaged;
        }
      }
    } else {
      // Switching back to binary — drop any previously set hormone profile.
      // The field is meaningless outside of nonBinary.
      userEntity.caloriesProfile = null;
    }

    await _profileBloc.updateUser(userEntity);
  }

  Future<void> _showCaloriesProfileDialog(
    BuildContext context,
    UserEntity userEntity,
  ) async {
    final selected = await showDialog<CaloriesProfileEntity>(
      context: context,
      builder: (BuildContext context) => CaloriesProfileInfoDialog(
        initialProfile:
            userEntity.caloriesProfile ?? CaloriesProfileEntity.averaged,
      ),
    );
    if (selected == null) return;
    userEntity.caloriesProfile = selected;
    await _profileBloc.updateUser(userEntity);
  }
}
