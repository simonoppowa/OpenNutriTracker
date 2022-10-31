import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/bmi_overview.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileBloc = ProfileBloc();
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: profileBloc,
      builder: (context, state) {
        if (state is ProfileInitial) {
          profileBloc.add(LoadProfileEvent(context: context));
          return _getLoadingContent();
        } else if (state is ProfileLoadingState) {
          return _getLoadingContent();
        } else if (state is ProfileLoadedState) {
          return _getLoadedContent(context);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }
}

Widget _getLoadingContent() {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

Widget _getLoadedContent(BuildContext context) {
  return ListView(
    children: [
      const SizedBox(height: 32.0),
      const BMIOverview(),
      const SizedBox(height: 32.0),
      ListTile(
        title: Text(
          S.of(context).activityLabel,
          style: Theme.of(context).textTheme.headline6,
        ),
        subtitle: Text(
          'Moderate Activity',
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
          'Maintain Weight',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        leading: const SizedBox(
          height: double.infinity,
          child: Icon(Icons.flag_outlined),
        ),
      ),
      ListTile(
        title: Text(
          S.of(context).weightLabel,
          style: Theme.of(context).textTheme.headline6,
        ),
        subtitle: Text(
          '80 kg',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        leading: const SizedBox(
          height: double.infinity,
          child: Icon(Icons.monitor_weight_outlined),
        ),
      ),
      ListTile(
        title: Text(
          S.of(context).heightLabel,
          style: Theme.of(context).textTheme.headline6,
        ),
        subtitle: Text(
          '180 cm',
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
          '22 years',
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
          '♂ male',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        leading: const SizedBox(
          height: double.infinity,
          child: Icon(Icons.male_outlined),
        ),
      ),
    ],
  );
}
