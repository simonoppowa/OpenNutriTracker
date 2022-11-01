import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/bmi_overview.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set%20_weight_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_gender_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_goal_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ProfilePage extends StatelessWidget {
  final _profileBloc = ProfileBloc();

  ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      builder: (context, state) {
        if (state is ProfileInitial) {
          _profileBloc.add(LoadProfileEvent(context: context));
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
          statusName: userBMIEntity.nutritionalStatus.getName(context),
        ),
        const SizedBox(height: 32.0),
        ListTile(
          title: Text(
            S.of(context).activityLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            user.pal.getName(context),
            style: Theme.of(context).textTheme.subtitle1,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.directions_walk_outlined),
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).goalLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            user.goal.getName(context),
            style: Theme.of(context).textTheme.subtitle1,
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
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            '${user.weightKG} kg',
            style: Theme.of(context).textTheme.subtitle1,
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
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            '${user.heightCM.toInt()} cm',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.height_outlined),
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).ageLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            S.of(context).yearsLabel(user.age),
            style: Theme.of(context).textTheme.subtitle1,
          ),
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.cake_outlined),
          ),
        ),
        ListTile(
          title: Text(
            S.of(context).genderLabel,
            style: Theme.of(context).textTheme.headline6,
          ),
          subtitle: Text(
            user.gender.getName(context),
            style: Theme.of(context).textTheme.subtitle1,
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

  Future<void> _showSetGoalDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGoal = await showDialog<UserWeightGoalEntity>(
        context: context,
        builder: (BuildContext context) => const SetWeightGoalDialog());
    if (selectedGoal != null) {
      userEntity.goal = selectedGoal;
      _profileBloc.updateUser(context, userEntity);
    }
  }

  Future<void> _showSetGenderDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGender = await showDialog<UserGenderEntity>(
        context: context,
        builder: (BuildContext context) => const SetGenderDialog());
    if (selectedGender != null) {
      userEntity.gender = selectedGender;
      _profileBloc.updateUser(context, userEntity);
    }
  }

  Future<void> _showSetWeightDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedWeight = await showDialog(
        context: context,
        builder: (context) => SetWeightDialog(userWeight: userEntity.weightKG));
    if (selectedWeight != null) {
      userEntity.weightKG = selectedWeight;
      _profileBloc.updateUser(context, userEntity);
    }
  }
}
