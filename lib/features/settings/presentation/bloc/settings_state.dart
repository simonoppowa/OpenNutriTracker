part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  @override
  List<Object> get props => [];
}

class SettingsLoadingState extends SettingsState {
  @override
  List<Object?> get props => [];
}

class SettingsLoadedState extends SettingsState {
  final String versionNumber;
  final bool sendAnonymousData;
  final AppThemeEntity appTheme;

  const SettingsLoadedState(
      this.versionNumber, this.sendAnonymousData, this.appTheme);

  @override
  List<Object?> get props => [versionNumber, sendAnonymousData, appTheme];
}
