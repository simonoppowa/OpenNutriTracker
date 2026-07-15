// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a cs locale. All the
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
  String get localeName => 'cs';

  static String m0(sourceName) => "Více informací na\n${sourceName}";

  static String m1(versionNumber) => "Verze ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% sacharidy, ${pctFats}% tuky, ${pctProteins}% bílkoviny";

  static String m3(count, size) => "${count} položek · ${size}";

  static String m4(imported, skipped) =>
      "Importováno ${imported} jídel; ${skipped} řádků přeskočeno kvůli neplatným datům.";

  static String m5(count) => "Importováno ${count} jídel.";

  static String m6(unit) => "${unit} v jedné porci";

  static String m7(loser, winner) =>
      "Tímto se všechny záznamy zapsané s ${loser} nahradí, aby se zobrazovaly jako ${winner}, a ${loser} bude odstraněna z vašich vlastních potravin. Tuto akci nelze vrátit zpět.";

  static String m8(winner) => "Sloučeno — ${winner} má nyní 1 záznam.";

  static String m9(count, winner) =>
      "Sloučeno — ${winner} má nyní ${count} záznamů.";

  static String m10(count) => "Smazat ${count} recept(ů)?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "ref. ${value}";

  static String m13(remaining) => "Půst · zbývá ${remaining}";

  static String m14(value) => "Zbývá ${value}";

  static String m15(value) => "Cíl: ${value}";

  static String m16(count) => "Importovat ${count} aktivit?";

  static String m17(mealType) => "Tyto položky budou přidány do ${mealType}.";

  static String m18(count) => "Importovat ${count} položek?";

  static String m19(count) =>
      "${count} položek nebylo možné načíst z OpenFoodFacts.";

  static String m20(count) =>
      "Importovat tento recept s ${count} ingrediencí(emi)?";

  static String m21(amount) => "Přidat ${amount} ml";

  static String m22(threshold) =>
      "Dospělí by bez lékařského dohledu neměli dlouhodobě přijímat méně než ${threshold} kcal denně. Zvažte, prosím, konzultaci se zdravotníkem, než u tak nízkého cíle zůstanete.";

  static String m23(kcal) => "(+${kcal} kcal aktuální výběr)";

  static String m24(consumed, goal) => "Denní součet: ${consumed} / ${goal}";

  static String m25(qty, unit) => "Na ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'tyčinka', few: 'tyčinky', other: 'tyčinek')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'láhev', few: 'láhve', other: 'lahví')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'plechovka', few: 'plechovky', other: 'plechovek')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'šálek', few: 'šálky', other: 'šálků')}";

  static String m30(count) =>
      "${Intl.plural(count, one: 'vejce', few: 'vejce', other: 'vajec')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'balení', few: 'balení', other: 'balení')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'kus', few: 'kusy', other: 'kusů')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'porce', few: 'porce', other: 'porcí')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'porce', few: 'porce', other: 'porcí')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'plátek', few: 'plátky', other: 'plátků')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'lžíce', few: 'lžíce', other: 'lžic')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'lžička', few: 'lžičky', other: 'lžiček')}";

  static String m38(riskValue) => "Riziko komorbidit: ${riskValue}";

  static String m39(value) => "Zbývá ${value} do cíle";

  static String m40(mealType) => "Přidáno do ${mealType}";

  static String m41(count) => "${count} ingredience(í)";

  static String m42(count) => "Vybráno: ${count}";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Čas připomínky: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/týden";

  static String m48(rate) => "${rate} lbs/týden";

  static String m49(age) => "${age} let";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "např. běh, cyklistika, jóga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Activita"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage("Přidat nový záznam:"),
    "addLabel": MessageLookupByLibrary.simpleMessage("Vložit"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Přidat profil"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Informace poskytnutá\n během \n\'2024 Compendium\n of Physical Activities\'",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Vlastní jídlo",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Více informadcí na\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Více informací najdete na\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Vlastní recept",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Neznámá položka jídla",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Věk"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Vše"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alfa]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker je volně šiřitelný open-source tracker kalorického příjmu a nutričních hodnot, který respektuje Vaše soukromí.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("Licence GPL-3.0"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Tento 13místný čárový kód vypadá překlepnutě: poslední číslice nesouhlasí s ostatními",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Výživové hodnoty na",
    ),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Body Mass Index (BMI) je výpočet pro klasifikaci nadváhy a obezity u dospělých. Je definován jako hmotnost v kilogramech vydělená druhou mocninou výšky v metrech (kg/m²).\n\nBMI nerozlišuje mezi tukovou tkání a svalovou hmotou a může být chybně interpretován u některých jedinců.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "např. obilniny, mléko, káva...",
    ),
    "breakfastLabel": MessageLookupByLibrary.simpleMessage("Snídaně"),
    "burnedLabel": MessageLookupByLibrary.simpleMessage("vydáno"),
    "buttonNextLabel": MessageLookupByLibrary.simpleMessage("DALŠÍ"),
    "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Reset"),
    "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Uložit"),
    "buttonStartLabel": MessageLookupByLibrary.simpleMessage("START"),
    "buttonYesLabel": MessageLookupByLibrary.simpleMessage("ANO"),
    "calciumLabel": MessageLookupByLibrary.simpleMessage("vápník"),
    "calculationsMacronutrientsDistributionLabel":
        MessageLookupByLibrary.simpleMessage("Poměr nutričních složek"),
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(doporučeno)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Výpočet Institute of Medicine (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "Výpočet TDEE",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Zprůměrovaná reference (výchozí)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Estrogenní reference",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Pro nebinární osoby neexistuje publikovaná kalorická základní hodnota — referenční rovnice vycházejí z mužských a ženských vzorků. Standardně používáme průměr obou, neutrální výchozí bod, který od vás nevyžaduje nic dalšího sdělovat o vašem těle. Posuvník kcal v Nastavení je vždy k dispozici pro doladění; toto je výchozí bod, nikoli přesný odhad.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Kalorická reference",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Testosteronová reference"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("s"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Týdenní tempo hmotnosti",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Zvolte cílovou hmotnost",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Odstraní lokálně uložené výsledky vyhledávání a skenování z Open Food Facts a FDC. Mezipaměť se automaticky obnoví při dalším vyhledávání a skenování. Vaše vlastní jídla nejsou ovlivněna.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Vymazat mezipaměť?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Vymazat mezipaměť",
    ),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Kód zkopírován"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Jídlo zkopírováno do profilu",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Kopírovat"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kopírovat kód"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Který typ jídla si přejete zkopírovat?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Pomocí \"Kopírovat pro dnešek\" můžete vytvořit kopii pro dnešní jídlo. Volbou \"Smazat\" odstraníte zvolený pokrm.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Jakou akci si přejete provést?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Kopírovat do profilu",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Přejete si vytvořit vlastní potravinu?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Vytvořit vlastní potravinu?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage(
      "Vytvořit recept",
    ),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Máte čárový kód? Přispějte produktem do Open Food Facts:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nelze přečíst CSV soubor. Zkontrolujte formát a zkuste znovu.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Zadejte spálené kalorie přímo, pro tréninky, které nejsou na seznamu, nebo hodnoty z fitness náramku",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Zadejte spálené kilojouly přímo, pro tréninky, které nejsou na seznamu, nebo hodnoty z fitness náramku",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("např. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Spálené kalorie",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Vlastní aktivita",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "např. Večerní jízda do práce",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Název (nepovinné)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Vybrat z uložených šablon",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Uložit jako šablonu pro příště",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Zatím nemáte uložené žádné šablony. Zaškrtněte „Uložit jako šablonu pro příště“, abyste si vlastní aktivitu zapamatovali na později.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Naskenuj nebo zadej čárový kód, aby ses k jídlu mohl/a později vrátit",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Čárový kód musí mít 8 až 14 číslic",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage(
      "Čárový kód",
    ),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Naskenovat čárový kód",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage("Pokročilý"),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Zadejte velikosti a hodnoty na 100 g/ml pro přesné škálování.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Zobrazení formuláře",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Jednoduchý"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Zadejte hodnoty pro jednu porci.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Všechny záznamy v deníku používající toto jídlo budou také odstraněny.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Smazat vlastní jídlo?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Zatím žádná vlastní jídla uložena.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Sloučit s jinou vlastní potravinou",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Která zůstane?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Sloučit",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Sloučit vlastní potraviny?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Pokračovat",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Vyberte vlastní potravinu pro sloučení",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Další akce",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Úprava denního kalorického příjmu:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Úprava denního příjmu (kJ):",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Odesílat anonymní hlášení o pádech, abychom mohli opravovat chyby. Neodesílají se žádné záznamy o jídle, hmotnosti ani osobní údaje.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profil 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Smazat vše"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Tímto se trvale smaže profil i všechna jeho data. Tuto akci nelze vrátit zpět.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Smazat profil?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Přejete si vymazat označený záznam?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Přejete si vymazat všechny položky vybraného pokrmu?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Smazat položky?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Smazat záznam?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ZRUŠIT"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Zavřít"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage(
      "Kopírovat pro dnešek",
    ),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SMAZAT"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Upravujete datum v budoucnosti",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Diář"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Sčítají se zde pouze živiny, které jsou u zaznamenaných jídel zachyceny. Jídlo bez hodnoty k dané živině nepřispěje — součty proto mohou být podhodnocené.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Dnešní živiny",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Sacharidy (sestupně)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage("Tuky (sestupně)"),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Kalorie (sestupně)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Řadit podle"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Bílkoviny (sestupně)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Času přidání"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "např. polévka, kuřecí maso, víno...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Večeře"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Zahodit",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Vaše neuložené změny budou ztraceny.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Zahodit změny?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker není aplikace pro lékařské účely. Doporučené hodnoty nejsou validovány a měly by být použity opatrně za použití selského rozumu. Dodržujte prosím obecné zásady zdravého životního stylu a kontaktujte lékaře v případě zdravotních problémů. Používání aplikace se nedoporučuje během nemoci, těhotenství či kojení. Recenzované zdroje ke každému výpočtu najdete přes ikonu informací na obrazovce Domů nebo Profil.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Vzorová jídla (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Vzorová jídla (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Vzorové recepty (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Vzorové recepty (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Tyto referenční hodnoty pocházejí z doporučených dietních příjmů IOM pro dospělé a liší se podle věku a pohlaví. Jde o orientační údaj, nikoli o cíl — tvoje vlastní potřeby se mohou lišit.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Zdroj: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Referenční příjem",
    ),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Tato potravina už byla dnes přidána k tomuto jídlu. Přidat ji znovu?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Duplikovat"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(kopie)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Upravit záznam",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Upravit jídlo"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage("Upravit profil"),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage("Upravit recept"),
    "energyLabel": MessageLookupByLibrary.simpleMessage("energie"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("zbývá"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("navíc"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilokalorie (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage("Kilojouly (kJ)"),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Chyba získání dat o produktu",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Chyba načítání aktivit",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Chyba ukládání jídla. Zkontrolujte prosím správnost zadaných informací.",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Chyba spouštění webového prohlížeče",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Chyba spouštění mailové aplikace",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Produkt nenalezen",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Export"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import dat aplikace",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV obsahuje aktivitu, deník jídla a zaznamenané dny. Recepty a připojené fotky se ukládají jen do JSON — přepni na JSON, pokud je chceš mít v záloze.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Můžete uložit data z aplikace do .zip archívu a později je znovu importovat. To je užitečné, pokud potřebujete data zálohovat, nebo přenést na jiné zařízení.\n\nAplikace pro ukládání dat nepoužívá žádné cloudové služby.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import selhal",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Export / Import byl úspěšný",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Ukončit půst"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Aktuální relace bude uzavřena.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Ukončit půst teď?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage("Relace dokončena"),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Uplynulo"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Jednorázová upozornění, když půst dosáhne svého cíle.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Časovač půstu",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Cílový čas byl dosažen.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Půst dokončen",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Vlastní"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Spustit časovač"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jednoduchý časovač pro sledování času mezi jídly. Žádné série, žádné cíle, jen hodiny.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Časovač půstu"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Rozumím, zapnout časovač",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Sledování doby půstu může být pro někoho užitečné a pro jiného zraňující, zvlášť pokud máte zkušenost s poruchou příjmu potravy. Pokud se vás to týká, prosím postarejte se nejdřív o sebe. Podporu nabízí BEAT (UK) a NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "Není to pro mě",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage("Než začnete"),
    "fatLabel": MessageLookupByLibrary.simpleMessage("tuky"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("t"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("vláknina"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Vždy zapnuto",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Výsledky vyhledávání pocházejí z těchto databází potravin. Open Food Facts pohání vyhledávání produktů a čárových kódů a je vždy zapnutá.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("žena"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Pohlaví"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("muž"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("nebinární"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Přibrat"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Cíl"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Zhubnout"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage(
      "Zachovat hmotnost",
    ),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Výška"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Klepnutím na + zaznamenáte své první jídlo nebo aktivitu",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Domů"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("hodiny"),
    "importAction": MessageLookupByLibrary.simpleMessage("Import"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Tyto aktivity budou přidány do dneška.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Importovat sdílený trénink",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Trénink importován",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Importujte vlastní jídla z CSV souboru nebo vložením JSON. Stáhněte si ukázku, abyste viděli očekávaný tvar a povinná pole.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Importovat vlastní data potravin",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Neplatný QR kód",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Importovat sdílené jídlo",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Jídlo importováno",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importovat jídla (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importovat jídla (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nepodařilo se zpracovat kód receptu",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Importovat recept",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Recept importován",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importovat recepty (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importovat recepty (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Tyto hodnoty si úplně neodpovídají — zadané kalorie neodpovídají energii ze sacharidů, tuků a bílkovin. Uložit i tak, nebo se podívat ještě jednou?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Podívat se ještě jednou",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Uložit i tak"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Čísla nesedí",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Vložena nová aktivita",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Vložen nový příjem",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("železo"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Záznam smazán",
    ),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Záznam upraven",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal zbývá"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal navíc"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zaznamenat příjem vody",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Není co vrátit",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Vrátit poslední",
    ),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Tento denní cíl je poměrně nízký",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Zobrazit upozornění",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "např. pizza, salát, rýže...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Oběd"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Název byl přeložen automaticky",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Poměr nutričních složek:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("hořčík"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Spravovat profily",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Výrobce, značka"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Sacharidy"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energie"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Tuky"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Přidat fotku"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Vybrat z galerie",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Odebrat fotku"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage("Nahradit fotku"),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage("Pořídit fotku"),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal na"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Název jídla"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Název jídla musí obsahovat alespoň jedno písmeno",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Celkové množství",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("5 malých"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Středomořský",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("1 jídlo"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Rychlé předvolby",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Standardní"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("2 jídla"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Bílkoviny"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Velikost balení"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Velikost balení (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Jednotka jídla"),
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
      "Chybí požadovaná energie nebo nutriční hodnoty",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "mononenasycené tuky",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Nová vlastní potravina",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("niacin (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Žádné aktivity dosud nezadány",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Žádné pokrmy dosud nezadány",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Nenalezeny žádné výsledky",
    ),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("neuvedeno"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("Nezadáno"),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Nezapomeňte si dnes zaznamenat svá jídla!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Denní připomenutí k zaznamenání jídel",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Denní připomenutí"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Oprávnění k upozorněním bylo odepřeno.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Všechny živiny skryté — zapni některé v Nastavení → Živiny.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Den"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("limit"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Týden"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Nutriční hodnoty",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Normální hmotnost",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Obezita 1. stupně",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Obezita 2. stupně",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Obezita 3. stupně",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Nadváha",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Průměrné",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Zvýšené",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Nízké \n(ale zvýšené pro jiné \nklinické problémy)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Střední",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Vysoké",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Velmi vysoké",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Podváha",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Data poskytnutá aplikací jsou získána z databáze Open Food Facts. Nelze garantovat jejich přesnost, kompletnost nebo spolehlivost. Data jsou poskytována bez záruky a jejich původní poskytovatel (Open Food Facts) není zodpovědný za jakékoliv újmy vzniklé jejich používáním.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jak aktivně žijete? (Obecně - proteď prosím neberte v úvahu konkrétní cvičení.)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Vložte datum",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Kdy jste se narodil(a)?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Datum narození",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jak zaznamenáváte jídlo a nápoje",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaké je Vaše pohlaví?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaký je Váš cíl ohledně hmotnosti?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "např. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "např. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaká je Vaše výška?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Než začnete, aplikace o Vás potřebuje zadat několik údajů, aby mohla spočítat Váš denní kalorický cíl.\nVeškeré osobní údaje jsou bezpečně uloženy pouze ve Vašem zařízení.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Přečíst zdroje našich zdravotních výpočtů",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kcal denně",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage("kJ denně"),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Pro nebinární osoby neexistuje publikovaná kalorická základní hodnota, proto standardně používáme průměr mužských a ženských vzorců — výchozí bod, nikoli přesný odhad. Kdykoli to můžeš upravit v Nastavení → Výpočty.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Další možnosti",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Přizpůsobte si aplikaci — vše lze později změnit v nastavení",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage("Přehled"),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Nesprávné zadání, vložte prosím hodnotu znovu",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Volitelné",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Máš hmotnost, ke které směřuješ? Pole můžeš nechat prázdné nebo ho později změnit v Profilu.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "např. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "např. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaká je Vaše hmotnost?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage("Vítejte v"),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Zadejte správnou výšku",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Zadejte správnou hmotnost",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vář kalorický cíl:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Vaše nutriční cíle:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "aktivní videohry",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, obecně",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "americký fotbal",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "kontaktní, bezkontaktní, obecný",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("lukostřelba"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nesouvisející s lovem",
    ),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("automobilový sport"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("formule"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage("turistika"),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "jednotlivec, dvojice, obecný",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("basketball"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("cyklistika"),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "cyklistika, horské kolo",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "obecná",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "cyklistika, stacionární",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "obecná",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("kulečník"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("box"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage(
      "trénink s boxovacím pytlem",
    ),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("box"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "v ringu, obecný",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "kalistenika",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nízká a střední intenzita, obecná (např. cvičení na záda)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kanoistika"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "veslování, pro zábavu, obecná",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("rugby nebo baseball"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("chytání"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage(
      "cheerleading (choreografické povzbuzování)",
    ),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "gymnastické cviky, soutěžní",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("dětské hry"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(např. panák, čtvercový král, dodgeball (moderní vybíjená), hry na dětském hřišti, tee-ball, tetherball, kuličky, arcade hry), střední námaha",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "chození po horách, bez zátěže",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "bez zátěže",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "odpalování, nadhazování, hra v poli",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "běh na lyžích",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "běh na lyžích, obecně",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("curling (lední metaná)"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("aerobik"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "obecný",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("obecný tanec"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "např. disco, folk, irské stepování, choreografický tanec, polka, contra, country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("šipky"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage(
      "zeď nebo venkovní prostory",
    ),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("potápění"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "bez přístroje, s dýchacím přístrojem, obecné",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "skoky do vody",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "z můstku či plošiny",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("šerm"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage(
      "frisbee (házení diskem)",
    ),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("gymnastika"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paHackySack": MessageLookupByLibrary.simpleMessage(
      "Footbag (hakysák/hakisák)",
    ),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("házená"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("závěsné létání"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("cyklistika"),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "kondiční cvičení",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("tanec"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("běh"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("sporty"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("chůze"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "vodní sporty",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "zimní sporty",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "vysoce intenzivní intervalový trénink",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "střední intenzita",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "vysoce intenzivní intervalový trénink",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "burpees, horolezci, výskoky z dřepu, Tabata, vysoká intenzita",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage(
      "chůze v přírodě",
    ),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "ve volné přírodě",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("pozemní hokej"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage(
      "jízda na koni",
    ),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage("lední hokej"),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage(
      "bruslení na ledě",
    ),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai (pelota)"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("žonglování"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kajak"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "střední úsilí",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("trávníkový bowling"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "bocce ball (italský bowling), venkovní bowling",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "bojová umění",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "různé druhy, střední tempo (např. judo, jujitsu, karate, kickbox, taekwondo, tai-bo, thajský box)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage("bojová umění"),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "různé druhy, mírné tempo, začátečníci, nácvik",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-cross"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "off-road jízda, terénní vozy, obecný",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("horolezectví"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "na skálu či horu",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("severská chůze"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("orientační běh"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("paddle boarding"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("ve stoje"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pádlování"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage(
      "rekreační, obecný",
    ),
    "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("pólo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koni"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("raketbal"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "silový trénink",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "vzpírání, cvičení s vlastní váhou, cvičení na nautilu, obecné posilování",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "silový trénink (intenzivní)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "intenzivní úsilí, silový trojboj nebo kulturistika",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "rodeo",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "obecné, střední úsilí",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage(
      "jízda na inline bruslích",
    ),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage("in-line"),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "skákání přes švihadlo",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "střední tempo, 100-120 skoků/min, obecné, snožmo, základní skok",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "skákání přes švihadlo",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "týmová soutěžní hra",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "kontaktní, nesoutěžní",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("běh"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("plachtění"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "plachtění na lodi a prkně, windsurfing, plachtění na ledě, obecné",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "jízda na skateboardu",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "obecný, střední úsilí",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
      "jízda na kolečkových bruslích",
    ),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("lyžování"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "vodní lyžování",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "vodní lyžování, wakeboarding",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("seskoky volným pádem"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "skoky z letadla, base jumping, bungee jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("šnorchlování"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "odhrabování sněhu",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "ručně, střední námaha",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage(
      "chůze na sněžnicích",
    ),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("fotbal"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rekreační, obecný",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "softball / baseball",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ryachlý nebo pomalý nadhoz, obecný",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paStretching": MessageLookupByLibrary.simpleMessage("strečink"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage("mírné, obecně"),
    "paSurfing": MessageLookupByLibrary.simpleMessage("surfování"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "bodysurfing či na prkně, obecné",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("plavání"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "šlapání vody, střední úsilí, obecné",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage(
      "stolní tenis",
    ),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "stolní tenis, ping pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "tai či, qi gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("lehká atletika"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(např. střelba, hod diskem, hod kladivem)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(např. skok do výšky, skok do dálky, trojskok, hod oštěpem, skok o tyči)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(např. dostihy, překážkový běh)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolína"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage("rekreačně"),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "běh na běžícím pásu",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "na běžícím pásu, obecně",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("jednokolka"),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("volejbal"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nesoutěžní, 6 - 9 hráčů, obecný",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("chůze"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "pro zábavu",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("venčení psa"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("vodní cvičení"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "vodní aerobik, vodní kalistenika",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("vodní pólo"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("obecné"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage("vodní volejbal"),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "vodní aerobik",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "vodní aerobik, vodní kalistenika",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("obecný"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Práce převážně ve stoje nebo vyžadující chůzi a aktivní volnočasové činnosti",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Aktivní životní styl",
    ),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "např. práce v sedě či ve stoje a lehké volnočasové aktivity",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Nízká aktivita",
    ),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "např. kancelářská práce a aktivity provozované převážně v sedě",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage(
      "Sedavý životní styl",
    ),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Převažující chůze, běh nebo nošení břemen při práci a aktivní volnočasové činnosti",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Velmi aktivní životní styl",
    ),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Vložte sem sdílený kód jídla",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Vložit kód"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Na 100g/ml"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Na porci"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "polynenasycené tuky",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("draslík"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Pravidla týkající se soukromí",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Aktivní"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage(
      "Časovač půstu",
    ),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage("Přidat fotku"),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage("Odebrat fotku"),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage("Změnit fotku"),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Název profilu"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Jméno"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Vymazat",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Cílová hmotnost",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Nenastaveno",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Dosáhli jste svého cíle",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Historie hmotnosti",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("bílkoviny"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("b"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Množství"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Aktivita přidána",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Doba trvání (min, volitelné)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Spálená energie (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Spálená energie (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Název (volitelné)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Rychlé přidání aktivity",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Rychlé přidání",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Sacharidy (g, volitelné)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage("Rychlé přidání"),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage(
      "Rychlé přidání",
    ),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energie (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energie (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Tuky (g, volitelné)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Bílkoviny (g, volitelné)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Přidat"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Název"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Četl jsem pravidla ohledně soukromí a souhlasím s nimi.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Nedávné"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Přidat ingredienci",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Předchozí záznamy v deníku z tohoto receptu budou zachovány.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Smazat recept?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Popis (volitelný)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage("Přidat fotku"),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Vybrat z galerie",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage("Odebrat fotku"),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage(
      "Nahradit fotku",
    ),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Pořídit fotku",
    ),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Množství",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotka",
    ),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Ingredience",
    ),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Celková hmotnost musí být větší než nula",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Zaznamenat tento recept",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Název receptu"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Recept potřebuje název",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Přidejte alespoň jednu ingredienci",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Zatím žádné ingredience",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "Na 100 g",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Výživa (celkem)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Recept se nepodařilo uložit.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Zapněte, aby toto jídlo zůstalo v seznamu uložených pro příště. Nechte vypnuté u jednorázového jídla, které už nebudete jíst.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Uložit pro příště",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Uložit recept"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Umožňuje zaznamenávat tento recept po porcích místo gramů.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Porce (volitelné)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Oddělené čárkou, např. \"snídaně, veganské\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Štítky"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Výchozí hodnotou je součet ingrediencí. Tekutiny jsou přibližně 1 ml ≈ 1 g.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Celková hmotnost (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Vytvořte jídlo z více ingrediencí a používejte ho jako jakoukoli jinou potravinu.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Zatím žádné recepty",
    ),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Vše"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Recepty"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Recepty se nepodařilo načíst. Zkuste to prosím později.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Přejete si nahlásit chybu vývojáři aplikace?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Znovu"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "nasycené mastné kyseliny",
    ),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage(
      "Skenovat produkt",
    ),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Uzamknout na výšku",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Zadat kód ručně",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage("Zrušit"),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zadejte čárový kód",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "8 až 14 číslic",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Tento čárový kód nevypadá platně. Zkontrolujte prosím číslice a zkuste to znovu.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage(
      "Vyhledat",
    ),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Povolit otáčení",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Zadejte prosím slovo k vyhledání",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Potraviny"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Vyhledat"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkty"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Výsledky hledání",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Vyberte pohlaví",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Zadejte výšku",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Zvolte úroveň vašich aktivit",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Zadejte hmotnost",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Odesílat anonymní data o používání aplikace",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Porce"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Jedna porce (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Jedna porce",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("O aplikaci"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage(
      "Zpětná vazba",
    ),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Akcentová barva",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Vlastní barva…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Otevřít posuvník odstínu pro přesný výběr",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Tento hex kód nevypadá správně — šest znaků, 0-9 a A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex kód"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Vypněte systémové barvy, abyste mohli zvolit vlastní akcent.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Obnovit"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Akcentová barva",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Vyberte barvu",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Vlastní",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Výchozí",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotka tělesné hmotnosti",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl vápníku v miligramech. Výchozí reference je 1000 mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl vápníku",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Postupně zmenšuje denní deficit, aby posledních pár kilogramů nepůsobilo jako zeď.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Upravovat kalorický cíl, jak se blížíte k cílové váze",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage("O aplikaci"),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Vzhled",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Data"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage(
      "Zobrazení",
    ),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Cíle a výživa",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Jednotky a energie",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Vlastní jídla",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Zvol hodinu, ve které začíná tvůj den. Jídla a aktivity zaznamenané před touto hodinou se počítají k předchozímu dni — hodí se při nočních směnách nebo pozdním jídle.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Hodiny",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Den začíná v",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Minuty",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Smazat vše",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Tato akce trvale odstraní z tohoto zařízení váš profil, jídla, aktivity, historii hmotnosti a všechny vlastní recepty. Databáze Open Food Facts a USDA Food Data Central tím nejsou dotčeny. Akci nelze vrátit zpět.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Smazat všechna vaše data?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Smazat všechna moje data",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profil, jídla, aktivity a historii hmotnosti",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Vzdání se nároku",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Vzdálenost"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotka energie",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl vlákniny v gramech. Výchozí reference je 30 g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl vlákniny",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Databáze potravin",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Vyberte, odkud pocházejí výsledky vyhledávání",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperiální (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotky potravin",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrické (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperiální (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Jednotky výšky",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrické (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Imperiální (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl železa v miligramech. Výchozí podle pohlaví (8 mg muž, 18 mg žena, 14 mg jinak).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage("Cíl železa"),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Denní úprava kcal",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Nastavení"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Jazyk"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Licence"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Rozdělení makroživin",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl hořčíku v miligramech. Výchozí podle pohlaví (400 mg muž, 310 mg žena, 355 mg jinak).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl hořčíku",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Hmota"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sladí aplikaci s akcentem vaší tapety v Androidu 12 a novějším.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Použít systémové barvy",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metrické (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Denní připomínka",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Osobní cíle pro každou živinu v denním panelu. Deník je použije místo výchozích denních referencí, kdykoli některý nastavíš.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Cíle živin",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Zvol, které živiny jsou v denním panelu vidět. Skryté lze kdykoli znovu zapnout.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage("Živiny"),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Vyber, které živiny se zobrazí v panelu deníku",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Snídaně",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Rozdělte denní cíl kcal mezi snídani, oběd, večeři a svačiny. Součet podílů musí být 100 %.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Večeře",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Podíl kcal na jídlo",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Oběd",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Svačina",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl draslíku v miligramech. Výchozí reference je 3500 mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl draslíku",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Nastavení soukromí",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nahlásit chybu",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní limit nasycených tuků v gramech. Výchozí reference je 20 g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl nasycených tuků",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Zobrazit sledování aktivity",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Zobrazit makra jídla",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Zobrazit mikroživiny",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní limit sodíku v miligramech. Výchozí reference je 2300 mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl sodíku",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Zdrojový kód",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Zdroje a reference",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní limit cukrů v gramech. Výchozí reference je 50 g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl cukrů",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Systém"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Tmavý"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Vzhled"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Světlý"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Dle systémového nastavení",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Jednotky"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl vitaminu B12 v mikrogramech. Výchozí reference je 2,4 µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl vitaminu B12",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Denní cíl vitaminu D v mikrogramech. Výchozí reference je 15 µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cíl vitaminu D",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Objem"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Používá se pro ukazatel vody na hlavní obrazovce.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Denní cíl pití vody",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Sdílet trénink",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Sdílet kód"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Sdílet jídlo"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage("Sdílet recept"),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "např. jablko, zmrzlina, čokoláda...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Svačina"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodík"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Kalorie spálené při aktivitě se odhadují jako MET × tělesná hmotnost (kg) × doba (hodiny) podle hodnot z Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Kalorie z aktivity (hodnoty MET)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "BMI se počítá jako hmotnost (kg) dělená druhou mocninou výšky (m²). Kategorie (podváha, normální váha, nadváha, obezita I.–III. stupně) odpovídají klasifikaci BMI pro dospělé podle Světové zdravotnické organizace.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Index tělesné hmotnosti (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Denní kalorické cíle, bazální metabolismus a koeficienty fyzické aktivity vycházejí z rovnic Institute of Medicine. Zdroj: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, kapitola 5 a tabulka 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Energetická potřeba (TDEE, BMR a úroveň aktivity)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage(
      "Zobrazit zdroje",
    ),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "Výchozí rozložení 60 % sacharidů, 25 % tuků a 15 % bílkovin spadá do doporučených rozsahů příjmu živin podle WHO. V Nastavení → Výpočty si je můžeš upravit. Zdroj: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Rozložení makroživin",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Výzkum energetického výdeje historicky používal pouze binární pohlavní kategorie, takže pro non-binární osoby neexistuje jediný validovaný vzorec TDEE. OpenNutriTracker proto v Nastavení → Výpočty nabízí volbu mezi zprůměrovanou referencí, estrogen-typickou referencí a testosteron-typickou referencí. Pokud na přesné hodnotě skutečně záleží, prosím poraď se s lékařem, který zná tvůj hormonální stav.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Výpočet kalorií pro non-binární osoby",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Denní referenční hodnoty zobrazené v panelu živin v deníku pocházejí ze souhrnu Dietary Reference Intakes Institute of Medicine, který pokrývá cíle pro jednotlivé živiny u dospělých.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Referenční příjem živin",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Otevřít zdroj",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker používá pro každý zobrazený výpočet zavedené, recenzované metody. Následující odkazy vedou na původní zdroje, takže si můžeš každé číslo sám ověřit.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("cukry"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("přijato"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Přepnout profil",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("trans tuky"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("rekord"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Kalorie"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Denní průměr",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage("dní v řadě"),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "dní v cíli tento týden",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Trendy"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/týden"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Voda"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "týdnů do cíle",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Jednotka"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamin A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamin B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamin B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamin C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamin D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Varování"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Týdenní tempo",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Nenastaveno",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage(
      "Přidat záznam",
    ),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Zaznamenejte alespoň dva dny, abyste viděli vývoj.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Datum"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Zatím žádné záznamy hmotnosti. Přidejte první, abyste mohli sledovat vývoj.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Poznámka (volitelná)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Hmotnost",
    ),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Hmotnost"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Vy"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("zinek"),
  };
}
