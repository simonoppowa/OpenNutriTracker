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

  /// `Hello World`
  String get helloWorld {
    return Intl.message(
      'Hello World',
      name: 'helloWorld',
      desc: '',
      args: [],
    );
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

  /// `Units`
  String get settingsUnitsLabel {
    return Intl.message(
      'Units',
      name: 'settingsUnitsLabel',
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

  /// `OpenNutriTracker is not a medical application. All data provider is not validated and should be taken with caution. Please ensure a healthy lifestyle and talk to a professional if you have problems.\n\n\nThe application is still under construction. Errors within the app cannot be ruled out.`
  String get disclaimerText {
    return Intl.message(
      'OpenNutriTracker is not a medical application. All data provider is not validated and should be taken with caution. Please ensure a healthy lifestyle and talk to a professional if you have problems.\n\n\nThe application is still under construction. Errors within the app cannot be ruled out.',
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
