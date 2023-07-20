import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';

enum AppThemeEntity {
  light,
  dark,
  system;

  factory AppThemeEntity.fromAppThemeDBO(AppThemeDBO dbo) {
    AppThemeEntity entity;
    switch (dbo) {
      case AppThemeDBO.light:
        entity = AppThemeEntity.light;
        break;
      case AppThemeDBO.dark:
        entity = AppThemeEntity.dark;
        break;
      case AppThemeDBO.system:
        entity = AppThemeEntity.system;
        break;
      default:
        return AppThemeEntity.system;
    }
    return entity;
  }

  ThemeMode toThemeMode() {
    ThemeMode mode;
    switch (this) {
      case AppThemeEntity.light:
        mode = ThemeMode.light;
        break;
      case AppThemeEntity.dark:
        mode = ThemeMode.dark;
        break;
      case AppThemeEntity.system:
        mode = ThemeMode.system;
        break;
    }
    return mode;
  }
}
