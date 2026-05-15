// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(versionNumber) => "Version ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% carbs, ${pctFats}% fats, ${pctProteins}% proteins";

  static String m2(riskValue) => "Risk of comorbidities: ${riskValue}";

  static String m3(age) => "${age} years";

  static String m4(mealType) =>
      "These items will be added to your ${mealType}.";

  static String m5(count) => "Import ${count} items?";

  static String m6(count) =>
      "${count} item(s) could not be fetched from OpenFoodFacts.";

  static String m7(count) => "Import ${count} activities?";

  static String m8(rate) => "${rate} kg/week";

  static String m9(rate) => "${rate} lbs/week";

  static String m10(qty, unit) => "Per ${qty} ${unit}";

  static String m11(time) => "Reminder time: ${time}";

  static String m12(count) =>
      "Imported ${count} meal(s) from the CSV file.";

  static String m13(imported, skipped) =>
      "Imported ${imported} meal(s); ${skipped} row(s) were skipped due to invalid data.";

  static String m14(count, size) => "${count} item(s) · ${size}";

  static String m15(count) => "${count} ingredient(s)";

  static String m16(count) =>
      "Import this recipe with ${count} ingredient(s)?";

  static String m17(count) => "${count} selected";

  static String m18(count) => "Delete ${count} recipe(s)?";

  static String m19(detail) => "Couldn\'t parse: ${detail}";

  static String m20(count, customCount) =>
      "Logged ${count} from JSON, ${customCount} saved as custom meals";

  static String m21(value) => "${value} to your target";

  static String m22(consumed, target) => "${consumed} / ${target} kcal";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "e.g. running, biking, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Activity"),
        "addItemLabel": MessageLookupByLibrary.simpleMessage("Add new Item:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Add"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Information provided\n by the \n\'2024 Compendium\n of Physical Activities\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Custom Meal Item"),
        "additionalInfoLabelRecipe":
            MessageLookupByLibrary.simpleMessage("Custom Recipe"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "More Information at\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "More Information at\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Unknown Meal Item"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Age"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("All"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker is a free and open-source calorie and nutrient tracker that respects your privacy."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("GPL-3.0 license"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Base quantity (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "e.g. cereal, milk, coffee ..."),
        "breakfastLabel": MessageLookupByLibrary.simpleMessage("Breakfast"),
        "burnedLabel": MessageLookupByLibrary.simpleMessage("burned"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("NEXT"),
        "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Reset"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Save"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("START"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("YES"),
        "calciumLabel": MessageLookupByLibrary.simpleMessage("calcium"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Macros distribution"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(recommended)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Institute of Medicine Equation (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("TDEE equation"),
        "caloriesProfileAveragedLabel":
            MessageLookupByLibrary.simpleMessage("Averaged reference (default)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Estrogen-typical reference"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "There isn\'t a published non-binary calorie baseline — the reference equations are built around male and female samples. We use an average of the two by default, a neutral starting point that doesn\'t ask you to disclose more about your body. The kcal slider in Settings is always available to fine-tune; this is a starting point, not a precise estimate."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Calorie reference"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Testosterone-typical reference"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("carbohydrate"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("carbs"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("c"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Weekly weight rate"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Choose Weight Goal"),
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Code copied"),
        "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Copy code"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Which meal type do you want to copy to?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "With \"Copy to today\" you can copy the meal to today. With \"Delete\" you can delete the meal."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("What do you want to do?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Do you want create a custom meal item?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Create custom meal item?"),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Daily Kcal adjustment:"),
        "dailyKjAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Daily kJ adjustment:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Support development by providing anonymous usage data"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Delete all"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Do want to delete the selected item?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Do want to delete all items of this meal?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Delete Items?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Delete Item?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("CANCEL"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Copy to today"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("DELETE"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Diary"),
        "diaryNutrientPanelDataDisclaimer":
            MessageLookupByLibrary.simpleMessage("Only nutrients tracked on the meals you logged are summed here. A meal missing a value contributes nothing to that nutrient — so these totals may underreport."),
        "diaryFutureDateWarning":
            MessageLookupByLibrary.simpleMessage("You are editing a future date"),
        "diaryNutrientPanelTitle":
            MessageLookupByLibrary.simpleMessage("Today\'s nutrients"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "e.g. soup, chicken, wine ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Dinner"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker is not a medical application. All data provided is not validated and should be used with caution. Please maintain a healthy lifestyle and consult a professional if you have any problems. Use during illness, pregnancy or lactation is not recommended. For the peer-reviewed sources behind each calculation, tap the info icon on the Home or Profile screen."),
        "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
            "This food has already been added to this meal today. Add it again?"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Edit item"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Edit meal"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("energy"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Error while fetching product data"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Error while loading activities"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Error while saving meal. Did you input the correct meal information?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Error while opening browser app"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Error while opening email app"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Product not found"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Removes the locally cached search and scan results from Open Food Facts and FDC. The cache rebuilds automatically as you search and scan products. Your custom meals are not affected."),
        "clearOffCacheConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Clear cached items?"),
        "clearOffCacheLabel":
            MessageLookupByLibrary.simpleMessage("Clear cached items"),
        "clearOffCacheSubtitle": m14,
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Have a barcode? Help everyone by contributing the product to Open Food Facts:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Could not read CSV file. Check the format and try again."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "downloadSampleCsvAction":
            MessageLookupByLibrary.simpleMessage("Sample meals (csv)"),
        "downloadSampleJsonAction":
            MessageLookupByLibrary.simpleMessage("Sample meals (json)"),
        "importMealsJsonAction":
            MessageLookupByLibrary.simpleMessage("Import meals (json)"),
        "downloadSampleRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Sample recipes (json)"),
        "importRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Import recipes (json)"),
        "downloadSampleRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Sample recipes (csv)"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Import meals (csv)"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Export"),
        "customActivityName":
            MessageLookupByLibrary.simpleMessage("Custom activity"),
        "customActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Enter calories burned directly, for workouts that aren\'t in the list or readings from a fitness tracker"),
        "customActivityDescriptionKj":
            MessageLookupByLibrary.simpleMessage("Enter kilojoules burned directly, for workouts that aren't in the list or readings from a fitness tracker"),
        "customActivityKcalLabel":
            MessageLookupByLibrary.simpleMessage("Calories burned"),
        "customActivityKcalHint":
            MessageLookupByLibrary.simpleMessage("e.g. 250"),
        "customActivityNameFieldLabel":
            MessageLookupByLibrary.simpleMessage("Name (optional)"),
        "customActivityNameFieldHint":
            MessageLookupByLibrary.simpleMessage("e.g. Evening bike commute"),
        "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
            "Save as template for next time"),
        "customActivityPickFromTemplate":
            MessageLookupByLibrary.simpleMessage("Pick from saved templates"),
        "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
            "You haven\'t saved any templates yet. Tick \"Save as template for next time\" to remember a Custom activity for later."),
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "All diary entries using this meal will also be removed."),
        "customMealsDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Delete custom meal?"),
        "customMealsEmptyLabel":
            MessageLookupByLibrary.simpleMessage("No custom meals saved yet."),
        "ironLabel": MessageLookupByLibrary.simpleMessage("iron"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnesium"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Micronutrients"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("monounsaturated fat"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("niacin (B3)"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("phosphorus"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("polyunsaturated fat"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("potassium"),
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Custom Meals"),
        "exportImportCsvRecipesNote":
            MessageLookupByLibrary.simpleMessage("CSV keeps your activity, meal log and tracked days. Recipes and any photos you've attached are JSON-only — switch to JSON if you want them in your backup."),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import error"),
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Export / Import App Data"),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Import Custom Food Data"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Import your own meals from a CSV file or by pasting JSON. Download a sample to see the expected shape and required fields."),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import successful"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("fat"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("f"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("fiber"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("female"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Gender"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("male"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("non-binary"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Gain Weight"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Goal"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Lose Weight"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Maintain Weight"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Height"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Home"),
        "importAction": MessageLookupByLibrary.simpleMessage("Import"),
        "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
            "These activities will be added to today."),
        "importActivityConfirmTitle": m7,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Import shared workout"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Workout imported"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Invalid QR code"),
        "importMealLabel":
            MessageLookupByLibrary.simpleMessage("Import shared meal"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Meal imported"),
        "importOffFetchFailedLabel": m6,
        "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
            "These values don't quite line up — the calories you've entered don't match the energy in the carbs, fat and protein below. Save anyway, or take a second look?"),
        "inconsistentNutritionWarningEdit":
            MessageLookupByLibrary.simpleMessage("Take another look"),
        "inconsistentNutritionWarningSaveAnyway":
            MessageLookupByLibrary.simpleMessage("Save anyway"),
        "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
            "Numbers don't quite line up"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Added new activity"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Added new intake"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Item deleted"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Item updated"),
        "kcalExceededLabel":
            MessageLookupByLibrary.simpleMessage("kcal exceeded"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal left"),
        "kcalTooMuchLabel":
            MessageLookupByLibrary.simpleMessage("kcal too much"),
        "energyLeftLabel": MessageLookupByLibrary.simpleMessage("left"),
        "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("too much"),
        "settingsEnergyUnitLabel":
            MessageLookupByLibrary.simpleMessage("Energy unit"),
        "energyUnitKcalLabel":
            MessageLookupByLibrary.simpleMessage("Kilocalories (kcal)"),
        "energyUnitKjLabel":
            MessageLookupByLibrary.simpleMessage("Kilojoules (kJ)"),
        "onboardingKjPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kJ per day"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample":
            MessageLookupByLibrary.simpleMessage("e.g. pizza, salad, rice ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Lunch"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Macronutrient Distribution:"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Brands"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("carbs per"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("fat per"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal per"),
        "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energy"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Meal name"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Meal name must contain at least one letter"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Total amount"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("protein per 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Meal size (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Meal size (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Meal unit"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Product missing required kcal or macronutrients information"),
        "noActivityRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("No activity recently added"),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("No meals recently added"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/A"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Nothing added"),
        "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Day"),
        "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Week"),
        "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
            "All nutrients hidden — turn some on in Settings → Nutrients."),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Nutrition Information"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Normal Weight"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obesity Class I"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obesity Class II"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obesity Class III"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Pre-obesity"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Average"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Increased"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Low \n(but risk of other \nclinical problems increased)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Moderate"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Severe"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Very severe"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Underweight"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            'The data provided to you by this app are retrieved from the Open Food Facts database. No guarantees can be made for the accuracy, completeness, or reliability of the information provided. The data are provided "as is" and the originating source for the data (Open Food Facts) is not liable for any damages arising out of the use of the data.'),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "How active are you? (without workouts)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Enter Date"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("When is your birthday?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Birthday"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("What\'s your gender?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "What\'s your current weight goal?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("e.g. 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("e.g. 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Whats your current height?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "To start, the app needs some information about you to calculate your daily calorie goal.\nAll information about you is stored securely on your device."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kcal per day"),
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "There\'s no published non-binary calorie baseline, so by default we use an average of the male and female formulas — a starting point, not a precise estimate. You can fine-tune anytime in Settings → Calculations."),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Overview"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Wrong input, please try again"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("e.g. 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("e.g. 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Whats your current weight?"),
        "onboardingTargetWeightSubtitle":
            MessageLookupByLibrary.simpleMessage("Is there a weight you\'re working towards? You can leave this blank or change it later in Profile."),
        "onboardingTargetWeightHintOptional":
            MessageLookupByLibrary.simpleMessage("Optional"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Welcome to"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Enter correct height"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Enter correct weight"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Your calorie goal:"),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("Your macronutrient goals:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("active video games"),
        "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
            "Wii Sports, Dance Dance Revolution, general"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("football"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("touch, flag, general"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("archery"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("non-hunting"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("auto racing"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("open wheel"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("backpacking"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "social singles and doubles, general"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basketball"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("bicycling"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("bicycling, mountain"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("bicycling, stationary"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("billiards"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boxing"),
        "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("punching bag"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boxing"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("in ring, general"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("calisthenics"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "light or moderate effort, general (e.g., back exercises)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("canoeing"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rowing, for pleasure, general"),
        "paCatch": MessageLookupByLibrary.simpleMessage("football or baseball"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("playing catch"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "gymnastic moves, competitive"),
        "paChildrenGame":
            MessageLookupByLibrary.simpleMessage("children's games"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort"),
        "paClimbingHillsNoLoadGeneral":
            MessageLookupByLibrary.simpleMessage("climbing hills, no load"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("no load"),
        "paCricket": MessageLookupByLibrary.simpleMessage("cricket"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("batting, bowling, fielding"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("croquet"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("cross-country skiing"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("cross-country, general"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobic"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("general dancing"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("darts"),
        "paDartsWallDesc": MessageLookupByLibrary.simpleMessage("wall or lawn"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("diving"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "skindiving, scuba diving, general"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("diving"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("springboard or platform"),
        "paFencing": MessageLookupByLibrary.simpleMessage("fencing"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee playing"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("gymnastics"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("handball"),
        "paHandballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("hang gliding"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("bicycling"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("conditioning exercise"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("dancing"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("running"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("sports"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Paste the shared meal code here"),
        "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Paste code"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("walking"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("water activities"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("winter activities"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "high intensity interval exercise"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("moderate effort"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "high intensity interval exercise"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "burpees, mountain climbers, squat jumps, Tabata, vigorous effort"),
        "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("hiking"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("cross country"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("hockey, field"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("horseback riding"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("ice hockey"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("ice skating"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("juggling"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kayaking"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("moderate effort"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("lawn bowling"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("bocce ball, outdoor"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("martial arts"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("martial arts"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "different types, slower pace, novice performers, practice"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-cross"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "off-road motor sports, all-terrain vehicle, general"),
        "paMountainClimbing": MessageLookupByLibrary.simpleMessage("climbing"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("rock or mountain climbing"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("orienteering"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("paddle boarding"),
        "paPaddleBoardingDesc":
            MessageLookupByLibrary.simpleMessage("standing"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("paddle boat"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("casual, general"),
        "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
        "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("on horseback"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("resistance training"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "weight lifting, free weight, nautilus or universal"),
        "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
            "resistance training (vigorous)"),
        "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
            "vigorous effort, powerlifting or bodybuilding"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("rodeo sports"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("general, moderate effort"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("rollerblading"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("in-line skating"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("rope jumping"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("rope skipping"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("union, team, competitive"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("touch, non-competitive"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("running"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("running on treadmill"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("on treadmill, general"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("sailing"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "boat and board sailing, windsurfing, ice sailing, general"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("skateboarding"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general, moderate effort"),
        "paSkatingRoller":
            MessageLookupByLibrary.simpleMessage("roller skating"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("skiing"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("water skiing"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("water or wakeboarding"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("skydiving"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "skydiving, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("snorkeling"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("snow shoveling"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("by hand, moderate effort"),
        "paSnowshoeing": MessageLookupByLibrary.simpleMessage("snowshoeing"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("soccer"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("casual, general"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("fast or slow pitch, general"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paStretching": MessageLookupByLibrary.simpleMessage("stretching"),
        "paStretchingDesc": MessageLookupByLibrary.simpleMessage("mild, general"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surfing"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("body or board, general"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("swimming"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "treading water, moderate effort, general"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("table tennis"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("table tennis, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tennis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("track and field"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(e.g. shot, discus, hammer throw)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(e.g. high jump, long jump, triple jump, javelin, pole vault)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(e.g. steeplechase, hurdles)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampoline"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("recreational"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("unicycling"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paVolleyballGeneral":
            MessageLookupByLibrary.simpleMessage("volleyball"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "non-competitive, 6 - 9 member team, general"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("walking"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("for pleasure"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("walking the dog"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("nordic walking"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("water exercise"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "water aerobics, water calisthenics"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("water polo"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("general"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("water volleyball"),
        "paWaterVolleyballDesc":
            MessageLookupByLibrary.simpleMessage("general"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("water aerobics"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "water aerobics, water calisthenics"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("general"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Mostly standing or walking in job and active free time activities"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Active"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "e.g. sitting or standing in job and light free time activities"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Low Active"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "e.g. office job and mostly sitting free time activities"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sedentary"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Mostly walking, running or carrying weight in job and active free time activities"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Very Active"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Per 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Per Serving"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Privacy policy"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profile"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("protein"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantity"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "I have read and accept the privacy policy."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Recently"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Recipes"),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("No recipes yet"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Build a meal from multiple ingredients and reuse it like any other food."),
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Create Recipe"),
        "newCustomMealLabel":
            MessageLookupByLibrary.simpleMessage("New Custom Food"),
        "discardChangesTitle":
            MessageLookupByLibrary.simpleMessage("Discard changes?"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Your unsaved changes will be lost."),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Discard"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Edit Recipe"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Recipe name"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Description (optional)"),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Servings (optional)"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Lets you log this recipe by serving instead of grams."),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Ingredients"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Add Ingredient"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("No ingredients yet"),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Total weight (g)"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "Defaults to sum of ingredients. Liquids approximated as 1 ml ≈ 1 g."),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Nutrition (total)"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("Per 100 g"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Amount"),
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Unit"),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Save Recipe"),
        "recipeSaveErrorLabel":
            MessageLookupByLibrary.simpleMessage("Could not save recipe."),
        "recipeSaveForLaterLabel":
            MessageLookupByLibrary.simpleMessage("Save for next time"),
        "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
            "Turn this on to keep this meal in your saved list for next time. Leave it off for a one-off you won\'t eat again."),
        "recipeNameRequiredLabel":
            MessageLookupByLibrary.simpleMessage("Recipe needs a name"),
        "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
            "Add at least one ingredient"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Total weight must be greater than zero"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Share recipe"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Duplicate"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(copy)"),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tags"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Comma-separated, e.g. \"breakfast, vegan\""),
        "customMealBarcodeLabel":
            MessageLookupByLibrary.simpleMessage("Barcode"),
        "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
            "Scan or type a barcode to recall this meal later"),
        "customMealBarcodeScanButton":
            MessageLookupByLibrary.simpleMessage("Scan barcode"),
        "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
            "Barcode must be 8 to 14 digits"),
        "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
            "This 13-digit barcode looks miskeyed: its last digit doesn\'t match the rest"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("All"),
        "importRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Import recipes (csv)"),
        "selectionCountLabel": m17,
        "deleteSelectedRecipesConfirmTitle": m18,
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Import recipe"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Recipe imported"),
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Could not parse recipe code"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Could not load recipes. Try again later."),
        "importRecipeConfirmContent": m16,
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Delete recipe?"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Past diary entries logged from this recipe will be kept."),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Log this Recipe"),
        "recipeIngredientCountLabel": m15,
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Do you want to report an error to the developer?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Retry"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("saturated fat"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Scan Product"),
        "searchDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Please enter a search word"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Food"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Search"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Products"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Search results"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Gender"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Height"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Select Activity Level"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Select Weight"),
        "sendAnonymousUserData":
            MessageLookupByLibrary.simpleMessage("Send anonymous usage data"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Serving"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Serving size (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Serving size (g/ml)"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("About"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Feedback"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Calculations"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Disclaimer"),
        "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily fibre target in grams. Default reference is 30g."),
        "settingsFibreGoalLabel":
            MessageLookupByLibrary.simpleMessage("Fibre goal"),
        "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
            "Personal targets for every nutrient on the daily panel. The diary uses these in place of the default daily references whenever you set one."),
        "settingsNutrientGoalsLabel":
            MessageLookupByLibrary.simpleMessage("Nutrient goals"),
        "settingsSaturatedFatGoalDescription":
            MessageLookupByLibrary.simpleMessage(
                "Daily saturated fat cap in grams. Default reference is 20g."),
        "settingsSaturatedFatGoalLabel":
            MessageLookupByLibrary.simpleMessage("Saturated fat goal"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Sources & References"),
        "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily sugars cap in grams. Default reference is 50g."),
        "settingsSugarsGoalLabel":
            MessageLookupByLibrary.simpleMessage("Sugars goal"),
        "settingsSodiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Sodium goal"),
        "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily sodium cap in milligrams. Default reference is 2300mg."),
        "settingsCalciumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Calcium goal"),
        "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily calcium target in milligrams. Default reference is 1000mg."),
        "settingsIronGoalLabel":
            MessageLookupByLibrary.simpleMessage("Iron goal"),
        "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily iron target in milligrams. Default varies by gender (8mg male, 18mg female, 14mg otherwise)."),
        "settingsPotassiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Potassium goal"),
        "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily potassium target in milligrams. Default reference is 3500mg."),
        "settingsMagnesiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Magnesium goal"),
        "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily magnesium target in milligrams. Default varies by gender (400mg male, 310mg female, 355mg otherwise)."),
        "settingsVitaminDGoalLabel":
            MessageLookupByLibrary.simpleMessage("Vitamin D goal"),
        "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily vitamin D target in micrograms. Default reference is 15µg."),
        "settingsVitaminB12GoalLabel":
            MessageLookupByLibrary.simpleMessage("Vitamin B12 goal"),
        "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
            "Daily vitamin B12 target in micrograms. Default reference is 2.4µg."),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("View sources"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker uses well-established, peer-reviewed methodologies for every calculation it shows. The citations below link to the original sources so you can verify any number yourself."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Energy needs (TDEE, BMR & activity level)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Daily calorie targets, basal metabolic rate, and physical activity coefficients use the equations from the Institute of Medicine. Source: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Chapter 5 and Table 5-5."),
        "sourcesBmiTitle":
            MessageLookupByLibrary.simpleMessage("Body Mass Index (BMI)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "BMI is computed as weight (kg) divided by height squared (m²). The health categories (underweight, normal, pre-obesity, obesity class I–III) follow the World Health Organization\'s adult BMI classification."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Macronutrient distribution"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "The default split of 60% carbohydrates, 25% fat, and 15% protein falls within the population nutrient intake ranges published by the WHO. You can adjust this in Settings → Calculations. Source: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Activity calories (MET values)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Calories burned during an activity are estimated as MET × body weight (kg) × duration (hours), using values from the Adult Compendium of Physical Activities."),
        "sourcesNonBinaryTitle":
            MessageLookupByLibrary.simpleMessage("Non-binary calorie estimation"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "Energy-expenditure research has historically used binary sex categories, so there is no single validated TDEE formula for non-binary people. OpenNutriTracker therefore lets you choose between an averaged reference, an estrogen-typical reference, or a testosterone-typical reference under Settings → Calculations. If an accurate number genuinely matters for your care, please speak to a clinician familiar with your hormone status."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("View source"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Distance"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperial (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsLanguageLabel":
            MessageLookupByLibrary.simpleMessage("Language"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licenses"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Mass"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metric (kg, cm, ml)"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Privacy Settings"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Daily Reminder"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("Notification permission denied."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Don\'t forget to log your meals today!"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Report Error"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Show Activity Tracking"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Show Meal Macros"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Show Micronutrients"),
        "settingsNutrientsLabel":
            MessageLookupByLibrary.simpleMessage("Nutrients"),
        "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
            "Pick which nutrients appear on the diary panel"),
        "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
            "Choose which nutrients are visible on the daily panel. Hidden ones can be turned back on at any time."),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Source Code"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("System"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Dark"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Theme"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Light"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("System default"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Units"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
        "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Share code"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "e.g. apple, ice cream, chocolate ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Snack"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodium"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("sugar"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("supplied"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("trans fat"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Unit"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamin A"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamin B12"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamin B6"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamin C"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamin D"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Warning"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Weekly rate"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Not set"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Weight"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("zinc"),
        "profileWeightHistoryTitle":
            MessageLookupByLibrary.simpleMessage("Weight history"),
        "weightHistoryAddEntry":
            MessageLookupByLibrary.simpleMessage("Add entry"),
        "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
            "No weight readings yet. Add your first one to start tracking a trend."),
        "weightHistoryDateLabel":
            MessageLookupByLibrary.simpleMessage("Date"),
        "weightHistoryWeightLabel":
            MessageLookupByLibrary.simpleMessage("Weight"),
        "weightHistoryNoteLabel":
            MessageLookupByLibrary.simpleMessage("Note (optional)"),
        "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
            "Log at least two days to see your trend."),
        "diarySortByCarbs":
            MessageLookupByLibrary.simpleMessage("Carbs (high to low)"),
        "diarySortByFat":
            MessageLookupByLibrary.simpleMessage("Fat (high to low)"),
        "diarySortByKcal":
            MessageLookupByLibrary.simpleMessage("Calories (high to low)"),
        "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Sort by"),
        "diarySortByProtein":
            MessageLookupByLibrary.simpleMessage("Protein (high to low)"),
        "diarySortByTime": MessageLookupByLibrary.simpleMessage("Time added"),
        "profileTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Target weight"),
        "profileTargetWeightNotSetLabel":
            MessageLookupByLibrary.simpleMessage("Not set"),
        "profileTargetWeightClearAction":
            MessageLookupByLibrary.simpleMessage("Clear"),
        "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
            "You\'ve reached your target"),
        "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
            "Reduces the daily deficit gradually so the last few kg don\'t feel like a wall."),
        "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
            "Adjust calorie goal as you approach target"),
        "settingsTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Target weight"),
        "profileTargetWeightToGo": m21,
        "recipeImageLabel":
            MessageLookupByLibrary.simpleMessage("Add a photo"),
        "recipeImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Choose from gallery"),
        "recipeImageRemove":
            MessageLookupByLibrary.simpleMessage("Remove photo"),
        "recipeImageReplace":
            MessageLookupByLibrary.simpleMessage("Replace photo"),
        "mealImageLabel":
            MessageLookupByLibrary.simpleMessage("Add a photo"),
        "mealImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Choose from gallery"),
        "mealImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Take photo"),
        "mealImageRemove":
            MessageLookupByLibrary.simpleMessage("Remove photo"),
        "mealImageReplace":
            MessageLookupByLibrary.simpleMessage("Replace photo"),
        "recipeImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Take photo"),
        "mealPatternFiveSmall":
            MessageLookupByLibrary.simpleMessage("Five-small"),
        "mealPatternMediterranean":
            MessageLookupByLibrary.simpleMessage("Mediterranean"),
        "mealPatternOmad": MessageLookupByLibrary.simpleMessage("OMAD"),
        "mealPatternPresetsLabel":
            MessageLookupByLibrary.simpleMessage("Quick presets"),
        "mealPatternStandard":
            MessageLookupByLibrary.simpleMessage("Standard"),
        "mealPatternTwoMeal":
            MessageLookupByLibrary.simpleMessage("Two-meal"),
        "settingsPerMealKcalShareBreakfast":
            MessageLookupByLibrary.simpleMessage("Breakfast"),
        "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
            "Split your daily kcal goal across breakfast, lunch, dinner, and snacks. The shares must add up to 100%."),
        "settingsPerMealKcalShareDinner":
            MessageLookupByLibrary.simpleMessage("Dinner"),
        "settingsPerMealKcalShareLabel":
            MessageLookupByLibrary.simpleMessage("Per-meal kcal share"),
        "settingsPerMealKcalShareLunch":
            MessageLookupByLibrary.simpleMessage("Lunch"),
        "settingsPerMealKcalShareSnack":
            MessageLookupByLibrary.simpleMessage("Snack"),
        "diaryMealKcalConsumedOfTarget": m22,
      };
}
