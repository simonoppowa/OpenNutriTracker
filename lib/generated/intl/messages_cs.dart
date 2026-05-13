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

  static String m0(versionNumber) => "Verze ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% sacharidy, ${pctFats}% tuky, ${pctProteins}% bílkoviny";

  static String m2(riskValue) => "Riziko komorbidit: ${riskValue}";

  static String m3(age) => "${age} let";

  static String m4(mealType) =>
      "Tyto položky budou přidány do ${mealType}.";

  static String m5(count) => "Importovat ${count} položek?";

  static String m6(count) =>
      "${count} položek nebylo možné načíst z OpenFoodFacts.";

  static String m8(rate) => "${rate} kg/týden";

  static String m9(rate) => "${rate} lbs/týden";

  static String m10(qty, unit) => "Na ${qty} ${unit}";

  static String m11(time) => "Čas připomínky: ${time}";

  static String m12(count) => "Importováno ${count} jídel z CSV souboru.";

  static String m13(imported, skipped) =>
      "Importováno ${imported} jídel; ${skipped} řádků přeskočeno kvůli neplatným datům.";

  static String m14(count, size) => "${count} položek · ${size}";

  static String m15(count) => "${count} ingredience(í)";

  static String m16(count) =>
      "Importovat tento recept s ${count} ingrediencí(emi)?";

  static String m17(count) => "Vybráno: ${count}";

  static String m18(count) => "Smazat ${count} recept(ů)?";


  static String m19(count) => "Importovat ${count} aktivit?";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "např. běh, cyklistika, jóga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Activita"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Přidat nový záznam:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Vložit"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informace poskytnutá\n během \n\'2024 Compendium\n of Physical Activities\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Vlastní jídlo"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Více informadcí na\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Více informací najdete na\nOpenFoodFacts"),
        "additionalInfoLabelRecipe":
            MessageLookupByLibrary.simpleMessage("Vlastní recept"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Neznámá položka jídla"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Věk"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Vše"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alfa]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker je volně šiřitelný open-source tracker kalorického příjmu a nutričních hodnot, který respektuje Vaše soukromí."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Licence GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Základní množství (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Body Mass Index (BMI) je výpočet pro klasifikaci nadváhy a obezity u dospělých. Je definován jako hmotnost v kilogramech vydělená druhou mocninou výšky v metrech (kg/m²).\n\nBMI nerozlišuje mezi tukovou tkání a svalovou hmotou a může být chybně interpretován u některých jedinců."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "např. obilniny, mléko, káva..."),
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
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(doporučeno)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Výpočet Institute of Medicine (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Výpočet TDEE"),
        "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
            "Zprůměrovaná reference (výchozí)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Estrogenní reference"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "Pro nebinární osoby neexistuje publikovaná kalorická základní hodnota — referenční rovnice vycházejí z mužských a ženských vzorků. Standardně používáme průměr obou, neutrální výchozí bod, který od vás nevyžaduje nic dalšího sdělovat o vašem těle. Posuvník kcal v Nastavení je vždy k dispozici pro doladění; toto je výchozí bod, nikoli přesný odhad."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Kalorická reference"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Testosteronová reference"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("s"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Týdenní tempo hmotnosti"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Zvolte cílovou hmotnost"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Odstraní lokálně uložené výsledky Open Food Facts. Mezipaměť se automaticky obnoví při dalším vyhledávání a skenování. Vaše vlastní jídla nejsou ovlivněna."),
        "clearOffCacheConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Vymazat mezipaměť?"),
        "clearOffCacheLabel":
            MessageLookupByLibrary.simpleMessage("Vymazat mezipaměť"),
        "clearOffCacheSubtitle": m14,
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "codeCopiedLabel":
            MessageLookupByLibrary.simpleMessage("Kód zkopírován"),
        "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kopírovat kód"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Který typ jídla si přejete zkopírovat?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Pomocí \"Kopírovat pro dnešek\" můžete vytvořit kopii pro dnešní jídlo. Volbou \"Smazat\" odstraníte zvolený pokrm."),
        "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Jakou akci si přejete provést?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Přejete si vytvořit vlastní potravinu?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Vytvořit vlastní potravinu?"),
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Vytvořit recept"),
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Máte čárový kód? Přispějte produktem do Open Food Facts:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Nelze přečíst CSV soubor. Zkontrolujte formát a zkuste znovu."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Všechny záznamy v deníku používající toto jídlo budou také odstraněny."),
        "customMealsDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Smazat vlastní jídlo?"),
        "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
            "Zatím žádná vlastní jídla uložena."),
        "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
            "Úprava denního kalorického příjmu:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Poskytněte anonymní data týkající se používání aplikace pro pomoc s jejím vývojem"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Smazat vše"),
        "deleteSelectedRecipesConfirmTitle": m18,
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Přejete si vymazat označený záznam?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Přejete si vymazat všechny položky vybraného pokrmu?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Smazat položky?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Smazat záznam?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ZRUŠIT"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Kopírovat pro dnešek"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SMAZAT"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
            "Upravujete datum v budoucnosti"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Diář"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "např. polévka, kuřecí maso, víno..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Večeře"),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Zahodit"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Vaše neuložené změny budou ztraceny."),
        "discardChangesTitle":
            MessageLookupByLibrary.simpleMessage("Zahodit změny?"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker není aplikace pro lékařské účely. Doporučené hodnoty nejsou validovány a měly by být použity opatrně za použití selského rozumu. Dodržujte prosím obecné zásady zdravého životního stylu a kontaktujte lékaře v případě zdravotních problémů. Používání aplikace se nedoporučuje během nemoci, těhotenství či kojení. Recenzované zdroje ke každému výpočtu najdete přes ikonu informací na obrazovce Domů nebo Profil."),
        "downloadSampleCsvAction":
            MessageLookupByLibrary.simpleMessage("Vzorová jídla (csv)"),
        "downloadSampleRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Vzorové recepty (csv)"),
        "duplicateMealDialogContent":
            MessageLookupByLibrary.simpleMessage("Tato potravina už byla dnes přidána k tomuto jídlu. Přidat ji znovu?"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Duplikovat"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(kopie)"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Upravit záznam"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Upravit jídlo"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Upravit recept"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("energie"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Chyba získání dat o produktu"),
        "errorLoadingActivities":
            MessageLookupByLibrary.simpleMessage("Chyba načítání aktivit"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Chyba ukládání jídla. Zkontrolujte prosím správnost zadaných informací."),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Chyba spouštění webového prohlížeče"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Chyba spouštění mailové aplikace"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Produkt nenalezen"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Export"),
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Export / Import dat aplikace"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Můžete uložit data z aplikace do .zip archívu a později je znovu importovat. To je užitečné, pokud potřebujete data zálohovat, nebo přenést na jiné zařízení.\n\nAplikace pro ukládání dat nepoužívá žádné cloudové služby."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import selhal"),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import byl úspěšný"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("tuky"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("t"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("vláknina"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("žena"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Pohlaví"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("muž"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("nebinární"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Přibrat"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Cíl"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Zhubnout"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Zachovat hmotnost"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Výška"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Domů"),
        "importAction": MessageLookupByLibrary.simpleMessage("Import"),
        "importActivityConfirmContent":
            MessageLookupByLibrary.simpleMessage("Tyto aktivity budou přidány do dneška."),
        "importActivityConfirmTitle": m19,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Importovat sdílený trénink"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Trénink importován"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Importujte vlastní jídla ze souboru CSV. Stáhněte si vzor, abyste viděli očekávaný formát sloupců a povinná pole."),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Importovat vlastní data potravin"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Neplatný QR kód"),
        "importMealLabel": MessageLookupByLibrary.simpleMessage(
            "Importovat sdílené jídlo"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Jídlo importováno"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Importovat jídla (csv)"),
        "importOffFetchFailedLabel": m6,
        "importRecipeConfirmContent": m16,
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Nepodařilo se zpracovat kód receptu"),
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Importovat recept"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Recept importován"),
        "importRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Importovat recepty (csv)"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Vložena nová aktivita"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Vložen nový příjem"),
        "ironLabel": MessageLookupByLibrary.simpleMessage("železo"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Záznam smazán"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Záznam upraven"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal zbývá"),
        "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal navíc"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample":
            MessageLookupByLibrary.simpleMessage("např. pizza, salát, rýže..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Oběd"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Poměr nutričních složek:"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("hořčík"),
        "mealBrandsLabel":
            MessageLookupByLibrary.simpleMessage("Výrobce, značka"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("sacharidů na"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("tuků na"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal na"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Název jídla"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Název jídla musí obsahovat alespoň jedno písmeno"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Celkové množství"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("bílkovin na 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Velikost jídla (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Velikost jídla (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Jednotka jídla"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mikroživiny"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Chybí požadovaná energie nebo nutriční hodnoty"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("mononenasycené tuky"),
        "newCustomMealLabel":
            MessageLookupByLibrary.simpleMessage("Nová vlastní potravina"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("niacin (B3)"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Žádné aktivity dosud nezadány"),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("Žádné pokrmy dosud nezadány"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nenalezeny žádné výsledky"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("neuvedeno"),
        "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("Nezadáno"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Nutriční hodnoty"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Normální hmotnost"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obezita 1. stupně"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obezita 2. stupně"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obezita 3. stupně"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Nadváha"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Průměrné"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Zvýšené"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Nízké \n(ale zvýšené pro jiné \nklinické problémy)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Střední"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Vysoké"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Velmi vysoké"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Podváha"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Data poskytnutá aplikací jsou získána z databáze Open Food Facts. Nelze garantovat jejich přesnost, kompletnost nebo spolehlivost. Data jsou poskytována bez záruky a jejich původní poskytovatel (Open Food Facts) není zodpovědný za jakékoliv újmy vzniklé jejich používáním."),
        "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Jak aktivně žijete? (Obecně - proteď prosím neberte v úvahu konkrétní cvičení.)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Vložte datum"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Kdy jste se narodil(a)?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Datum narození"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Jaké je Vaše pohlaví?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Jaký je Váš cíl ohledně hmotnosti?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("např. 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("např. 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Jaká je Vaše výška?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Než začnete, aplikace o Vás potřebuje zadat několik údajů, aby mohla spočítat Váš denní kalorický cíl.\nVeškeré osobní údaje jsou bezpečně uloženy pouze ve Vašem zařízení."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kcal denně"),
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Pro nebinární osoby neexistuje publikovaná kalorická základní hodnota, proto standardně používáme průměr mužských a ženských vzorců — výchozí bod, nikoli přesný odhad. Kdykoli to můžeš upravit v Nastavení → Výpočty."),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Přehled"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Nesprávné zadání, vložte prosím hodnotu znovu"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("např. 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("např. 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Jaká je Vaše hmotnost?"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Vítejte v"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Zadejte správnou výšku"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Zadejte správnou hmotnost"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Vář kalorický cíl:"),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("Vaše nutriční cíle:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("aktivní videohry"),
        "paActiveVideoGamesDesc":
            MessageLookupByLibrary.simpleMessage("Wii Sports, Dance Dance Revolution, obecně"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("americký fotbal"),
        "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "kontaktní, bezkontaktní, obecný"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("lukostřelba"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("nesouvisející s lovem"),
        "paAutoRacing":
            MessageLookupByLibrary.simpleMessage("automobilový sport"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("formule"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("turistika"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "jednotlivec, dvojice, obecný"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basketball"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecný"),
        "paBicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("cyklistika"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("cyklistika, horské kolo"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("cyklistika, stacionární"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("kulečník"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecný"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("box"),
        "paBoxingBagDesc":
            MessageLookupByLibrary.simpleMessage("trénink s boxovacím pytlem"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("box"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("v ringu, obecný"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("kalistenika"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "nízká a střední intenzita, obecná (např. cvičení na záda)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kanoistika"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "veslování, pro zábavu, obecná"),
        "paCatch": MessageLookupByLibrary.simpleMessage("rugby nebo baseball"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("chytání"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage(
            "cheerleading (choreografické povzbuzování)"),
        "paCheerleadingDesc":
            MessageLookupByLibrary.simpleMessage("gymnastické cviky, soutěžní"),
        "paChildrenGame": MessageLookupByLibrary.simpleMessage("dětské hry"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(např. panák, čtvercový král, dodgeball (moderní vybíjená), hry na dětském hřišti, tee-ball, tetherball, kuličky, arcade hry), střední námaha"),
        "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
            "chození po horách, bez zátěže"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("bez zátěže"),
        "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
        "paCricketDesc": MessageLookupByLibrary.simpleMessage(
            "odpalování, nadhazování, hra v poli"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("běh na lyžích"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("běh na lyžích, obecně"),
        "paCurling":
            MessageLookupByLibrary.simpleMessage("curling (lední metaná)"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobik"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecný"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("obecný tanec"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "např. disco, folk, irské stepování, choreografický tanec, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("šipky"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("zeď nebo venkovní prostory"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("potápění"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "bez přístroje, s dýchacím přístrojem, obecné"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("skoky do vody"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("z můstku či plošiny"),
        "paFencing": MessageLookupByLibrary.simpleMessage("šerm"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paFrisbee":
            MessageLookupByLibrary.simpleMessage("frisbee (házení diskem)"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("gymnastika"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paHackySack":
            MessageLookupByLibrary.simpleMessage("Footbag (hakysák/hakisák)"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("házená"),
        "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("obecná"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("závěsné létání"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paHeadingBicycling":
            MessageLookupByLibrary.simpleMessage("cyklistika"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("kondiční cvičení"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("tanec"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("běh"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("sporty"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("chůze"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("vodní sporty"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("zimní sporty"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "vysoce intenzivní intervalový trénink"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("střední intenzita"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "vysoce intenzivní intervalový trénink"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "burpees, horolezci, výskoky z dřepu, Tabata, vysoká intenzita"),
        "paHikingCrossCountry":
            MessageLookupByLibrary.simpleMessage("chůze v přírodě"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("ve volné přírodě"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("pozemní hokej"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("jízda na koni"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("lední hokej"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecný"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("bruslení na ledě"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecné"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai (pelota)"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("žonglování"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kajak"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("střední úsilí"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paLawnBowling":
            MessageLookupByLibrary.simpleMessage("trávníkový bowling"),
        "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
            "bocce ball (italský bowling), venkovní bowling"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("bojová umění"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "různé druhy, střední tempo (např. judo, jujitsu, karate, kickbox, taekwondo, tai-bo, thajský box)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("bojová umění"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "různé druhy, mírné tempo, začátečníci, nácvik"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-cross"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "off-road jízda, terénní vozy, obecný"),
        "paMountainClimbing":
            MessageLookupByLibrary.simpleMessage("horolezectví"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("na skálu či horu"),
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("severská chůze"),
        "paOrienteering":
            MessageLookupByLibrary.simpleMessage("orientační běh"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("paddle boarding"),
        "paPaddleBoardingDesc":
            MessageLookupByLibrary.simpleMessage("ve stoje"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pádlování"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("rekreační, obecný"),
        "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
        "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("pólo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koni"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("raketbal"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("silový trénink"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "vzpírání, cvičení s vlastní váhou, cvičení na nautilu, obecné posilování"),
        "paResistanceTrainingVigorous":
            MessageLookupByLibrary.simpleMessage("silový trénink (intenzivní)"),
        "paResistanceTrainingVigorousDesc":
            MessageLookupByLibrary.simpleMessage("intenzivní úsilí, silový trojboj nebo kulturistika"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("rodeo"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("obecné, střední úsilí"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("jízda na inline bruslích"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("in-line"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("skákání přes švihadlo"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "střední tempo, 100-120 skoků/min, obecné, snožmo, základní skok"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("skákání přes švihadlo"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecné"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("týmová soutěžní hra"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("kontaktní, nesoutěžní"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("běh"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("plachtění"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "plachtění na lodi a prkně, windsurfing, plachtění na ledě, obecné"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("jízda na skateboardu"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecný, střední úsilí"),
        "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
            "jízda na kolečkových bruslích"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("obecná"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("lyžování"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("vodní lyžování"),
        "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
            "vodní lyžování, wakeboarding"),
        "paSkydiving":
            MessageLookupByLibrary.simpleMessage("seskoky volným pádem"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "skoky z letadla, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("šnorchlování"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("odhrabování sněhu"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("ručně, střední námaha"),
        "paSnowshoeing":
            MessageLookupByLibrary.simpleMessage("chůze na sněžnicích"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("fotbal"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("rekreační, obecný"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "ryachlý nebo pomalý nadhoz, obecný"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paStretching": MessageLookupByLibrary.simpleMessage("strečink"),
        "paStretchingDesc":
            MessageLookupByLibrary.simpleMessage("mírné, obecně"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surfování"),
        "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
            "bodysurfing či na prkně, obecné"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("plavání"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "šlapání vody, střední úsilí, obecné"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("stolní tenis"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("stolní tenis, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai či, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecné"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("lehká atletika"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(např. střelba, hod diskem, hod kladivem)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(např. skok do výšky, skok do dálky, trojskok, hod oštěpem, skok o tyči)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(např. dostihy, překážkový běh)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolína"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("rekreačně"),
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("běh na běžícím pásu"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("na běžícím pásu, obecně"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("jednokolka"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("obecná"),
        "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("volejbal"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "nesoutěžní, 6 - 9 hráčů, obecný"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("chůze"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("pro zábavu"),
        "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("venčení psa"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("vodní cvičení"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "vodní aerobik, vodní kalistenika"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("vodní pólo"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("obecné"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("vodní volejbal"),
        "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("vodní aerobik"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "vodní aerobik, vodní kalistenika"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("obecný"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Práce převážně ve stoje nebo vyžadující chůzi a aktivní volnočasové činnosti"),
        "palActiveLabel":
            MessageLookupByLibrary.simpleMessage("Aktivní životní styl"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "např. práce v sedě či ve stoje a lehké volnočasové aktivity"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Nízká aktivita"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "např. kancelářská práce a aktivity provozované převážně v sedě"),
        "palSedentaryLabel":
            MessageLookupByLibrary.simpleMessage("Sedavý životní styl"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Převažující chůze, běh nebo nošení břemen při práci a aktivní volnočasové činnosti"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Velmi aktivní životní styl"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Vložte sem sdílený kód jídla"),
        "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Vložit kód"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Na 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Na porci"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("polynenasycené tuky"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("draslík"),
        "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
            "Pravidla týkající se soukromí"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("bílkoviny"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("b"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Množství"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Četl jsem pravidla ohledně soukromí a souhlasím s nimi."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Nedávné"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Přidat ingredienci"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Předchozí záznamy v deníku z tohoto receptu budou zachovány."),
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Smazat recept?"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Popis (volitelný)"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Množství"),
        "recipeIngredientCountLabel": m15,
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Jednotka"),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Ingredience"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Celková hmotnost musí být větší než nula"),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Zaznamenat tento recept"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Název receptu"),
        "recipeNameRequiredLabel":
            MessageLookupByLibrary.simpleMessage("Recept potřebuje název"),
        "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
            "Přidejte alespoň jednu ingredienci"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Zatím žádné ingredience"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("Na 100 g"),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Výživa (celkem)"),
        "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Recept se nepodařilo uložit."),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Uložit recept"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Umožňuje zaznamenávat tento recept po porcích místo gramů."),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Porce (volitelné)"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Oddělené čárkou, např. \"snídaně, veganské\""),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Štítky"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "Výchozí hodnotou je součet ingrediencí. Tekutiny jsou přibližně 1 ml ≈ 1 g."),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Celková hmotnost (g)"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Vytvořte jídlo z více ingrediencí a používejte ho jako jakoukoli jinou potravinu."),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("Zatím žádné recepty"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("Vše"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Recepty"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Recepty se nepodařilo načíst. Zkuste to prosím později."),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Přejete si nahlásit chybu vývojáři aplikace?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Znovu"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("nasycené mastné kyseliny"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Skenovat produkt"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Zadejte prosím slovo k vyhledání"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Potraviny"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Vyhledat"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkty"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Výsledky hledání"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Vyberte pohlaví"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Zadejte výšku"),
        "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
            "Zvolte úroveň vašich aktivit"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Zadejte hmotnost"),
        "selectionCountLabel": m17,
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Odesílat anonymní data o používání aplikace"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Porce"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Velikost porce (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Velikost porce (g/ml)"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("O aplikaci"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Zpětná vazba"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Vypočtené hodnoty"),
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Vlastní jídla"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Vzdání se nároku"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Zdroje a reference"),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("Zobrazit zdroje"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker používá pro každý zobrazený výpočet zavedené, recenzované metody. Následující odkazy vedou na původní zdroje, takže si můžeš každé číslo sám ověřit."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Energetická potřeba (TDEE, BMR a úroveň aktivity)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Denní kalorické cíle, bazální metabolismus a koeficienty fyzické aktivity vycházejí z rovnic Institute of Medicine. Zdroj: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, kapitola 5 a tabulka 5-5."),
        "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
            "Index tělesné hmotnosti (BMI)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "BMI se počítá jako hmotnost (kg) dělená druhou mocninou výšky (m²). Kategorie (podváha, normální váha, nadváha, obezita I.–III. stupně) odpovídají klasifikaci BMI pro dospělé podle Světové zdravotnické organizace."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Rozložení makroživin"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "Výchozí rozložení 60 % sacharidů, 25 % tuků a 15 % bílkovin spadá do doporučených rozsahů příjmu živin podle WHO. V Nastavení → Výpočty si je můžeš upravit. Zdroj: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Kalorie z aktivity (hodnoty MET)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Kalorie spálené při aktivitě se odhadují jako MET × tělesná hmotnost (kg) × doba (hodiny) podle hodnot z Adult Compendium of Physical Activities."),
        "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
            "Výpočet kalorií pro non-binární osoby"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "Výzkum energetického výdeje historicky používal pouze binární pohlavní kategorie, takže pro non-binární osoby neexistuje jediný validovaný vzorec TDEE. OpenNutriTracker proto v Nastavení → Výpočty nabízí volbu mezi zprůměrovanou referencí, estrogen-typickou referencí a testosteron-typickou referencí. Pokud na přesné hodnotě skutečně záleží, prosím poraď se s lékařem, který zná tvůj hormonální stav. Zdroj: Linsenmeyer W, Waters J. Sex and gender differences in nutrition research: considerations with the transgender and gender nonconforming population. Nutrition Journal 2021;20:6."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("Otevřít zdroj"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Vzdálenost"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperiální (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Nastavení"),
        "settingsLanguageLabel":
            MessageLookupByLibrary.simpleMessage("Jazyk"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licence"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Hmota"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metrické (kg, cm, ml)"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Denní připomínka"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("Oprávnění k upozorněním bylo odepřeno."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Nezapomeňte si dnes zaznamenat svá jídla!"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Nastavení soukromí"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Nahlásit chybu"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Zobrazit sledování aktivity"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Zobrazit makra jídla"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Zobrazit mikroživiny"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Zdrojový kód"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Systém"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Tmavý"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Vzhled"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Světlý"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Dle systémového nastavení"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Jednotky"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Objem"),
        "shareActivityLabel":
            MessageLookupByLibrary.simpleMessage("Sdílet trénink"),
        "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Sdílet kód"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("Sdílet jídlo"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Sdílet recept"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "např. jablko, zmrzlina, čokoláda..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Svačina"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodík"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("cukry"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("přijato"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("trans tuky"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Jednotka"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamin A"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamin B12"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamin B6"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamin C"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamin D"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Varování"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Týdenní tempo"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Nenastaveno"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Hmotnost"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("zinek"),
      };
}
