// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a sk locale. All the
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
  String get localeName => 'sk';

  static String m0(sourceName) => "Viac informácií na\n${sourceName}";

  static String m1(versionNumber) => "Verzia ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% sacharidy, ${pctFats}% tuky, ${pctProteins}% bielkoviny";

  static String m3(count, size) => "${count} položiek · ${size}";

  static String m4(imported, skipped) =>
      "Importovaných ${imported} jedál; ${skipped} riadkov bolo preskočených pre neplatné údaje.";

  static String m5(count) => "Importovaných ${count} jedál.";

  static String m6(unit) => "${unit} v jednej porcii";

  static String m7(loser, winner) =>
      "Tým sa všetky záznamy zapísané s ${loser} nahradia, aby zobrazovali ${winner}, a ${loser} bude odstránené z vašich vlastných jedál. Túto akciu nemožno vrátiť späť.";

  static String m8(winner) => "Zlúčené — ${winner} má teraz 1 záznam.";

  static String m9(count, winner) =>
      "Zlúčené — ${winner} má teraz ${count} záznamov.";

  static String m10(count) => "Zmazať ${count} recept(ov)?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "ref. ${value}";

  static String m13(remaining) => "Pôst · zostáva ${remaining}";

  static String m14(value) => "Zostáva ${value}";

  static String m15(value) => "Cieľ: ${value}";

  static String m16(count) => "Importovať ${count} aktivít?";

  static String m17(mealType) =>
      "Tieto položky budú pridané do vašich ${mealType}.";

  static String m18(count) => "Importovať ${count} položiek?";

  static String m19(count) =>
      "${count} položiek sa nepodarilo načítať z OpenFoodFacts.";

  static String m20(count) =>
      "Importovať tento recept s ${count} ingredienciou(ami)?";

  static String m21(amount) => "Pridať ${amount} ml";

  static String m22(threshold) =>
      "Dospelí by bez lekárskeho dohľadu nemali dlhodobo prijímať menej než ${threshold} kcal denne. Zvážte konzultáciu so zdravotníckym odborníkom skôr, než zostanete pri takomto nízkom cieli.";

  static String m23(kcal) => "(+${kcal} kcal aktuálny výber)";

  static String m24(consumed, goal) => "Denný súčet: ${consumed} / ${goal}";

  static String m25(qty, unit) => "Na ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'tyčinka', few: 'tyčinky', other: 'tyčiniek')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'fľaša', few: 'fľaše', other: 'fliaš')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'plechovka', few: 'plechovky', other: 'plechoviek')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'šálka', few: 'šálky', other: 'šálok')}";

  static String m30(count) =>
      "${Intl.plural(count, one: 'vajce', few: 'vajcia', other: 'vajec')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'balenie', few: 'balenia', other: 'balení')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'kus', few: 'kusy', other: 'kusov')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'porcia', few: 'porcie', other: 'porcií')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'porcia', few: 'porcie', other: 'porcií')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'plátok', few: 'plátky', other: 'plátkov')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'lyžica', few: 'lyžice', other: 'lyžíc')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'lyžička', few: 'lyžičky', other: 'lyžičiek')}";

  static String m38(riskValue) => "Riziko sprievodných ochorení: ${riskValue}";

  static String m39(value) => "${value} do cieľa";

  static String m40(mealType) => "Pridané do ${mealType}";

  static String m41(count) => "${count} ingrediencií";

  static String m42(count) => "Vybrané: ${count}";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Čas pripomienky: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/týždeň";

  static String m48(rate) => "${rate} lbs/týždeň";

  static String m49(age) => "${age} rokov";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "napr. beh, cyklistika, joga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Aktivita"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage(
      "Pridať novú položku:",
    ),
    "addLabel": MessageLookupByLibrary.simpleMessage("Pridať"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Pridať profil"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Informácie poskytnuté\n cez \n\'2024 Compendium\n of Physical Activities\'",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Vlastná položka jedla",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Viac informácií na\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Viac informácií na\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Vlastný recept",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Neznáma položka jedla",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Vek"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Všetky"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alfa]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker je bezplatná open-source aplikácia na sledovanie kalórií a živín, ktorá rešpektuje vaše súkromie.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("Licencia GPL-3.0"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Tento 13-miestny čiarový kód vyzerá ako preklep: posledná číslica nesedí so zvyškom",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Výživové hodnoty na",
    ),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Index telesnej hmotnosti (BMI) je ukazovateľ na klasifikáciu nadváhy a obezity u dospelých. Vypočíta sa ako hmotnosť v kilogramoch delená druhou mocninou výšky v metroch (kg/m²).\n\nBMI nerozlišuje medzi tukovou a svalovou hmotou a u niektorých jednotlivcov môže byť zavádzajúci.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "napr. cereálie, mlieko, káva ...",
    ),
    "breakfastLabel": MessageLookupByLibrary.simpleMessage("Raňajky"),
    "burnedLabel": MessageLookupByLibrary.simpleMessage("spálené"),
    "buttonNextLabel": MessageLookupByLibrary.simpleMessage("ĎALEJ"),
    "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Obnoviť"),
    "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Uložiť"),
    "buttonStartLabel": MessageLookupByLibrary.simpleMessage("ZAČAŤ"),
    "buttonYesLabel": MessageLookupByLibrary.simpleMessage("ÁNO"),
    "calciumLabel": MessageLookupByLibrary.simpleMessage("vápnik"),
    "calculationsMacronutrientsDistributionLabel":
        MessageLookupByLibrary.simpleMessage("Rozdelenie makroživín"),
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(odporúčané)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Rovnica Institute of Medicine (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "Rovnica TDEE",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Spriemerovaná referencia (predvolené)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Estrogénová referencia",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Pre nebinárne osoby neexistuje publikovaná kalorická základňa — referenčné rovnice vychádzajú z mužských a ženských vzoriek. Štandardne používame priemer oboch, neutrálny východiskový bod, ktorý od vás nežiada nič viac o vašom tele. Posuvník kcal v Nastaveniach je vždy k dispozícii na doladenie; je to východiskový bod, nie presný odhad.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Kalorická referencia",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Testosterónová referencia"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("s"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Týždenné tempo hmotnosti",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Zvoľte cieľovú hmotnosť",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Odstráni lokálne uložené výsledky vyhľadávania a skenovania z Open Food Facts a FDC. Pamäť sa automaticky obnoví pri ďalšom vyhľadávaní a skenovaní produktov. Vaše vlastné jedlá to neovplyvní.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Vymazať uložené položky?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Vymazať uložené položky",
    ),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Kód skopírovaný"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Jedlo skopírované do profilu",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Kopírovať"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kopírovať kód"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Do ktorého typu jedla chcete skopírovať?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Voľbou \"Kopírovať na dnes\" môžete jedlo skopírovať na dnešok. Voľbou \"Zmazať\" môžete jedlo odstrániť.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Čo chcete urobiť?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Kopírovať do profilu",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Chcete vytvoriť vlastnú položku jedla?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Vytvoriť vlastnú položku jedla?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage(
      "Vytvoriť recept",
    ),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Máte čiarový kód? Pomôžte všetkým a prispejte produktom do Open Food Facts:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "CSV súbor sa nepodarilo prečítať. Skontrolujte formát a skúste to znova.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Zadajte spálené kalórie priamo, pre tréningy ktoré nie sú v zozname, alebo údaje z fitness náramku",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Zadajte spálené kilojouly priamo, pre tréningy ktoré nie sú v zozname, alebo údaje z fitness náramku",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("napr. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Spálené kalórie",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Vlastná aktivita",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "napr. Bicykel domov z práce",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Názov (voliteľný)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Vybrať z uložených šablón",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Uložiť ako šablónu na nabudúce",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Zatiaľ ste si neuložili žiadne šablóny. Zaškrtnite „Uložiť ako šablónu na nabudúce\", ak chcete vlastnú aktivitu zapamätať.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Naskenujte alebo zadajte čiarový kód, aby ste si toto jedlo neskôr ľahko vyvolali",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Čiarový kód musí mať 8 až 14 číslic",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage(
      "Čiarový kód",
    ),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Naskenovať kód",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage("Pokročilý"),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Nastavte veľkosti a hodnoty na 100, aby ste mohli presne škálovať.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Režim zadávania",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Jednoduchý"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Zadajte celkové hodnoty pre jednu porciu.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Všetky záznamy v denníku, ktoré používajú toto jedlo, budú tiež odstránené.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Zmazať vlastné jedlo?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Zatiaľ nie sú uložené žiadne vlastné jedlá.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Zlúčiť s iným vlastným jedlom",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Ktoré ostane?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Zlúčiť",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Zlúčiť vlastné jedlá?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Pokračovať",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Vyberte vlastné jedlo na zlúčenie",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Ďalšie akcie",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Denná úprava kcal:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Denná úprava kJ:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Posielať anonymné hlásenia o páde, aby sme mohli opravovať chyby. Nezahŕňajú sa žiadne záznamy o jedle, hmotnosti ani osobné údaje.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profil 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Zmazať všetko"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Týmto sa natrvalo odstráni profil aj všetky jeho údaje. Túto akciu nie je možné vrátiť späť.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Odstrániť profil?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Naozaj chcete zmazať vybranú položku?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Naozaj chcete zmazať všetky položky tohto jedla?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Zmazať položky?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zmazať položku?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ZRUŠIŤ"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Zavrieť"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage(
      "Kopírovať na dnes",
    ),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("ZMAZAŤ"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Upravujete dátum v budúcnosti",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Denník"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Sčítavajú sa iba živiny zaznamenané pri zalogovaných jedlách. Jedlo bez hodnoty k danej živine neprispeje — súčty preto môžu byť podhodnotené.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Dnešné živiny",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Sacharidy (od najvyšších)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage(
      "Tuky (od najvyšších)",
    ),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Kalórie (od najvyšších)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Zoradiť podľa"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Bielkoviny (od najvyšších)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Času pridania"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "napr. polievka, kuracie mäso, víno ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Večera"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Zahodiť",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Vaše neuložené zmeny budú stratené.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Zahodiť zmeny?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker nie je zdravotnícka aplikácia. Všetky poskytnuté údaje nie sú validované a mali by sa používať s opatrnosťou. Dodržiavajte zdravý životný štýl a v prípade ťažkostí sa poraďte s odborníkom. Používanie počas choroby, tehotenstva alebo dojčenia sa neodporúča. Recenzované zdroje za každým výpočtom nájdete cez ikonu informácií na obrazovke Domov alebo Profil.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Vzorové jedlá (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Vzorové jedlá (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Vzorové recepty (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Vzorové recepty (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Tieto referenčné hodnoty pochádzajú z odporúčaných dietetických príjmov IOM pre dospelých a líšia sa podľa veku a pohlavia. Sú orientačné, nie cieľové — tvoje vlastné potreby sa môžu líšiť.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Zdroj: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Referenčný príjem",
    ),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Toto jedlo už bolo dnes pridané. Pridať ho znova?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Duplikovať"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(kópia)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Upraviť položku",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Upraviť jedlo"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage("Upraviť profil"),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage("Upraviť recept"),
    "energyLabel": MessageLookupByLibrary.simpleMessage("energia"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("zostáva"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("navyše"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilokalórie (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage("Kilojouly (kJ)"),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Chyba pri načítavaní údajov o produkte",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Chyba pri načítavaní aktivít",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Chyba pri ukladaní jedla. Zadali ste správne údaje o jedle?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Chyba pri otváraní prehliadača",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Chyba pri otváraní e-mailovej aplikácie",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Produkt sa nenašiel",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Exportovať"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Exportovať / Importovať údaje aplikácie",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV obsahuje aktivitu, denník jedál a zaznamenané dni. Recepty a pripojené fotky sa ukladajú len do JSON — prepni na JSON, ak ich chceš mať v zálohe.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Údaje aplikácie môžete exportovať do zip súboru a neskôr ich importovať. Hodí sa to, keď si chcete údaje zálohovať alebo preniesť do iného zariadenia.\n\nAplikácia nepoužíva na ukladanie vašich údajov žiadnu cloudovú službu.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Chyba exportu / importu",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import bol úspešný",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Ukončiť pôst"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Aktuálna relácia bude uzavretá.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Ukončiť pôst teraz?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage(
      "Relácia dokončená",
    ),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Uplynulo"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Jednorazové upozornenia, keď pôst dosiahne svoj cieľ.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Časovač pôstu",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Cieľový čas bol dosiahnutý.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Pôst dokončený",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Vlastné"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Spustiť časovač"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jednoduchý časovač na sledovanie času medzi jedlami. Žiadne série, žiadne ciele, len hodiny.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Časovač pôstu"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Rozumiem, zapnúť časovač",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Sledovanie času pôstu môže byť niekomu užitočné a niekoho zraniť, najmä ak má za sebou poruchu príjmu potravy. Ak si to ty, postaraj sa najprv o seba. Podporu poskytujú BEAT (UK) a NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "Nie je to pre mňa",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Skôr než začneš",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("tuky"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("t"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("vláknina"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Vždy zapnuté",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Výsledky vyhľadávania pochádzajú z týchto databáz potravín. Open Food Facts poháňa vyhľadávanie produktov a čiarových kódov a je vždy zapnutá.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("žena"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Pohlavie"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("muž"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("nebinárne"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Pribrať"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Cieľ"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Schudnúť"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage(
      "Udržať hmotnosť",
    ),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Výška"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Klepnutím na + zaznamenáte svoje prvé jedlo alebo aktivitu",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Domov"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("hodiny"),
    "importAction": MessageLookupByLibrary.simpleMessage("Importovať"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Tieto aktivity budú pridané k dnešku.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Importovať zdieľaný tréning",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Tréning importovaný",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Importujte vlastné jedlá zo súboru CSV alebo vložením JSON. Stiahnite si vzor, aby ste videli očakávaný tvar a povinné polia.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Importovať vlastné údaje o jedle",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Neplatný QR kód",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Importovať zdieľané jedlo",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Jedlo importované",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importovať jedlá (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importovať jedlá (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Kód receptu sa nepodarilo spracovať",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Importovať recept",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Recept importovaný",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importovať recepty (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importovať recepty (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Tieto hodnoty úplne nesedia — kalórie, ktoré ste zadali, nezodpovedajú energii zo sacharidov, tukov a bielkovín nižšie. Uložiť aj tak, alebo to ešte raz prejsť?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Ešte raz prejsť",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Uložiť aj tak"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Čísla úplne nesedia",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Pridaná nová aktivita",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Pridaný nový príjem",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("železo"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Položka zmazaná",
    ),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Položka aktualizovaná",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal zostáva"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal navyše"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zaznamenať príjem vody",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Nie je čo vrátiť",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Vrátiť posledný",
    ),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Tento denný cieľ je dosť nízky",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Zobraziť upozornenie",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "napr. pizza, šalát, ryža ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Obed"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Názov bol preložený automaticky",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Rozdelenie makroživín:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("horčík"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Spravovať profily",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Značky"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Sacharidy"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energia"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Tuky"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Pridať fotku"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Vybrať z galérie",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Odstrániť fotku"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage("Nahradiť fotku"),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage("Odfotiť"),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Názov jedla"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Názov jedla musí obsahovať aspoň jedno písmeno",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Celkové množstvo",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("Päť malých"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Stredomorský",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("OMAD"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Rýchle predvoľby",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Štandard"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("Dve jedlá"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Bielkoviny"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Veľkosť balenia"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Veľkosť balenia (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Jednotka jedla"),
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
    "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mikroživiny"),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "Produktu chýbajú povinné údaje o kcal alebo makroživinách",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "mononenasýtené tuky",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Nové vlastné jedlo",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("niacín (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "V poslednom čase neboli pridané žiadne aktivity",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "V poslednom čase neboli pridané žiadne jedlá",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Nenašli sa žiadne výsledky",
    ),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("neuvedené"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("Nič nepridané"),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Nezabudnite si dnes zapísať svoje jedlá!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Denné pripomenutie na zaznamenanie jedál",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Denné pripomenutia"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Povolenie pre upozornenia bolo zamietnuté.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Všetky živiny sú skryté — zapnite niektoré v Nastavenia → Živiny.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Deň"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("limit"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Týždeň"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Nutričné údaje",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Normálna hmotnosť",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Obezita 1. stupňa",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Obezita 2. stupňa",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Obezita 3. stupňa",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Nadváha",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Priemerné",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Zvýšené",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Nízke \n(ale zvýšené riziko \niných klinických problémov)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Stredné",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Vysoké",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Veľmi vysoké",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Podváha",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Údaje poskytnuté touto aplikáciou pochádzajú z databázy Open Food Facts. Nemožno zaručiť ich presnosť, úplnosť ani spoľahlivosť. Údaje sa poskytujú „tak, ako sú“ a pôvodný zdroj údajov (Open Food Facts) nezodpovedá za žiadne škody vyplývajúce z ich použitia.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Aký aktívny životný štýl vediete? (bez cvičení)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Zadajte dátum",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Kedy máte narodeniny?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Narodeniny",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ako zaznamenávate jedlo a nápoje",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Aké je vaše pohlavie?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Aký je váš aktuálny cieľ ohľadom hmotnosti?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "napr. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "napr. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Aká je vaša aktuálna výška?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Na začiatok potrebuje aplikácia o vás niekoľko informácií, aby mohla vypočítať váš denný kalorický cieľ.\nVšetky informácie o vás sú bezpečne uložené iba vo vašom zariadení.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Prečítať zdroje našich zdravotných výpočtov",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kcal za deň",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kJ za deň",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Pre nebinárne osoby neexistuje publikovaná kalorická základňa, preto štandardne používame priemer mužského a ženského vzorca — východiskový bod, nie presný odhad. Kedykoľvek si to môžete doladiť v Nastavenia → Výpočty.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Ďalšie možnosti",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Prispôsobte si aplikáciu — všetko môžete neskôr zmeniť v nastaveniach",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage("Prehľad"),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Nesprávny vstup, skúste to znova",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Voliteľné",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Máš hmotnosť, ku ktorej smeruješ? Pole môžeš nechať prázdne alebo ho neskôr zmeniť v Profile.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "napr. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "napr. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Aká je vaša aktuálna hmotnosť?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage("Víta vás"),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Zadajte správnu výšku",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Zadajte správnu hmotnosť",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Váš kalorický cieľ:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vaše ciele pre makroživiny:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "aktívne videohry",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, všeobecne",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "americký futbal",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "kontaktný, bezkontaktný, všeobecne",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("lukostreľba"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "neloveckého charakteru",
    ),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage(
      "automobilové preteky",
    ),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("formula"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage(
      "turistika s batohom",
    ),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("bedminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rekreačná dvojhra a štvorhra, všeobecne",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("basketbal"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("cyklistika"),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "cyklistika, horská",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "cyklistika, stacionárna",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("biliard"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("box"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage(
      "tréning s boxovacím vrecom",
    ),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("box"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "v ringu, všeobecne",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "kalistenika",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ľahká alebo stredná záťaž, všeobecne (napr. cvičenie na chrbát)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kanoistika"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "veslovanie, pre potešenie, všeobecne",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("futbal alebo bejzbal"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("naháňačka s loptou"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("roztlieskavanie"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "gymnastické prvky, súťažné",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("detské hry"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(napr. škôlka, štvorec, vybíjaná, prvky ihriska, t-ball, švihadlo na stĺpe, guľôčky, arkádové hry), stredná záťaž",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "stúpanie do kopcov, bez záťaže",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "bez záťaže",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "pálkovanie, nadhadzovanie, chytanie",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "beh na lyžiach",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "beh na lyžiach, všeobecne",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("aerobik"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("všeobecný tanec"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "napr. disko, ľudový, írsky step, line dance, polka, contra, country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("šípky"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage(
      "stena alebo trávnik",
    ),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("potápanie"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "freediving, scuba diving, všeobecne",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "skoky do vody",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "z mostíka alebo plošiny",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("šerm"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("gymnastika"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("hádzaná"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("závesné lietanie"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("cyklistika"),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "kondičné cvičenie",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("tanec"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("beh"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("športy"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("chôdza"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "vodné aktivity",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "zimné aktivity",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "vysoko intenzívny intervalový tréning",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "stredná záťaž",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "vysoko intenzívny intervalový tréning",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "burpees, horolezci, drepy s výskokom, Tabata, vysoká záťaž",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("turistika"),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "v teréne",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("hokej, pozemný"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage(
      "jazda na koni",
    ),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage("ľadový hokej"),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage(
      "korčuľovanie na ľade",
    ),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("žonglovanie"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kajak"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "stredná záťaž",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("trávnikový bowling"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage("bocce, vonku"),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "bojové umenia",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "rôzne druhy, stredné tempo (napr. judo, jiu-jitsu, karate, kickbox, taekwondo, tai-bo, thajský box)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage(
      "bojové umenia",
    ),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "rôzne druhy, pomalšie tempo, začiatočníci, nácvik",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("motokros"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "terénne motošporty, štvorkolky, všeobecne",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("horolezectvo"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "lezenie po skalách alebo horách",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("nordic walking"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("orientačný beh"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("paddleboarding"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("v stoji"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("šliapací čln"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage(
      "rekreačne, všeobecne",
    ),
    "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("pólo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koni"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "silový tréning",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "vzpieranie, voľné činky, nautilus alebo univerzálne stroje",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "silový tréning (intenzívny)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "intenzívna záťaž, powerlifting alebo kulturistika",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "rodeo",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne, stredná záťaž",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage("rollerblade"),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "kolieskové korčule v rade",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "skákanie cez švihadlo",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "stredné tempo, 100 – 120 skokov/min, všeobecne, znožmo, základný skok",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "skákanie cez švihadlo",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "union, tímové, súťažné",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "dotykové, nesúťažné",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("beh"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("plachtenie"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "plachtenie na lodi a doske, windsurfing, plachtenie na ľade, všeobecne",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "skateboarding",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne, stredná záťaž",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
      "kolieskové korčuľovanie",
    ),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("lyžovanie"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "vodné lyžovanie",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "vodné lyžovanie alebo wakeboarding",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("skoky padákom"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "skoky padákom, base jumping, bungee jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("šnorchlovanie"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "odhŕňanie snehu",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "ručne, stredná záťaž",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage(
      "chôdza na snežniciach",
    ),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("futbal"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rekreačne, všeobecne",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "softbal / bejzbal",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rýchly alebo pomalý nadhoz, všeobecne",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paStretching": MessageLookupByLibrary.simpleMessage("strečing"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage(
      "mierny, všeobecne",
    ),
    "paSurfing": MessageLookupByLibrary.simpleMessage("surfovanie"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "telom alebo doskou, všeobecne",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("plávanie"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "šliapanie vody, stredná záťaž, všeobecne",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage(
      "stolný tenis",
    ),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "stolný tenis, ping pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "tai chi, qi gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("atletika"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(napr. guľa, disk, kladivo)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(napr. skok do výšky, skok do diaľky, trojskok, oštep, žrď)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(napr. steeplechase, prekážky)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolína"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage("rekreačne"),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "beh na bežiacom páse",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "na bežiacom páse, všeobecne",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("jednokolka"),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "všeobecne",
    ),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("volejbal"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nesúťažný, tím 6 – 9 hráčov, všeobecne",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("chôdza"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "pre potešenie",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("venčenie psa"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("vodné cvičenie"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "vodný aerobik, vodná kalistenika",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("vodné pólo"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage("vodný volejbal"),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "vodný aerobik",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "vodný aerobik, vodná kalistenika",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("zápasenie"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Prevažne státie alebo chôdza v práci a aktívne voľnočasové činnosti",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktívny"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "napr. sedavá alebo stojaca práca a ľahké voľnočasové činnosti",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Mierne aktívny",
    ),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "napr. kancelárska práca a prevažne sedavé voľnočasové činnosti",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sedavý"),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Prevažne chôdza, beh alebo nosenie záťaže v práci a aktívne voľnočasové činnosti",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Veľmi aktívny"),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Sem prilepte zdieľaný kód jedla",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Prilepiť kód"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Na 100 g/ml"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Na porciu"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "polynenasýtené tuky",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("draslík"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Zásady ochrany súkromia",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Aktívny"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage(
      "Časovač pôstu",
    ),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage("Pridať fotku"),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage(
      "Odstrániť fotku",
    ),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage("Zmeniť fotku"),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Názov profilu"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Meno"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Vymazať",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľová hmotnosť",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Nenastavené",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Dosiahli ste svoj cieľ",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "História hmotnosti",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("bielkoviny"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("b"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Množstvo"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Aktivita pridaná",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Trvanie (min, voliteľné)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Spálená energia (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Spálená energia (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Názov (voliteľné)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Rýchle pridanie aktivity",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Rýchle pridanie",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Sacharidy (g, voliteľné)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage(
      "Rýchle pridanie",
    ),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage(
      "Rýchle pridanie",
    ),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energia (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energia (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Tuky (g, voliteľné)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Bielkoviny (g, voliteľné)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Pridať"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Názov"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Prečítal/a som si a súhlasím so zásadami ochrany súkromia.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Nedávno"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Pridať ingredienciu",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Predchádzajúce záznamy v denníku z tohto receptu zostanú zachované.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Zmazať recept?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Popis (voliteľný)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage(
      "Pridať fotografiu",
    ),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Vybrať z galérie",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage(
      "Odstrániť fotografiu",
    ),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage(
      "Nahradiť fotografiu",
    ),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage("Odfotiť"),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Množstvo",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotka",
    ),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Ingrediencie",
    ),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Celková hmotnosť musí byť väčšia ako nula",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Zaznamenať tento recept",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Názov receptu"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Recept potrebuje názov",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Pridajte aspoň jednu ingredienciu",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Zatiaľ žiadne ingrediencie",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "Na 100 g",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Výživa (celkom)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Recept sa nepodarilo uložiť.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Zapnite, ak si chcete toto jedlo ponechať v uloženom zozname na nabudúce. Nechajte vypnuté pri jednorazovom jedle, ktoré už opäť nezjete.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Uložiť na nabudúce",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Uložiť recept"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Umožní vám zaznamenať tento recept po porciách namiesto gramov.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Porcie (voliteľné)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Oddelené čiarkou, napr. „raňajky, vegánske“",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Štítky"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Predvolene súčet ingrediencií. Tekutiny sa približujú ako 1 ml ≈ 1 g.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Celková hmotnosť (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Postavte si jedlo z viacerých ingrediencií a používajte ho ako ktorúkoľvek inú potravinu.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Zatiaľ žiadne recepty",
    ),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Všetky"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Recepty"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Recepty sa nepodarilo načítať. Skúste to neskôr.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Chcete nahlásiť chybu vývojárovi?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Skúsiť znova"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("nasýtené tuky"),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage(
      "Naskenovať produkt",
    ),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Uzamknúť na výšku",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Zadať kód ručne",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage("Zrušiť"),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zadajte čiarový kód",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "8 až 14 číslic",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Tento čiarový kód nevyzerá platne. Skontrolujte číslice a skúste to znova.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage(
      "Vyhľadať",
    ),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Povoliť otáčanie",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Zadajte prosím hľadané slovo",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Potraviny"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Vyhľadať"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkty"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Výsledky vyhľadávania",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Vyberte pohlavie",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Vyberte výšku",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Vyberte úroveň aktivity",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Vyberte hmotnosť",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Odosielať anonymné údaje o používaní",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Porcia"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Jedna porcia (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Jedna porcia",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("O aplikácii"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage(
      "Spätná väzba",
    ),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Farba zvýraznenia",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Vlastná farba…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Otvorte posuvník odtieňa pre presný výber",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Tento hex kód nevyzerá správne — šesť znakov, 0-9 a A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex kód"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Vypnite systémové farby, aby ste mohli vybrať vlastný akcent.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Obnoviť"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Farba zvýraznenia",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Vyberte farbu",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Vlastné",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Predvolené",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotka telesnej hmotnosti",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ vápnika v miligramoch. Predvolená referencia je 1000 mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ vápnika",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Postupne znižuje denný kalorický deficit, aby posledné kilá nepôsobili ako stena.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Upraviť kalorický cieľ s blížením k cieľovej hmotnosti",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage(
      "O aplikácii",
    ),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Vzhľad",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Údaje"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage(
      "Zobrazenie",
    ),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Ciele a výživa",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Jednotky a energia",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Vlastné jedlá",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Vyber hodinu, kedy sa začína tvoj deň. Jedlá a aktivity zaznamenané pred touto hodinou sa počítajú do predchádzajúceho dňa — hodí sa pri nočných smenách alebo neskorom jedle.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Hodiny",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Deň začína o",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Minúty",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Zmazať všetko",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Tým sa z tohto zariadenia natrvalo odstráni váš profil, jedlá, aktivity, história hmotnosti a všetky vlastné recepty. Databázy Open Food Facts a USDA Food Data Central tým nie sú ovplyvnené. Túto akciu nie je možné vrátiť späť.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Zmazať všetky vaše údaje?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Zmazať všetky moje údaje",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profil, jedlá, aktivity a históriu hmotnosti",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Upozornenie",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage(
      "Vzdialenosť",
    ),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotka energie",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ vlákniny v gramoch. Predvolená referencia je 30 g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ vlákniny",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Databázy potravín",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Vyberte, odkiaľ pochádzajú výsledky vyhľadávania",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperiálne (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotky potravín",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrické (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperiálne (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotky výšky",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrické (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Imperiálne (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ železa v miligramoch. Predvolená referencia sa líši podľa pohlavia (8 mg muž, 18 mg žena, 14 mg inak).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ železa",
    ),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Denná úprava kcal",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Nastavenia"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Jazyk"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Licencie"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Rozdelenie makroživín",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ horčíka v miligramoch. Predvolená referencia sa líši podľa pohlavia (400 mg muž, 310 mg žena, 355 mg inak).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ horčíka",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Hmotnosť"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Zladí aplikáciu s farbou tapety v Androide 12 a novšom.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Použiť systémové farby",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metrické (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Denná pripomienka",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Osobné ciele pre každú živinu v dennom paneli. Denník ich použije namiesto predvolených denných referencií vždy, keď jednu nastavíte.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Ciele živín",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Vyberte, ktoré živiny sa zobrazujú v dennom paneli. Skryté sa kedykoľvek dajú zapnúť späť.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage("Živiny"),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Vyberte, ktoré živiny sa objavia v paneli denníka",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Raňajky",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Rozdeľte svoj denný kcal cieľ medzi raňajky, obed, večeru a snacky. Podiely musia spolu dať 100 %.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Večera",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Podiel kcal na jedlo",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Obed",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Snack",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ draslíka v miligramoch. Predvolená referencia je 3500 mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ draslíka",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Nastavenia súkromia",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nahlásiť chybu",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný limit nasýtených tukov v gramoch. Predvolená referencia je 20 g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ nasýtených tukov",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Zobraziť sledovanie aktivity",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Zobraziť makroživiny jedla",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Zobraziť mikroživiny",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný limit sodíka v miligramoch. Predvolená referencia je 2300 mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ sodíka",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Zdrojový kód",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Zdroje a referencie",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný limit cukrov v gramoch. Predvolená referencia je 50 g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ cukrov",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Systém"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Tmavá"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Vzhľad"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Svetlá"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Podľa systému",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Jednotky"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ vitamínu B12 v mikrogramoch. Predvolená referencia je 2,4 µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ vitamínu B12",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ vitamínu D v mikrogramoch. Predvolená referencia je 15 µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cieľ vitamínu D",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Objem"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Používa sa ukazovateľom vody na hlavnej obrazovke.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Denný cieľ pitia vody",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Zdieľať tréning",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Zdieľať kód"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Zdieľať jedlo"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage("Zdieľať recept"),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "napr. jablko, zmrzlina, čokoláda ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Olovrant"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodík"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Kalórie spálené počas aktivity sa odhadujú ako MET × telesná hmotnosť (kg) × trvanie (hodiny) podľa hodnôt z Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Kalórie z aktivity (hodnoty MET)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "BMI sa počíta ako hmotnosť (kg) delená druhou mocninou výšky (m²). Zdravotné kategórie (podváha, normálna hmotnosť, nadváha, obezita I. – III. stupňa) zodpovedajú klasifikácii BMI pre dospelých podľa Svetovej zdravotníckej organizácie.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Index telesnej hmotnosti (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Denné kalorické ciele, bazálny metabolizmus a koeficienty fyzickej aktivity používajú rovnice Institute of Medicine. Zdroj: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, kapitola 5 a tabuľka 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Energetická potreba (TDEE, BMR a úroveň aktivity)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage(
      "Zobraziť zdroje",
    ),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "Predvolené rozdelenie 60 % sacharidov, 25 % tukov a 15 % bielkovín spadá do odporúčaných rozsahov príjmu živín podľa WHO. V Nastavenia → Výpočty si ho môžete upraviť. Zdroj: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Rozdelenie makroživín",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Výskum energetického výdaja historicky používal binárne pohlavné kategórie, takže pre nebinárne osoby neexistuje jediný validovaný vzorec TDEE. OpenNutriTracker vám preto v Nastavenia → Výpočty ponúka voľbu medzi spriemerovanou referenciou, estrogénovo-typickou referenciou a testosterónovo-typickou referenciou. Ak na presnom čísle pre vašu starostlivosť skutočne záleží, prosím poraďte sa s klinikom, ktorý pozná váš hormonálny stav.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Odhad kalórií pre nebinárne osoby",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Denné referenčné hodnoty zobrazené v paneli živín v denníku pochádzajú zo súhrnu Dietary Reference Intakes Institute of Medicine, ktorý pokrýva ciele pre jednotlivé živiny u dospelých.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Referenčné príjmy živín",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Zobraziť zdroj",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker používa pre každý zobrazený výpočet zavedené, recenzované metódy. Nasledujúce odkazy vedú na pôvodné zdroje, takže si každé číslo môžete sami overiť.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("cukor"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("prijaté"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Prepnúť profil",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("trans tuky"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("rekord"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Kalórie"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Denný priemer",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage("dní v rade"),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "dní v pláne tento týždeň",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Trendy"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/týždeň"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Voda"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "týždňov do cieľa",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Jednotka"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamín A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamín B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamín B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamín C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamín D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Upozornenie"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Týždenné tempo",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Nenastavené",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage(
      "Pridať záznam",
    ),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Zaznamenajte aspoň dva dni, aby ste videli svoj trend.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Dátum"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Zatiaľ žiadne záznamy o hmotnosti. Pridajte prvý a začnite sledovať trend.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Poznámka (voliteľná)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Hmotnosť",
    ),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Hmotnosť"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Ty"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("zinok"),
  };
}
