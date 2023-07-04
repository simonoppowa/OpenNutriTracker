import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/bmi_overview.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_gender_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_goal_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_height_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_pal_category_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

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
          return _getLoadedContent(context, state.userBMI, state.userEntity);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  Widget _getLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _getLoadedContent(
      BuildContext context, UserBMIEntity userBMIEntity, UserEntity user) {
    return ListView(
      children: [
        const SizedBox(height: 32.0),
        BMIOverview(
          bmiValue: userBMIEntity.bmiValue,
          nutritionalStatus: userBMIEntity.nutritionalStatus,
        ),
        const SizedBox(height: 32.0),
        ListTile(
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
        ListTile(
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
        ListTile(
          title: Text(
            S.of(context).weightLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            '${user.weightKG} kg',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.monitor_weight_outlined),
          ),
          onTap: () {
            _showSetWeightDialog(context, user);
          },
        ),
        ListTile(
          title: Text(
            S.of(context).heightLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            '${user.heightCM.toInt()} cm',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.height_outlined),
          ),
          onTap: () {
            _showSetHeightDialog(context, user);
          },
        ),
        ListTile(
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
        ListTile(
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
            child: Icon(user.gender.getIcon()),
          ),
          onTap: () {
            _showSetGenderDialog(context, user);
          },
        ),
      ],
    );
  }

  Future<void> _showSetPALCategoryDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedPalCategory = await showDialog<UserPALEntity>(
        context: context,
        builder: (BuildContext context) => const SetPALCategoryDialog());
    if (selectedPalCategory != null) {
      userEntity.pal = selectedPalCategory;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGoalDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGoal = await showDialog<UserWeightGoalEntity>(
        context: context,
        builder: (BuildContext context) => const SetWeightGoalDialog());
    if (selectedGoal != null) {
      userEntity.goal = selectedGoal;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetHeightDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedHeight = await showDialog<double>(
        context: context,
        builder: (context) => SetHeightDialog(
              userHeightCM: userEntity.heightCM,
            ));
    if (selectedHeight != null) {
      userEntity.heightCM = selectedHeight;

      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetWeightDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedWeight = await showDialog<double>(
        context: context,
        builder: (context) => SetWeightDialog(userWeight: userEntity.weightKG));
    if (selectedWeight != null) {
      userEntity.weightKG = selectedWeight;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetBirthdayDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedDate = await showDatePicker(
        context: context,
        initialDate: userEntity.birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (selectedDate != null) {
      userEntity.birthday = selectedDate;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGenderDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGender = await showDialog<UserGenderEntity>(
        context: context,
        builder: (BuildContext context) => const SetGenderDialog());
    if (selectedGender != null) {
      userEntity.gender = selectedGender;

      _profileBloc.updateUser(userEntity);
    }
  }
}
