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

  static String m0(sourceName) => "More Information at\n${sourceName}";

  static String m1(versionNumber) => "Version ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% carbs, ${pctFats}% fats, ${pctProteins}% proteins";

  static String m3(count, size) => "${count} item(s) · ${size}";

  static String m4(imported, skipped) =>
      "Imported ${imported} meal(s); ${skipped} row(s) were skipped due to invalid data.";

  static String m5(count) => "Imported ${count} meal(s).";

  static String m6(unit) => "${unit} in one serving";

  static String m7(loser, winner) =>
      "This will replace all entries logged with ${loser} so they show ${winner} instead, and remove ${loser} from your custom foods. This can\'t be undone.";

  static String m8(winner) => "Merged — ${winner} now has 1 logged entry.";

  static String m9(count, winner) =>
      "Merged — ${winner} now has ${count} logged entries.";

  static String m10(count) => "Delete ${count} recipe(s)?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "ref ${value}";

  static String m13(remaining) => "Fasting · ${remaining} left";

  static String m14(value) => "${value} remaining";

  static String m15(value) => "Target: ${value}";

  static String m16(count) => "Import ${count} activities?";

  static String m17(mealType) =>
      "These items will be added to your ${mealType}.";

  static String m18(count) => "Import ${count} items?";

  static String m19(count) =>
      "${count} item(s) could not be fetched from OpenFoodFacts.";

  static String m20(count) => "Import this recipe with ${count} ingredient(s)?";

  static String m21(amount) => "Add ${amount} ml";

  static String m22(threshold) =>
      "Most adults shouldn\'t eat fewer than ${threshold} kcal a day for any length of time without medical guidance. Please consider speaking with a healthcare professional before sticking with a target this low.";

  static String m23(kcal) => "(+${kcal} kcal current selection)";

  static String m24(consumed, goal) => "Day total: ${consumed} / ${goal}";

  static String m25(qty, unit) => "Per ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'bar', other: 'bars')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'bottle', other: 'bottles')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'can', other: 'cans')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'cup', other: 'cups')}";

  static String m30(count) =>
      "${Intl.plural(count, one: 'egg', other: 'eggs')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'package', other: 'packages')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'piece', other: 'pieces')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'portion', other: 'portions')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'serving', other: 'servings')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'slice', other: 'slices')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'tablespoon', other: 'tablespoons')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'teaspoon', other: 'teaspoons')}";

  static String m38(riskValue) => "Risk of comorbidities: ${riskValue}";

  static String m39(value) => "${value} to your target";

  static String m40(mealType) => "Added to ${mealType}";

  static String m41(count) => "${count} ingredient(s)";

  static String m42(count) => "${count} selected";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Reminder time: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/week";

  static String m48(rate) => "${rate} lbs/week";

  static String m49(age) => "${age} years";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "e.g. running, biking, yoga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Activity"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage("Add new Item:"),
    "addLabel": MessageLookupByLibrary.simpleMessage("Add"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Add profile"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Information provided\n by the \n\'2024 Compendium\n of Physical Activities\'",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Custom Meal Item",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "More Information at\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "More Information at\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Custom Recipe",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Unknown Meal Item",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Age"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("All"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker is a free and open-source calorie and nutrient tracker that respects your privacy.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("GPL-3.0 license"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "This 13-digit barcode looks miskeyed: its last digit doesn\'t match the rest",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Nutrition is per",
    ),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Body Mass Index (BMI) is a index to classify overweight and obesity in adults. It is defined as weight in kilograms divided by the square of height in meters (kg/m²).\n\nBMI does not differentiate between fat and muscle mass and can be misleading for some individuals.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "e.g. cereal, milk, coffee ...",
    ),
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
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(recommended)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Institute of Medicine Equation (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "TDEE equation",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Averaged reference (default)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Estrogen-typical reference",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "There isn\'t a published non-binary calorie baseline — the reference equations are built around male and female samples. We use an average of the two by default, a neutral starting point that doesn\'t ask you to disclose more about your body. The kcal slider in Settings is always available to fine-tune; this is a starting point, not a precise estimate.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Calorie reference",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Testosterone-typical reference"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("carbohydrate"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("carbs"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("c"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Weekly weight rate",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Choose Weight Goal",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Removes the locally cached search and scan results from Open Food Facts and FDC. The cache rebuilds automatically as you search and scan products. Your custom meals are not affected.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Clear cached items?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Clear cached items",
    ),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Code copied"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Meal copied to profile",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Copy code"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Which meal type do you want to copy to?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "With \"Copy to today\" you can copy the meal to today. With \"Delete\" you can delete the meal.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "What do you want to do?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Copy to profile",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Do you want create a custom meal item?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Create custom meal item?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage("Create Recipe"),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Have a barcode? Help everyone by contributing the product to Open Food Facts:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Could not read CSV file. Check the format and try again.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Enter calories burned directly, for workouts that aren\'t in the list or readings from a fitness tracker",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Enter kilojoules burned directly, for workouts that aren\'t in the list or readings from a fitness tracker",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("e.g. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Calories burned",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Custom activity",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "e.g. Evening bike commute",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Name (optional)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Pick from saved templates",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Save as template for next time",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "You haven\'t saved any templates yet. Tick \"Save as template for next time\" to remember a Custom activity for later.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Scan or type a barcode to recall this meal later",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Barcode must be 8 to 14 digits",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage("Barcode"),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Scan barcode",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage("Advanced"),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Set the sizes and per-100 values for precise scaling.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Form view",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Simple"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Type the totals for one serving.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "All diary entries using this meal will also be removed.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete custom meal?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "No custom meals saved yet.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Merge with another custom food",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Which one stays?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Merge",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Merge custom foods?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Continue",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Pick the custom food to merge with",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "More actions",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Daily Kcal adjustment:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Daily kJ adjustment:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Send anonymous crash reports to help fix bugs. No food log, weight, or personal data is included.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profile 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Delete all"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "This permanently deletes the profile and all of its data and cannot be undone.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete profile?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Do want to delete the selected item?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Do want to delete all items of this meal?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Delete Items?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Delete Item?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("CANCEL"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Close"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage("Copy to today"),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("DELETE"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "You are editing a future date",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Diary"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Only nutrients tracked on the meals you logged are summed here. A meal missing a value contributes nothing to that nutrient — so these totals may underreport.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Today\'s nutrients",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Carbs (high to low)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage("Fat (high to low)"),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Calories (high to low)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Sort by"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Protein (high to low)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Time added"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "e.g. soup, chicken, wine ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Dinner"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Discard",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Your unsaved changes will be lost.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Discard changes?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker is not a medical application. All data provided is not validated and should be used with caution. Please maintain a healthy lifestyle and consult a professional if you have any problems. Use during illness, pregnancy or lactation is not recommended. For the peer-reviewed sources behind each calculation, tap the info icon on the Home or Profile screen.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Sample meals (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Sample meals (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Sample recipes (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Sample recipes (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "These reference amounts come from the IOM Dietary Reference Intakes for adults and vary by age and gender. They\'re a point of reference, not a target — your own needs may differ.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Source: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Reference intake",
    ),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "This food has already been added to this meal today. Add it again?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage("(copy)"),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage("Edit item"),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Edit meal"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage("Edit profile"),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage("Edit Recipe"),
    "energyLabel": MessageLookupByLibrary.simpleMessage("energy"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("left"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("too much"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilocalories (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage(
      "Kilojoules (kJ)",
    ),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Error while fetching product data",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Error while loading activities",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Error while saving meal. Did you input the correct meal information?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Error while opening browser app",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Error while opening email app",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Product not found",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Export"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import App Data",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV keeps your activity, meal log and tracked days. Recipes and any photos you\'ve attached are JSON-only — switch to JSON if you want them in your backup.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "You can export the app data to a zip file and import it later. This is useful if you want to backup your data or transfer it to another device.\n\nThe app does not use any cloud service to store your data.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import error",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import successful",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("End fast"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "This will close the current session.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "End fast now?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage("Session complete"),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Elapsed"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "One-off pings when a fasting session reaches its target.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Fasting timer",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Your target time has been reached.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Fasting session complete",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Custom"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Start timer"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "A simple timer for tracking time between meals. No streaks, no targets, just the clock.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Fasting timer"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "I understand, enable timer",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Tracking fasting time can be helpful for some people and distressing for others, especially anyone with a history of disordered eating. If that\'s you, please look after yourself first. Support is available from BEAT (UK) and NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage("Not for me"),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Before you start",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("fat"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("f"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("fiber"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Always enabled",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Search results come from these food databases. Open Food Facts powers the product and barcode search and is always enabled.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("female"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Gender"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("male"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("non-binary"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Gain Weight"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Goal"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Lose Weight"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage(
      "Maintain Weight",
    ),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Height"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Tap + to log your first meal or activity",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Home"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("hours"),
    "importAction": MessageLookupByLibrary.simpleMessage("Import"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "These activities will be added to today.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Import shared workout",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Workout imported",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Import your own meals from a CSV file or by pasting JSON. Download a sample to see the expected shape and required fields.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Import Custom Food Data",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Invalid QR code",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Import shared meal",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Meal imported",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Import meals (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Import meals (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Could not parse recipe code",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage("Import recipe"),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Recipe imported",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Import recipes (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Import recipes (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "These values don\'t quite line up — the calories you\'ve entered don\'t match the energy in the carbs, fat and protein below. Save anyway, or take a second look?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Take another look",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Save anyway"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Numbers don\'t quite line up",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Added new activity",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Added new intake",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("iron"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage("Item deleted"),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage("Item updated"),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal left"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal too much"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Log water intake",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Nothing to undo",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage("Undo last"),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "This daily target is on the low side",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "View disclaimer",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "e.g. pizza, salad, rice ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Lunch"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Name translated automatically",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Macronutrient Distribution:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnesium"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Manage profiles",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Brands"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Carbohydrates"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energy"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Fat"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Add a photo"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Choose from gallery",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Remove photo"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage("Replace photo"),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage("Take photo"),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Meal name"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Meal name must contain at least one letter",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Total amount",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("Five-small"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Mediterranean",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("OMAD"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Quick presets",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Standard"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("Two-meal"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Protein"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Pack size"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Pack size (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Meal unit"),
    "measureUnitBar": m26,
    "measureUnitBottle": m27,
    "measureUnitCan": m28,
    "measureUnitCup": m29,
    "measureUnitEgg": m30,
    "measureUnitPackage": m31,
    "measureUnitPiece": m32,
    "measureUnitPortion": m33,
    "measureUnitServing": m34,
    "measureUnitSlice": m35,
    "measureUnitTablespoon": m36,
    "measureUnitTeaspoon": m37,
    "micronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Micronutrients",
    ),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "Product missing required kcal or macronutrients information",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "monounsaturated fat",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "New Custom Food",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("niacin (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "No activity recently added",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "No meals recently added",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage("No results found"),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/A"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("Nothing added"),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Don\'t forget to log your meals today!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage("Daily meal logging reminder"),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Daily Reminders"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Notification permission denied.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "All nutrients hidden — turn some on in Settings → Nutrients.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Day"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("limit"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Week"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Nutrition Information",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Normal Weight",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Obesity Class I",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Obesity Class II",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Obesity Class III",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Pre-obesity",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Average",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Increased",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Low \n(but risk of other \nclinical problems increased)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Moderate",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Severe",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Very severe",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Underweight",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "The data provided to you by this app are retrieved from the Open Food Facts database. No guarantees can be made for the accuracy, completeness, or reliability of the information provided. The data are provided \"as is\" and the originating source for the data (Open Food Facts) is not liable for any damages arising out of the use of the data.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "How active are you? (without workouts)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Enter Date",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "When is your birthday?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Birthday",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "How you log food and drinks",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "What\'s your gender?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "What\'s your current weight goal?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "e.g. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "e.g. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "What\'s your current height?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "To start, the app needs some information about you to calculate your daily calorie goal.\nAll information about you is stored securely on your device.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Read our medical calculation sources",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kcal per day",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kJ per day",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "There\'s no published non-binary calorie baseline, so by default we use an average of the male and female formulas — a starting point, not a precise estimate. You can fine-tune anytime in Settings → Calculations.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Other options",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Personalize the app — you can change everything later in Settings",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage("Overview"),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Wrong input, please try again",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Optional",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Is there a weight you\'re working towards? You can leave this blank or change it later in Profile.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "e.g. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "e.g. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "What\'s your current weight?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage(
      "Welcome to",
    ),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Enter correct height",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Enter correct weight",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Your calorie goal:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Your macronutrient goals:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "active video games",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, general",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "football",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "touch, flag, general",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("archery"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage("non-hunting"),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("auto racing"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("open wheel"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage("backpacking"),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "social singles and doubles, general",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("basketball"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("bicycling"),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "bicycling, mountain",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "general",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "bicycling, stationary",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "general",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("billiards"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("boxing"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("punching bag"),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boxing"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "in ring, general",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "calisthenics",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "light or moderate effort, general (e.g., back exercises)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("canoeing"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rowing, for pleasure, general",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("football or baseball"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("playing catch"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "gymnastic moves, competitive",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("children\'s games"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(e.g., hopscotch, 4-square, dodgeball, playground apparatus, t-ball, tetherball, marbles, arcade games), moderate effort",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "climbing hills, no load",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "no load",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("cricket"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "batting, bowling, fielding",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("croquet"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "cross-country skiing",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "cross-country, general",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("aerobic"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "general",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("general dancing"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "e.g. disco, folk, Irish step dancing, line dancing, polka, contra, country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("darts"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage("wall or lawn"),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("diving"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "skindiving, scuba diving, general",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "diving",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "springboard or platform",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("fencing"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee playing"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("gymnastics"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("handball"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("hang gliding"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("bicycling"),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "conditioning exercise",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("dancing"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("running"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("sports"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("walking"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "water activities",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "winter activities",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "high intensity interval exercise",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "moderate effort",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "high intensity interval exercise",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "burpees, mountain climbers, squat jumps, Tabata, vigorous effort",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("hiking"),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "cross country",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("hockey, field"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage(
      "horseback riding",
    ),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage("ice hockey"),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage("ice skating"),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("juggling"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kayaking"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "moderate effort",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("lawn bowling"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "bocce ball, outdoor",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "martial arts",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "different types, moderate pace (e.g., judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage("martial arts"),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "different types, slower pace, novice performers, practice",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-cross"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "off-road motor sports, all-terrain vehicle, general",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("climbing"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "rock or mountain climbing",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("nordic walking"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("orienteering"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("paddle boarding"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("standing"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("paddle boat"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage("casual, general"),
    "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("on horseback"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "resistance training",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "weight lifting, free weight, nautilus or universal",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "resistance training (vigorous)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "vigorous effort, powerlifting or bodybuilding",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "rodeo sports",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "general, moderate effort",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage(
      "rollerblading",
    ),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "in-line skating",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "rope jumping",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "moderate pace, 100-120 skips/min, general, 2 foot skip, plain bounce",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "rope skipping",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "general",
    ),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "union, team, competitive",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "touch, non-competitive",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("running"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("sailing"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "boat and board sailing, windsurfing, ice sailing, general",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "skateboarding",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "general, moderate effort",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage("roller skating"),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("skiing"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "water skiing",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "water or wakeboarding",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("skydiving"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "skydiving, base jumping, bungee jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("snorkeling"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "snow shoveling",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "by hand, moderate effort",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage("snowshoeing"),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("soccer"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "casual, general",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "softball / baseball",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "fast or slow pitch, general",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paStretching": MessageLookupByLibrary.simpleMessage("stretching"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage("mild, general"),
    "paSurfing": MessageLookupByLibrary.simpleMessage("surfing"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "body or board, general",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("swimming"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "treading water, moderate effort, general",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage(
      "table tennis",
    ),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "table tennis, ping pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "tai chi, qi gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "general",
    ),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tennis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("track and field"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(e.g. shot, discus, hammer throw)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(e.g. high jump, long jump, triple jump, javelin, pole vault)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(e.g. steeplechase, hurdles)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampoline"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage(
      "recreational",
    ),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "running on treadmill",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "on treadmill, general",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("unicycling"),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("volleyball"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "non-competitive, 6 - 9 member team, general",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("walking"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "for pleasure",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("walking the dog"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("water exercise"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "water aerobics, water calisthenics",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("water polo"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage(
      "water volleyball",
    ),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("general"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "water aerobics",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "water aerobics, water calisthenics",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("general"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Mostly standing or walking in job and active free time activities",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Active"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "e.g. sitting or standing in job and light free time activities",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Low Active"),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "e.g. office job and mostly sitting free time activities",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sedentary"),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Mostly walking, running or carrying weight in job and active free time activities",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Very Active"),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Paste the shared meal code here",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Paste code"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Per 100g/ml"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Per Serving"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("phosphorus"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "polyunsaturated fat",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("potassium"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Privacy policy",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Active"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage(
      "Fasting timer",
    ),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage("Add a photo"),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage("Remove photo"),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage("Change photo"),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Profile name"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Name"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Clear",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Target weight",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Not set",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "You\'ve reached your target",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Weight history",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("protein"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantity"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Activity added",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Duration (min, optional)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energy burned (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energy burned (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Name (optional)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Quick add activity",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Quick add",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Carbs (g, optional)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage("Quick add"),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage("Quick add"),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energy (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energy (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Fat (g, optional)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Protein (g, optional)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Add"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Title"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "I have read and accept the privacy policy.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Recently"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Add Ingredient",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Past diary entries logged from this recipe will be kept.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete recipe?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Description (optional)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage("Add a photo"),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Choose from gallery",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage("Remove photo"),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage("Replace photo"),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage("Take photo"),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Amount",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage("Unit"),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Ingredients",
    ),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Total weight must be greater than zero",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Log this Recipe",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Recipe name"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Recipe needs a name",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Add at least one ingredient",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "No ingredients yet",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "Per 100 g",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Nutrition (total)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Could not save recipe.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Turn this on to keep this meal in your saved list for next time. Leave it off for a one-off you won\'t eat again.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Save for next time",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Save Recipe"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Lets you log this recipe by serving instead of grams.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Servings (optional)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Comma-separated, e.g. \"breakfast, vegan\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tags"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Defaults to sum of ingredients. Liquids approximated as 1 ml ≈ 1 g.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Total weight (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Build a meal from multiple ingredients and reuse it like any other food.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage("No recipes yet"),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("All"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Recipes"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Could not load recipes. Try again later.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Do you want to report an error to the developer?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Retry"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("saturated fat"),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage("Scan Product"),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Lock to portrait",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Type code manually",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Enter barcode",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "8 to 14 digits",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "That barcode doesn\'t look valid. Please check the digits and try again.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage("Look up"),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Allow rotation",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Please enter a search word",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Food"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Search"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Products"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Search results",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Select Gender",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Select Height",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Select Activity Level",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Select Weight",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Send anonymous usage data",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Serving"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "One serving (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "One serving",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("About"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Feedback"),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Accent colour",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Custom colour…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Open the hue picker for a precise choice",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "That hex code doesn’t look right — six digits, 0-9 and A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex code"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Turn off system colours to choose a custom accent.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Reset"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Accent colour",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Pick a colour",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Custom",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Default",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Body weight unit",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily calcium target in milligrams. Default reference is 1000mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Calcium goal",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Reduces the daily deficit gradually so the last few kg don\'t feel like a wall.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Adjust calorie goal as you approach target",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage("About"),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Appearance",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Data"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage("Display"),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Goals & nutrition",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Units & energy",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Custom Meals",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Choose the hour at which your day begins. Meals and activities logged before this hour count toward the previous day — useful if you work nights or eat late.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Hours",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Day starts at",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Minutes",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Delete everything",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "This permanently removes your profile, meals, activities, weight history and any custom recipes from this device. The Open Food Facts and USDA Food Data Central catalogues are not affected. This cannot be undone.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete all your data?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Delete all my data",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profile, meals, activities and weight history",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Disclaimer",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Distance"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Energy unit",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily fibre target in grams. Default reference is 30g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Fibre goal",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Food databases",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Choose where food search results come from",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperial (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Food units",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metric (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperial (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Height units",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metric (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Imperial (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily iron target in milligrams. Default varies by gender (8mg male, 18mg female, 14mg otherwise).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage("Iron goal"),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Daily kcal adjustment",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Language"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Licenses"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Macro split",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily magnesium target in milligrams. Default varies by gender (400mg male, 310mg female, 355mg otherwise).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Magnesium goal",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Mass"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Match your wallpaper accent on Android 12 and newer.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Use system colours",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metric (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Daily Reminder",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Personal targets for every nutrient on the daily panel. The diary uses these in place of the default daily references whenever you set one.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Nutrient goals",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Choose which nutrients are visible on the daily panel. Hidden ones can be turned back on at any time.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage("Nutrients"),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Pick which nutrients appear on the diary panel",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Breakfast",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Split your daily kcal goal across breakfast, lunch, dinner, and snacks. The shares must add up to 100%.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Dinner",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Per-meal kcal share",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Lunch",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Snack",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily potassium target in milligrams. Default reference is 3500mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Potassium goal",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Privacy Settings",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Report Error",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily saturated fat cap in grams. Default reference is 20g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Saturated fat goal",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Show Activity Tracking",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Show Meal Macros",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Show Micronutrients",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily sodium cap in milligrams. Default reference is 2300mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Sodium goal",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Source Code",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Sources & References",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily sugars cap in grams. Default reference is 50g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Sugars goal",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("System"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Dark"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Theme"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Light"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "System default",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Units"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily vitamin B12 target in micrograms. Default reference is 2.4µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vitamin B12 goal",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Daily vitamin D target in micrograms. Default reference is 15µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vitamin D goal",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Used by the water chip on the home screen.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Daily water goal",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage("Share workout"),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Share code"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage("Share recipe"),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "e.g. apple, ice cream, chocolate ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Snack"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodium"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Calories burned during an activity are estimated as MET × body weight (kg) × duration (hours), using values from the Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Activity calories (MET values)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "BMI is computed as weight (kg) divided by height squared (m²). The health categories (underweight, normal, pre-obesity, obesity class I–III) follow the World Health Organization\'s adult BMI classification.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Body Mass Index (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Daily calorie targets, basal metabolic rate, and physical activity coefficients use the equations from the Institute of Medicine. Source: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Chapter 5 and Table 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Energy needs (TDEE, BMR & activity level)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage("View sources"),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "The default split of 60% carbohydrates, 25% fat, and 15% protein falls within the population nutrient intake ranges published by the WHO. You can adjust this in Settings → Calculations. Source: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Macronutrient distribution",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Energy-expenditure research has historically used binary sex categories, so there is no single validated TDEE formula for non-binary people. OpenNutriTracker therefore lets you choose between an averaged reference, an estrogen-typical reference, or a testosterone-typical reference under Settings → Calculations. If an accurate number genuinely matters for your care, please speak to a clinician familiar with your hormone status.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Non-binary calorie estimation",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Daily reference amounts shown on the diary nutrient panel come from the Institute of Medicine\'s Dietary Reference Intakes summary, which covers per-nutrient targets for adults.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Nutrient reference intakes",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "View source",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker uses well-established, peer-reviewed methodologies for every calculation it shows. The citations below link to the original sources so you can verify any number yourself.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("sugar"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("supplied"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Switch profile",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("trans fat"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("best"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Calories"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Daily average",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage("day streak"),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "days on track this week",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Trends"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/week"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Water"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "weeks to goal",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Unit"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamin A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamin B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamin B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamin C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamin D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Warning"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Weekly rate",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Not set",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage("Add entry"),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Log at least two days to see your trend.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Date"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "No weight readings yet. Add your first one to start tracking a trend.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Note (optional)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage("Weight"),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Weight"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("You"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("zinc"),
  };
}
