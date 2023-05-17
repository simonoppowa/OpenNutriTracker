// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `OpenNutriTracker`
  String get appTitle {
    return Intl.message(
      'OpenNutriTracker',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Version {versionNumber}`
  String appVersionName(Object versionNumber) {
    return Intl.message(
      'Version $versionNumber',
      name: 'appVersionName',
      desc: '',
      args: [versionNumber],
    );
  }

  /// `OpenNutriTracker is a free and open-source calorie and nutrient tracker that respects your privacy.`
  String get appDescription {
    return Intl.message(
      'OpenNutriTracker is a free and open-source calorie and nutrient tracker that respects your privacy.',
      name: 'appDescription',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get addLabel {
    return Intl.message(
      'Add',
      name: 'addLabel',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settingsLabel {
    return Intl.message(
      'Settings',
      name: 'settingsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get homeLabel {
    return Intl.message(
      'Home',
      name: 'homeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Diary`
  String get diaryLabel {
    return Intl.message(
      'Diary',
      name: 'diaryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profileLabel {
    return Intl.message(
      'Profile',
      name: 'profileLabel',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get searchLabel {
    return Intl.message(
      'Search',
      name: 'searchLabel',
      desc: '',
      args: [],
    );
  }

  /// `Search results`
  String get searchResultsLabel {
    return Intl.message(
      'Search results',
      name: 'searchResultsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Please enter search word`
  String get searchDefaultLabel {
    return Intl.message(
      'Please enter search word',
      name: 'searchDefaultLabel',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get dialogOKLabel {
    return Intl.message(
      'OK',
      name: 'dialogOKLabel',
      desc: '',
      args: [],
    );
  }

  /// `CANCEL`
  String get dialogCancelLabel {
    return Intl.message(
      'CANCEL',
      name: 'dialogCancelLabel',
      desc: '',
      args: [],
    );
  }

  /// `START`
  String get buttonStartLabel {
    return Intl.message(
      'START',
      name: 'buttonStartLabel',
      desc: '',
      args: [],
    );
  }

  /// `NEXT`
  String get buttonNextLabel {
    return Intl.message(
      'NEXT',
      name: 'buttonNextLabel',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to`
  String get onboardingWelcomeLabel {
    return Intl.message(
      'Welcome to',
      name: 'onboardingWelcomeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Overview`
  String get onboardingOverviewLabel {
    return Intl.message(
      'Overview',
      name: 'onboardingOverviewLabel',
      desc: '',
      args: [],
    );
  }

  /// `Your goal:`
  String get onboardingYourGoalLabel {
    return Intl.message(
      'Your goal:',
      name: 'onboardingYourGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal per day`
  String get onboardingKcalPerDayLabel {
    return Intl.message(
      'kcal per day',
      name: 'onboardingKcalPerDayLabel',
      desc: '',
      args: [],
    );
  }

  /// `To start, the app needs some information about you to calculate your daily calorie goal.\nAll information about you is stored securely on your device.`
  String get onboardingIntroDescription {
    return Intl.message(
      'To start, the app needs some information about you to calculate your daily calorie goal.\nAll information about you is stored securely on your device.',
      name: 'onboardingIntroDescription',
      desc: '',
      args: [],
    );
  }

  /// `What's your gender?`
  String get onboardingGenderQuestionSubtitle {
    return Intl.message(
      'What\'s your gender?',
      name: 'onboardingGenderQuestionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Birthday`
  String get onboardingEnterBirthdayLabel {
    return Intl.message(
      'Birthday',
      name: 'onboardingEnterBirthdayLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter Date`
  String get onboardingBirthdayHint {
    return Intl.message(
      'Enter Date',
      name: 'onboardingBirthdayHint',
      desc: '',
      args: [],
    );
  }

  /// `When is your birthday?`
  String get onboardingBirthdayQuestionSubtitle {
    return Intl.message(
      'When is your birthday?',
      name: 'onboardingBirthdayQuestionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Whats your current height?`
  String get onboardingHeightQuestionSubtitle {
    return Intl.message(
      'Whats your current height?',
      name: 'onboardingHeightQuestionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Whats your current weight?`
  String get onboardingWeightQuestionSubtitle {
    return Intl.message(
      'Whats your current weight?',
      name: 'onboardingWeightQuestionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter correct height`
  String get onboardingWrongHeightLabel {
    return Intl.message(
      'Enter correct height',
      name: 'onboardingWrongHeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter correct weight`
  String get onboardingWrongWeightLabel {
    return Intl.message(
      'Enter correct weight',
      name: 'onboardingWrongWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. 60`
  String get onboardingWeightExampleHint {
    return Intl.message(
      'e.g. 60',
      name: 'onboardingWeightExampleHint',
      desc: '',
      args: [],
    );
  }

  /// `e.g. 170`
  String get onboardingHeightExampleHint {
    return Intl.message(
      'e.g. 170',
      name: 'onboardingHeightExampleHint',
      desc: '',
      args: [],
    );
  }

  /// `How active are you? (Without workouts)`
  String get onboardingActivityQuestionSubtitle {
    return Intl.message(
      'How active are you? (Without workouts)',
      name: 'onboardingActivityQuestionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `What's your current weight goal?`
  String get onboardingGoalQuestionSubtitle {
    return Intl.message(
      'What\'s your current weight goal?',
      name: 'onboardingGoalQuestionSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Wrong input, please try again`
  String get onboardingSaveUserError {
    return Intl.message(
      'Wrong input, please try again',
      name: 'onboardingSaveUserError',
      desc: '',
      args: [],
    );
  }

  /// `Units`
  String get settingsUnitsLabel {
    return Intl.message(
      'Units',
      name: 'settingsUnitsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Calculations`
  String get settingsCalculationsLabel {
    return Intl.message(
      'Calculations',
      name: 'settingsCalculationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Licenses`
  String get settingsLicensesLabel {
    return Intl.message(
      'Licenses',
      name: 'settingsLicensesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Disclaimer`
  String get settingsDisclaimerLabel {
    return Intl.message(
      'Disclaimer',
      name: 'settingsDisclaimerLabel',
      desc: '',
      args: [],
    );
  }

  /// `Report Error`
  String get settingsReportErrorLabel {
    return Intl.message(
      'Report Error',
      name: 'settingsReportErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Source Code`
  String get settingsSourceCodeLabel {
    return Intl.message(
      'Source Code',
      name: 'settingsSourceCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get settingFeedbackLabel {
    return Intl.message(
      'Feedback',
      name: 'settingFeedbackLabel',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get settingAboutLabel {
    return Intl.message(
      'About',
      name: 'settingAboutLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mass`
  String get settingsMassLabel {
    return Intl.message(
      'Mass',
      name: 'settingsMassLabel',
      desc: '',
      args: [],
    );
  }

  /// `Distance`
  String get settingsDistanceLabel {
    return Intl.message(
      'Distance',
      name: 'settingsDistanceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Volume`
  String get settingsVolumeLabel {
    return Intl.message(
      'Volume',
      name: 'settingsVolumeLabel',
      desc: '',
      args: [],
    );
  }

  /// `OpenNutriTracker is not a medical application. All data provider is not validated and should be taken with caution. Please ensure a healthy lifestyle and talk to a professional if you have problems. Usage during illness, pregnancy or lactation is not advised.\n\n\nThe application is still under construction. Errors, bugs and crashes might occur.`
  String get disclaimerText {
    return Intl.message(
      'OpenNutriTracker is not a medical application. All data provider is not validated and should be taken with caution. Please ensure a healthy lifestyle and talk to a professional if you have problems. Usage during illness, pregnancy or lactation is not advised.\n\n\nThe application is still under construction. Errors, bugs and crashes might occur.',
      name: 'disclaimerText',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to report an error to the developer?`
  String get reportErrorDialogText {
    return Intl.message(
      'Do you want to report an error to the developer?',
      name: 'reportErrorDialogText',
      desc: '',
      args: [],
    );
  }

  /// `GPL-3.0 license`
  String get appLicenseLabel {
    return Intl.message(
      'GPL-3.0 license',
      name: 'appLicenseLabel',
      desc: '',
      args: [],
    );
  }

  /// `TDEE equation`
  String get calculationsTDEELabel {
    return Intl.message(
      'TDEE equation',
      name: 'calculationsTDEELabel',
      desc: '',
      args: [],
    );
  }

  /// `Institute of Medicine Equation`
  String get calculationsTDEEIOM2006Label {
    return Intl.message(
      'Institute of Medicine Equation',
      name: 'calculationsTDEEIOM2006Label',
      desc: '',
      args: [],
    );
  }

  /// `(recommended)`
  String get calculationsRecommendedLabel {
    return Intl.message(
      '(recommended)',
      name: 'calculationsRecommendedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Macros distribution`
  String get calculationsMacronutrientsDistributionLabel {
    return Intl.message(
      'Macros distribution',
      name: 'calculationsMacronutrientsDistributionLabel',
      desc: '',
      args: [],
    );
  }

  /// `{pctCarbs}% carbs, {pctFats}% fats, {pctProteins}% proteins`
  String calculationsMacrosDistribution(
      Object pctCarbs, Object pctFats, Object pctProteins) {
    return Intl.message(
      '$pctCarbs% carbs, $pctFats% fats, $pctProteins% proteins',
      name: 'calculationsMacrosDistribution',
      desc: '',
      args: [pctCarbs, pctFats, pctProteins],
    );
  }

  /// `Add new Item:`
  String get addItemLabel {
    return Intl.message(
      'Add new Item:',
      name: 'addItemLabel',
      desc: '',
      args: [],
    );
  }

  /// `Activity`
  String get activityLabel {
    return Intl.message(
      'Activity',
      name: 'activityLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. running, biking, yoga ...`
  String get activityExample {
    return Intl.message(
      'e.g. running, biking, yoga ...',
      name: 'activityExample',
      desc: '',
      args: [],
    );
  }

  /// `Breakfast`
  String get breakfastLabel {
    return Intl.message(
      'Breakfast',
      name: 'breakfastLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. cereal, milk, coffee ...`
  String get breakfastExample {
    return Intl.message(
      'e.g. cereal, milk, coffee ...',
      name: 'breakfastExample',
      desc: '',
      args: [],
    );
  }

  /// `Lunch`
  String get lunchLabel {
    return Intl.message(
      'Lunch',
      name: 'lunchLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. pizza, salad, rice ...`
  String get lunchExample {
    return Intl.message(
      'e.g. pizza, salad, rice ...',
      name: 'lunchExample',
      desc: '',
      args: [],
    );
  }

  /// `Dinner`
  String get dinnerLabel {
    return Intl.message(
      'Dinner',
      name: 'dinnerLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. soup, chicken, wine ...`
  String get dinnerExample {
    return Intl.message(
      'e.g. soup, chicken, wine ...',
      name: 'dinnerExample',
      desc: '',
      args: [],
    );
  }

  /// `Snack`
  String get snackLabel {
    return Intl.message(
      'Snack',
      name: 'snackLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. apple, ice cream, chocolate ...`
  String get snackExample {
    return Intl.message(
      'e.g. apple, ice cream, chocolate ...',
      name: 'snackExample',
      desc: '',
      args: [],
    );
  }

  /// `Delete Item?`
  String get deleteTimeDialogTitle {
    return Intl.message(
      'Delete Item?',
      name: 'deleteTimeDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do want to delete the selected item?`
  String get deleteTimeDialogContent {
    return Intl.message(
      'Do want to delete the selected item?',
      name: 'deleteTimeDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Item deleted`
  String get itemDeletedSnackbar {
    return Intl.message(
      'Item deleted',
      name: 'itemDeletedSnackbar',
      desc: '',
      args: [],
    );
  }

  /// `supplied`
  String get suppliedLabel {
    return Intl.message(
      'supplied',
      name: 'suppliedLabel',
      desc: '',
      args: [],
    );
  }

  /// `burned`
  String get burnedLabel {
    return Intl.message(
      'burned',
      name: 'burnedLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal left`
  String get kcalLeftLabel {
    return Intl.message(
      'kcal left',
      name: 'kcalLeftLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nutrition Information`
  String get nutritionInfoLabel {
    return Intl.message(
      'Nutrition Information',
      name: 'nutritionInfoLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal`
  String get kcalLabel {
    return Intl.message(
      'kcal',
      name: 'kcalLabel',
      desc: '',
      args: [],
    );
  }

  /// `carbs`
  String get carbsLabel {
    return Intl.message(
      'carbs',
      name: 'carbsLabel',
      desc: '',
      args: [],
    );
  }

  /// `fat`
  String get fatLabel {
    return Intl.message(
      'fat',
      name: 'fatLabel',
      desc: '',
      args: [],
    );
  }

  /// `protein`
  String get proteinLabel {
    return Intl.message(
      'protein',
      name: 'proteinLabel',
      desc: '',
      args: [],
    );
  }

  /// `energy`
  String get energyLabel {
    return Intl.message(
      'energy',
      name: 'energyLabel',
      desc: '',
      args: [],
    );
  }

  /// `saturated fat`
  String get saturatedFatLabel {
    return Intl.message(
      'saturated fat',
      name: 'saturatedFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `carbohydrate`
  String get carbohydrateLabel {
    return Intl.message(
      'carbohydrate',
      name: 'carbohydrateLabel',
      desc: '',
      args: [],
    );
  }

  /// `sugar`
  String get sugarLabel {
    return Intl.message(
      'sugar',
      name: 'sugarLabel',
      desc: '',
      args: [],
    );
  }

  /// `fiber`
  String get fiberLabel {
    return Intl.message(
      'fiber',
      name: 'fiberLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per 100g`
  String get per100gLabel {
    return Intl.message(
      'Per 100g',
      name: 'per100gLabel',
      desc: '',
      args: [],
    );
  }

  /// `More Information at\nOpenFoodFacts`
  String get additionalInfoLabelOFF {
    return Intl.message(
      'More Information at\nOpenFoodFacts',
      name: 'additionalInfoLabelOFF',
      desc: '',
      args: [],
    );
  }

  /// `Information provided\n by the \n'2011 Compendium\n of Physical Activities'`
  String get additionalInfoLabelCompendium2011 {
    return Intl.message(
      'Information provided\n by the \n\'2011 Compendium\n of Physical Activities\'',
      name: 'additionalInfoLabelCompendium2011',
      desc: '',
      args: [],
    );
  }

  /// `Quantity`
  String get quantityLabel {
    return Intl.message(
      'Quantity',
      name: 'quantityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Unit`
  String get unitLabel {
    return Intl.message(
      'Unit',
      name: 'unitLabel',
      desc: '',
      args: [],
    );
  }

  /// `Scan Product`
  String get scanProductLabel {
    return Intl.message(
      'Scan Product',
      name: 'scanProductLabel',
      desc: '',
      args: [],
    );
  }

  /// `Added new intake`
  String get infoAddedIntakeLabel {
    return Intl.message(
      'Added new intake',
      name: 'infoAddedIntakeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Added new activity`
  String get infoAddedActivityLabel {
    return Intl.message(
      'Added new activity',
      name: 'infoAddedActivityLabel',
      desc: '',
      args: [],
    );
  }

  /// `BMI`
  String get bmiLabel {
    return Intl.message(
      'BMI',
      name: 'bmiLabel',
      desc: '',
      args: [],
    );
  }

  /// `Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals.`
  String get bmiInfo {
    return Intl.message(
      'Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals.',
      name: 'bmiInfo',
      desc: '',
      args: [],
    );
  }

  /// `I have read the`
  String get readLabel {
    return Intl.message(
      'I have read the',
      name: 'readLabel',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicyLabel {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sedentary`
  String get palSedentaryLabel {
    return Intl.message(
      'Sedentary',
      name: 'palSedentaryLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. office job and mostly sitting free time activities`
  String get palSedentaryDescriptionLabel {
    return Intl.message(
      'e.g. office job and mostly sitting free time activities',
      name: 'palSedentaryDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Low Active`
  String get palLowLActiveLabel {
    return Intl.message(
      'Low Active',
      name: 'palLowLActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. sitting or standing in job and light free time activities`
  String get palLowActiveDescriptionLabel {
    return Intl.message(
      'e.g. sitting or standing in job and light free time activities',
      name: 'palLowActiveDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get palActiveLabel {
    return Intl.message(
      'Active',
      name: 'palActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mostly standing or walking in job and active free time activities`
  String get palActiveDescriptionLabel {
    return Intl.message(
      'Mostly standing or walking in job and active free time activities',
      name: 'palActiveDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Very Active`
  String get palVeryActiveLabel {
    return Intl.message(
      'Very Active',
      name: 'palVeryActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Mostly walking, running or carrying weight in job and active free time activities`
  String get palVeryActiveDescriptionLabel {
    return Intl.message(
      'Mostly walking, running or carrying weight in job and active free time activities',
      name: 'palVeryActiveDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Activity Level`
  String get selectPalCategoryLabel {
    return Intl.message(
      'Select Activity Level',
      name: 'selectPalCategoryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Choose Weight Goal`
  String get chooseWeightGoalLabel {
    return Intl.message(
      'Choose Weight Goal',
      name: 'chooseWeightGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Lose Weight`
  String get goalLoseWeight {
    return Intl.message(
      'Lose Weight',
      name: 'goalLoseWeight',
      desc: '',
      args: [],
    );
  }

  /// `Maintain Weight`
  String get goalMaintainWeight {
    return Intl.message(
      'Maintain Weight',
      name: 'goalMaintainWeight',
      desc: '',
      args: [],
    );
  }

  /// `Gain Weight`
  String get goalGainWeight {
    return Intl.message(
      'Gain Weight',
      name: 'goalGainWeight',
      desc: '',
      args: [],
    );
  }

  /// `Goal`
  String get goalLabel {
    return Intl.message(
      'Goal',
      name: 'goalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Height`
  String get selectHeightDialogLabel {
    return Intl.message(
      'Select Height',
      name: 'selectHeightDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get heightLabel {
    return Intl.message(
      'Height',
      name: 'heightLabel',
      desc: '',
      args: [],
    );
  }

  /// `cm`
  String get cmLabel {
    return Intl.message(
      'cm',
      name: 'cmLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select Weight`
  String get selectWeightDialogLabel {
    return Intl.message(
      'Select Weight',
      name: 'selectWeightDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get weightLabel {
    return Intl.message(
      'Weight',
      name: 'weightLabel',
      desc: '',
      args: [],
    );
  }

  /// `kg`
  String get kgLabel {
    return Intl.message(
      'kg',
      name: 'kgLabel',
      desc: '',
      args: [],
    );
  }

  /// `Age`
  String get ageLabel {
    return Intl.message(
      'Age',
      name: 'ageLabel',
      desc: '',
      args: [],
    );
  }

  /// `{age} years`
  String yearsLabel(Object age) {
    return Intl.message(
      '$age years',
      name: 'yearsLabel',
      desc: '',
      args: [age],
    );
  }

  /// `Select Gender`
  String get selectGenderDialogLabel {
    return Intl.message(
      'Select Gender',
      name: 'selectGenderDialogLabel',
      desc: '',
      args: [],
    );
  }

  /// `Gender`
  String get genderLabel {
    return Intl.message(
      'Gender',
      name: 'genderLabel',
      desc: '',
      args: [],
    );
  }

  /// `♂ male`
  String get genderMaleLabel {
    return Intl.message(
      '♂ male',
      name: 'genderMaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `♀ female`
  String get genderFemaleLabel {
    return Intl.message(
      '♀ female',
      name: 'genderFemaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nothing added`
  String get nothingAddedLabel {
    return Intl.message(
      'Nothing added',
      name: 'nothingAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Underweight`
  String get nutritionalStatusUnderweight {
    return Intl.message(
      'Underweight',
      name: 'nutritionalStatusUnderweight',
      desc: '',
      args: [],
    );
  }

  /// `Normal Weight`
  String get nutritionalStatusNormalWeight {
    return Intl.message(
      'Normal Weight',
      name: 'nutritionalStatusNormalWeight',
      desc: '',
      args: [],
    );
  }

  /// `Pre-obesity`
  String get nutritionalStatusPreObesity {
    return Intl.message(
      'Pre-obesity',
      name: 'nutritionalStatusPreObesity',
      desc: '',
      args: [],
    );
  }

  /// `Obesity Class I`
  String get nutritionalStatusObeseClassI {
    return Intl.message(
      'Obesity Class I',
      name: 'nutritionalStatusObeseClassI',
      desc: '',
      args: [],
    );
  }

  /// `Obesity Class II`
  String get nutritionalStatusObeseClassII {
    return Intl.message(
      'Obesity Class II',
      name: 'nutritionalStatusObeseClassII',
      desc: '',
      args: [],
    );
  }

  /// `Obesity Class III`
  String get nutritionalStatusObeseClassIII {
    return Intl.message(
      'Obesity Class III',
      name: 'nutritionalStatusObeseClassIII',
      desc: '',
      args: [],
    );
  }

  /// `Risk of comorbidities: {riskValue}`
  String nutritionalStatusRiskLabel(Object riskValue) {
    return Intl.message(
      'Risk of comorbidities: $riskValue',
      name: 'nutritionalStatusRiskLabel',
      desc: '',
      args: [riskValue],
    );
  }

  /// `Low \n(but risk of other \nclinical problems increased)`
  String get nutritionalStatusRiskLow {
    return Intl.message(
      'Low \n(but risk of other \nclinical problems increased)',
      name: 'nutritionalStatusRiskLow',
      desc: '',
      args: [],
    );
  }

  /// `Average`
  String get nutritionalStatusRiskAverage {
    return Intl.message(
      'Average',
      name: 'nutritionalStatusRiskAverage',
      desc: '',
      args: [],
    );
  }

  /// `Increased`
  String get nutritionalStatusRiskIncreased {
    return Intl.message(
      'Increased',
      name: 'nutritionalStatusRiskIncreased',
      desc: '',
      args: [],
    );
  }

  /// `Moderate`
  String get nutritionalStatusRiskModerate {
    return Intl.message(
      'Moderate',
      name: 'nutritionalStatusRiskModerate',
      desc: '',
      args: [],
    );
  }

  /// `Severe`
  String get nutritionalStatusRiskSevere {
    return Intl.message(
      'Severe',
      name: 'nutritionalStatusRiskSevere',
      desc: '',
      args: [],
    );
  }

  /// `Very severe`
  String get nutritionalStatusRiskVerySevere {
    return Intl.message(
      'Very severe',
      name: 'nutritionalStatusRiskVerySevere',
      desc: '',
      args: [],
    );
  }

  /// `Error while opening email app`
  String get errorOpeningEmail {
    return Intl.message(
      'Error while opening email app',
      name: 'errorOpeningEmail',
      desc: '',
      args: [],
    );
  }

  /// `Error while opening browser app`
  String get errorOpeningBrowser {
    return Intl.message(
      'Error while opening browser app',
      name: 'errorOpeningBrowser',
      desc: '',
      args: [],
    );
  }

  /// `bicycling`
  String get paHeadingBicycling {
    return Intl.message(
      'bicycling',
      name: 'paHeadingBicycling',
      desc: '',
      args: [],
    );
  }

  /// `conditioning exercise`
  String get paHeadingConditionalExercise {
    return Intl.message(
      'conditioning exercise',
      name: 'paHeadingConditionalExercise',
      desc: '',
      args: [],
    );
  }

  /// `dancing`
  String get paHeadingDancing {
    return Intl.message(
      'dancing',
      name: 'paHeadingDancing',
      desc: '',
      args: [],
    );
  }

  /// `running`
  String get paHeadingRunning {
    return Intl.message(
      'running',
      name: 'paHeadingRunning',
      desc: '',
      args: [],
    );
  }

  /// `sports`
  String get paHeadingSports {
    return Intl.message(
      'sports',
      name: 'paHeadingSports',
      desc: '',
      args: [],
    );
  }

  /// `walking`
  String get paHeadingWalking {
    return Intl.message(
      'walking',
      name: 'paHeadingWalking',
      desc: '',
      args: [],
    );
  }

  /// `water activities`
  String get paHeadingWaterActivities {
    return Intl.message(
      'water activities',
      name: 'paHeadingWaterActivities',
      desc: '',
      args: [],
    );
  }

  /// `winter activities`
  String get paHeadingWinterActivities {
    return Intl.message(
      'winter activities',
      name: 'paHeadingWinterActivities',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, general`
  String get paBicyclingGeneral {
    return Intl.message(
      'bicycling, general',
      name: 'paBicyclingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, mountain, general`
  String get paBicyclingMountainGeneral {
    return Intl.message(
      'bicycling, mountain, general',
      name: 'paBicyclingMountainGeneral',
      desc: '',
      args: [],
    );
  }

  /// `unicycling`
  String get paUnicyclingGeneral {
    return Intl.message(
      'unicycling',
      name: 'paUnicyclingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, stationary, general`
  String get paBicyclingStationaryGeneral {
    return Intl.message(
      'bicycling, stationary, general',
      name: 'paBicyclingStationaryGeneral',
      desc: '',
      args: [],
    );
  }

  /// `calisthenics, light or moderate effort, general (e.g., back exercises), going up & down from floor (Taylor Code 150)`
  String get paCalisthenicsGeneral {
    return Intl.message(
      'calisthenics, light or moderate effort, general (e.g., back exercises), going up & down from floor (Taylor Code 150)',
      name: 'paCalisthenicsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `resistance training (weight lifting, free weight, nautilus or universal), power lifting or body building, vigorous effort (Taylor Code 210)`
  String get paResistanceTraining {
    return Intl.message(
      'resistance training (weight lifting, free weight, nautilus or universal), power lifting or body building, vigorous effort (Taylor Code 210)',
      name: 'paResistanceTraining',
      desc: '',
      args: [],
    );
  }

  /// `rope skipping, general`
  String get paRopeSkippingGeneral {
    return Intl.message(
      'rope skipping, general',
      name: 'paRopeSkippingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics, water calisthenics, water exercise`
  String get paWaterAerobics {
    return Intl.message(
      'water aerobics, water calisthenics, water exercise',
      name: 'paWaterAerobics',
      desc: '',
      args: [],
    );
  }

  /// `aerobic, general`
  String get paDancingAerobicGeneral {
    return Intl.message(
      'aerobic, general',
      name: 'paDancingAerobicGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general dancing (e.g., disco, folk, Irish step dancing, line dancing, polka, contra, country)`
  String get paDancingGeneral {
    return Intl.message(
      'general dancing (e.g., disco, folk, Irish step dancing, line dancing, polka, contra, country)',
      name: 'paDancingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `jogging, general`
  String get paJoggingGeneral {
    return Intl.message(
      'jogging, general',
      name: 'paJoggingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `running, (Taylor code 200)`
  String get paRunningGeneral {
    return Intl.message(
      'running, (Taylor code 200)',
      name: 'paRunningGeneral',
      desc: '',
      args: [],
    );
  }

  /// `archery, non-hunting`
  String get paArcheryGeneral {
    return Intl.message(
      'archery, non-hunting',
      name: 'paArcheryGeneral',
      desc: '',
      args: [],
    );
  }

  /// `badminton, social singles and doubles, general`
  String get paBadmintonGeneral {
    return Intl.message(
      'badminton, social singles and doubles, general',
      name: 'paBadmintonGeneral',
      desc: '',
      args: [],
    );
  }

  /// `basketball, general`
  String get paBasketballGeneral {
    return Intl.message(
      'basketball, general',
      name: 'paBasketballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `billiards`
  String get paBilliardsGeneral {
    return Intl.message(
      'billiards',
      name: 'paBilliardsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `bowling (Taylor Code 390)`
  String get paBowlingGeneral {
    return Intl.message(
      'bowling (Taylor Code 390)',
      name: 'paBowlingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `boxing, punching bag`
  String get paBoxingBag {
    return Intl.message(
      'boxing, punching bag',
      name: 'paBoxingBag',
      desc: '',
      args: [],
    );
  }

  /// `boxing, in ring, general`
  String get paBoxingGeneral {
    return Intl.message(
      'boxing, in ring, general',
      name: 'paBoxingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `broomball`
  String get paBroomball {
    return Intl.message(
      'broomball',
      name: 'paBroomball',
      desc: '',
      args: [],
    );
  }

  /// `children’s games, adults playing (e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort`
  String get paChildrenGame {
    return Intl.message(
      'children’s games, adults playing (e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort',
      name: 'paChildrenGame',
      desc: '',
      args: [],
    );
  }

  /// `cheerleading, gymnastic moves, competitive`
  String get paCheerleading {
    return Intl.message(
      'cheerleading, gymnastic moves, competitive',
      name: 'paCheerleading',
      desc: '',
      args: [],
    );
  }

  /// `cricket, batting, bowling, fielding`
  String get paCricket {
    return Intl.message(
      'cricket, batting, bowling, fielding',
      name: 'paCricket',
      desc: '',
      args: [],
    );
  }

  /// `croquet`
  String get paCroquet {
    return Intl.message(
      'croquet',
      name: 'paCroquet',
      desc: '',
      args: [],
    );
  }

  /// `curling`
  String get paCurling {
    return Intl.message(
      'curling',
      name: 'paCurling',
      desc: '',
      args: [],
    );
  }

  /// `darts, wall or lawn`
  String get paDartsWall {
    return Intl.message(
      'darts, wall or lawn',
      name: 'paDartsWall',
      desc: '',
      args: [],
    );
  }

  /// `auto racing, open wheel`
  String get paAutoRacing {
    return Intl.message(
      'auto racing, open wheel',
      name: 'paAutoRacing',
      desc: '',
      args: [],
    );
  }

  /// `fencing`
  String get paFencing {
    return Intl.message(
      'fencing',
      name: 'paFencing',
      desc: '',
      args: [],
    );
  }

  /// `football, touch, flag, general (Taylor Code 510)`
  String get paAmericanFootballGeneral {
    return Intl.message(
      'football, touch, flag, general (Taylor Code 510)',
      name: 'paAmericanFootballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `football or baseball, playing catch`
  String get paCatch {
    return Intl.message(
      'football or baseball, playing catch',
      name: 'paCatch',
      desc: '',
      args: [],
    );
  }

  /// `frisbee playing, general`
  String get paFrisbee {
    return Intl.message(
      'frisbee playing, general',
      name: 'paFrisbee',
      desc: '',
      args: [],
    );
  }

  /// `golf, general`
  String get paGolfGeneral {
    return Intl.message(
      'golf, general',
      name: 'paGolfGeneral',
      desc: '',
      args: [],
    );
  }

  /// `gymnastics, general`
  String get paGymnasticsGeneral {
    return Intl.message(
      'gymnastics, general',
      name: 'paGymnasticsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `hacky sack`
  String get paHackySack {
    return Intl.message(
      'hacky sack',
      name: 'paHackySack',
      desc: '',
      args: [],
    );
  }

  /// `handball, general (Taylor Code 520)`
  String get paHandballGeneral {
    return Intl.message(
      'handball, general (Taylor Code 520)',
      name: 'paHandballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `hang gliding`
  String get paHangGliding {
    return Intl.message(
      'hang gliding',
      name: 'paHangGliding',
      desc: '',
      args: [],
    );
  }

  /// `hockey, field`
  String get paHockeyField {
    return Intl.message(
      'hockey, field',
      name: 'paHockeyField',
      desc: '',
      args: [],
    );
  }

  /// `hockey, ice, general`
  String get paIceHockeyGeneral {
    return Intl.message(
      'hockey, ice, general',
      name: 'paIceHockeyGeneral',
      desc: '',
      args: [],
    );
  }

  /// `horseback riding, general`
  String get paHorseRidingGeneral {
    return Intl.message(
      'horseback riding, general',
      name: 'paHorseRidingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `jai alai`
  String get paJaiAlai {
    return Intl.message(
      'jai alai',
      name: 'paJaiAlai',
      desc: '',
      args: [],
    );
  }

  /// `martial arts, different types, slower pace, novice performers, practice`
  String get paMartialArtsSlower {
    return Intl.message(
      'martial arts, different types, slower pace, novice performers, practice',
      name: 'paMartialArtsSlower',
      desc: '',
      args: [],
    );
  }

  /// `martial arts, different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)`
  String get paMartialArtsModerate {
    return Intl.message(
      'martial arts, different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)',
      name: 'paMartialArtsModerate',
      desc: '',
      args: [],
    );
  }

  /// `juggling`
  String get paJuggling {
    return Intl.message(
      'juggling',
      name: 'paJuggling',
      desc: '',
      args: [],
    );
  }

  /// `kickball`
  String get paKickball {
    return Intl.message(
      'kickball',
      name: 'paKickball',
      desc: '',
      args: [],
    );
  }

  /// `lacrosse`
  String get paLacrosse {
    return Intl.message(
      'lacrosse',
      name: 'paLacrosse',
      desc: '',
      args: [],
    );
  }

  /// `lawn bowling, bocce ball, outdoor`
  String get paLawnBowling {
    return Intl.message(
      'lawn bowling, bocce ball, outdoor',
      name: 'paLawnBowling',
      desc: '',
      args: [],
    );
  }

  /// `moto-cross, off-road motor sports, all-terrain vehicle, general`
  String get paMotoCross {
    return Intl.message(
      'moto-cross, off-road motor sports, all-terrain vehicle, general',
      name: 'paMotoCross',
      desc: '',
      args: [],
    );
  }

  /// `orienteering`
  String get paOrienteering {
    return Intl.message(
      'orienteering',
      name: 'paOrienteering',
      desc: '',
      args: [],
    );
  }

  /// `paddleball, casual, general (Taylor Code 460)`
  String get paPaddleball {
    return Intl.message(
      'paddleball, casual, general (Taylor Code 460)',
      name: 'paPaddleball',
      desc: '',
      args: [],
    );
  }

  /// `polo, on horseback`
  String get paPoloHorse {
    return Intl.message(
      'polo, on horseback',
      name: 'paPoloHorse',
      desc: '',
      args: [],
    );
  }

  /// `racquetball, general (Taylor Code 470)`
  String get paRacquetball {
    return Intl.message(
      'racquetball, general (Taylor Code 470)',
      name: 'paRacquetball',
      desc: '',
      args: [],
    );
  }

  /// `rock or mountain climbing (Taylor Code 470)`
  String get paMountainClimbing {
    return Intl.message(
      'rock or mountain climbing (Taylor Code 470)',
      name: 'paMountainClimbing',
      desc: '',
      args: [],
    );
  }

  /// `rodeo sports, general, moderate effort`
  String get paRodeoSportGeneralModerate {
    return Intl.message(
      'rodeo sports, general, moderate effort',
      name: 'paRodeoSportGeneralModerate',
      desc: '',
      args: [],
    );
  }

  /// `rope jumping, moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce`
  String get paRopeJumpingGeneral {
    return Intl.message(
      'rope jumping, moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce',
      name: 'paRopeJumpingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `rugby, union, team, competitive`
  String get paRugbyCompetitive {
    return Intl.message(
      'rugby, union, team, competitive',
      name: 'paRugbyCompetitive',
      desc: '',
      args: [],
    );
  }

  /// `rugby, touch, non-competitive`
  String get paRugbyNonCompetitive {
    return Intl.message(
      'rugby, touch, non-competitive',
      name: 'paRugbyNonCompetitive',
      desc: '',
      args: [],
    );
  }

  /// `shuffleboard`
  String get paShuffleboard {
    return Intl.message(
      'shuffleboard',
      name: 'paShuffleboard',
      desc: '',
      args: [],
    );
  }

  /// `skateboarding, general, moderate effort`
  String get paSkateboardingGeneral {
    return Intl.message(
      'skateboarding, general, moderate effort',
      name: 'paSkateboardingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `skating, roller (Taylor Code 360)`
  String get paSkatingRoller {
    return Intl.message(
      'skating, roller (Taylor Code 360)',
      name: 'paSkatingRoller',
      desc: '',
      args: [],
    );
  }

  /// `rollerblading, in-line skating, 14.4 km/h (9.0 mph), recreational pace`
  String get paRollerbladingLight {
    return Intl.message(
      'rollerblading, in-line skating, 14.4 km/h (9.0 mph), recreational pace',
      name: 'paRollerbladingLight',
      desc: '',
      args: [],
    );
  }

  /// `skydiving, base jumping, bungee jumping`
  String get paSkydiving {
    return Intl.message(
      'skydiving, base jumping, bungee jumping',
      name: 'paSkydiving',
      desc: '',
      args: [],
    );
  }

  /// `soccer, casual, general (Taylor Code 540)`
  String get paSoccerGeneral {
    return Intl.message(
      'soccer, casual, general (Taylor Code 540)',
      name: 'paSoccerGeneral',
      desc: '',
      args: [],
    );
  }

  /// `softball or baseball, fast or slow pitch, general (Taylor Code 440)`
  String get paSoftballBaseballGeneral {
    return Intl.message(
      'softball or baseball, fast or slow pitch, general (Taylor Code 440)',
      name: 'paSoftballBaseballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `squash, general`
  String get paSquashGeneral {
    return Intl.message(
      'squash, general',
      name: 'paSquashGeneral',
      desc: '',
      args: [],
    );
  }

  /// `table tennis, ping pong (Taylor Code 410)`
  String get paTableTennisGeneral {
    return Intl.message(
      'table tennis, ping pong (Taylor Code 410)',
      name: 'paTableTennisGeneral',
      desc: '',
      args: [],
    );
  }

  /// `tai chi, qi gong, general`
  String get paTaiChiQiGongGeneral {
    return Intl.message(
      'tai chi, qi gong, general',
      name: 'paTaiChiQiGongGeneral',
      desc: '',
      args: [],
    );
  }

  /// `tennis, general`
  String get paTennisGeneral {
    return Intl.message(
      'tennis, general',
      name: 'paTennisGeneral',
      desc: '',
      args: [],
    );
  }

  /// `trampoline, recreational`
  String get paTrampolineLight {
    return Intl.message(
      'trampoline, recreational',
      name: 'paTrampolineLight',
      desc: '',
      args: [],
    );
  }

  /// `volleyball, non-competitive, 6 - 9 member team, general`
  String get paVolleyballGeneral {
    return Intl.message(
      'volleyball, non-competitive, 6 - 9 member team, general',
      name: 'paVolleyballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `wrestling (one match = 5 minutes)`
  String get paWrestling {
    return Intl.message(
      'wrestling (one match = 5 minutes)',
      name: 'paWrestling',
      desc: '',
      args: [],
    );
  }

  /// `wallyball, general`
  String get paWallyball {
    return Intl.message(
      'wallyball, general',
      name: 'paWallyball',
      desc: '',
      args: [],
    );
  }

  /// `track and field (e.g., shot, discus, hammer throw)`
  String get paTrackField1 {
    return Intl.message(
      'track and field (e.g., shot, discus, hammer throw)',
      name: 'paTrackField1',
      desc: '',
      args: [],
    );
  }

  /// `track and field (e.g., high jump, long jump, triple jump, javelin, pole vault)`
  String get paTrackField2 {
    return Intl.message(
      'track and field (e.g., high jump, long jump, triple jump, javelin, pole vault)',
      name: 'paTrackField2',
      desc: '',
      args: [],
    );
  }

  /// `track and field (e.g., steeplechase, hurdles)`
  String get paTrackField3 {
    return Intl.message(
      'track and field (e.g., steeplechase, hurdles)',
      name: 'paTrackField3',
      desc: '',
      args: [],
    );
  }

  /// `backpacking`
  String get paBackpackingGeneral {
    return Intl.message(
      'backpacking',
      name: 'paBackpackingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `climbing hills, no load`
  String get paClimbingHillsNoLoadGeneral {
    return Intl.message(
      'climbing hills, no load',
      name: 'paClimbingHillsNoLoadGeneral',
      desc: '',
      args: [],
    );
  }

  /// `hiking, cross country (Taylor Code 040)`
  String get paHikingCrossCountry {
    return Intl.message(
      'hiking, cross country (Taylor Code 040)',
      name: 'paHikingCrossCountry',
      desc: '',
      args: [],
    );
  }

  /// `walking for pleasure`
  String get paWalkingForPleasure {
    return Intl.message(
      'walking for pleasure',
      name: 'paWalkingForPleasure',
      desc: '',
      args: [],
    );
  }

  /// `walking the dog`
  String get paWalkingTheDog {
    return Intl.message(
      'walking the dog',
      name: 'paWalkingTheDog',
      desc: '',
      args: [],
    );
  }

  /// `canoeing, rowing, for pleasure, general (Taylor Code 250)`
  String get paCanoeingGeneral {
    return Intl.message(
      'canoeing, rowing, for pleasure, general (Taylor Code 250)',
      name: 'paCanoeingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `diving, springboard or platform`
  String get paDivingSpringboardPlatform {
    return Intl.message(
      'diving, springboard or platform',
      name: 'paDivingSpringboardPlatform',
      desc: '',
      args: [],
    );
  }

  /// `kayaking, moderate effort`
  String get paKayakingModerate {
    return Intl.message(
      'kayaking, moderate effort',
      name: 'paKayakingModerate',
      desc: '',
      args: [],
    );
  }

  /// `paddle boat`
  String get paPaddleBoat {
    return Intl.message(
      'paddle boat',
      name: 'paPaddleBoat',
      desc: '',
      args: [],
    );
  }

  /// `sailing, boat and board sailing, windsurfing, ice sailing, general (Taylor Code 235)`
  String get paSailingGeneral {
    return Intl.message(
      'sailing, boat and board sailing, windsurfing, ice sailing, general (Taylor Code 235)',
      name: 'paSailingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `skiing, water or wakeboarding (Taylor Code 220)`
  String get paSkiingWaterWakeboarding {
    return Intl.message(
      'skiing, water or wakeboarding (Taylor Code 220)',
      name: 'paSkiingWaterWakeboarding',
      desc: '',
      args: [],
    );
  }

  /// `skindiving, scuba diving, general (Taylor Code 310)`
  String get paDivingGeneral {
    return Intl.message(
      'skindiving, scuba diving, general (Taylor Code 310)',
      name: 'paDivingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `snorkeling (Taylor Code 310)`
  String get paSnorkeling {
    return Intl.message(
      'snorkeling (Taylor Code 310)',
      name: 'paSnorkeling',
      desc: '',
      args: [],
    );
  }

  /// `surfing, body or board, general`
  String get paSurfing {
    return Intl.message(
      'surfing, body or board, general',
      name: 'paSurfing',
      desc: '',
      args: [],
    );
  }

  /// `paddle boarding, standing`
  String get paPaddleBoarding {
    return Intl.message(
      'paddle boarding, standing',
      name: 'paPaddleBoarding',
      desc: '',
      args: [],
    );
  }

  /// `swimming, treading water, moderate effort, general`
  String get paSwimmingGeneral {
    return Intl.message(
      'swimming, treading water, moderate effort, general',
      name: 'paSwimmingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics, water calisthenics`
  String get paWateraerobicsCalisthenics {
    return Intl.message(
      'water aerobics, water calisthenics',
      name: 'paWateraerobicsCalisthenics',
      desc: '',
      args: [],
    );
  }

  /// `water polo`
  String get paWaterPolo {
    return Intl.message(
      'water polo',
      name: 'paWaterPolo',
      desc: '',
      args: [],
    );
  }

  /// `water volleyball`
  String get paWaterVolleyball {
    return Intl.message(
      'water volleyball',
      name: 'paWaterVolleyball',
      desc: '',
      args: [],
    );
  }

  /// `skating, ice, general`
  String get paIceSkatingGeneral {
    return Intl.message(
      'skating, ice, general',
      name: 'paIceSkatingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `skiing, general`
  String get paSkiingGeneral {
    return Intl.message(
      'skiing, general',
      name: 'paSkiingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `snow shoveling, by hand, moderate effort`
  String get paSnowShovingModerate {
    return Intl.message(
      'snow shoveling, by hand, moderate effort',
      name: 'paSnowShovingModerate',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
