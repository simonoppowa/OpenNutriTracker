import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';

class ThemeModeProvider extends ChangeNotifier {
  AppThemeEntity appTheme;

  ThemeModeProvider({required this.appTheme});

  get themeMode => appTheme.toThemeMode();

  void updateTheme(AppThemeEntity appTheme) {
    this.appTheme = appTheme;
    notifyListeners();
  }
}
