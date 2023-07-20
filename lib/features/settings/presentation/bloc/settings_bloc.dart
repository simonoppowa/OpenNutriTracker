import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final log = Logger('SettingsBloc');

  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;

  SettingsBloc(this._getConfigUsecase, this._addConfigUsecase)
      : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoadingState());

      final userConfig = await _getConfigUsecase.getConfig();
      final appVersion = await AppConst.getVersionNumber();

      emit(SettingsLoadedState(appVersion,
          userConfig.hasAcceptedSendAnonymousData, userConfig.appTheme));
    });
  }

  void setHasAcceptedAnonymousData(bool hasAcceptedAnonymousData) {
    _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  void setAppTheme(AppThemeEntity appTheme) async {
    await _addConfigUsecase.setConfigAppTheme(appTheme);
  }
}
