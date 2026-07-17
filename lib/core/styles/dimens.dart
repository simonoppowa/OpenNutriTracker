import 'package:flutter/material.dart';

/// Layout and motion tokens for the calm friendly-flat design.
///
/// The look leans on generous spacing, soft-rounded corners and *subtle* depth
/// (a hairline border and a barely-there shadow) rather than heavy elevation.
abstract final class Dimens {
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  static const double radiusS = 14;
  static const double radiusM = 20;
  static const double radiusL = 26;
  static const double radiusXL = 32;

  static const BorderRadius borderRadiusS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));

  static const RoundedRectangleBorder shapeM = RoundedRectangleBorder(borderRadius: borderRadiusM);
  static const RoundedRectangleBorder shapeL = RoundedRectangleBorder(borderRadius: borderRadiusL);
  static const RoundedRectangleBorder shapeXL = RoundedRectangleBorder(borderRadius: borderRadiusXL);

  static const double hairline = 1;
  static const double minTouchTarget = 52;

  // Recurring widget sizes.
  static const double mealThumb = 60;
  static const double intakeCardSize = 120;
}

/// Gentle motion — emphasised easing for delight without flashiness.
abstract final class AppMotion {
  static const Duration durationShort = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationLong = Duration(milliseconds: 600);

  static const Curve standard = Easing.standard;
  static const Curve emphasized = Easing.emphasizedDecelerate;
  static const Curve emphasizedExit = Easing.emphasizedAccelerate;
}
