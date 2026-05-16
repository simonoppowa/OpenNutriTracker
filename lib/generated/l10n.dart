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

  /// `[Alpha]`
  String get alphaVersionName {
    return Intl.message(
      '[Alpha]',
      name: 'alphaVersionName',
      desc: '',
      args: [],
    );
  }

  /// `[Beta]`
  String get betaVersionName {
    return Intl.message(
      '[Beta]',
      name: 'betaVersionName',
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

  /// `Warning`
  String get warningLabel {
    return Intl.message(
      'Warning',
      name: 'warningLabel',
      desc: '',
      args: [],
    );
  }

  /// `This food has already been added to this meal today. Add it again?`
  String get duplicateMealDialogContent {
    return Intl.message(
      'This food has already been added to this meal today. Add it again?',
      name: 'duplicateMealDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Create custom meal item?`
  String get createCustomDialogTitle {
    return Intl.message(
      'Create custom meal item?',
      name: 'createCustomDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do you want create a custom meal item?`
  String get createCustomDialogContent {
    return Intl.message(
      'Do you want create a custom meal item?',
      name: 'createCustomDialogContent',
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

  /// `Recipes`
  String get recipesLabel {
    return Intl.message(
      'Recipes',
      name: 'recipesLabel',
      desc: '',
      args: [],
    );
  }

  /// `No recipes yet`
  String get recipesEmptyLabel {
    return Intl.message(
      'No recipes yet',
      name: 'recipesEmptyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Build a meal from multiple ingredients and reuse it like any other food.`
  String get recipesEmptyHint {
    return Intl.message(
      'Build a meal from multiple ingredients and reuse it like any other food.',
      name: 'recipesEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Create Recipe`
  String get createRecipeTitle {
    return Intl.message(
      'Create Recipe',
      name: 'createRecipeTitle',
      desc: '',
      args: [],
    );
  }

  /// `New Custom Food`
  String get newCustomMealLabel {
    return Intl.message(
      'New Custom Food',
      name: 'newCustomMealLabel',
      desc: '',
      args: [],
    );
  }

  /// `Discard changes?`
  String get discardChangesTitle {
    return Intl.message(
      'Discard changes?',
      name: 'discardChangesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your unsaved changes will be lost.`
  String get discardChangesContent {
    return Intl.message(
      'Your unsaved changes will be lost.',
      name: 'discardChangesContent',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get discardChangesConfirmLabel {
    return Intl.message(
      'Discard',
      name: 'discardChangesConfirmLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit Recipe`
  String get editRecipeTitle {
    return Intl.message(
      'Edit Recipe',
      name: 'editRecipeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Recipe name`
  String get recipeNameLabel {
    return Intl.message(
      'Recipe name',
      name: 'recipeNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Description (optional)`
  String get recipeDescriptionLabel {
    return Intl.message(
      'Description (optional)',
      name: 'recipeDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Servings (optional)`
  String get recipeServingsCountLabel {
    return Intl.message(
      'Servings (optional)',
      name: 'recipeServingsCountLabel',
      desc: '',
      args: [],
    );
  }

  /// `Lets you log this recipe by serving instead of grams.`
  String get recipeServingsCountHelper {
    return Intl.message(
      'Lets you log this recipe by serving instead of grams.',
      name: 'recipeServingsCountHelper',
      desc: '',
      args: [],
    );
  }

  /// `Ingredients`
  String get recipeIngredientsLabel {
    return Intl.message(
      'Ingredients',
      name: 'recipeIngredientsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Add Ingredient`
  String get recipeAddIngredientLabel {
    return Intl.message(
      'Add Ingredient',
      name: 'recipeAddIngredientLabel',
      desc: '',
      args: [],
    );
  }

  /// `No ingredients yet`
  String get recipeNoIngredientsLabel {
    return Intl.message(
      'No ingredients yet',
      name: 'recipeNoIngredientsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Total weight (g)`
  String get recipeTotalWeightLabel {
    return Intl.message(
      'Total weight (g)',
      name: 'recipeTotalWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Defaults to sum of ingredients. Liquids approximated as 1 ml ≈ 1 g.`
  String get recipeTotalWeightHelper {
    return Intl.message(
      'Defaults to sum of ingredients. Liquids approximated as 1 ml ≈ 1 g.',
      name: 'recipeTotalWeightHelper',
      desc: '',
      args: [],
    );
  }

  /// `Nutrition (total)`
  String get recipeNutritionPreviewLabel {
    return Intl.message(
      'Nutrition (total)',
      name: 'recipeNutritionPreviewLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per 100 g`
  String get recipeNutritionPer100Label {
    return Intl.message(
      'Per 100 g',
      name: 'recipeNutritionPer100Label',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get recipeIngredientAmountLabel {
    return Intl.message(
      'Amount',
      name: 'recipeIngredientAmountLabel',
      desc: '',
      args: [],
    );
  }

  /// `Unit`
  String get recipeIngredientUnitLabel {
    return Intl.message(
      'Unit',
      name: 'recipeIngredientUnitLabel',
      desc: '',
      args: [],
    );
  }

  /// `Save Recipe`
  String get recipeSaveLabel {
    return Intl.message(
      'Save Recipe',
      name: 'recipeSaveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Could not save recipe.`
  String get recipeSaveErrorLabel {
    return Intl.message(
      'Could not save recipe.',
      name: 'recipeSaveErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Save for next time`
  String get recipeSaveForLaterLabel {
    return Intl.message(
      'Save for next time',
      name: 'recipeSaveForLaterLabel',
      desc: '',
      args: [],
    );
  }

  /// `Turn this on to keep this meal in your saved list for next time. Leave it off for a one-off you won't eat again.`
  String get recipeSaveForLaterDescription {
    return Intl.message(
      'Turn this on to keep this meal in your saved list for next time. Leave it off for a one-off you won\'t eat again.',
      name: 'recipeSaveForLaterDescription',
      desc: '',
      args: [],
    );
  }

  /// `Recipe needs a name`
  String get recipeNameRequiredLabel {
    return Intl.message(
      'Recipe needs a name',
      name: 'recipeNameRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Add at least one ingredient`
  String get recipeNeedsIngredientsLabel {
    return Intl.message(
      'Add at least one ingredient',
      name: 'recipeNeedsIngredientsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Total weight must be greater than zero`
  String get recipeInvalidTotalWeightLabel {
    return Intl.message(
      'Total weight must be greater than zero',
      name: 'recipeInvalidTotalWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Share recipe`
  String get shareRecipeLabel {
    return Intl.message(
      'Share recipe',
      name: 'shareRecipeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate`
  String get duplicateRecipeLabel {
    return Intl.message(
      'Duplicate',
      name: 'duplicateRecipeLabel',
      desc: '',
      args: [],
    );
  }

  /// `(copy)`
  String get duplicateRecipeNameSuffix {
    return Intl.message(
      '(copy)',
      name: 'duplicateRecipeNameSuffix',
      desc: '',
      args: [],
    );
  }

  /// `Tags`
  String get recipeTagsLabel {
    return Intl.message(
      'Tags',
      name: 'recipeTagsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Comma-separated, e.g. "breakfast, vegan"`
  String get recipeTagsHelper {
    return Intl.message(
      'Comma-separated, e.g. "breakfast, vegan"',
      name: 'recipeTagsHelper',
      desc: '',
      args: [],
    );
  }

  /// `Add a photo`
  String get recipeImageLabel {
    return Intl.message(
      'Add a photo',
      name: 'recipeImageLabel',
      desc: '',
      args: [],
    );
  }

  /// `Barcode`
  String get customMealBarcodeLabel {
    return Intl.message(
      'Barcode',
      name: 'customMealBarcodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Choose from gallery`
  String get recipeImagePickFromGallery {
    return Intl.message(
      'Choose from gallery',
      name: 'recipeImagePickFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Scan or type a barcode to recall this meal later`
  String get customMealBarcodeHint {
    return Intl.message(
      'Scan or type a barcode to recall this meal later',
      name: 'customMealBarcodeHint',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get recipeImageTakePhoto {
    return Intl.message(
      'Take photo',
      name: 'recipeImageTakePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Scan barcode`
  String get customMealBarcodeScanButton {
    return Intl.message(
      'Scan barcode',
      name: 'customMealBarcodeScanButton',
      desc: '',
      args: [],
    );
  }

  /// `Remove photo`
  String get recipeImageRemove {
    return Intl.message(
      'Remove photo',
      name: 'recipeImageRemove',
      desc: '',
      args: [],
    );
  }

  /// `Barcode must be 8 to 14 digits`
  String get customMealBarcodeInvalid {
    return Intl.message(
      'Barcode must be 8 to 14 digits',
      name: 'customMealBarcodeInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Replace photo`
  String get recipeImageReplace {
    return Intl.message(
      'Replace photo',
      name: 'recipeImageReplace',
      desc: '',
      args: [],
    );
  }

  /// `Add a photo`
  String get mealImageLabel {
    return Intl.message(
      'Add a photo',
      name: 'mealImageLabel',
      desc: '',
      args: [],
    );
  }

  /// `Choose from gallery`
  String get mealImagePickFromGallery {
    return Intl.message(
      'Choose from gallery',
      name: 'mealImagePickFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get mealImageTakePhoto {
    return Intl.message(
      'Take photo',
      name: 'mealImageTakePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Remove photo`
  String get mealImageRemove {
    return Intl.message(
      'Remove photo',
      name: 'mealImageRemove',
      desc: '',
      args: [],
    );
  }

  /// `Replace photo`
  String get mealImageReplace {
    return Intl.message(
      'Replace photo',
      name: 'mealImageReplace',
      desc: '',
      args: [],
    );
  }

  /// `This 13-digit barcode looks miskeyed: its last digit doesn't match the rest`
  String get barcodeInvalidEan13CheckDigit {
    return Intl.message(
      'This 13-digit barcode looks miskeyed: its last digit doesn\'t match the rest',
      name: 'barcodeInvalidEan13CheckDigit',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get recipesFilterAllLabel {
    return Intl.message(
      'All',
      name: 'recipesFilterAllLabel',
      desc: '',
      args: [],
    );
  }

  /// `{count} selected`
  String selectionCountLabel(Object count) {
    return Intl.message(
      '$count selected',
      name: 'selectionCountLabel',
      desc: '',
      args: [count],
    );
  }

  /// `Import recipes (csv)`
  String get importRecipesCsvAction {
    return Intl.message(
      'Import recipes (csv)',
      name: 'importRecipesCsvAction',
      desc: '',
      args: [],
    );
  }

  /// `Delete {count} recipe(s)?`
  String deleteSelectedRecipesConfirmTitle(Object count) {
    return Intl.message(
      'Delete $count recipe(s)?',
      name: 'deleteSelectedRecipesConfirmTitle',
      desc: '',
      args: [count],
    );
  }

  /// `Import recipe`
  String get importRecipeLabel {
    return Intl.message(
      'Import recipe',
      name: 'importRecipeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Recipe imported`
  String get importRecipeSuccessLabel {
    return Intl.message(
      'Recipe imported',
      name: 'importRecipeSuccessLabel',
      desc: '',
      args: [],
    );
  }

  /// `Could not parse recipe code`
  String get importRecipeErrorLabel {
    return Intl.message(
      'Could not parse recipe code',
      name: 'importRecipeErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Could not load recipes. Try again later.`
  String get recipesLoadErrorLabel {
    return Intl.message(
      'Could not load recipes. Try again later.',
      name: 'recipesLoadErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Import this recipe with {count} ingredient(s)?`
  String importRecipeConfirmContent(Object count) {
    return Intl.message(
      'Import this recipe with $count ingredient(s)?',
      name: 'importRecipeConfirmContent',
      desc: '',
      args: [count],
    );
  }

  /// `Delete recipe?`
  String get recipeDeleteConfirmTitle {
    return Intl.message(
      'Delete recipe?',
      name: 'recipeDeleteConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Past diary entries logged from this recipe will be kept.`
  String get recipeDeleteConfirmContent {
    return Intl.message(
      'Past diary entries logged from this recipe will be kept.',
      name: 'recipeDeleteConfirmContent',
      desc: '',
      args: [],
    );
  }

  /// `Log this Recipe`
  String get recipeLogCtaLabel {
    return Intl.message(
      'Log this Recipe',
      name: 'recipeLogCtaLabel',
      desc: '',
      args: [],
    );
  }

  /// `{count} ingredient(s)`
  String recipeIngredientCountLabel(Object count) {
    return Intl.message(
      '$count ingredient(s)',
      name: 'recipeIngredientCountLabel',
      desc: '',
      args: [count],
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

  /// `Products`
  String get searchProductsPage {
    return Intl.message(
      'Products',
      name: 'searchProductsPage',
      desc: '',
      args: [],
    );
  }

  /// `Food`
  String get searchFoodPage {
    return Intl.message(
      'Food',
      name: 'searchFoodPage',
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

  /// `Please enter a search word`
  String get searchDefaultLabel {
    return Intl.message(
      'Please enter a search word',
      name: 'searchDefaultLabel',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get allItemsLabel {
    return Intl.message(
      'All',
      name: 'allItemsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Recently`
  String get recentlyAddedLabel {
    return Intl.message(
      'Recently',
      name: 'recentlyAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `No meals recently added`
  String get noMealsRecentlyAddedLabel {
    return Intl.message(
      'No meals recently added',
      name: 'noMealsRecentlyAddedLabel',
      desc: '',
      args: [],
    );
  }

  /// `No activity recently added`
  String get noActivityRecentlyAddedLabel {
    return Intl.message(
      'No activity recently added',
      name: 'noActivityRecentlyAddedLabel',
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

  /// `Save`
  String get buttonSaveLabel {
    return Intl.message(
      'Save',
      name: 'buttonSaveLabel',
      desc: '',
      args: [],
    );
  }

  /// `YES`
  String get buttonYesLabel {
    return Intl.message(
      'YES',
      name: 'buttonYesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get buttonResetLabel {
    return Intl.message(
      'Reset',
      name: 'buttonResetLabel',
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

  /// `Your calorie goal:`
  String get onboardingYourGoalLabel {
    return Intl.message(
      'Your calorie goal:',
      name: 'onboardingYourGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Your macronutrient goals:`
  String get onboardingYourMacrosGoalLabel {
    return Intl.message(
      'Your macronutrient goals:',
      name: 'onboardingYourMacrosGoalLabel',
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

  /// `Is there a weight you're working towards? You can leave this blank or change it later in Profile.`
  String get onboardingTargetWeightSubtitle {
    return Intl.message(
      'Is there a weight you\'re working towards? You can leave this blank or change it later in Profile.',
      name: 'onboardingTargetWeightSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Optional`
  String get onboardingTargetWeightHintOptional {
    return Intl.message(
      'Optional',
      name: 'onboardingTargetWeightHintOptional',
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
  String get onboardingWeightExampleHintKg {
    return Intl.message(
      'e.g. 60',
      name: 'onboardingWeightExampleHintKg',
      desc: '',
      args: [],
    );
  }

  /// `e.g. 132`
  String get onboardingWeightExampleHintLbs {
    return Intl.message(
      'e.g. 132',
      name: 'onboardingWeightExampleHintLbs',
      desc: '',
      args: [],
    );
  }

  /// `e.g. 170`
  String get onboardingHeightExampleHintCm {
    return Intl.message(
      'e.g. 170',
      name: 'onboardingHeightExampleHintCm',
      desc: '',
      args: [],
    );
  }

  /// `e.g. 5.8`
  String get onboardingHeightExampleHintFt {
    return Intl.message(
      'e.g. 5.8',
      name: 'onboardingHeightExampleHintFt',
      desc: '',
      args: [],
    );
  }

  /// `How active are you? (without workouts)`
  String get onboardingActivityQuestionSubtitle {
    return Intl.message(
      'How active are you? (without workouts)',
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

  /// `Daily kcal adjustment`
  String get settingsKcalAdjustmentLabel {
    return Intl.message(
      'Daily kcal adjustment',
      name: 'settingsKcalAdjustmentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Macro split`
  String get settingsMacroSplitLabel {
    return Intl.message(
      'Macro split',
      name: 'settingsMacroSplitLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nutrient goals`
  String get settingsNutrientGoalsLabel {
    return Intl.message(
      'Nutrient goals',
      name: 'settingsNutrientGoalsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Personal targets for every nutrient on the daily panel. The diary uses these in place of the default daily references whenever you set one.`
  String get settingsNutrientGoalsHint {
    return Intl.message(
      'Personal targets for every nutrient on the daily panel. The diary uses these in place of the default daily references whenever you set one.',
      name: 'settingsNutrientGoalsHint',
      desc: '',
      args: [],
    );
  }

  /// `Fibre goal`
  String get settingsFibreGoalLabel {
    return Intl.message(
      'Fibre goal',
      name: 'settingsFibreGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily fibre target in grams. Default reference is 30g.`
  String get settingsFibreGoalDescription {
    return Intl.message(
      'Daily fibre target in grams. Default reference is 30g.',
      name: 'settingsFibreGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Saturated fat goal`
  String get settingsSaturatedFatGoalLabel {
    return Intl.message(
      'Saturated fat goal',
      name: 'settingsSaturatedFatGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily saturated fat cap in grams. Default reference is 20g.`
  String get settingsSaturatedFatGoalDescription {
    return Intl.message(
      'Daily saturated fat cap in grams. Default reference is 20g.',
      name: 'settingsSaturatedFatGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Sugars goal`
  String get settingsSugarsGoalLabel {
    return Intl.message(
      'Sugars goal',
      name: 'settingsSugarsGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily sugars cap in grams. Default reference is 50g.`
  String get settingsSugarsGoalDescription {
    return Intl.message(
      'Daily sugars cap in grams. Default reference is 50g.',
      name: 'settingsSugarsGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Sodium goal`
  String get settingsSodiumGoalLabel {
    return Intl.message(
      'Sodium goal',
      name: 'settingsSodiumGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily sodium cap in milligrams. Default reference is 2300mg.`
  String get settingsSodiumGoalDescription {
    return Intl.message(
      'Daily sodium cap in milligrams. Default reference is 2300mg.',
      name: 'settingsSodiumGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Calcium goal`
  String get settingsCalciumGoalLabel {
    return Intl.message(
      'Calcium goal',
      name: 'settingsCalciumGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily calcium target in milligrams. Default reference is 1000mg.`
  String get settingsCalciumGoalDescription {
    return Intl.message(
      'Daily calcium target in milligrams. Default reference is 1000mg.',
      name: 'settingsCalciumGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Iron goal`
  String get settingsIronGoalLabel {
    return Intl.message(
      'Iron goal',
      name: 'settingsIronGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily iron target in milligrams. Default varies by gender (8mg male, 18mg female, 14mg otherwise).`
  String get settingsIronGoalDescription {
    return Intl.message(
      'Daily iron target in milligrams. Default varies by gender (8mg male, 18mg female, 14mg otherwise).',
      name: 'settingsIronGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Potassium goal`
  String get settingsPotassiumGoalLabel {
    return Intl.message(
      'Potassium goal',
      name: 'settingsPotassiumGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily potassium target in milligrams. Default reference is 3500mg.`
  String get settingsPotassiumGoalDescription {
    return Intl.message(
      'Daily potassium target in milligrams. Default reference is 3500mg.',
      name: 'settingsPotassiumGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Magnesium goal`
  String get settingsMagnesiumGoalLabel {
    return Intl.message(
      'Magnesium goal',
      name: 'settingsMagnesiumGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily magnesium target in milligrams. Default varies by gender (400mg male, 310mg female, 355mg otherwise).`
  String get settingsMagnesiumGoalDescription {
    return Intl.message(
      'Daily magnesium target in milligrams. Default varies by gender (400mg male, 310mg female, 355mg otherwise).',
      name: 'settingsMagnesiumGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Vitamin D goal`
  String get settingsVitaminDGoalLabel {
    return Intl.message(
      'Vitamin D goal',
      name: 'settingsVitaminDGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily vitamin D target in micrograms. Default reference is 15µg.`
  String get settingsVitaminDGoalDescription {
    return Intl.message(
      'Daily vitamin D target in micrograms. Default reference is 15µg.',
      name: 'settingsVitaminDGoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Vitamin B12 goal`
  String get settingsVitaminB12GoalLabel {
    return Intl.message(
      'Vitamin B12 goal',
      name: 'settingsVitaminB12GoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily vitamin B12 target in micrograms. Default reference is 2.4µg.`
  String get settingsVitaminB12GoalDescription {
    return Intl.message(
      'Daily vitamin B12 target in micrograms. Default reference is 2.4µg.',
      name: 'settingsVitaminB12GoalDescription',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get settingsThemeLabel {
    return Intl.message(
      'Theme',
      name: 'settingsThemeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get settingsThemeLightLabel {
    return Intl.message(
      'Light',
      name: 'settingsThemeLightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get settingsThemeDarkLabel {
    return Intl.message(
      'Dark',
      name: 'settingsThemeDarkLabel',
      desc: '',
      args: [],
    );
  }

  /// `System default`
  String get settingsThemeSystemDefaultLabel {
    return Intl.message(
      'System default',
      name: 'settingsThemeSystemDefaultLabel',
      desc: '',
      args: [],
    );
  }

  /// `Licenses`
  String get settingsLanguageLabel {
    return Intl.message(
      'Language',
      name: 'settingsLanguageLabel',
      desc: '',
      args: [],
    );
  }

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

  /// `Sources & References`
  String get settingsSourcesLabel {
    return Intl.message(
      'Sources & References',
      name: 'settingsSourcesLabel',
      desc: '',
      args: [],
    );
  }

  /// `View sources`
  String get sourcesIconTooltip {
    return Intl.message(
      'View sources',
      name: 'sourcesIconTooltip',
      desc: '',
      args: [],
    );
  }

  /// `OpenNutriTracker uses well-established, peer-reviewed methodologies for every calculation it shows. The citations below link to the original sources so you can verify any number yourself.`
  String get sourcesScreenIntro {
    return Intl.message(
      'OpenNutriTracker uses well-established, peer-reviewed methodologies for every calculation it shows. The citations below link to the original sources so you can verify any number yourself.',
      name: 'sourcesScreenIntro',
      desc: '',
      args: [],
    );
  }

  /// `Energy needs (TDEE, BMR & activity level)`
  String get sourcesEnergyTitle {
    return Intl.message(
      'Energy needs (TDEE, BMR & activity level)',
      name: 'sourcesEnergyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Daily calorie targets, basal metabolic rate, and physical activity coefficients use the equations from the Institute of Medicine. Source: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Chapter 5 and Table 5-5.`
  String get sourcesEnergyDescription {
    return Intl.message(
      'Daily calorie targets, basal metabolic rate, and physical activity coefficients use the equations from the Institute of Medicine. Source: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Chapter 5 and Table 5-5.',
      name: 'sourcesEnergyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Body Mass Index (BMI)`
  String get sourcesBmiTitle {
    return Intl.message(
      'Body Mass Index (BMI)',
      name: 'sourcesBmiTitle',
      desc: '',
      args: [],
    );
  }

  /// `BMI is computed as weight (kg) divided by height squared (m²). The health categories (underweight, normal, pre-obesity, obesity class I–III) follow the World Health Organization's adult BMI classification.`
  String get sourcesBmiDescription {
    return Intl.message(
      'BMI is computed as weight (kg) divided by height squared (m²). The health categories (underweight, normal, pre-obesity, obesity class I–III) follow the World Health Organization\'s adult BMI classification.',
      name: 'sourcesBmiDescription',
      desc: '',
      args: [],
    );
  }

  /// `Macronutrient distribution`
  String get sourcesMacrosTitle {
    return Intl.message(
      'Macronutrient distribution',
      name: 'sourcesMacrosTitle',
      desc: '',
      args: [],
    );
  }

  /// `The default split of 60% carbohydrates, 25% fat, and 15% protein falls within the population nutrient intake ranges published by the WHO. You can adjust this in Settings → Calculations. Source: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.`
  String get sourcesMacrosDescription {
    return Intl.message(
      'The default split of 60% carbohydrates, 25% fat, and 15% protein falls within the population nutrient intake ranges published by the WHO. You can adjust this in Settings → Calculations. Source: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.',
      name: 'sourcesMacrosDescription',
      desc: '',
      args: [],
    );
  }

  /// `Activity calories (MET values)`
  String get sourcesActivityTitle {
    return Intl.message(
      'Activity calories (MET values)',
      name: 'sourcesActivityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Calories burned during an activity are estimated as MET × body weight (kg) × duration (hours), using values from the Adult Compendium of Physical Activities.`
  String get sourcesActivityDescription {
    return Intl.message(
      'Calories burned during an activity are estimated as MET × body weight (kg) × duration (hours), using values from the Adult Compendium of Physical Activities.',
      name: 'sourcesActivityDescription',
      desc: '',
      args: [],
    );
  }

  /// `Non-binary calorie estimation`
  String get sourcesNonBinaryTitle {
    return Intl.message(
      'Non-binary calorie estimation',
      name: 'sourcesNonBinaryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Energy-expenditure research has historically used binary sex categories, so there is no single validated TDEE formula for non-binary people. OpenNutriTracker therefore lets you choose between an averaged reference, an estrogen-typical reference, or a testosterone-typical reference under Settings → Calculations. If an accurate number genuinely matters for your care, please speak to a clinician familiar with your hormone status.`
  String get sourcesNonBinaryDescription {
    return Intl.message(
      'Energy-expenditure research has historically used binary sex categories, so there is no single validated TDEE formula for non-binary people. OpenNutriTracker therefore lets you choose between an averaged reference, an estrogen-typical reference, or a testosterone-typical reference under Settings → Calculations. If an accurate number genuinely matters for your care, please speak to a clinician familiar with your hormone status.',
      name: 'sourcesNonBinaryDescription',
      desc: '',
      args: [],
    );
  }

  /// `View source`
  String get sourcesOpenSourceLabel {
    return Intl.message(
      'View source',
      name: 'sourcesOpenSourceLabel',
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

  /// `Privacy Settings`
  String get settingsPrivacySettings {
    return Intl.message(
      'Privacy Settings',
      name: 'settingsPrivacySettings',
      desc: '',
      args: [],
    );
  }

  /// `Show Activity Tracking`
  String get settingsShowActivityTracking {
    return Intl.message(
      'Show Activity Tracking',
      name: 'settingsShowActivityTracking',
      desc: '',
      args: [],
    );
  }

  String get settingsShowMealMacros {
    return Intl.message(
      'Show Meal Macros',
      name: 'settingsShowMealMacros',
      desc: '',
      args: [],
    );
  }

  /// `Daily Reminder`
  String get settingsNotificationsLabel {
    return Intl.message(
      'Daily Reminder',
      name: 'settingsNotificationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Reminder time: {time}`
  String settingsNotificationsTimeLabel(String time) {
    return Intl.message(
      'Reminder time: $time',
      name: 'settingsNotificationsTimeLabel',
      desc: '',
      args: [time],
    );
  }

  /// `Notification permission denied.`
  String get notificationsPermissionDeniedSnack {
    return Intl.message(
      'Notification permission denied.',
      name: 'notificationsPermissionDeniedSnack',
      desc: '',
      args: [],
    );
  }

  /// `OpenNutriTracker`
  String get notificationsDailyReminderTitle {
    return Intl.message(
      'OpenNutriTracker',
      name: 'notificationsDailyReminderTitle',
      desc: '',
      args: [],
    );
  }

  /// `Don't forget to log your meals today!`
  String get notificationsDailyReminderBody {
    return Intl.message(
      'Don\'t forget to log your meals today!',
      name: 'notificationsDailyReminderBody',
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

  /// `System`
  String get settingsSystemLabel {
    return Intl.message(
      'System',
      name: 'settingsSystemLabel',
      desc: '',
      args: [],
    );
  }

  /// `Metric (kg, cm, ml)`
  String get settingsMetricLabel {
    return Intl.message(
      'Metric (kg, cm, ml)',
      name: 'settingsMetricLabel',
      desc: '',
      args: [],
    );
  }

  /// `Imperial (lbs, ft, oz)`
  String get settingsImperialLabel {
    return Intl.message(
      'Imperial (lbs, ft, oz)',
      name: 'settingsImperialLabel',
      desc: '',
      args: [],
    );
  }

  /// `Show Micronutrients`
  String get settingsShowMicronutrientsLabel {
    return Intl.message(
      'Show Micronutrients',
      name: 'settingsShowMicronutrientsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per-meal kcal share`
  String get settingsPerMealKcalShareLabel {
    return Intl.message(
      'Per-meal kcal share',
      name: 'settingsPerMealKcalShareLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nutrients`
  String get settingsNutrientsLabel {
    return Intl.message(
      'Nutrients',
      name: 'settingsNutrientsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Split your daily kcal goal across breakfast, lunch, dinner, and snacks. The shares must add up to 100%.`
  String get settingsPerMealKcalShareDescription {
    return Intl.message(
      'Split your daily kcal goal across breakfast, lunch, dinner, and snacks. The shares must add up to 100%.',
      name: 'settingsPerMealKcalShareDescription',
      desc: '',
      args: [],
    );
  }

  /// `Pick which nutrients appear on the diary panel`
  String get settingsNutrientsSubtitle {
    return Intl.message(
      'Pick which nutrients appear on the diary panel',
      name: 'settingsNutrientsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Breakfast`
  String get settingsPerMealKcalShareBreakfast {
    return Intl.message(
      'Breakfast',
      name: 'settingsPerMealKcalShareBreakfast',
      desc: '',
      args: [],
    );
  }

  /// `Choose which nutrients are visible on the daily panel. Hidden ones can be turned back on at any time.`
  String get settingsNutrientsHelp {
    return Intl.message(
      'Choose which nutrients are visible on the daily panel. Hidden ones can be turned back on at any time.',
      name: 'settingsNutrientsHelp',
      desc: '',
      args: [],
    );
  }

  /// `Lunch`
  String get settingsPerMealKcalShareLunch {
    return Intl.message(
      'Lunch',
      name: 'settingsPerMealKcalShareLunch',
      desc: '',
      args: [],
    );
  }

  /// `Dinner`
  String get settingsPerMealKcalShareDinner {
    return Intl.message(
      'Dinner',
      name: 'settingsPerMealKcalShareDinner',
      desc: '',
      args: [],
    );
  }

  /// `Snack`
  String get settingsPerMealKcalShareSnack {
    return Intl.message(
      'Snack',
      name: 'settingsPerMealKcalShareSnack',
      desc: '',
      args: [],
    );
  }

  /// `Quick presets`
  String get mealPatternPresetsLabel {
    return Intl.message(
      'Quick presets',
      name: 'mealPatternPresetsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Standard`
  String get mealPatternStandard {
    return Intl.message(
      'Standard',
      name: 'mealPatternStandard',
      desc: '',
      args: [],
    );
  }

  /// `Mediterranean`
  String get mealPatternMediterranean {
    return Intl.message(
      'Mediterranean',
      name: 'mealPatternMediterranean',
      desc: '',
      args: [],
    );
  }

  /// `Two-meal`
  String get mealPatternTwoMeal {
    return Intl.message(
      'Two-meal',
      name: 'mealPatternTwoMeal',
      desc: '',
      args: [],
    );
  }

  /// `OMAD`
  String get mealPatternOmad {
    return Intl.message(
      'OMAD',
      name: 'mealPatternOmad',
      desc: '',
      args: [],
    );
  }

  /// `Five-small`
  String get mealPatternFiveSmall {
    return Intl.message(
      'Five-small',
      name: 'mealPatternFiveSmall',
      desc: '',
      args: [],
    );
  }

  /// `{consumed} / {target} kcal`
  String diaryMealKcalConsumedOfTarget(String consumed, String target) {
    return Intl.message(
      '$consumed / $target kcal',
      name: 'diaryMealKcalConsumedOfTarget',
      desc: '',
      args: [consumed, target],
    );
  }

  /// `Day starts at`
  String get settingsDayStartLabel {
    return Intl.message(
      'Day starts at',
      name: 'settingsDayStartLabel',
      desc: '',
      args: [],
    );
  }

  /// `Choose the hour at which your day begins. Meals and activities logged before this hour count toward the previous day — useful if you work nights or eat late.`
  String get settingsDayStartDescription {
    return Intl.message(
      'Choose the hour at which your day begins. Meals and activities logged before this hour count toward the previous day — useful if you work nights or eat late.',
      name: 'settingsDayStartDescription',
      desc: '',
      args: [],
    );
  }

  /// `{hour}:00`
  String settingsDayStartHourLabel(int hour) {
    return Intl.message(
      '$hour:00',
      name: 'settingsDayStartHourLabel',
      desc: '',
      args: [hour],
    );
  }

  /// `Hours`
  String get settingsDayStartHoursPickerLabel {
    return Intl.message(
      'Hours',
      name: 'settingsDayStartHoursPickerLabel',
      desc: '',
      args: [],
    );
  }

  /// `Minutes`
  String get settingsDayStartMinutesPickerLabel {
    return Intl.message(
      'Minutes',
      name: 'settingsDayStartMinutesPickerLabel',
      desc: '',
      args: [],
    );
  }

  /// `{hour}:{minute}`
  String settingsDayStartTimeLabel(int hour, String minute) {
    return Intl.message(
      '$hour:$minute',
      name: 'settingsDayStartTimeLabel',
      desc: '',
      args: [hour, minute],
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

  /// `OpenNutriTracker is not a medical application. All data provided is not validated and should be used with caution. Please maintain a healthy lifestyle and consult a professional if you have any problems. Use during illness, pregnancy or lactation is not recommended. For the peer-reviewed sources behind each calculation, tap the info icon on the Home or Profile screen.`
  String get disclaimerText {
    return Intl.message(
      'OpenNutriTracker is not a medical application. All data provided is not validated and should be used with caution. Please maintain a healthy lifestyle and consult a professional if you have any problems. Use during illness, pregnancy or lactation is not recommended. For the peer-reviewed sources behind each calculation, tap the info icon on the Home or Profile screen.',
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

  /// `Send anonymous usage data`
  String get sendAnonymousUserData {
    return Intl.message(
      'Send anonymous usage data',
      name: 'sendAnonymousUserData',
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

  /// `Institute of Medicine Equation (2005)`
  String get calculationsTDEEIOM2006Label {
    return Intl.message(
      'Institute of Medicine Equation (2005)',
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

  /// `Daily Kcal adjustment:`
  String get dailyKcalAdjustmentLabel {
    return Intl.message(
      'Daily Kcal adjustment:',
      name: 'dailyKcalAdjustmentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily kJ adjustment:`
  String get dailyKjAdjustmentLabel {
    return Intl.message(
      'Daily kJ adjustment:',
      name: 'dailyKjAdjustmentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Macronutrient Distribution:`
  String get macroDistributionLabel {
    return Intl.message(
      'Macronutrient Distribution:',
      name: 'macroDistributionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Custom Meals`
  String get settingsCustomMealsLabel {
    return Intl.message(
      'Custom Meals',
      name: 'settingsCustomMealsLabel',
      desc: '',
      args: [],
    );
  }

  /// `No custom meals saved yet.`
  String get customMealsEmptyLabel {
    return Intl.message(
      'No custom meals saved yet.',
      name: 'customMealsEmptyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Delete custom meal?`
  String get customMealsDeleteConfirmTitle {
    return Intl.message(
      'Delete custom meal?',
      name: 'customMealsDeleteConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `All diary entries using this meal will also be removed.`
  String get customMealsDeleteConfirmContent {
    return Intl.message(
      'All diary entries using this meal will also be removed.',
      name: 'customMealsDeleteConfirmContent',
      desc: '',
      args: [],
    );
  }

  /// `Form view`
  String get customMealFormModeLabel {
    return Intl.message(
      'Form view',
      name: 'customMealFormModeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Simple`
  String get customMealFormSimple {
    return Intl.message(
      'Simple',
      name: 'customMealFormSimple',
      desc: '',
      args: [],
    );
  }

  /// `Advanced`
  String get customMealFormAdvanced {
    return Intl.message(
      'Advanced',
      name: 'customMealFormAdvanced',
      desc: '',
      args: [],
    );
  }

  /// `Type the totals for one serving.`
  String get customMealFormSimpleHelp {
    return Intl.message(
      'Type the totals for one serving.',
      name: 'customMealFormSimpleHelp',
      desc: '',
      args: [],
    );
  }

  String customMealFormSimpleFieldHelper(String unit) {
    return Intl.message(
      '$unit in one serving',
      name: 'customMealFormSimpleFieldHelper',
      desc: '',
      args: [unit],
    );
  }

  /// `Set base quantity and per-100 values for precise scaling.`
  String get customMealFormAdvancedHelp {
    return Intl.message(
      'Set base quantity and per-100 values for precise scaling.',
      name: 'customMealFormAdvancedHelp',
      desc: '',
      args: [],
    );
  }

  String get exportImportAppDataLabel {
    return Intl.message(
      'Export / Import App Data',
      name: 'exportImportAppDataLabel',
      desc: '',
      args: [],
    );
  }

  String get importCustomFoodDataLabel {
    return Intl.message(
      'Import Custom Food Data',
      name: 'importCustomFoodDataLabel',
      desc: '',
      args: [],
    );
  }

  String get importCustomFoodDataDescription {
    return Intl.message(
      'Import your own meals from a CSV file. Download a sample to see the expected column shape and required fields.',
      name: 'importCustomFoodDataDescription',
      desc: '',
      args: [],
    );
  }

  String get clearOffCacheLabel {
    return Intl.message(
      'Clear cached items',
      name: 'clearOffCacheLabel',
      desc: '',
      args: [],
    );
  }

  String clearOffCacheSubtitle(int count, String size) {
    return Intl.message(
      '$count item(s) · $size',
      name: 'clearOffCacheSubtitle',
      desc: '',
      args: [count, size],
    );
  }

  String get clearOffCacheConfirmTitle {
    return Intl.message(
      'Clear cached items?',
      name: 'clearOffCacheConfirmTitle',
      desc: '',
      args: [],
    );
  }

  String get clearOffCacheConfirmContent {
    return Intl.message(
      'Removes the locally cached search and scan results from Open Food Facts and FDC. The cache rebuilds automatically as you search and scan products. Your custom meals are not affected.',
      name: 'clearOffCacheConfirmContent',
      desc: '',
      args: [],
    );
  }

  /// `CSV keeps your activity, meal log and tracked days. Recipes and any photos you've attached are JSON-only — switch to JSON if you want them in your backup.`
  String get exportImportCsvRecipesNote {
    return Intl.message(
      'CSV keeps your activity, meal log and tracked days. Recipes and any photos you\'ve attached are JSON-only — switch to JSON if you want them in your backup.',
      name: 'exportImportCsvRecipesNote',
      desc: '',
      args: [],
    );
  }

  /// `You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data.`
  String get exportImportDescription {
    return Intl.message(
      'You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data.',
      name: 'exportImportDescription',
      desc: '',
      args: [],
    );
  }

  /// `Export / Import successful`
  String get exportImportSuccessLabel {
    return Intl.message(
      'Export / Import successful',
      name: 'exportImportSuccessLabel',
      desc: '',
      args: [],
    );
  }

  /// `Export / Import error`
  String get exportImportErrorLabel {
    return Intl.message(
      'Export / Import error',
      name: 'exportImportErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Export`
  String get exportAction {
    return Intl.message(
      'Export',
      name: 'exportAction',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get importAction {
    return Intl.message(
      'Import',
      name: 'importAction',
      desc: '',
      args: [],
    );
  }

  String get downloadSampleCsvAction {
    return Intl.message(
      'Sample meals (csv)',
      name: 'downloadSampleCsvAction',
      desc: '',
      args: [],
    );
  }

  String get downloadSampleJsonAction {
    return Intl.message(
      'Sample meals (json)',
      name: 'downloadSampleJsonAction',
      desc: '',
      args: [],
    );
  }

  String get downloadSampleRecipesCsvAction {
    return Intl.message(
      'Sample recipes (csv)',
      name: 'downloadSampleRecipesCsvAction',
      desc: '',
      args: [],
    );
  }

  String get importMealsCsvAction {
    return Intl.message(
      'Import meals (csv)',
      name: 'importMealsCsvAction',
      desc: '',
      args: [],
    );
  }

  String csvImportSuccessLabel(int count) {
    return Intl.message(
      'Imported $count meal(s).',
      name: 'csvImportSuccessLabel',
      desc: '',
      args: [count],
    );
  }

  String csvImportPartialLabel(int imported, int skipped) {
    return Intl.message(
      'Imported $imported meal(s); $skipped row(s) were skipped due to invalid data.',
      name: 'csvImportPartialLabel',
      desc: '',
      args: [imported, skipped],
    );
  }

  String get csvImportErrorLabel {
    return Intl.message(
      'Could not read CSV file. Check the format and try again.',
      name: 'csvImportErrorLabel',
      desc: '',
      args: [],
    );
  }

  String get csvImportContributeOffPrefix {
    return Intl.message(
      'Have a barcode? Help everyone by contributing the product to Open Food Facts:',
      name: 'csvImportContributeOffPrefix',
      desc: '',
      args: [],
    );
  }

  String get csvImportContributeOffAndroidLink {
    return Intl.message(
      'Android',
      name: 'csvImportContributeOffAndroidLink',
      desc: '',
      args: [],
    );
  }

  String get csvImportContributeOffIosLink {
    return Intl.message(
      'iOS',
      name: 'csvImportContributeOffIosLink',
      desc: '',
      args: [],
    );
  }

  /// `Import meals (json)`
  String get importMealsJsonAction {
    return Intl.message(
      'Import meals (json)',
      name: 'importMealsJsonAction',
      desc: '',
      args: [],
    );
  }

  /// `Sample recipes (json)`
  String get downloadSampleRecipesJsonAction {
    return Intl.message(
      'Sample recipes (json)',
      name: 'downloadSampleRecipesJsonAction',
      desc: '',
      args: [],
    );
  }

  /// `Import recipes (json)`
  String get importRecipesJsonAction {
    return Intl.message(
      'Import recipes (json)',
      name: 'importRecipesJsonAction',
      desc: '',
      args: [],
    );
  }

  /// `Import shared meal`
  String get importMealLabel {
    return Intl.message(
      'Import shared meal',
      name: 'importMealLabel',
      desc: '',
      args: [],
    );
  }

  /// `Import {count} items?`
  String importMealConfirmTitle(int count) {
    return Intl.message(
      'Import $count items?',
      name: 'importMealConfirmTitle',
      desc: '',
      args: [count],
    );
  }

  /// `These items will be added to your {mealType}.`
  String importMealConfirmContent(String mealType) {
    return Intl.message(
      'These items will be added to your $mealType.',
      name: 'importMealConfirmContent',
      desc: '',
      args: [mealType],
    );
  }

  /// `Meal imported`
  String get importMealSuccessLabel {
    return Intl.message(
      'Meal imported',
      name: 'importMealSuccessLabel',
      desc: '',
      args: [],
    );
  }

  /// `Invalid QR code`
  String get importMealErrorLabel {
    return Intl.message(
      'Invalid QR code',
      name: 'importMealErrorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Share workout`
  String get shareActivityLabel {
    return Intl.message(
      'Share workout',
      name: 'shareActivityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Import shared workout`
  String get importActivityLabel {
    return Intl.message(
      'Import shared workout',
      name: 'importActivityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Import {count} activities?`
  String importActivityConfirmTitle(int count) {
    return Intl.message(
      'Import $count activities?',
      name: 'importActivityConfirmTitle',
      desc: '',
      args: [count],
    );
  }

  /// `These activities will be added to today.`
  String get importActivityConfirmContent {
    return Intl.message(
      'These activities will be added to today.',
      name: 'importActivityConfirmContent',
      desc: '',
      args: [],
    );
  }

  /// `Workout imported`
  String get importActivitySuccessLabel {
    return Intl.message(
      'Workout imported',
      name: 'importActivitySuccessLabel',
      desc: '',
      args: [],
    );
  }

  /// `{count} item(s) could not be fetched from OpenFoodFacts.`
  String importOffFetchFailedLabel(int count) {
    return Intl.message(
      '$count item(s) could not be fetched from OpenFoodFacts.',
      name: 'importOffFetchFailedLabel',
      desc: '',
      args: [count],
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

  /// `Edit item`
  String get editItemDialogTitle {
    return Intl.message(
      'Edit item',
      name: 'editItemDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Item updated`
  String get itemUpdatedSnackbar {
    return Intl.message(
      'Item updated',
      name: 'itemUpdatedSnackbar',
      desc: '',
      args: [],
    );
  }

  /// `You are editing a future date`
  String get diaryFutureDateWarning {
    return Intl.message(
      'You are editing a future date',
      name: 'diaryFutureDateWarning',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get diarySortByLabel {
    return Intl.message(
      'Sort by',
      name: 'diarySortByLabel',
      desc: '',
      args: [],
    );
  }

  /// `Only nutrients tracked on the meals you logged are summed here. A meal missing a value contributes nothing to that nutrient — so these totals may underreport.`
  String get diaryNutrientPanelDataDisclaimer {
    return Intl.message(
      'Only nutrients tracked on the meals you logged are summed here. A meal missing a value contributes nothing to that nutrient — so these totals may underreport.',
      name: 'diaryNutrientPanelDataDisclaimer',
      desc: '',
      args: [],
    );
  }

  /// `Time added`
  String get diarySortByTime {
    return Intl.message(
      'Time added',
      name: 'diarySortByTime',
      desc: '',
      args: [],
    );
  }

  /// `Today's nutrients`
  String get diaryNutrientPanelTitle {
    return Intl.message(
      "Today's nutrients",
      name: 'diaryNutrientPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Calories (high to low)`
  String get diarySortByKcal {
    return Intl.message(
      'Calories (high to low)',
      name: 'diarySortByKcal',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get nutrientPanelDayLabel {
    return Intl.message(
      'Day',
      name: 'nutrientPanelDayLabel',
      desc: '',
      args: [],
    );
  }

  /// `Protein (high to low)`
  String get diarySortByProtein {
    return Intl.message(
      'Protein (high to low)',
      name: 'diarySortByProtein',
      desc: '',
      args: [],
    );
  }

  /// `Week`
  String get nutrientPanelWeekLabel {
    return Intl.message(
      'Week',
      name: 'nutrientPanelWeekLabel',
      desc: '',
      args: [],
    );
  }

  /// `Carbs (high to low)`
  String get diarySortByCarbs {
    return Intl.message(
      'Carbs (high to low)',
      name: 'diarySortByCarbs',
      desc: '',
      args: [],
    );
  }

  /// `Fat (high to low)`
  String get diarySortByFat {
    return Intl.message(
      'Fat (high to low)',
      name: 'diarySortByFat',
      desc: '',
      args: [],
    );
  }

  /// `All nutrients hidden — turn some on in Settings → Nutrients.`
  String get nutrientPanelAllHiddenLabel {
    return Intl.message(
      'All nutrients hidden — turn some on in Settings → Nutrients.',
      name: 'nutrientPanelAllHiddenLabel',
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

  /// `Delete Items?`
  String get deleteTimeDialogPluralTitle {
    return Intl.message(
      'Delete Items?',
      name: 'deleteTimeDialogPluralTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do want to delete all items of this meal?`
  String get deleteTimeDialogPluralContent {
    return Intl.message(
      'Do want to delete all items of this meal?',
      name: 'deleteTimeDialogPluralContent',
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

  /// `Share meal`
  String get shareMealLabel {
    return Intl.message(
      'Share meal',
      name: 'shareMealLabel',
      desc: '',
      args: [],
    );
  }

  /// `Copy code`
  String get copyCodeLabel {
    return Intl.message(
      'Copy code',
      name: 'copyCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Share code`
  String get shareCodeLabel {
    return Intl.message(
      'Share code',
      name: 'shareCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Code copied`
  String get codeCopiedLabel {
    return Intl.message(
      'Code copied',
      name: 'codeCopiedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Paste code`
  String get pasteCodeLabel {
    return Intl.message(
      'Paste code',
      name: 'pasteCodeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Paste the shared meal code here`
  String get pasteCodeHint {
    return Intl.message(
      'Paste the shared meal code here',
      name: 'pasteCodeHint',
      desc: '',
      args: [],
    );
  }

  /// `Which meal type do you want to copy to?`
  String get copyDialogTitle {
    return Intl.message(
      'Which meal type do you want to copy to?',
      name: 'copyDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `What do you want to do?`
  String get copyOrDeleteTimeDialogTitle {
    return Intl.message(
      'What do you want to do?',
      name: 'copyOrDeleteTimeDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `With "Copy to today" you can copy the meal to today. With "Delete" you can delete the meal.`
  String get copyOrDeleteTimeDialogContent {
    return Intl.message(
      'With "Copy to today" you can copy the meal to today. With "Delete" you can delete the meal.',
      name: 'copyOrDeleteTimeDialogContent',
      desc: '',
      args: [],
    );
  }

  /// `Copy to today`
  String get dialogCopyLabel {
    return Intl.message(
      'Copy to today',
      name: 'dialogCopyLabel',
      desc: '',
      args: [],
    );
  }

  /// `DELETE`
  String get dialogDeleteLabel {
    return Intl.message(
      'DELETE',
      name: 'dialogDeleteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Delete all`
  String get deleteAllLabel {
    return Intl.message(
      'Delete all',
      name: 'deleteAllLabel',
      desc: '',
      args: [],
    );
  }

  /// `Delete all my data`
  String get settingsDeleteAllDataLabel {
    return Intl.message(
      'Delete all my data',
      name: 'settingsDeleteAllDataLabel',
      desc: '',
      args: [],
    );
  }

  /// `Profile, meals, activities and weight history`
  String get settingsDeleteAllDataSubtitle {
    return Intl.message(
      'Profile, meals, activities and weight history',
      name: 'settingsDeleteAllDataSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Delete all your data?`
  String get settingsDeleteAllDataConfirmTitle {
    return Intl.message(
      'Delete all your data?',
      name: 'settingsDeleteAllDataConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `This permanently removes your profile, meals, activities, weight history and any custom recipes from this device. The Open Food Facts and USDA Food Data Central catalogues are not affected. This cannot be undone.`
  String get settingsDeleteAllDataConfirmContent {
    return Intl.message(
      'This permanently removes your profile, meals, activities, weight history and any custom recipes from this device. The Open Food Facts and USDA Food Data Central catalogues are not affected. This cannot be undone.',
      name: 'settingsDeleteAllDataConfirmContent',
      desc: '',
      args: [],
    );
  }

  /// `Delete everything`
  String get settingsDeleteAllDataConfirmAction {
    return Intl.message(
      'Delete everything',
      name: 'settingsDeleteAllDataConfirmAction',
      desc: '',
      args: [],
    );
  }

  /// `This daily target is on the low side`
  String get lowKcalWarningTitle {
    return Intl.message(
      'This daily target is on the low side',
      name: 'lowKcalWarningTitle',
      desc: '',
      args: [],
    );
  }

  /// `Most adults shouldn't eat fewer than {threshold} kcal a day for any length of time without medical guidance. Please consider speaking with a healthcare professional before sticking with a target this low.`
  String lowKcalWarningBody(int threshold) {
    return Intl.message(
      'Most adults shouldn\'t eat fewer than $threshold kcal a day for any length of time without medical guidance. Please consider speaking with a healthcare professional before sticking with a target this low.',
      name: 'lowKcalWarningBody',
      desc: '',
      args: [threshold],
    );
  }

  /// `View disclaimer`
  String get lowKcalWarningViewDisclaimer {
    return Intl.message(
      'View disclaimer',
      name: 'lowKcalWarningViewDisclaimer',
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

  /// `kcal too much`
  String get kcalTooMuchLabel {
    return Intl.message(
      'kcal too much',
      name: 'kcalTooMuchLabel',
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

  /// `kJ`
  String get kjLabel {
    return Intl.message(
      'kJ',
      name: 'kjLabel',
      desc: '',
      args: [],
    );
  }

  /// `left`
  String get energyLeftLabel {
    return Intl.message(
      'left',
      name: 'energyLeftLabel',
      desc: '',
      args: [],
    );
  }

  /// `too much`
  String get energyTooMuchLabel {
    return Intl.message(
      'too much',
      name: 'energyTooMuchLabel',
      desc: '',
      args: [],
    );
  }

  /// `Energy unit`
  String get settingsEnergyUnitLabel {
    return Intl.message(
      'Energy unit',
      name: 'settingsEnergyUnitLabel',
      desc: '',
      args: [],
    );
  }

  /// `Kilocalories (kcal)`
  String get energyUnitKcalLabel {
    return Intl.message(
      'Kilocalories (kcal)',
      name: 'energyUnitKcalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Kilojoules (kJ)`
  String get energyUnitKjLabel {
    return Intl.message(
      'Kilojoules (kJ)',
      name: 'energyUnitKjLabel',
      desc: '',
      args: [],
    );
  }

  /// `kJ per day`
  String get onboardingKjPerDayLabel {
    return Intl.message(
      'kJ per day',
      name: 'onboardingKjPerDayLabel',
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

  /// `c`
  String get carbsLabelShort {
    return Intl.message(
      'c',
      name: 'carbsLabelShort',
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

  /// `f`
  String get fatLabelShort {
    return Intl.message(
      'f',
      name: 'fatLabelShort',
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

  /// `p`
  String get proteinLabelShort {
    return Intl.message(
      'p',
      name: 'proteinLabelShort',
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

  /// `monounsaturated fat`
  String get monounsaturatedFatLabel {
    return Intl.message(
      'monounsaturated fat',
      name: 'monounsaturatedFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `polyunsaturated fat`
  String get polyunsaturatedFatLabel {
    return Intl.message(
      'polyunsaturated fat',
      name: 'polyunsaturatedFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `trans fat`
  String get transFatLabel {
    return Intl.message(
      'trans fat',
      name: 'transFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `cholesterol`
  String get cholesterolLabel {
    return Intl.message(
      'cholesterol',
      name: 'cholesterolLabel',
      desc: '',
      args: [],
    );
  }

  /// `sodium`
  String get sodiumLabel {
    return Intl.message(
      'sodium',
      name: 'sodiumLabel',
      desc: '',
      args: [],
    );
  }

  /// `potassium`
  String get potassiumLabel {
    return Intl.message(
      'potassium',
      name: 'potassiumLabel',
      desc: '',
      args: [],
    );
  }

  /// `magnesium`
  String get magnesiumLabel {
    return Intl.message(
      'magnesium',
      name: 'magnesiumLabel',
      desc: '',
      args: [],
    );
  }

  /// `calcium`
  String get calciumLabel {
    return Intl.message(
      'calcium',
      name: 'calciumLabel',
      desc: '',
      args: [],
    );
  }

  /// `iron`
  String get ironLabel {
    return Intl.message(
      'iron',
      name: 'ironLabel',
      desc: '',
      args: [],
    );
  }

  /// `zinc`
  String get zincLabel {
    return Intl.message(
      'zinc',
      name: 'zincLabel',
      desc: '',
      args: [],
    );
  }

  /// `phosphorus`
  String get phosphorusLabel {
    return Intl.message(
      'phosphorus',
      name: 'phosphorusLabel',
      desc: '',
      args: [],
    );
  }

  /// `vitamin A`
  String get vitaminALabel {
    return Intl.message(
      'vitamin A',
      name: 'vitaminALabel',
      desc: '',
      args: [],
    );
  }

  /// `vitamin C`
  String get vitaminCLabel {
    return Intl.message(
      'vitamin C',
      name: 'vitaminCLabel',
      desc: '',
      args: [],
    );
  }

  /// `vitamin D`
  String get vitaminDLabel {
    return Intl.message(
      'vitamin D',
      name: 'vitaminDLabel',
      desc: '',
      args: [],
    );
  }

  /// `vitamin B6`
  String get vitaminB6Label {
    return Intl.message(
      'vitamin B6',
      name: 'vitaminB6Label',
      desc: '',
      args: [],
    );
  }

  /// `vitamin B12`
  String get vitaminB12Label {
    return Intl.message(
      'vitamin B12',
      name: 'vitaminB12Label',
      desc: '',
      args: [],
    );
  }

  /// `niacin (B3)`
  String get niacinLabel {
    return Intl.message(
      'niacin (B3)',
      name: 'niacinLabel',
      desc: '',
      args: [],
    );
  }

  /// `Micronutrients`
  String get micronutrientsLabel {
    return Intl.message(
      'Micronutrients',
      name: 'micronutrientsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per 100g/ml`
  String get per100gmlLabel {
    return Intl.message(
      'Per 100g/ml',
      name: 'per100gmlLabel',
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

  /// `The data provided to you by this app are retrieved from the Open Food Facts database. No guarantees can be made for the accuracy, completeness, or reliability of the information provided. The data are provided "as is" and the originating source for the data (Open Food Facts) is not liable for any damages arising out of the use of the data.`
  String get offDisclaimer {
    return Intl.message(
      'The data provided to you by this app are retrieved from the Open Food Facts database. No guarantees can be made for the accuracy, completeness, or reliability of the information provided. The data are provided "as is" and the originating source for the data (Open Food Facts) is not liable for any damages arising out of the use of the data.',
      name: 'offDisclaimer',
      desc: '',
      args: [],
    );
  }

  /// `More Information at\nFoodData Central`
  String get additionalInfoLabelFDC {
    return Intl.message(
      'More Information at\nFoodData Central',
      name: 'additionalInfoLabelFDC',
      desc: '',
      args: [],
    );
  }

  /// `Unknown Meal Item`
  String get additionalInfoLabelUnknown {
    return Intl.message(
      'Unknown Meal Item',
      name: 'additionalInfoLabelUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Custom Meal Item`
  String get additionalInfoLabelCustom {
    return Intl.message(
      'Custom Meal Item',
      name: 'additionalInfoLabelCustom',
      desc: '',
      args: [],
    );
  }

  /// `Custom Recipe`
  String get additionalInfoLabelRecipe {
    return Intl.message(
      'Custom Recipe',
      name: 'additionalInfoLabelRecipe',
      desc: '',
      args: [],
    );
  }

  /// `Information provided\n by the \n'2024 Compendium\n of Physical Activities'`
  String get additionalInfoLabelCompendium2011 {
    return Intl.message(
      'Information provided\n by the \n\'2024 Compendium\n of Physical Activities\'',
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

  /// `Base quantity (g/ml)`
  String get baseQuantityLabel {
    return Intl.message(
      'Base quantity (g/ml)',
      name: 'baseQuantityLabel',
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

  /// `Type code manually`
  String get scannerManualEntryButton {
    return Intl.message(
      'Type code manually',
      name: 'scannerManualEntryButton',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get scannerManualEntryCancel {
    return Intl.message(
      'Cancel',
      name: 'scannerManualEntryCancel',
      desc: '',
      args: [],
    );
  }

  /// `Enter barcode`
  String get scannerManualEntryDialogTitle {
    return Intl.message(
      'Enter barcode',
      name: 'scannerManualEntryDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `8 to 14 digits`
  String get scannerManualEntryFieldHint {
    return Intl.message(
      '8 to 14 digits',
      name: 'scannerManualEntryFieldHint',
      desc: '',
      args: [],
    );
  }

  /// `That barcode doesn't look valid. Please check the digits and try again.`
  String get scannerManualEntryInvalid {
    return Intl.message(
      'That barcode doesn\'t look valid. Please check the digits and try again.',
      name: 'scannerManualEntryInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Look up`
  String get scannerManualEntrySubmit {
    return Intl.message(
      'Look up',
      name: 'scannerManualEntrySubmit',
      desc: '',
      args: [],
    );
  }

  /// `g`
  String get gramUnit {
    return Intl.message(
      'g',
      name: 'gramUnit',
      desc: '',
      args: [],
    );
  }

  /// `ml`
  String get milliliterUnit {
    return Intl.message(
      'ml',
      name: 'milliliterUnit',
      desc: '',
      args: [],
    );
  }

  /// `g/ml`
  String get gramMilliliterUnit {
    return Intl.message(
      'g/ml',
      name: 'gramMilliliterUnit',
      desc: '',
      args: [],
    );
  }

  /// `oz`
  String get ozUnit {
    return Intl.message(
      'oz',
      name: 'ozUnit',
      desc: '',
      args: [],
    );
  }

  /// `fl.oz`
  String get flOzUnit {
    return Intl.message(
      'fl.oz',
      name: 'flOzUnit',
      desc: '',
      args: [],
    );
  }

  /// `N/A`
  String get notAvailableLabel {
    return Intl.message(
      'N/A',
      name: 'notAvailableLabel',
      desc: '',
      args: [],
    );
  }

  /// `Product missing required kcal or macronutrients information`
  String get missingProductInfo {
    return Intl.message(
      'Product missing required kcal or macronutrients information',
      name: 'missingProductInfo',
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

  /// `Edit meal`
  String get editMealLabel {
    return Intl.message(
      'Edit meal',
      name: 'editMealLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal name`
  String get mealNameLabel {
    return Intl.message(
      'Meal name',
      name: 'mealNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal name must contain at least one letter`
  String get mealNameValidationError {
    return Intl.message(
      'Meal name must contain at least one letter',
      name: 'mealNameValidationError',
      desc: '',
      args: [],
    );
  }

  /// `Numbers don't quite line up`
  String get inconsistentNutritionWarningTitle {
    return Intl.message(
      'Numbers don\'t quite line up',
      name: 'inconsistentNutritionWarningTitle',
      desc: '',
      args: [],
    );
  }

  /// `These values don't quite line up — the calories you've entered don't match the energy in the carbs, fat and protein below. Save anyway, or take a second look?`
  String get inconsistentNutritionWarningBody {
    return Intl.message(
      'These values don\'t quite line up — the calories you\'ve entered don\'t match the energy in the carbs, fat and protein below. Save anyway, or take a second look?',
      name: 'inconsistentNutritionWarningBody',
      desc: '',
      args: [],
    );
  }

  /// `Save anyway`
  String get inconsistentNutritionWarningSaveAnyway {
    return Intl.message(
      'Save anyway',
      name: 'inconsistentNutritionWarningSaveAnyway',
      desc: '',
      args: [],
    );
  }

  /// `Take another look`
  String get inconsistentNutritionWarningEdit {
    return Intl.message(
      'Take another look',
      name: 'inconsistentNutritionWarningEdit',
      desc: '',
      args: [],
    );
  }

  /// `Brands`
  String get mealBrandsLabel {
    return Intl.message(
      'Brands',
      name: 'mealBrandsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal size (g/ml)`
  String get mealSizeLabel {
    return Intl.message(
      'Meal size (g/ml)',
      name: 'mealSizeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Meal size (oz/fl oz)`
  String get mealSizeLabelImperial {
    return Intl.message(
      'Meal size (oz/fl oz)',
      name: 'mealSizeLabelImperial',
      desc: '',
      args: [],
    );
  }

  /// `Serving`
  String get servingLabel {
    return Intl.message(
      'Serving',
      name: 'servingLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per Serving`
  String get perServingLabel {
    return Intl.message(
      'Per Serving',
      name: 'perServingLabel',
      desc: '',
      args: [],
    );
  }

  /// `Serving size (g/ml)`
  String get servingSizeLabelMetric {
    return Intl.message(
      'Serving size (g/ml)',
      name: 'servingSizeLabelMetric',
      desc: '',
      args: [],
    );
  }

  /// `Serving size (oz/fl oz)`
  String get servingSizeLabelImperial {
    return Intl.message(
      'Serving size (oz/fl oz)',
      name: 'servingSizeLabelImperial',
      desc: '',
      args: [],
    );
  }

  /// `Meal unit`
  String get mealUnitLabel {
    return Intl.message(
      'Meal unit',
      name: 'mealUnitLabel',
      desc: '',
      args: [],
    );
  }

  /// `kcal per`
  String get mealKcalLabel {
    return Intl.message(
      'kcal',
      name: 'mealKcalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Energy`
  String get mealEnergyLabel {
    return Intl.message(
      'Energy',
      name: 'mealEnergyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Carbohydrates (g)`
  String get mealCarbsLabel {
    return Intl.message(
      'Carbohydrates (g)',
      name: 'mealCarbsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Fat (g)`
  String get mealFatLabel {
    return Intl.message(
      'Fat (g)',
      name: 'mealFatLabel',
      desc: '',
      args: [],
    );
  }

  /// `Protein (g)`
  String get mealProteinLabel {
    return Intl.message(
      'Protein (g)',
      name: 'mealProteinLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per {qty} {unit}`
  String mealNutrientsPerQtyLabel(String qty, String unit) {
    return Intl.message(
      'Per $qty $unit',
      name: 'mealNutrientsPerQtyLabel',
      desc: '',
      args: [qty, unit],
    );
  }

  /// `Total amount`
  String get mealNutrientsTotalLabel {
    return Intl.message(
      'Total amount',
      name: 'mealNutrientsTotalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Error while saving meal. Did you input the correct meal information?`
  String get errorMealSave {
    return Intl.message(
      'Error while saving meal. Did you input the correct meal information?',
      name: 'errorMealSave',
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

  /// `I have read and accept the privacy policy.`
  String get readLabel {
    return Intl.message(
      'I have read and accept the privacy policy.',
      name: 'readLabel',
      desc: '',
      args: [],
    );
  }

  /// `Privacy policy`
  String get privacyPolicyLabel {
    return Intl.message(
      'Privacy policy',
      name: 'privacyPolicyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Support development by providing anonymous usage data`
  String get dataCollectionLabel {
    return Intl.message(
      'Support development by providing anonymous usage data',
      name: 'dataCollectionLabel',
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

  /// `Weekly rate`
  String get weeklyWeightGoalLabel {
    return Intl.message(
      'Weekly rate',
      name: 'weeklyWeightGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Not set`
  String get weeklyWeightGoalNoneLabel {
    return Intl.message(
      'Not set',
      name: 'weeklyWeightGoalNoneLabel',
      desc: '',
      args: [],
    );
  }

  /// `{rate} kg/week`
  String weeklyWeightGoalKgPerWeek(String rate) {
    return Intl.message(
      '$rate kg/week',
      name: 'weeklyWeightGoalKgPerWeek',
      desc: '',
      args: [rate],
    );
  }

  /// `{rate} lbs/week`
  String weeklyWeightGoalLbsPerWeek(String rate) {
    return Intl.message(
      '$rate lbs/week',
      name: 'weeklyWeightGoalLbsPerWeek',
      desc: '',
      args: [rate],
    );
  }

  /// `Weekly weight rate`
  String get chooseWeeklyWeightGoalLabel {
    return Intl.message(
      'Weekly weight rate',
      name: 'chooseWeeklyWeightGoalLabel',
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

  /// `ft`
  String get ftLabel {
    return Intl.message(
      'ft',
      name: 'ftLabel',
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

  /// `lbs`
  String get lbsLabel {
    return Intl.message(
      'lbs',
      name: 'lbsLabel',
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

  /// `male`
  String get genderMaleLabel {
    return Intl.message(
      'male',
      name: 'genderMaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `female`
  String get genderFemaleLabel {
    return Intl.message(
      'female',
      name: 'genderFemaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `non-binary`
  String get genderNonBinaryLabel {
    return Intl.message(
      'non-binary',
      name: 'genderNonBinaryLabel',
      desc: '',
      args: [],
    );
  }

  /// `Calorie reference`
  String get caloriesProfileInfoTitle {
    return Intl.message(
      'Calorie reference',
      name: 'caloriesProfileInfoTitle',
      desc: '',
      args: [],
    );
  }

  /// `There isn't a published non-binary calorie baseline ...`
  String get caloriesProfileInfoBody {
    return Intl.message(
      "There isn't a published non-binary calorie baseline — the reference equations are built around male and female samples. We use an average of the two by default, a neutral starting point that doesn't ask you to disclose more about your body. The kcal slider in Settings is always available to fine-tune; this is a starting point, not a precise estimate.",
      name: 'caloriesProfileInfoBody',
      desc: '',
      args: [],
    );
  }

  /// `Averaged reference (default)`
  String get caloriesProfileAveragedLabel {
    return Intl.message(
      'Averaged reference (default)',
      name: 'caloriesProfileAveragedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Estrogen-typical reference`
  String get caloriesProfileEstrogenTypicalLabel {
    return Intl.message(
      'Estrogen-typical reference',
      name: 'caloriesProfileEstrogenTypicalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Testosterone-typical reference`
  String get caloriesProfileTestosteroneTypicalLabel {
    return Intl.message(
      'Testosterone-typical reference',
      name: 'caloriesProfileTestosteroneTypicalLabel',
      desc: '',
      args: [],
    );
  }

  /// `There's no published non-binary calorie baseline ...`
  String get onboardingNonBinaryDisclaimer {
    return Intl.message(
      "There's no published non-binary calorie baseline, so by default we use an average of the male and female formulas — a starting point, not a precise estimate. You can fine-tune anytime in Settings → Calculations.",
      name: 'onboardingNonBinaryDisclaimer',
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

  /// `Error while fetching product data`
  String get errorFetchingProductData {
    return Intl.message(
      'Error while fetching product data',
      name: 'errorFetchingProductData',
      desc: '',
      args: [],
    );
  }

  /// `Product not found`
  String get errorProductNotFound {
    return Intl.message(
      'Product not found',
      name: 'errorProductNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Error while loading activities`
  String get errorLoadingActivities {
    return Intl.message(
      'Error while loading activities',
      name: 'errorLoadingActivities',
      desc: '',
      args: [],
    );
  }

  /// `No results found`
  String get noResultsFound {
    return Intl.message(
      'No results found',
      name: 'noResultsFound',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retryLabel {
    return Intl.message(
      'Retry',
      name: 'retryLabel',
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

  /// `general`
  String get paGeneralDesc {
    return Intl.message(
      'general',
      name: 'paGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bicycling`
  String get paBicyclingGeneral {
    return Intl.message(
      'bicycling',
      name: 'paBicyclingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBicyclingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBicyclingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, mountain`
  String get paBicyclingMountainGeneral {
    return Intl.message(
      'bicycling, mountain',
      name: 'paBicyclingMountainGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBicyclingMountainGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBicyclingMountainGeneralDesc',
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

  /// `general`
  String get paUnicyclingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paUnicyclingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bicycling, stationary`
  String get paBicyclingStationaryGeneral {
    return Intl.message(
      'bicycling, stationary',
      name: 'paBicyclingStationaryGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBicyclingStationaryGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBicyclingStationaryGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `calisthenics`
  String get paCalisthenicsGeneral {
    return Intl.message(
      'calisthenics',
      name: 'paCalisthenicsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `light or moderate effort, general (e.g., back exercises)`
  String get paCalisthenicsGeneralDesc {
    return Intl.message(
      'light or moderate effort, general (e.g., back exercises)',
      name: 'paCalisthenicsGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `resistance training`
  String get paResistanceTraining {
    return Intl.message(
      'resistance training',
      name: 'paResistanceTraining',
      desc: '',
      args: [],
    );
  }

  /// `weight lifting, free weight, nautilus or universal`
  String get paResistanceTrainingDesc {
    return Intl.message(
      'weight lifting, free weight, nautilus or universal',
      name: 'paResistanceTrainingDesc',
      desc: '',
      args: [],
    );
  }

  /// `resistance training (vigorous)`
  String get paResistanceTrainingVigorous {
    return Intl.message(
      'resistance training (vigorous)',
      name: 'paResistanceTrainingVigorous',
      desc: '',
      args: [],
    );
  }

  /// `vigorous effort, powerlifting or bodybuilding`
  String get paResistanceTrainingVigorousDesc {
    return Intl.message(
      'vigorous effort, powerlifting or bodybuilding',
      name: 'paResistanceTrainingVigorousDesc',
      desc: '',
      args: [],
    );
  }

  /// `high intensity interval exercise`
  String get paHighIntensityIntervalExercise {
    return Intl.message(
      'high intensity interval exercise',
      name: 'paHighIntensityIntervalExercise',
      desc: '',
      args: [],
    );
  }

  /// `moderate effort`
  String get paHighIntensityIntervalExerciseDesc {
    return Intl.message(
      'moderate effort',
      name: 'paHighIntensityIntervalExerciseDesc',
      desc: '',
      args: [],
    );
  }

  /// `high intensity interval exercise`
  String get paHighIntensityIntervalExerciseVigorous {
    return Intl.message(
      'high intensity interval exercise',
      name: 'paHighIntensityIntervalExerciseVigorous',
      desc: '',
      args: [],
    );
  }

  /// `burpees, mountain climbers, squat jumps, Tabata, vigorous effort`
  String get paHighIntensityIntervalExerciseVigorousDesc {
    return Intl.message(
      'burpees, mountain climbers, squat jumps, Tabata, vigorous effort',
      name: 'paHighIntensityIntervalExerciseVigorousDesc',
      desc: '',
      args: [],
    );
  }

  /// `pilates`
  String get paPilates {
    return Intl.message(
      'pilates',
      name: 'paPilates',
      desc: '',
      args: [],
    );
  }

  /// `stretching`
  String get paStretching {
    return Intl.message(
      'stretching',
      name: 'paStretching',
      desc: '',
      args: [],
    );
  }

  /// `mild, general`
  String get paStretchingDesc {
    return Intl.message(
      'mild, general',
      name: 'paStretchingDesc',
      desc: '',
      args: [],
    );
  }

  /// `rope skipping`
  String get paRopeSkippingGeneral {
    return Intl.message(
      'rope skipping',
      name: 'paRopeSkippingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paRopeSkippingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paRopeSkippingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `water exercise`
  String get paWaterAerobics {
    return Intl.message(
      'water exercise',
      name: 'paWaterAerobics',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics, water calisthenics`
  String get paWaterAerobicsDesc {
    return Intl.message(
      'water aerobics, water calisthenics',
      name: 'paWaterAerobicsDesc',
      desc: '',
      args: [],
    );
  }

  /// `aerobic`
  String get paDancingAerobicGeneral {
    return Intl.message(
      'aerobic',
      name: 'paDancingAerobicGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paDancingAerobicGeneralDesc {
    return Intl.message(
      'general',
      name: 'paDancingAerobicGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `general dancing`
  String get paDancingGeneral {
    return Intl.message(
      'general dancing',
      name: 'paDancingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country`
  String get paDancingGeneralDesc {
    return Intl.message(
      'e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country',
      name: 'paDancingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `jogging`
  String get paJoggingGeneral {
    return Intl.message(
      'jogging',
      name: 'paJoggingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paJoggingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paJoggingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `running`
  String get paRunningGeneral {
    return Intl.message(
      'running',
      name: 'paRunningGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paRunningGeneralDesc {
    return Intl.message(
      'general',
      name: 'paRunningGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `running on treadmill`
  String get paTreadmillRunning {
    return Intl.message(
      'running on treadmill',
      name: 'paTreadmillRunning',
      desc: '',
      args: [],
    );
  }

  /// `on treadmill, general`
  String get paTreadmillRunningDesc {
    return Intl.message(
      'on treadmill, general',
      name: 'paTreadmillRunningDesc',
      desc: '',
      args: [],
    );
  }

  /// `archery`
  String get paArcheryGeneral {
    return Intl.message(
      'archery',
      name: 'paArcheryGeneral',
      desc: '',
      args: [],
    );
  }

  /// `non-hunting`
  String get paArcheryGeneralDesc {
    return Intl.message(
      'non-hunting',
      name: 'paArcheryGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `badminton`
  String get paBadmintonGeneral {
    return Intl.message(
      'badminton',
      name: 'paBadmintonGeneral',
      desc: '',
      args: [],
    );
  }

  /// `social singles and doubles, general`
  String get paBadmintonGeneralDesc {
    return Intl.message(
      'social singles and doubles, general',
      name: 'paBadmintonGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `basketball`
  String get paBasketballGeneral {
    return Intl.message(
      'basketball',
      name: 'paBasketballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBasketballGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBasketballGeneralDesc',
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

  /// `general`
  String get paBilliardsGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBilliardsGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `bowling`
  String get paBowlingGeneral {
    return Intl.message(
      'bowling',
      name: 'paBowlingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paBowlingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBowlingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `boxing`
  String get paBoxingBag {
    return Intl.message(
      'boxing',
      name: 'paBoxingBag',
      desc: '',
      args: [],
    );
  }

  /// `punching bag`
  String get paBoxingBagDesc {
    return Intl.message(
      'punching bag',
      name: 'paBoxingBagDesc',
      desc: '',
      args: [],
    );
  }

  /// `boxing`
  String get paBoxingGeneral {
    return Intl.message(
      'boxing',
      name: 'paBoxingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `in ring, general`
  String get paBoxingGeneralDesc {
    return Intl.message(
      'in ring, general',
      name: 'paBoxingGeneralDesc',
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

  /// `general`
  String get paBroomballDesc {
    return Intl.message(
      'general',
      name: 'paBroomballDesc',
      desc: '',
      args: [],
    );
  }

  /// `children's games`
  String get paChildrenGame {
    return Intl.message(
      "children's games",
      name: 'paChildrenGame',
      desc: '',
      args: [],
    );
  }

  /// `(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort`
  String get paChildrenGameDesc {
    return Intl.message(
      '(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort',
      name: 'paChildrenGameDesc',
      desc: '',
      args: [],
    );
  }

  /// `cheerleading`
  String get paCheerleading {
    return Intl.message(
      'cheerleading',
      name: 'paCheerleading',
      desc: '',
      args: [],
    );
  }

  /// `gymnastic moves, competitive`
  String get paCheerleadingDesc {
    return Intl.message(
      'gymnastic moves, competitive',
      name: 'paCheerleadingDesc',
      desc: '',
      args: [],
    );
  }

  /// `cricket`
  String get paCricket {
    return Intl.message(
      'cricket',
      name: 'paCricket',
      desc: '',
      args: [],
    );
  }

  /// `batting, bowling, fielding`
  String get paCricketDesc {
    return Intl.message(
      'batting, bowling, fielding',
      name: 'paCricketDesc',
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

  /// `general`
  String get paCroquetDesc {
    return Intl.message(
      'general',
      name: 'paCroquetDesc',
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

  /// `general`
  String get paCurlingDesc {
    return Intl.message(
      'general',
      name: 'paCurlingDesc',
      desc: '',
      args: [],
    );
  }

  /// `darts`
  String get paDartsWall {
    return Intl.message(
      'darts',
      name: 'paDartsWall',
      desc: '',
      args: [],
    );
  }

  /// `wall or lawn`
  String get paDartsWallDesc {
    return Intl.message(
      'wall or lawn',
      name: 'paDartsWallDesc',
      desc: '',
      args: [],
    );
  }

  /// `auto racing`
  String get paAutoRacing {
    return Intl.message(
      'auto racing',
      name: 'paAutoRacing',
      desc: '',
      args: [],
    );
  }

  /// `open wheel`
  String get paAutoRacingDesc {
    return Intl.message(
      'open wheel',
      name: 'paAutoRacingDesc',
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

  /// `general`
  String get paFencingDesc {
    return Intl.message(
      'general',
      name: 'paFencingDesc',
      desc: '',
      args: [],
    );
  }

  /// `football`
  String get paAmericanFootballGeneral {
    return Intl.message(
      'football',
      name: 'paAmericanFootballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `touch, flag, general`
  String get paAmericanFootballGeneralDesc {
    return Intl.message(
      'touch, flag, general',
      name: 'paAmericanFootballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `football or baseball`
  String get paCatch {
    return Intl.message(
      'football or baseball',
      name: 'paCatch',
      desc: '',
      args: [],
    );
  }

  /// `playing catch`
  String get paCatchDesc {
    return Intl.message(
      'playing catch',
      name: 'paCatchDesc',
      desc: '',
      args: [],
    );
  }

  /// `frisbee playing`
  String get paFrisbee {
    return Intl.message(
      'frisbee playing',
      name: 'paFrisbee',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paFrisbeeDesc {
    return Intl.message(
      'general',
      name: 'paFrisbeeDesc',
      desc: '',
      args: [],
    );
  }

  /// `golf`
  String get paGolfGeneral {
    return Intl.message(
      'golf',
      name: 'paGolfGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paGolfGeneralDesc {
    return Intl.message(
      'general',
      name: 'paGolfGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `gymnastics`
  String get paGymnasticsGeneral {
    return Intl.message(
      'gymnastics',
      name: 'paGymnasticsGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paGymnasticsGeneralDesc {
    return Intl.message(
      'general',
      name: 'paGymnasticsGeneralDesc',
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

  /// `general`
  String get paHackySackDesc {
    return Intl.message(
      'general',
      name: 'paHackySackDesc',
      desc: '',
      args: [],
    );
  }

  /// `handball`
  String get paHandballGeneral {
    return Intl.message(
      'handball',
      name: 'paHandballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHandballGeneralDesc {
    return Intl.message(
      'general',
      name: 'paHandballGeneralDesc',
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

  /// `general`
  String get paHangGlidingDesc {
    return Intl.message(
      'general',
      name: 'paHangGlidingDesc',
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

  /// `general`
  String get paHockeyFieldDesc {
    return Intl.message(
      'general',
      name: 'paHockeyFieldDesc',
      desc: '',
      args: [],
    );
  }

  /// `ice hockey`
  String get paIceHockeyGeneral {
    return Intl.message(
      'ice hockey',
      name: 'paIceHockeyGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paIceHockeyGeneralDesc {
    return Intl.message(
      'general',
      name: 'paIceHockeyGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `horseback riding`
  String get paHorseRidingGeneral {
    return Intl.message(
      'horseback riding',
      name: 'paHorseRidingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paHorseRidingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paHorseRidingGeneralDesc',
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

  /// `general`
  String get paJaiAlaiDesc {
    return Intl.message(
      'general',
      name: 'paJaiAlaiDesc',
      desc: '',
      args: [],
    );
  }

  /// `martial arts`
  String get paMartialArtsSlower {
    return Intl.message(
      'martial arts',
      name: 'paMartialArtsSlower',
      desc: '',
      args: [],
    );
  }

  /// `different types, slower pace, novice performers, practice`
  String get paMartialArtsSlowerDesc {
    return Intl.message(
      'different types, slower pace, novice performers, practice',
      name: 'paMartialArtsSlowerDesc',
      desc: '',
      args: [],
    );
  }

  /// `martial arts`
  String get paMartialArtsModerate {
    return Intl.message(
      'martial arts',
      name: 'paMartialArtsModerate',
      desc: '',
      args: [],
    );
  }

  /// `different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)`
  String get paMartialArtsModerateDesc {
    return Intl.message(
      'different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)',
      name: 'paMartialArtsModerateDesc',
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

  /// `general`
  String get paJugglingDesc {
    return Intl.message(
      'general',
      name: 'paJugglingDesc',
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

  /// `general`
  String get paKickballDesc {
    return Intl.message(
      'general',
      name: 'paKickballDesc',
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

  /// `general`
  String get paLacrosseDesc {
    return Intl.message(
      'general',
      name: 'paLacrosseDesc',
      desc: '',
      args: [],
    );
  }

  /// `lawn bowling`
  String get paLawnBowling {
    return Intl.message(
      'lawn bowling',
      name: 'paLawnBowling',
      desc: '',
      args: [],
    );
  }

  /// `bocce ball, outdoor`
  String get paLawnBowlingDesc {
    return Intl.message(
      'bocce ball, outdoor',
      name: 'paLawnBowlingDesc',
      desc: '',
      args: [],
    );
  }

  /// `moto-cross`
  String get paMotoCross {
    return Intl.message(
      'moto-cross',
      name: 'paMotoCross',
      desc: '',
      args: [],
    );
  }

  /// `off-road motor sports, all-terrain vehicle, general`
  String get paMotoCrossDesc {
    return Intl.message(
      'off-road motor sports, all-terrain vehicle, general',
      name: 'paMotoCrossDesc',
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

  /// `general`
  String get paOrienteeringDesc {
    return Intl.message(
      'general',
      name: 'paOrienteeringDesc',
      desc: '',
      args: [],
    );
  }

  /// `paddleball`
  String get paPaddleball {
    return Intl.message(
      'paddleball',
      name: 'paPaddleball',
      desc: '',
      args: [],
    );
  }

  /// `casual, general`
  String get paPaddleballDesc {
    return Intl.message(
      'casual, general',
      name: 'paPaddleballDesc',
      desc: '',
      args: [],
    );
  }

  /// `polo`
  String get paPoloHorse {
    return Intl.message(
      'polo',
      name: 'paPoloHorse',
      desc: '',
      args: [],
    );
  }

  /// `on horseback`
  String get paPoloHorseDesc {
    return Intl.message(
      'on horseback',
      name: 'paPoloHorseDesc',
      desc: '',
      args: [],
    );
  }

  /// `pickleball`
  String get paPickleball {
    return Intl.message(
      'pickleball',
      name: 'paPickleball',
      desc: '',
      args: [],
    );
  }

  /// `active video games`
  String get paActiveVideoGames {
    return Intl.message(
      'active video games',
      name: 'paActiveVideoGames',
      desc: '',
      args: [],
    );
  }

  /// `Wii Sports, Dance Dance Revolution, general`
  String get paActiveVideoGamesDesc {
    return Intl.message(
      'Wii Sports, Dance Dance Revolution, general',
      name: 'paActiveVideoGamesDesc',
      desc: '',
      args: [],
    );
  }

  /// `racquetball`
  String get paRacquetball {
    return Intl.message(
      'racquetball',
      name: 'paRacquetball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paRacquetballDesc {
    return Intl.message(
      'general',
      name: 'paRacquetballDesc',
      desc: '',
      args: [],
    );
  }

  /// `climbing`
  String get paMountainClimbing {
    return Intl.message(
      'climbing',
      name: 'paMountainClimbing',
      desc: '',
      args: [],
    );
  }

  /// `rock or mountain climbing`
  String get paMountainClimbingDesc {
    return Intl.message(
      'rock or mountain climbing',
      name: 'paMountainClimbingDesc',
      desc: '',
      args: [],
    );
  }

  /// `rodeo sports`
  String get paRodeoSportGeneralModerate {
    return Intl.message(
      'rodeo sports',
      name: 'paRodeoSportGeneralModerate',
      desc: '',
      args: [],
    );
  }

  /// `general, moderate effort`
  String get paRodeoSportGeneralModerateDesc {
    return Intl.message(
      'general, moderate effort',
      name: 'paRodeoSportGeneralModerateDesc',
      desc: '',
      args: [],
    );
  }

  /// `rope jumping`
  String get paRopeJumpingGeneral {
    return Intl.message(
      'rope jumping',
      name: 'paRopeJumpingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce`
  String get paRopeJumpingGeneralDesc {
    return Intl.message(
      'moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce',
      name: 'paRopeJumpingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `rugby`
  String get paRugbyCompetitive {
    return Intl.message(
      'rugby',
      name: 'paRugbyCompetitive',
      desc: '',
      args: [],
    );
  }

  /// `union, team, competitive`
  String get paRugbyCompetitiveDesc {
    return Intl.message(
      'union, team, competitive',
      name: 'paRugbyCompetitiveDesc',
      desc: '',
      args: [],
    );
  }

  /// `rugby`
  String get paRugbyNonCompetitive {
    return Intl.message(
      'rugby',
      name: 'paRugbyNonCompetitive',
      desc: '',
      args: [],
    );
  }

  /// `touch, non-competitive`
  String get paRugbyNonCompetitiveDesc {
    return Intl.message(
      'touch, non-competitive',
      name: 'paRugbyNonCompetitiveDesc',
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

  /// `general`
  String get paShuffleboardDesc {
    return Intl.message(
      'general',
      name: 'paShuffleboardDesc',
      desc: '',
      args: [],
    );
  }

  /// `skateboarding`
  String get paSkateboardingGeneral {
    return Intl.message(
      'skateboarding',
      name: 'paSkateboardingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general, moderate effort`
  String get paSkateboardingGeneralDesc {
    return Intl.message(
      'general, moderate effort',
      name: 'paSkateboardingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `roller skating`
  String get paSkatingRoller {
    return Intl.message(
      'roller skating',
      name: 'paSkatingRoller',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSkatingRollerDesc {
    return Intl.message(
      'general',
      name: 'paSkatingRollerDesc',
      desc: '',
      args: [],
    );
  }

  /// `rollerblading`
  String get paRollerbladingLight {
    return Intl.message(
      'rollerblading',
      name: 'paRollerbladingLight',
      desc: '',
      args: [],
    );
  }

  /// `in-line skating`
  String get paRollerbladingLightDesc {
    return Intl.message(
      'in-line skating',
      name: 'paRollerbladingLightDesc',
      desc: '',
      args: [],
    );
  }

  /// `skydiving`
  String get paSkydiving {
    return Intl.message(
      'skydiving',
      name: 'paSkydiving',
      desc: '',
      args: [],
    );
  }

  /// `skydiving, base jumping, bungee jumping`
  String get paSkydivingDesc {
    return Intl.message(
      'skydiving, base jumping, bungee jumping',
      name: 'paSkydivingDesc',
      desc: '',
      args: [],
    );
  }

  /// `soccer`
  String get paSoccerGeneral {
    return Intl.message(
      'soccer',
      name: 'paSoccerGeneral',
      desc: '',
      args: [],
    );
  }

  /// `casual, general`
  String get paSoccerGeneralDesc {
    return Intl.message(
      'casual, general',
      name: 'paSoccerGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `softball / baseball`
  String get paSoftballBaseballGeneral {
    return Intl.message(
      'softball / baseball',
      name: 'paSoftballBaseballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `fast or slow pitch, general`
  String get paSoftballBaseballGeneralDesc {
    return Intl.message(
      'fast or slow pitch, general',
      name: 'paSoftballBaseballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `squash`
  String get paSquashGeneral {
    return Intl.message(
      'squash',
      name: 'paSquashGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSquashGeneralDesc {
    return Intl.message(
      'general',
      name: 'paSquashGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `table tennis`
  String get paTableTennisGeneral {
    return Intl.message(
      'table tennis',
      name: 'paTableTennisGeneral',
      desc: '',
      args: [],
    );
  }

  /// `table tennis, ping pong`
  String get paTableTennisGeneralDesc {
    return Intl.message(
      'table tennis, ping pong',
      name: 'paTableTennisGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `tai chi, qi gong`
  String get paTaiChiQiGongGeneral {
    return Intl.message(
      'tai chi, qi gong',
      name: 'paTaiChiQiGongGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paTaiChiQiGongGeneralDesc {
    return Intl.message(
      'general',
      name: 'paTaiChiQiGongGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `tennis`
  String get paTennisGeneral {
    return Intl.message(
      'tennis',
      name: 'paTennisGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paTennisGeneralDesc {
    return Intl.message(
      'general',
      name: 'paTennisGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `trampoline`
  String get paTrampolineLight {
    return Intl.message(
      'trampoline',
      name: 'paTrampolineLight',
      desc: '',
      args: [],
    );
  }

  /// `recreational`
  String get paTrampolineLightDesc {
    return Intl.message(
      'recreational',
      name: 'paTrampolineLightDesc',
      desc: '',
      args: [],
    );
  }

  /// `volleyball`
  String get paVolleyballGeneral {
    return Intl.message(
      'volleyball',
      name: 'paVolleyballGeneral',
      desc: '',
      args: [],
    );
  }

  /// `non-competitive, 6 - 9 member team, general`
  String get paVolleyballGeneralDesc {
    return Intl.message(
      'non-competitive, 6 - 9 member team, general',
      name: 'paVolleyballGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `wrestling`
  String get paWrestling {
    return Intl.message(
      'wrestling',
      name: 'paWrestling',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWrestlingDesc {
    return Intl.message(
      'general',
      name: 'paWrestlingDesc',
      desc: '',
      args: [],
    );
  }

  /// `wallyball`
  String get paWallyball {
    return Intl.message(
      'wallyball',
      name: 'paWallyball',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paWallyballDesc {
    return Intl.message(
      'general',
      name: 'paWallyballDesc',
      desc: '',
      args: [],
    );
  }

  /// `track and field`
  String get paTrackField {
    return Intl.message(
      'track and field',
      name: 'paTrackField',
      desc: '',
      args: [],
    );
  }

  /// `(e.g. shot, discus, hammer throw)`
  String get paTrackField1Desc {
    return Intl.message(
      '(e.g. shot, discus, hammer throw)',
      name: 'paTrackField1Desc',
      desc: '',
      args: [],
    );
  }

  /// `(e.g. high jump, long jump, triple jump, javelin, pole vault)`
  String get paTrackField2Desc {
    return Intl.message(
      '(e.g. high jump, long jump, triple jump, javelin, pole vault)',
      name: 'paTrackField2Desc',
      desc: '',
      args: [],
    );
  }

  /// `(e.g. steeplechase, hurdles)`
  String get paTrackField3Desc {
    return Intl.message(
      '(e.g. steeplechase, hurdles)',
      name: 'paTrackField3Desc',
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

  /// `general`
  String get paBackpackingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paBackpackingGeneralDesc',
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

  /// `no load`
  String get paClimbingHillsNoLoadGeneralDesc {
    return Intl.message(
      'no load',
      name: 'paClimbingHillsNoLoadGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `hiking`
  String get paHikingCrossCountry {
    return Intl.message(
      'hiking',
      name: 'paHikingCrossCountry',
      desc: '',
      args: [],
    );
  }

  /// `cross country`
  String get paHikingCrossCountryDesc {
    return Intl.message(
      'cross country',
      name: 'paHikingCrossCountryDesc',
      desc: '',
      args: [],
    );
  }

  /// `walking`
  String get paWalkingForPleasure {
    return Intl.message(
      'walking',
      name: 'paWalkingForPleasure',
      desc: '',
      args: [],
    );
  }

  /// `for pleasure`
  String get paWalkingForPleasureDesc {
    return Intl.message(
      'for pleasure',
      name: 'paWalkingForPleasureDesc',
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

  /// `general`
  String get paWalkingTheDogDesc {
    return Intl.message(
      'general',
      name: 'paWalkingTheDogDesc',
      desc: '',
      args: [],
    );
  }

  /// `nordic walking`
  String get paNordicWalking {
    return Intl.message(
      'nordic walking',
      name: 'paNordicWalking',
      desc: '',
      args: [],
    );
  }

  /// `canoeing`
  String get paCanoeingGeneral {
    return Intl.message(
      'canoeing',
      name: 'paCanoeingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `rowing, for pleasure, general`
  String get paCanoeingGeneralDesc {
    return Intl.message(
      'rowing, for pleasure, general',
      name: 'paCanoeingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `diving`
  String get paDivingSpringboardPlatform {
    return Intl.message(
      'diving',
      name: 'paDivingSpringboardPlatform',
      desc: '',
      args: [],
    );
  }

  /// `springboard or platform`
  String get paDivingSpringboardPlatformDesc {
    return Intl.message(
      'springboard or platform',
      name: 'paDivingSpringboardPlatformDesc',
      desc: '',
      args: [],
    );
  }

  /// `kayaking`
  String get paKayakingModerate {
    return Intl.message(
      'kayaking',
      name: 'paKayakingModerate',
      desc: '',
      args: [],
    );
  }

  /// `moderate effort`
  String get paKayakingModerateDesc {
    return Intl.message(
      'moderate effort',
      name: 'paKayakingModerateDesc',
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

  /// `general`
  String get paPaddleBoatDesc {
    return Intl.message(
      'general',
      name: 'paPaddleBoatDesc',
      desc: '',
      args: [],
    );
  }

  /// `sailing`
  String get paSailingGeneral {
    return Intl.message(
      'sailing',
      name: 'paSailingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `boat and board sailing, windsurfing, ice sailing, general`
  String get paSailingGeneralDesc {
    return Intl.message(
      'boat and board sailing, windsurfing, ice sailing, general',
      name: 'paSailingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `water skiing`
  String get paSkiingWaterWakeboarding {
    return Intl.message(
      'water skiing',
      name: 'paSkiingWaterWakeboarding',
      desc: '',
      args: [],
    );
  }

  /// `water or wakeboarding`
  String get paSkiingWaterWakeboardingDesc {
    return Intl.message(
      'water or wakeboarding',
      name: 'paSkiingWaterWakeboardingDesc',
      desc: '',
      args: [],
    );
  }

  /// `diving`
  String get paDivingGeneral {
    return Intl.message(
      'diving',
      name: 'paDivingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `skindiving, scuba diving, general`
  String get paDivingGeneralDesc {
    return Intl.message(
      'skindiving, scuba diving, general',
      name: 'paDivingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `snorkeling`
  String get paSnorkeling {
    return Intl.message(
      'snorkeling',
      name: 'paSnorkeling',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSnorkelingDesc {
    return Intl.message(
      'general',
      name: 'paSnorkelingDesc',
      desc: '',
      args: [],
    );
  }

  /// `surfing`
  String get paSurfing {
    return Intl.message(
      'surfing',
      name: 'paSurfing',
      desc: '',
      args: [],
    );
  }

  /// `body or board, general`
  String get paSurfingDesc {
    return Intl.message(
      'body or board, general',
      name: 'paSurfingDesc',
      desc: '',
      args: [],
    );
  }

  /// `paddle boarding`
  String get paPaddleBoarding {
    return Intl.message(
      'paddle boarding',
      name: 'paPaddleBoarding',
      desc: '',
      args: [],
    );
  }

  /// `standing`
  String get paPaddleBoardingDesc {
    return Intl.message(
      'standing',
      name: 'paPaddleBoardingDesc',
      desc: '',
      args: [],
    );
  }

  /// `swimming`
  String get paSwimmingGeneral {
    return Intl.message(
      'swimming',
      name: 'paSwimmingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `treading water, moderate effort, general`
  String get paSwimmingGeneralDesc {
    return Intl.message(
      'treading water, moderate effort, general',
      name: 'paSwimmingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics`
  String get paWateraerobicsCalisthenics {
    return Intl.message(
      'water aerobics',
      name: 'paWateraerobicsCalisthenics',
      desc: '',
      args: [],
    );
  }

  /// `water aerobics, water calisthenics`
  String get paWateraerobicsCalisthenicsDesc {
    return Intl.message(
      'water aerobics, water calisthenics',
      name: 'paWateraerobicsCalisthenicsDesc',
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

  /// `general`
  String get paWaterPoloDesc {
    return Intl.message(
      'general',
      name: 'paWaterPoloDesc',
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

  /// `general`
  String get paWaterVolleyballDesc {
    return Intl.message(
      'general',
      name: 'paWaterVolleyballDesc',
      desc: '',
      args: [],
    );
  }

  /// `ice skating`
  String get paIceSkatingGeneral {
    return Intl.message(
      'ice skating',
      name: 'paIceSkatingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paIceSkatingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paIceSkatingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `skiing`
  String get paSkiingGeneral {
    return Intl.message(
      'skiing',
      name: 'paSkiingGeneral',
      desc: '',
      args: [],
    );
  }

  /// `general`
  String get paSkiingGeneralDesc {
    return Intl.message(
      'general',
      name: 'paSkiingGeneralDesc',
      desc: '',
      args: [],
    );
  }

  /// `snow shoveling`
  String get paSnowShovingModerate {
    return Intl.message(
      'snow shoveling',
      name: 'paSnowShovingModerate',
      desc: '',
      args: [],
    );
  }

  /// `by hand, moderate effort`
  String get paSnowShovingModerateDesc {
    return Intl.message(
      'by hand, moderate effort',
      name: 'paSnowShovingModerateDesc',
      desc: '',
      args: [],
    );
  }

  /// `cross-country skiing`
  String get paCrossCountrySkiing {
    return Intl.message(
      'cross-country skiing',
      name: 'paCrossCountrySkiing',
      desc: '',
      args: [],
    );
  }

  /// `cross-country, general`
  String get paCrossCountrySkiingDesc {
    return Intl.message(
      'cross-country, general',
      name: 'paCrossCountrySkiingDesc',
      desc: '',
      args: [],
    );
  }

  /// `snowshoeing`
  String get paSnowshoeing {
    return Intl.message(
      'snowshoeing',
      name: 'paSnowshoeing',
      desc: '',
      args: [],
    );
  }


  /// `Not set`
  String get profileTargetWeightNotSetLabel {
    return Intl.message(
      'Not set',
      name: 'profileTargetWeightNotSetLabel',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get profileTargetWeightClearAction {
    return Intl.message(
      'Clear',
      name: 'profileTargetWeightClearAction',
      desc: '',
      args: [],
    );
  }

  /// `Target weight`
  String get profileTargetWeightLabel {
    return Intl.message(
      'Target weight',
      name: 'profileTargetWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `{value} to your target`
  String profileTargetWeightToGo(String value) {
    return Intl.message(
      '$value to your target',
      name: 'profileTargetWeightToGo',
      desc: '',
      args: [value],
    );
  }

  /// `You've reached your target`
  String get profileTargetWeightReached {
    return Intl.message(
      'You\'ve reached your target',
      name: 'profileTargetWeightReached',
      desc: '',
      args: [],
    );
  }

  /// `Adjust calorie goal as you approach target`
  String get settingsCaloriesTaperLabel {
    return Intl.message(
      'Adjust calorie goal as you approach target',
      name: 'settingsCaloriesTaperLabel',
      desc: '',
      args: [],
    );
  }

  /// `Reduces the daily deficit gradually so the last few kg don't feel like a wall.`
  String get settingsCaloriesTaperDescription {
    return Intl.message(
      'Reduces the daily deficit gradually so the last few kg don\'t feel like a wall.',
      name: 'settingsCaloriesTaperDescription',
      desc: '',
      args: [],
    );
  }

  /// `Weight history`
  String get profileWeightHistoryTitle {
    return Intl.message(
      'Weight history',
      name: 'profileWeightHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add entry`
  String get weightHistoryAddEntry {
    return Intl.message(
      'Add entry',
      name: 'weightHistoryAddEntry',
      desc: '',
      args: [],
    );
  }

  /// `No weight readings yet. Add your first one to start tracking a trend.`
  String get weightHistoryNoEntries {
    return Intl.message(
      'No weight readings yet. Add your first one to start tracking a trend.',
      name: 'weightHistoryNoEntries',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get weightHistoryDateLabel {
    return Intl.message(
      'Date',
      name: 'weightHistoryDateLabel',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get weightHistoryWeightLabel {
    return Intl.message(
      'Weight',
      name: 'weightHistoryWeightLabel',
      desc: '',
      args: [],
    );
  }

  /// `Note (optional)`
  String get weightHistoryNoteLabel {
    return Intl.message(
      'Note (optional)',
      name: 'weightHistoryNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Log at least two days to see your trend.`
  String get weightHistoryChartEmptyState {
    return Intl.message(
      'Log at least two days to see your trend.',
      name: 'weightHistoryChartEmptyState',
      desc: '',
      args: [],
    );
  }

  /// `Custom activity`
  String get customActivityName {
    return Intl.message(
      'Custom activity',
      name: 'customActivityName',
      desc: '',
      args: [],
    );
  }

  /// `Enter calories burned directly, for workouts that aren't in the list or readings from a fitness tracker`
  String get customActivityDescription {
    return Intl.message(
      'Enter calories burned directly, for workouts that aren\'t in the list or readings from a fitness tracker',
      name: 'customActivityDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enter kilojoules burned directly, for workouts that aren't in the list or readings from a fitness tracker`
  String get customActivityDescriptionKj {
    return Intl.message(
      'Enter kilojoules burned directly, for workouts that aren\'t in the list or readings from a fitness tracker',
      name: 'customActivityDescriptionKj',
      desc: '',
      args: [],
    );
  }

  /// `Calories burned`
  String get customActivityKcalLabel {
    return Intl.message(
      'Calories burned',
      name: 'customActivityKcalLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. 250`
  String get customActivityKcalHint {
    return Intl.message(
      'e.g. 250',
      name: 'customActivityKcalHint',
      desc: '',
      args: [],
    );
  }

  /// `Name (optional)`
  String get customActivityNameFieldLabel {
    return Intl.message(
      'Name (optional)',
      name: 'customActivityNameFieldLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. Evening bike commute`
  String get customActivityNameFieldHint {
    return Intl.message(
      'e.g. Evening bike commute',
      name: 'customActivityNameFieldHint',
      desc: '',
      args: [],
    );
  }

  /// `Save as template for next time`
  String get customActivitySaveAsTemplate {
    return Intl.message(
      'Save as template for next time',
      name: 'customActivitySaveAsTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Pick from saved templates`
  String get customActivityPickFromTemplate {
    return Intl.message(
      'Pick from saved templates',
      name: 'customActivityPickFromTemplate',
      desc: '',
      args: [],
    );
  }

  /// `You haven't saved any templates yet. Tick "Save as template for next time" to remember a Custom activity for later.`
  String get customActivityTemplatesEmpty {
    return Intl.message(
      'You haven\'t saved any templates yet. Tick "Save as template for next time" to remember a Custom activity for later.',
      name: 'customActivityTemplatesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `{current} / {goal} ml`
  String waterChipLabel(int current, int goal) {
    return Intl.message(
      '$current / $goal ml',
      name: 'waterChipLabel',
      desc: '',
      args: [current, goal],
    );
  }

  /// `Log water intake`
  String get logWaterDialogTitle {
    return Intl.message(
      'Log water intake',
      name: 'logWaterDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add {amount} ml`
  String logWaterAmountLabel(int amount) {
    return Intl.message(
      'Add $amount ml',
      name: 'logWaterAmountLabel',
      desc: '',
      args: [amount],
    );
  }

  /// `Undo last`
  String get logWaterUndoLabel {
    return Intl.message(
      'Undo last',
      name: 'logWaterUndoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Nothing to undo`
  String get logWaterNothingToUndoLabel {
    return Intl.message(
      'Nothing to undo',
      name: 'logWaterNothingToUndoLabel',
      desc: '',
      args: [],
    );
  }

  /// `ml`
  String get mlLabel {
    return Intl.message(
      'ml',
      name: 'mlLabel',
      desc: '',
      args: [],
    );
  }

  /// `Daily water goal`
  String get settingsWaterGoalLabel {
    return Intl.message(
      'Daily water goal',
      name: 'settingsWaterGoalLabel',
      desc: '',
      args: [],
    );
  }

  /// `Used by the water chip on the home screen.`
  String get settingsWaterGoalDescription {
    return Intl.message(
      'Used by the water chip on the home screen.',
      name: 'settingsWaterGoalDescription',
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
      Locale.fromSubtags(languageCode: 'cs'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'it'),
      Locale.fromSubtags(languageCode: 'pl'),
      Locale.fromSubtags(languageCode: 'sk'),
      Locale.fromSubtags(languageCode: 'tr'),
      Locale.fromSubtags(languageCode: 'uk'),
      Locale.fromSubtags(languageCode: 'zh'),
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
