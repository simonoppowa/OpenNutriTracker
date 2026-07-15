// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de locale. All the
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
  String get localeName => 'de';

  static String m0(sourceName) => "Weitere Informationen unter\n${sourceName}";

  static String m1(versionNumber) => "Version ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% Kohlenhydrate, ${pctFats}% Fette, ${pctProteins}% Proteine";

  static String m3(count, size) => "${count} Eintrag/Einträge · ${size}";

  static String m4(imported, skipped) =>
      "${imported} Mahlzeit(en) importiert; ${skipped} Zeile(n) wegen ungültiger Daten übersprungen.";

  static String m5(count) => "${count} Mahlzeit(en) importiert.";

  static String m6(unit) => "${unit} pro Portion";

  static String m7(loser, winner) =>
      "Dadurch werden alle Einträge, die mit ${loser} protokolliert wurden, ersetzt, sodass sie ${winner} anzeigen. Außerdem wird ${loser} aus deinen eigenen Mahlzeiten entfernt. Das kann nicht rückgängig gemacht werden.";

  static String m8(winner) =>
      "Zusammengeführt — ${winner} hat jetzt 1 Eintrag.";

  static String m9(count, winner) =>
      "Zusammengeführt — ${winner} hat jetzt ${count} Einträge.";

  static String m10(count) => "${count} Rezept(e) löschen?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "Ref. ${value}";

  static String m13(remaining) => "Fasten · noch ${remaining}";

  static String m14(value) => "Noch ${value}";

  static String m15(value) => "Ziel: ${value}";

  static String m16(count) => "${count} Aktivitäten importieren?";

  static String m17(mealType) =>
      "Diese Einträge werden zu ${mealType} hinzugefügt.";

  static String m18(count) => "${count} Einträge importieren?";

  static String m19(count) =>
      "${count} Einträge konnten nicht von OpenFoodFacts abgerufen werden.";

  static String m20(count) =>
      "Dieses Rezept mit ${count} Zutat(en) importieren?";

  static String m21(amount) => "${amount} ml hinzufügen";

  static String m22(threshold) =>
      "Erwachsene sollten ohne ärztliche Begleitung dauerhaft nicht weniger als ${threshold} kcal pro Tag zu sich nehmen. Bitte überlege, ob du vor einem so niedrigen Ziel mit einer medizinischen Fachperson sprichst.";

  static String m23(kcal) => "(+${kcal} kcal aktuelle Auswahl)";

  static String m24(consumed, goal) => "Tagessumme: ${consumed} / ${goal}";

  static String m25(qty, unit) => "Pro ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'Riegel', other: 'Riegel')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'Flasche', other: 'Flaschen')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'Dose', other: 'Dosen')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'Tasse', other: 'Tassen')}";

  static String m30(count) => "${Intl.plural(count, one: 'Ei', other: 'Eier')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'Packung', other: 'Packungen')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'Stück', other: 'Stück')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'Portion', other: 'Portionen')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'Portion', other: 'Portionen')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'Scheibe', other: 'Scheiben')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'Esslöffel', other: 'Esslöffel')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'Teelöffel', other: 'Teelöffel')}";

  static String m38(riskValue) =>
      "Risiko für Begleiterkrankungen: ${riskValue}";

  static String m39(value) => "Noch ${value} bis zum Ziel";

  static String m40(mealType) => "Zu ${mealType} hinzugefügt";

  static String m41(count) => "${count} Zutat(en)";

  static String m42(count) => "${count} ausgewählt";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Erinnerungszeit: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/Woche";

  static String m48(rate) => "${rate} lbs/Woche";

  static String m49(age) => "${age} Jahre";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "z. B. Laufen, Radfahren, Yoga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Aktivität"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage(
      "Neuen Eintrag hinzufügen:",
    ),
    "addLabel": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Profil hinzufügen",
    ),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Informationen bereitgestellt von\n\'2024 Compendium\n of Physical Activities\'",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Benutzerdefinierte Mahlzeit",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Weitere Informationen unter\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Weitere Informationen unter\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Benutzerdefiniertes Rezept",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Unbekannte Mahlzeit",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Alter"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Alle"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker ist ein kostenloser und  quelloffener Kalorien- und Nährstofftracker, der Ihre Privatsphäre respektiert.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("GPL-3.0 Lizenz"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Dieser 13-stellige Barcode scheint einen Tippfehler zu haben: die letzte Ziffer passt nicht zu den übrigen",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage("Nährwerte pro"),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Der Body-Mass-Index (BMI) ist ein Index zur Klassifizierung von Übergewicht und Fettleibigkeit bei Erwachsenen. Er wird berechnet, indem das Gewicht in Kilogramm durch das Quadrat der Körpergröße in Metern (kg/m²) geteilt wird.\n\nDer BMI unterscheidet nicht zwischen Fett- und Muskelmasse und kann für einige Personen irreführend sein.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "z. B. Müsli, Milch, Kaffee ...",
    ),
    "breakfastLabel": MessageLookupByLibrary.simpleMessage("Frühstück"),
    "burnedLabel": MessageLookupByLibrary.simpleMessage("verbrannt"),
    "buttonNextLabel": MessageLookupByLibrary.simpleMessage("WEITER"),
    "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Zurücksetzen"),
    "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Speichern"),
    "buttonStartLabel": MessageLookupByLibrary.simpleMessage("START"),
    "buttonYesLabel": MessageLookupByLibrary.simpleMessage("JA"),
    "calciumLabel": MessageLookupByLibrary.simpleMessage("Calcium"),
    "calculationsMacronutrientsDistributionLabel":
        MessageLookupByLibrary.simpleMessage("Verteilung der Makronährstoffe"),
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(empfohlen)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Institute of Medicine Gleichung (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "TDEE-Gleichung",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Gemittelte Referenz (Standard)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Östrogen-typische Referenz",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Es gibt keine veröffentlichte Kalorien-Grundlage für nicht-binäre Personen — die Referenzgleichungen basieren auf männlichen und weiblichen Stichproben. Wir verwenden standardmäßig den Mittelwert beider, einen neutralen Ausgangspunkt, der nichts Genaueres über deinen Körper verlangt. Der kcal-Schieberegler in den Einstellungen steht jederzeit zur Feinabstimmung zur Verfügung; dies ist ein Ausgangspunkt, keine genaue Schätzung.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Kalorienreferenz",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Testosteron-typische Referenz"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("Kohlenhydrate"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("Kohlenhydrate"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("k"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("Cholesterin"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Wöchentliche Gewichtsrate",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Gewichtsziel wählen",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Entfernt die lokal zwischengespeicherten Such- und Scan-Ergebnisse von Open Food Facts und FDC. Der Cache wird beim Suchen und Scannen automatisch neu aufgebaut. Deine eigenen Mahlzeiten sind nicht betroffen.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Cache leeren?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage("Cache leeren"),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Code kopiert"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Mahlzeit ins Profil kopiert",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Kopieren"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Code kopieren"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zu welcher Mahlzeit hinzufügen?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Auf \"Nach heute kopieren\" klicken, um die Mahlzeit nach heute zu kopieren. Mit \"Löschen\" kann die Mahlzeit entfernt werden",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Was soll getan werden?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "In Profil kopieren",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Möchten Sie einen benutzerdefinierte Mahlzeit erstellen?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Benutzerdefinierte Mahlzeit erstellen?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage(
      "Rezept erstellen",
    ),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Barcode dabei? Trag das Produkt zu Open Food Facts bei:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "CSV-Datei konnte nicht gelesen werden. Format prüfen und erneut versuchen.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Trage verbrannte Kalorien direkt ein – für Trainings, die nicht in der Liste sind, oder Werte aus einem Fitnesstracker",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Trage verbrannte Kilojoule direkt ein – für Trainings, die nicht in der Liste sind, oder Werte aus einem Fitnesstracker",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("z. B. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Verbrannte Kalorien",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Eigene Aktivität",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "z. B. Fahrt nach Hause",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Name (optional)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Aus gespeicherten Vorlagen wählen",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Als Vorlage für später speichern",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Du hast noch keine Vorlagen gespeichert. Setze das Häkchen bei „Als Vorlage für später speichern“, um eine eigene Aktivität für die Zukunft zu merken.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Scanne oder gib einen Barcode ein, um diese Mahlzeit später wiederzufinden",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Der Barcode muss 8 bis 14 Ziffern haben",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage("Barcode"),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Barcode scannen",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage("Erweitert"),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Größen und Werte pro 100 für genaue Skalierung festlegen.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Formularansicht",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Einfach"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Gib die Gesamtwerte für eine Portion ein.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Alle Tagebucheinträge, die diese Mahlzeit verwenden, werden ebenfalls entfernt.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eigene Mahlzeit löschen?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Noch keine eigenen Mahlzeiten gespeichert.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Mit einer anderen eigenen Mahlzeit zusammenführen",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Welche bleibt?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Zusammenführen",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eigene Mahlzeiten zusammenführen?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Weiter",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Wähle die eigene Mahlzeit zum Zusammenführen",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Weitere Aktionen",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Tägliche kcal-Anpassung:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Tägliche kJ-Anpassung:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Anonyme Absturzberichte senden, um bei der Fehlerbehebung zu helfen. Es werden keine Ernährungsdaten, Gewichtsdaten oder persönlichen Daten übermittelt.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profil 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Alle löschen"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Dadurch werden das Profil und alle seine Daten dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Profil löschen?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Möchten Sie den ausgewählten Eintrag löschen?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Möchten Sie alle Einträge dieser Mahlzeit löschen?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Einträge löschen?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Eintrag löschen?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ABBRECHEN"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Schließen"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage(
      "Nach heute kopieren",
    ),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("LÖSCHEN"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Du bearbeitest ein zukünftiges Datum",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Tagebuch"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Hier werden nur Nährstoffe summiert, die auf deinen protokollierten Mahlzeiten erfasst sind. Eine Mahlzeit ohne einen Wert trägt nichts zu diesem Nährstoff bei — die Summen können also zu niedrig sein.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Heutige Nährstoffe",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Kohlenhydrate (absteigend)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage("Fett (absteigend)"),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Kalorien (absteigend)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Sortieren nach"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Protein (absteigend)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Hinzugefügt am"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "z. B. Suppe, Hähnchen, Wein ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Abendessen"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Verwerfen",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Deine ungespeicherten Änderungen gehen verloren.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Änderungen verwerfen?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker ist keine medizinische Anwendung. Alle bereitgestellten Daten sind nicht validiert und sollten mit Vorsicht verwendet werden. Bitte pflegen Sie einen gesunden Lebensstil und konsultieren Sie einen Fachmann, wenn Sie Probleme haben. Die Verwendung während einer Krankheit, Schwangerschaft oder Stillzeit wird nicht empfohlen.\n\n\nDie Anwendung befindet sich noch in der Entwicklung. Fehler, Bugs und Abstürze können auftreten.\n\nDie peer-reviewed Quellen zu jeder Berechnung findest du über das Info-Symbol auf der Start- oder Profilseite.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Beispiel-Mahlzeiten (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Beispiel-Mahlzeiten (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Beispiel-Rezepte (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Beispiel-Rezepte (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Diese Referenzwerte stammen aus den IOM-Empfehlungen zur Nährstoffzufuhr für Erwachsene und hängen von Alter und Geschlecht ab. Sie dienen als Orientierung, nicht als Vorgabe — dein eigener Bedarf kann abweichen.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Quelle: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage("Referenzzufuhr"),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Dieses Lebensmittel wurde heute bereits zu dieser Mahlzeit hinzugefügt. Erneut hinzufügen?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Duplizieren"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(Kopie)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Eintrag aktualisieren",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage(
      "Mahlzeit bearbeiten",
    ),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage(
      "Profil bearbeiten",
    ),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage(
      "Rezept bearbeiten",
    ),
    "energyLabel": MessageLookupByLibrary.simpleMessage("Energie"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("übrig"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("zu viel"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilokalorien (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage("Kilojoule (kJ)"),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Abrufen von Produktinformationen",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Laden von Aktivitäten",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Speichern der Mahlzeit. Haben Sie die korrekten Mahlzeiteninformationen eingegeben?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Öffnen der Browser-Anwendung",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Öffnen der E-Mail-Anwendung",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Produkt nicht gefunden",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Exportieren"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "App-Daten exportieren / importieren",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV speichert Aktivitäten, das Essensprotokoll und protokollierte Tage. Rezepte und angehängte Fotos werden nur in JSON gesichert — wähle JSON, wenn du sie im Backup behalten möchtest.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Sie können die App-Daten in eine Zip-Datei exportieren und später importieren. Dies ist nützlich, wenn Sie Ihre Daten sichern oder auf ein anderes Gerät übertragen möchten.\n\nDie App nutzt keinen Cloud-Dienst, um Ihre Daten zu speichern.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Export/Import",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import erfolgreich",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Fasten beenden"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Damit wird die aktuelle Sitzung geschlossen.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Fasten jetzt beenden?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage(
      "Sitzung abgeschlossen",
    ),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Vergangen"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Einmalige Hinweise, wenn eine Fastenphase ihr Ziel erreicht.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Fasten-Timer",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Deine Zielzeit wurde erreicht.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Fastenzeit abgeschlossen",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Eigene Dauer"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Timer starten"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ein einfacher Timer für die Zeit zwischen den Mahlzeiten. Keine Serien, keine Ziele, nur die Uhr.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Fasten-Timer"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Verstanden, Timer aktivieren",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Das Verfolgen von Fastenzeiten kann für manche hilfreich und für andere belastend sein, besonders wenn eine Essstörung Teil deiner Geschichte ist. Bitte achte zuerst auf dich. Unterstützung findest du bei BEAT (UK) und NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "Nichts für mich",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Bevor du beginnst",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("Fett"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("f"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("Ballaststoffe"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Immer aktiviert",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Suchergebnisse stammen aus diesen Lebensmitteldatenbanken. Open Food Facts liefert die Produkt- und Barcode-Suche und ist immer aktiviert.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("weiblich"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Geschlecht"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("männlich"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("nicht-binär"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Gewicht zunehmen"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Ziel"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Gewicht verlieren"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage(
      "Gewicht halten",
    ),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Größe"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Tippe auf +, um deine erste Mahlzeit oder Aktivität zu erfassen",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Startseite"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("Stunden"),
    "importAction": MessageLookupByLibrary.simpleMessage("Importieren"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Diese Aktivitäten werden zu heute hinzugefügt.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Geteiltes Training importieren",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Training importiert",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Importiere eigene Mahlzeiten aus einer CSV-Datei oder durch Einfügen von JSON. Lade eine Beispieldatei herunter, um die erwartete Form und Pflichtfelder zu sehen.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Eigene Lebensmittel-Daten importieren",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Ungültiger QR-Code",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Geteilte Mahlzeit importieren",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Mahlzeit importiert",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Mahlzeiten importieren (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Mahlzeiten importieren (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Rezept-Code konnte nicht gelesen werden",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Rezept importieren",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Rezept importiert",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Rezepte importieren (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Rezepte importieren (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Diese Werte passen nicht ganz zusammen — die eingegebenen Kalorien stimmen nicht mit der Energie aus Kohlenhydraten, Fett und Eiweiß überein. Trotzdem speichern oder noch einmal nachsehen?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Noch einmal nachsehen",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Trotzdem speichern"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Die Zahlen passen nicht ganz zusammen",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Neue Aktivität hinzugefügt",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Neue Aufnahme hinzugefügt",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("Eisen"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Eintrag gelöscht",
    ),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Eintrag aktualisiert",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal übrig"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal zu viel"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Wasseraufnahme erfassen",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Nichts zurückzunehmen",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Letzten zurücknehmen",
    ),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Dieses Tagesziel ist eher niedrig",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Hinweis anzeigen",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "z. B. Pizza, Salat, Reis ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Mittagessen"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Name automatisch übersetzt",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Makronährstoff-Verteilung:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("Magnesium"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Profile verwalten",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marken"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Kohlenhydrate"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energie"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Fett"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Foto hinzufügen"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Aus Galerie wählen",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Foto entfernen"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage("Foto ersetzen"),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Foto aufnehmen",
    ),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Mahlzeitenname"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Mahlzeitenname muss mindestens einen Buchstaben enthalten",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Gesamtmenge",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("5 kleine"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Mediterran",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("1 Mahlzeit"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Schnellvorlagen",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Standard"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("2 Mahlzeiten"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Protein"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Packungsgröße"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Packungsgröße (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Mahlzeiteinheit"),
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
      "Mikronährstoffe",
    ),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "Produkt fehlen die erforderlichen Angaben zu Kalorien oder Makronährstoffen",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "einfach ungesättigte Fettsäuren",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Neues benutzerdefiniertes Lebensmittel",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("Niacin (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Keine kürzlich hinzugefügten Aktivitäten",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Keine kürzlich hinzugefügten Mahlzeiten",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Keine Ergebnisse gefunden",
    ),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/A"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Nichts hinzugefügt",
    ),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Vergiss nicht, heute deine Mahlzeiten zu protokollieren!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Tägliche Erinnerung zum Erfassen deiner Mahlzeiten",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Tägliche Erinnerungen"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Benachrichtigungsberechtigung verweigert.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Alle Nährstoffe ausgeblendet — schalte einige unter Einstellungen → Nährstoffe ein.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Tag"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("Limit"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Woche"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Nährwertangaben",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Normales Gewicht",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Fettleibigkeit Klasse I",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Fettleibigkeit Klasse II",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Fettleibigkeit Klasse III",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Prä-Adipositas",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Durchschnittlich",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Erhöht",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Niedrig \n(aber erhöhtes Risiko für andere \nklinische Probleme)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Mäßig",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Schwerwiegend",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Sehr schwerwiegend",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Untergewicht",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Die Daten, die Ihnen mit dieser App zur Verfügung gestellt werden, stammen aus der Open Food Facts-Datenbank. Es kann keine Garantie für die Richtigkeit, Vollständigkeit oder Zuverlässigkeit der bereitgestellten Informationen übernommen werden. Die Daten werden ohne Mängelgewähr zur Verfügung gestellt, und die Ursprungsquelle der Daten (Open Food Facts) haftet nicht für Schäden, die aus der Verwendung der Daten entstehen.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wie aktiv sind Sie? (Ohne Trainingseinheiten)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Datum eingeben",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wann haben Sie Geburtstag?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Geburtstag",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wie du Essen und Getränke erfasst",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Was ist Ihr Geschlecht?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Was ist Ihr aktuelles Gewichtsziel?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "z. B. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "z. B. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wie groß sind Sie derzeit?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Um loszulegen, benötigt die App einige Informationen über Sie, um Ihr tägliches Kalorienziel zu berechnen. Alle Informationen über Sie werden sicher auf Ihrem Gerät gespeichert.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Quellen unserer medizinischen Berechnungen ansehen",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kcal pro Tag",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kJ pro Tag",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Es gibt keine veröffentlichte Kalorien-Grundlage für nicht-binäre Personen. Wir verwenden standardmäßig einen Mittelwert der männlichen und weiblichen Formeln — ein Ausgangspunkt, keine genaue Schätzung. Du kannst dies jederzeit unter Einstellungen → Berechnungen anpassen.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Weitere Optionen",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Personalisiere die App — alles lässt sich später in den Einstellungen ändern",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage(
      "Übersicht",
    ),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Falsche Eingabe, bitte versuchen Sie es erneut",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Optional",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Gibt es ein Gewicht, auf das du hinarbeitest? Du kannst das Feld leer lassen oder es später im Profil ändern.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "z. B. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "z. B. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wie viel wiegen Sie derzeit?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage(
      "Willkommen bei",
    ),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Geben Sie eine korrekte Größe ein",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Geben Sie ein korrekte Gewicht ein",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ihr Kalorienziel:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ihr Ziel für Makronährstoffe:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "aktive Videospiele",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, allgemein",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "American Football",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Touch, Flag, allgemein",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("Bogenschießen"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage("keine Jagd"),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("Autorennen"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("offene Räder"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage(
      "Wandern mit Rucksack",
    ),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("Badminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "gesellige Einzel- und Doppelspiele, allgemein",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("Basketball"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("Radfahren"),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "Mountainbiking",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "Stationäres Radfahren",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("Billard"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("Bowling"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("Boxen"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("Boxsack"),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("Boxen"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "im Ring, allgemein",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("Broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "Calisthenics",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "leichte oder mäßige Anstrengung, allgemein (z.B. Rückenübungen)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("Kanufahren"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rudern, zum Vergnügen, allgemein",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("Football oder Baseball"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("Fangen spielen"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("Cheerleading"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "gymnastische Übungen, Wettkampf",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("Kinderspiele"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(z.B. Himmel und Hölle, Vier gewinnt, Völkerball, Spielplatzgeräte, T-Ball, Leitball, Murmeln, Arcade-Spiele), mäßige Anstrengung",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "Hügelklettern ohne Last",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "keine Last",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("Cricket"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "Schlagen, Werfen, Feldarbeit",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("Croquet"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage("Skilanglauf"),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "Langlauf, allgemein",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("Curling"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("Aerobic"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage(
      "allgemeines Tanzen",
    ),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "z.B. Disco, Folk, irischer Stepptanz, Line Dance, Polka, Contra, Country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("Darts"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage("Wand oder Rasen"),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("Tauchen"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Gerätetauchen, Sporttauchen, allgemein",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "Tauchen",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "Sprungbrett oder Plattform",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("Fechten"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("Frisbee spielen"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("Golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("Gymnastik"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paHackySack": MessageLookupByLibrary.simpleMessage("Hacky Sack"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("Handball"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("Drachenfliegen"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("Radfahren"),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "Konditionstraining",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("Tanzen"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("Laufen"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("Sport"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("Gehen"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "Wassersport",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "Winteraktivitäten",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "hochintensives Intervalltraining",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "mäßige Anstrengung",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "hochintensives Intervalltraining",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "Burpees, Mountain Climbers, Squat Jumps, Tabata, hohe Anstrengung",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("Wandern"),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "Cross-Country",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("Hockey, Feld"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage("Reiten"),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage("Eishockey"),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage("Eislaufen"),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("Jai Alai"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("Joggen"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("Jonglieren"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("Kajakfahren"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "mäßige Anstrengung",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("Kickball"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("Lacrosse"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("Rasenbowling"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "Boccia, draußen",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage("Kampfsport"),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "verschiedene Arten, moderates Tempo (z.B. Judo, Jujitsu, Karate, Kickboxen, Taekwondo, Tai-Bo, Muay Thai Boxen)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage("Kampfsport"),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "verschiedene Arten, langsames Tempo, Anfänger, Übung",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("Motocross"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "Geländemotorsport, Geländewagen, allgemein",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("Klettern"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "Felsen- oder Bergsteigen",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("Nordic Walking"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("Orientierungslauf"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage(
      "Stand-Up Paddeln",
    ),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("stehend"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("Tretboot"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("Paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage(
      "ungezwungen, allgemein",
    ),
    "paPickleball": MessageLookupByLibrary.simpleMessage("Pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("Pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("Polo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("auf dem Pferd"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("Racquetball"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "Krafttraining",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "Gewichtheben, Freigewichte, Nautilus oder Universal",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "Krafttraining (intensiv)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "intensive Anstrengung, Powerlifting oder Bodybuilding",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "Rodeosport",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein, moderater Aufwand",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage(
      "Inlineskaten",
    ),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "Seilspringen",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "mittleres Tempo, 100-120 Sprünge/Min., allgemein, beidfüßiges Springen, einfacher Sprung",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "Seilspringen",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("Rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "Union, Mannschaft, wettbewerbsorientiert",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("Rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "Berührung, nicht wettbewerbsorientiert",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("Laufen"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("Segeln"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Segeln, Windsurfen, Eissegeln, allgemein",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("Shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "Skateboarding",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein, mäßiger Aufwand",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage("Roller-Skating"),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("Skifahren"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "Wasserski",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "Wasser- oder Wakeboarding",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("Fallschirmspringen"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "Fallschirmspringen, Base-Jumping, Bungee-Jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("Schnorcheln"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "Schnee schaufeln",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "manuell, mäßige Anstrengung",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage("Schneeschuhwandern"),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("Fußball"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Freizeit, allgemein",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "Softball / Baseball",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Schnell- oder Langstreckenpitching, allgemein",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("Squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paStretching": MessageLookupByLibrary.simpleMessage("Dehnen"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage(
      "leicht, allgemein",
    ),
    "paSurfing": MessageLookupByLibrary.simpleMessage("Surfen"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "Körper- oder Brettsurfen, allgemein",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("Schwimmen"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Wassertreten, mäßige Anstrengung, allgemein",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage("Tischtennis"),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "Tischtennis, Ping Pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "Tai Chi, Qi Gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("Tennis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("Leichtathletik"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(z. B. Kugelstoßen, Diskuswurf, Hammerwurf)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(z. B. Hochsprung, Weitsprung, Dreisprung, Speerwurf, Stabhochsprung)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(z. B. Hindernislauf, Hürdenlauf)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("Trampolin"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage("Freizeit"),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "Laufen auf dem Laufband",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "auf dem Laufband, allgemein",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("Einradfahren"),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "allgemein",
    ),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("Volleyball"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nicht-wettkampforientiert, 6-9 Spieler, allgemein",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage(
      "Spazieren gehen",
    ),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "aus Vergnügen",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("Gassi gehen"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("Wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("Wassergymnastik"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "Wassergymnastik, Wasser-Calisthenics",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("Wasserball"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage(
      "Wasser-Volleyball",
    ),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "Wassergymnastik",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "Wassergymnastik, Wasser-Kalorienverbrennungsgymnastik",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("Ringen"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("allgemein"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Überwiegend Stehen oder Gehen bei der Arbeit und aktive Freizeitaktivitäten",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktiv"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "z. B. Sitzen oder Stehen bei der Arbeit und leichte Freizeitaktivitäten",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Leicht aktiv"),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "z. B. Büroarbeit und hauptsächlich sitzende Freizeitaktivitäten",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sitzend"),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Überwiegend Gehen, Laufen oder Gewichte tragen bei der Arbeit und aktive Freizeitaktivitäten",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Sehr aktiv"),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Füge hier den geteilten Mahlzeitencode ein",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Code einfügen"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Pro 100 g/ml"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Pro Portion"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("Phosphor"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "mehrfach ungesättigte Fettsäuren",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("Kalium"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Datenschutzrichtlinie",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Aktiv"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage("Fasten-Timer"),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage(
      "Foto hinzufügen",
    ),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage(
      "Foto entfernen",
    ),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage("Foto ändern"),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Profilname"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Name"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Löschen",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Zielgewicht",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Nicht festgelegt",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Du hast dein Ziel erreicht",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Gewichtsverlauf",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("Protein"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Menge"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Aktivität hinzugefügt",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Dauer (Min., optional)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Verbrannte Energie (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Verbrannte Energie (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Name (optional)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Aktivität schnell hinzufügen",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Schnelles Tracking",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Kohlenhydrate (g, optional)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage(
      "Schnelles Tracking",
    ),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage(
      "Schnelles Tracking",
    ),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energie (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energie (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Fett (g, optional)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Protein (g, optional)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Hinzufügen"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Titel"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Ich habe die Datenschutzbestimmungen gelesen und akzeptiere sie.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Kürzlich"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Zutat hinzufügen",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Bisherige Tagebucheinträge dieses Rezepts bleiben erhalten.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Rezept löschen?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Beschreibung (optional)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage("Foto hinzufügen"),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Aus Galerie wählen",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage("Foto entfernen"),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage("Foto ersetzen"),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Foto aufnehmen",
    ),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Menge",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Einheit",
    ),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage("Zutaten"),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Gesamtgewicht muss größer als null sein",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Dieses Rezept loggen",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Rezeptname"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Rezept benötigt einen Namen",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Mindestens eine Zutat hinzufügen",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Noch keine Zutaten",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "Pro 100 g",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Nährwerte (gesamt)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Rezept konnte nicht gespeichert werden.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Aktiviere dies, um diese Mahlzeit für das nächste Mal in deiner gespeicherten Liste zu behalten. Lass es aus für eine einmalige Mahlzeit, die du nicht noch einmal essen wirst.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Für später speichern",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Rezept speichern"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Ermöglicht das Loggen dieses Rezepts in Portionen statt in Gramm.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Portionen (optional)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Kommagetrennt, z. B. \"Frühstück, vegan\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tags"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Standardmäßig die Summe der Zutaten. Flüssigkeiten werden mit 1 ml ≈ 1 g angenähert.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Gesamtgewicht (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Erstelle ein Gericht aus mehreren Zutaten und verwende es wie jedes andere Lebensmittel.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Noch keine Rezepte",
    ),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Alle"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Rezepte"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Rezepte konnten nicht geladen werden. Bitte später erneut versuchen.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Möchten Sie einen Fehler an den Entwickler melden?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Erneut versuchen"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "gesättigtes Fett",
    ),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage("Produkt scannen"),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Auf Hochformat sperren",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Code manuell eingeben",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage(
      "Abbrechen",
    ),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Barcode eingeben",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "8 bis 14 Ziffern",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Dieser Barcode sieht nicht gültig aus. Bitte überprüfe die Ziffern und versuche es erneut.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage("Suchen"),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Drehung erlauben",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie ein Suchwort ein",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Lebensmittel"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Suchen"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkte"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Suchergebnisse",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Geschlecht auswählen",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Größe auswählen",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Aktivitätslevel auswählen",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Gewicht auswählen",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Anonyme Nutzungsdaten senden?",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Portion"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Eine Portion (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Eine Portion",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("Über"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Feedback"),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Akzentfarbe",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Eigene Farbe…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Öffne den Farbtonregler für eine genaue Auswahl",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Dieser Hex-Code stimmt nicht — sechs Zeichen, 0-9 und A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex-Code"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Schalte die Systemfarben aus, um eine eigene Akzentfarbe zu wählen.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage(
      "Zurücksetzen",
    ),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Akzentfarbe",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Farbe auswählen",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Eigene Farbe",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Standard",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Einheit für Körpergewicht",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Calciumziel in Milligramm. Standardreferenz: 1000 mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Calciumziel",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Reduziert das tägliche Defizit allmählich, damit die letzten Kilos nicht wie eine Wand wirken.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Kalorienziel anpassen, wenn du dich dem Ziel näherst",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage("Über"),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Darstellung",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Daten"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage("Anzeige"),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Ziele & Ernährung",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Einheiten & Energie",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Eigene Mahlzeiten",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Wähle die Stunde, zu der dein Tag beginnt. Mahlzeiten und Aktivitäten, die vor dieser Uhrzeit erfasst werden, zählen zum Vortag — hilfreich bei Nachtschicht oder spätem Essen.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Stunden",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Tag beginnt um",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Minuten",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Alles löschen",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Hierdurch werden dein Profil, deine Mahlzeiten, Aktivitäten, dein Gewichtsverlauf und alle eigenen Rezepte dauerhaft von diesem Gerät entfernt. Die Datenbanken von Open Food Facts und USDA Food Data Central sind davon nicht betroffen. Dies kann nicht rückgängig gemacht werden.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Alle Daten löschen?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Alle meine Daten löschen",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profil, Mahlzeiten, Aktivitäten und Gewichtsverlauf",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage("Hinweis"),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Entfernung"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Energieeinheit",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Ballaststoffziel in Gramm. Standardreferenz: 30 g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ballaststoffziel",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Lebensmitteldatenbanken",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wähle, woher die Suchergebnisse stammen",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperial (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Lebensmitteleinheiten",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrisch (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperial (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Größeneinheit",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrisch (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Imperial (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Eisenziel in Milligramm. Standard nach Geschlecht (8 mg männlich, 18 mg weiblich, 14 mg sonst).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage("Eisenziel"),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Tägliche kcal-Anpassung",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Sprache"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Lizenzen"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Makro-Aufteilung",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Magnesiumziel in Milligramm. Standard nach Geschlecht (400 mg männlich, 310 mg weiblich, 355 mg sonst).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Magnesiumziel",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Masse"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Übernimmt die Akzentfarbe deines Hintergrundbilds auf Android 12 und neuer.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Systemfarben verwenden",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metrisch (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Tägliche Erinnerung",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Persönliche Zielwerte für jeden Nährstoff im täglichen Panel. Das Tagebuch verwendet diese Werte anstelle der Standardreferenzen, sobald du einen festlegst.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Nährstoffziele",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Wähle, welche Nährstoffe im Tagespanel sichtbar sind. Ausgeblendete kannst du jederzeit wieder einschalten.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Nährstoffe",
    ),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wähle, welche Nährstoffe im Tagebuch erscheinen",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Frühstück",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Verteile dein tägliches kcal-Ziel auf Frühstück, Mittagessen, Abendessen und Snacks. Die Anteile müssen zusammen 100 % ergeben.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Abendessen",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "kcal-Anteil je Mahlzeit",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Mittagessen",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Snack",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Kaliumziel in Milligramm. Standardreferenz: 3500 mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Kaliumziel",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Datenschutzeinstellungen",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Fehler melden",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliche Obergrenze für gesättigte Fette in Gramm. Standardreferenz: 20 g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ziel für gesättigte Fette",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Aktivitätstracking anzeigen",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Makros je Mahlzeit anzeigen",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Mikronährstoffe anzeigen",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliche Natriumobergrenze in Milligramm. Standardreferenz: 2300 mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Natriumziel",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Quellcode",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Quellen & Referenzen",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliche Zuckerobergrenze in Gramm. Standardreferenz: 50 g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Zuckerziel",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("System"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Dunkel"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Thema"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Hell"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Systemstandard",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Einheiten"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Vitamin-B12-Ziel in Mikrogramm. Standardreferenz: 2,4 µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vitamin-B12-Ziel",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Vitamin-D-Ziel in Mikrogramm. Standardreferenz: 15 µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vitamin-D-Ziel",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volumen"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Wird vom Wasser-Chip auf dem Startbildschirm verwendet.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Tägliches Wasserziel",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Training teilen",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Code teilen"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Mahlzeit teilen"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage("Rezept teilen"),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "z. B. Apfel, Eiscreme, Schokolade ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Snack"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("Natrium"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Der Kalorienverbrauch bei einer Aktivität wird als MET × Körpergewicht (kg) × Dauer (Stunden) geschätzt, basierend auf den Werten des Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Aktivitätskalorien (MET-Werte)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "Der BMI wird als Gewicht (kg) geteilt durch das Quadrat der Körpergröße (m²) berechnet. Die Kategorien (Untergewicht, Normalgewicht, Präadipositas, Adipositas Grad I–III) folgen der BMI-Klassifikation für Erwachsene der Weltgesundheitsorganisation.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Body-Mass-Index (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Tägliches Kalorienziel, Grundumsatz und die Koeffizienten zur körperlichen Aktivität basieren auf den Gleichungen des Institute of Medicine. Quelle: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Kapitel 5 und Tabelle 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Energiebedarf (TDEE, Grundumsatz und Aktivitätslevel)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage(
      "Quellen anzeigen",
    ),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "Die Standardverteilung von 60 % Kohlenhydraten, 25 % Fett und 15 % Eiweiß liegt innerhalb der von der WHO empfohlenen Nährstoffspannen. In Einstellungen → Berechnungen kannst du sie anpassen. Quelle: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Makronährstoff-Verteilung",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Die Forschung zum Energieverbrauch hat historisch nur binäre Geschlechtskategorien verwendet, sodass es keine validierte TDEE-Formel für non-binäre Personen gibt. OpenNutriTracker bietet daher unter Einstellungen → Berechnungen eine gemittelte Referenz, eine Östrogen-typische Referenz und eine Testosteron-typische Referenz zur Auswahl. Wenn ein genauer Wert für deine Gesundheit wichtig ist, sprich bitte mit einer Ärztin oder einem Arzt, die deinen Hormonstatus kennen.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Kalorienberechnung für non-binäre Personen",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Die täglichen Referenzwerte im Nährstoff-Panel des Tagebuchs stammen aus der Zusammenfassung der Dietary Reference Intakes des Institute of Medicine — pro Nährstoff für Erwachsene.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Nährstoff-Referenzwerte",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Quelle öffnen",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker verwendet für alle Berechnungen etablierte, peer-reviewed Methoden. Die folgenden Quellenangaben verlinken auf die Originaltexte, damit du jede Zahl selbst überprüfen kannst.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("Zucker"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("zugeführt"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Profil wechseln",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("Transfettsäuren"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("Rekord"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Kalorien"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Tagesdurchschnitt",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage(
      "Tage in Folge",
    ),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "Tage im Plan diese Woche",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Trends"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/Woche"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Wasser"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Wochen bis zum Ziel",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Einheit"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("Vitamin A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("Vitamin B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("Vitamin B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("Vitamin C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("Vitamin D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Warnung"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Wöchentliche Rate",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Nicht festgelegt",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage(
      "Eintrag hinzufügen",
    ),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Trage mindestens zwei Tage ein, um deinen Verlauf zu sehen.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Datum"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Noch keine Gewichtseinträge. Füge deinen ersten Eintrag hinzu, um einen Verlauf zu sehen.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Notiz (optional)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage("Gewicht"),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Gewicht"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Du"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("Zink"),
  };
}
