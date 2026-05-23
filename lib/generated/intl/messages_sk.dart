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

  static String m0(versionNumber) => "Verzia ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% sacharidy, ${pctFats}% tuky, ${pctProteins}% bielkoviny";

  static String m2(riskValue) => "Riziko sprievodných ochorení: ${riskValue}";

  static String m3(age) => "${age} rokov";

  static String m4(mealType) =>
      "Tieto položky budú pridané do vašich ${mealType}.";

  static String m5(count) => "Importovať ${count} položiek?";

  static String m6(count) =>
      "${count} položiek sa nepodarilo načítať z OpenFoodFacts.";

  static String m8(rate) => "${rate} kg/týždeň";

  static String m9(rate) => "${rate} lbs/týždeň";

  static String m10(qty, unit) => "Na ${qty} ${unit}";

  static String m11(time) => "Čas pripomienky: ${time}";

  static String m12(count) => "Importovaných ${count} jedál.";

  static String m13(imported, skipped) =>
      "Importovaných ${imported} jedál; ${skipped} riadkov bolo preskočených pre neplatné údaje.";

  static String m14(count, size) => "${count} položiek · ${size}";

  static String m15(count) => "${count} ingrediencií";

  static String m16(count) =>
      "Importovať tento recept s ${count} ingredienciou(ami)?";

  static String m17(count) => "Vybrané: ${count}";

  static String m18(count) => "Zmazať ${count} recept(ov)?";


  static String m19(count) => "Importovať ${count} aktivít?";

  static String m20(detail) => "Spracovanie zlyhalo: ${detail}";

  static String m21(count, customCount) =>
      "Zaznamenaných ${count} z JSON, ${customCount} uložených ako vlastné jedlá";

  static String m22(value) => "${value} do cieľa";

  static String m23(consumed, target) => "${consumed} / ${target} kcal";

  static String m24(unit) => "${unit} v jednej porcii";

  static String m25(hour) => "${hour}:00";

  static String m26(hour, minute) => "${hour}:${minute}";

  static String mLowKcal(threshold) =>
      "Dospelí by bez lekárskeho dohľadu nemali dlhodobo prijímať menej než ${threshold} kcal denne. Zvážte konzultáciu so zdravotníckym odborníkom skôr, než zostanete pri takomto nízkom cieli.";

  static String mWaterChip(current, goal) => "${current} / ${goal} ml";

  static String mLogWaterAmount(amount) => "Pridať ${amount} ml";

  static String mFastingRemaining(value) => "Zostáva ${value}";

  static String mFastingTarget(value) => "Cieľ: ${value}";
  static String mMergeConfirm(loser, winner) =>
      "Tým sa všetky záznamy zapísané s ${loser} nahradia, aby zobrazovali ${winner}, a ${loser} bude odstránené z vašich vlastných jedál. Túto akciu nemožno vrátiť späť.";

  static String mMergeSuccess(count, winner) =>
      "Zlúčené — ${winner} má teraz ${count} zaznamenaných záznamov.";
  static String mDriRef(value) => "ref. ${value}";
  static String mMergeOneSk(winner) => "Zlúčené — ${winner} má teraz 1 záznam.";
  static String mFastingChipSk(remaining) => "Pôst · zostáva ${remaining}";

  static String mMealDetailDayTotal(consumed, goal) =>
      "Denný súčet: ${consumed} / ${goal}";

  static String mMealDetailCurrentSelection(kcal) =>
      "(+${kcal} kcal aktuálny výber)";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "napr. beh, cyklistika, joga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Aktivita"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Pridať novú položku:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Pridať"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informácie poskytnuté\n cez \n\'2024 Compendium\n of Physical Activities\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Vlastná položka jedla"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Viac informácií na\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Viac informácií na\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Neznáma položka jedla"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Vek"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Všetky"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alfa]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker je bezplatná open-source aplikácia na sledovanie kalórií a živín, ktorá rešpektuje vaše súkromie."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Licencia GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Základné množstvo (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Index telesnej hmotnosti (BMI) je ukazovateľ na klasifikáciu nadváhy a obezity u dospelých. Vypočíta sa ako hmotnosť v kilogramoch delená druhou mocninou výšky v metroch (kg/m²).\n\nBMI nerozlišuje medzi tukovou a svalovou hmotou a u niektorých jednotlivcov môže byť zavádzajúci."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "napr. cereálie, mlieko, káva ..."),
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
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(odporúčané)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Rovnica Institute of Medicine (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Rovnica TDEE"),
        "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
            "Spriemerovaná referencia (predvolené)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Estrogénová referencia"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "Pre nebinárne osoby neexistuje publikovaná kalorická základňa — referenčné rovnice vychádzajú z mužských a ženských vzoriek. Štandardne používame priemer oboch, neutrálny východiskový bod, ktorý od vás nežiada nič viac o vašom tele. Posuvník kcal v Nastaveniach je vždy k dispozícii na doladenie; je to východiskový bod, nie presný odhad."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Kalorická referencia"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Testosterónová referencia"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("sacharidy"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("s"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Týždenné tempo hmotnosti"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Zvoľte cieľovú hmotnosť"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Odstráni lokálne uložené výsledky vyhľadávania a skenovania z Open Food Facts a FDC. Pamäť sa automaticky obnoví pri ďalšom vyhľadávaní a skenovaní produktov. Vaše vlastné jedlá to neovplyvní."),
        "clearOffCacheConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Vymazať uložené položky?"),
        "clearOffCacheLabel":
            MessageLookupByLibrary.simpleMessage("Vymazať uložené položky"),
        "clearOffCacheSubtitle": m14,
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "codeCopiedLabel":
            MessageLookupByLibrary.simpleMessage("Kód skopírovaný"),
        "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kopírovať kód"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Do ktorého typu jedla chcete skopírovať?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Voľbou \"Kopírovať na dnes\" môžete jedlo skopírovať na dnešok. Voľbou \"Zmazať\" môžete jedlo odstrániť."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Čo chcete urobiť?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Chcete vytvoriť vlastnú položku jedla?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Vytvoriť vlastnú položku jedla?"),
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Vytvoriť recept"),
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Máte čiarový kód? Pomôžte všetkým a prispejte produktom do Open Food Facts:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "CSV súbor sa nepodarilo prečítať. Skontrolujte formát a skúste to znova."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "recipeImageLabel":
            MessageLookupByLibrary.simpleMessage("Pridať fotografiu"),
        "recipeImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Vybrať z galérie"),
        "recipeImageRemove":
            MessageLookupByLibrary.simpleMessage("Odstrániť fotografiu"),
        "recipeImageReplace":
            MessageLookupByLibrary.simpleMessage("Nahradiť fotografiu"),
        "mealImageLabel":
            MessageLookupByLibrary.simpleMessage("Pridať fotku"),
        "mealImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Vybrať z galérie"),
        "mealImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Odfotiť"),
        "mealImageRemove":
            MessageLookupByLibrary.simpleMessage("Odstrániť fotku"),
        "mealImageReplace":
            MessageLookupByLibrary.simpleMessage("Nahradiť fotku"),
        "recipeImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Odfotiť"),
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Všetky záznamy v denníku, ktoré používajú toto jedlo, budú tiež odstránené."),
        "customMealsDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Zmazať vlastné jedlo?"),
        "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
            "Zatiaľ nie sú uložené žiadne vlastné jedlá."),
        "customMealsRowMoreTooltip":
            MessageLookupByLibrary.simpleMessage("Ďalšie akcie"),
        "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
            "Zlúčiť s iným vlastným jedlom"),
        "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
            "Vyberte vlastné jedlo na zlúčenie"),
        "customMealsMergeChooseSurvivorTitle":
            MessageLookupByLibrary.simpleMessage("Ktoré ostane?"),
        "customMealsMergeContinueAction":
            MessageLookupByLibrary.simpleMessage("Pokračovať"),
        "customMealsMergeConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Zlúčiť vlastné jedlá?"),
        "customMealsMergeConfirmContent": mMergeConfirm,
        "customMealsMergeConfirmAction":
            MessageLookupByLibrary.simpleMessage("Zlúčiť"),
                "customMealsMergeSuccessSnackbarOne": mMergeOneSk,
        "customMealsMergeSuccessSnackbarOther": mMergeSuccess,
        "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
            "Denná úprava kcal:"),
        "dailyKjAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Denná úprava kJ:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Posielať anonymné hlásenia o páde, aby sme mohli opravovať chyby. Nezahŕňajú sa žiadne záznamy o jedle, hmotnosti ani osobné údaje."),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Zmazať všetko"),
        "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
            "Zmazať všetky moje údaje"),
        "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
            "Profil, jedlá, aktivity a históriu hmotnosti"),
        "settingsDeleteAllDataConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Zmazať všetky vaše údaje?"),
        "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Tým sa z tohto zariadenia natrvalo odstráni váš profil, jedlá, aktivity, história hmotnosti a všetky vlastné recepty. Databázy Open Food Facts a USDA Food Data Central tým nie sú ovplyvnené. Túto akciu nie je možné vrátiť späť."),
        "settingsDeleteAllDataConfirmAction":
            MessageLookupByLibrary.simpleMessage("Zmazať všetko"),
        "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
            "Tento denný cieľ je dosť nízky"),
        "lowKcalWarningBody": mLowKcal,
        "lowKcalWarningViewDisclaimer":
            MessageLookupByLibrary.simpleMessage("Zobraziť upozornenie"),
        "deleteSelectedRecipesConfirmTitle": m18,
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Naozaj chcete zmazať vybranú položku?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Naozaj chcete zmazať všetky položky tohto jedla?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Zmazať položky?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Zmazať položku?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ZRUŠIŤ"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Kopírovať na dnes"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("ZMAZAŤ"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryNutrientPanelDataDisclaimer":
            MessageLookupByLibrary.simpleMessage("Sčítavajú sa iba živiny zaznamenané pri zalogovaných jedlách. Jedlo bez hodnoty k danej živine neprispeje — súčty preto môžu byť podhodnotené."),
        "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
            "Upravujete dátum v budúcnosti"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Denník"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "napr. polievka, kuracie mäso, víno ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Večera"),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Zahodiť"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Vaše neuložené zmeny budú stratené."),
        "discardChangesTitle":
            MessageLookupByLibrary.simpleMessage("Zahodiť zmeny?"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker nie je zdravotnícka aplikácia. Všetky poskytnuté údaje nie sú validované a mali by sa používať s opatrnosťou. Dodržiavajte zdravý životný štýl a v prípade ťažkostí sa poraďte s odborníkom. Používanie počas choroby, tehotenstva alebo dojčenia sa neodporúča. Recenzované zdroje za každým výpočtom nájdete cez ikonu informácií na obrazovke Domov alebo Profil."),
        "downloadSampleCsvAction":
            MessageLookupByLibrary.simpleMessage("Vzorové jedlá (csv)"),
        "downloadSampleJsonAction":
            MessageLookupByLibrary.simpleMessage("Vzorové jedlá (json)"),
        "importMealsJsonAction":
            MessageLookupByLibrary.simpleMessage("Importovať jedlá (json)"),
        "downloadSampleRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Vzorové recepty (json)"),
        "importRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Importovať recepty (json)"),
        "downloadSampleRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Vzorové recepty (csv)"),
        "duplicateMealDialogContent":
            MessageLookupByLibrary.simpleMessage("Toto jedlo už bolo dnes pridané. Pridať ho znova?"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Duplikovať"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(kópia)"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Upraviť položku"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Upraviť jedlo"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Upraviť recept"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("energia"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Chyba pri načítavaní údajov o produkte"),
        "errorLoadingActivities":
            MessageLookupByLibrary.simpleMessage("Chyba pri načítavaní aktivít"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Chyba pri ukladaní jedla. Zadali ste správne údaje o jedle?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Chyba pri otváraní prehliadača"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Chyba pri otváraní e-mailovej aplikácie"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Produkt sa nenašiel"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Exportovať"),
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Exportovať / Importovať údaje aplikácie"),
        "exportImportCsvRecipesNote":
            MessageLookupByLibrary.simpleMessage("CSV obsahuje aktivitu, denník jedál a zaznamenané dni. Recepty a pripojené fotky sa ukladajú len do JSON — prepni na JSON, ak ich chceš mať v zálohe."),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Údaje aplikácie môžete exportovať do zip súboru a neskôr ich importovať. Hodí sa to, keď si chcete údaje zálohovať alebo preniesť do iného zariadenia.\n\nAplikácia nepoužíva na ukladanie vašich údajov žiadnu cloudovú službu."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Chyba exportu / importu"),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Export / Import bol úspešný"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("tuky"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("t"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("vláknina"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("žena"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Pohlavie"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("muž"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("nebinárne"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Pribrať"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Cieľ"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Schudnúť"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Udržať hmotnosť"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Výška"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Domov"),
        "importAction": MessageLookupByLibrary.simpleMessage("Importovať"),
        "importActivityConfirmContent":
            MessageLookupByLibrary.simpleMessage("Tieto aktivity budú pridané k dnešku."),
        "importActivityConfirmTitle": m19,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Importovať zdieľaný tréning"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Tréning importovaný"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Importujte vlastné jedlá zo súboru CSV alebo vložením JSON. Stiahnite si vzor, aby ste videli očakávaný tvar a povinné polia."),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Importovať vlastné údaje o jedle"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Neplatný QR kód"),
        "importMealLabel": MessageLookupByLibrary.simpleMessage(
            "Importovať zdieľané jedlo"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Jedlo importované"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Importovať jedlá (csv)"),
        "importOffFetchFailedLabel": m6,
        "importRecipeConfirmContent": m16,
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Kód receptu sa nepodarilo spracovať"),
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Importovať recept"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Recept importovaný"),
        "importRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Importovať recepty (csv)"),
        "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
            "Tieto hodnoty úplne nesedia — kalórie, ktoré ste zadali, nezodpovedajú energii zo sacharidov, tukov a bielkovín nižšie. Uložiť aj tak, alebo to ešte raz prejsť?"),
        "inconsistentNutritionWarningEdit":
            MessageLookupByLibrary.simpleMessage("Ešte raz prejsť"),
        "inconsistentNutritionWarningSaveAnyway":
            MessageLookupByLibrary.simpleMessage("Uložiť aj tak"),
        "inconsistentNutritionWarningTitle":
            MessageLookupByLibrary.simpleMessage("Čísla úplne nesedia"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Pridaná nová aktivita"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Pridaný nový príjem"),
        "ironLabel": MessageLookupByLibrary.simpleMessage("železo"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Položka zmazaná"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Položka aktualizovaná"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal zostáva"),
        "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal navyše"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample":
            MessageLookupByLibrary.simpleMessage("napr. pizza, šalát, ryža ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Obed"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Rozdelenie makroživín:"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("horčík"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Značky"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Sacharidy"),
        "mealDetailCurrentSelectionLabel": mMealDetailCurrentSelection,
        "mealDetailDayTotalLabel": mMealDetailDayTotal,
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("Tuky"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Názov jedla"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Názov jedla musí obsahovať aspoň jedno písmeno"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Celkové množstvo"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("Bielkoviny"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Veľkosť jedla (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Veľkosť jedla (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Jednotka jedla"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mikroživiny"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Produktu chýbajú povinné údaje o kcal alebo makroživinách"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("mononenasýtené tuky"),
        "newCustomMealLabel":
            MessageLookupByLibrary.simpleMessage("Nové vlastné jedlo"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("niacín (B3)"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "V poslednom čase neboli pridané žiadne aktivity"),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("V poslednom čase neboli pridané žiadne jedlá"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nenašli sa žiadne výsledky"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("neuvedené"),
        "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("Nič nepridané"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Nutričné údaje"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Normálna hmotnosť"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obezita 1. stupňa"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obezita 2. stupňa"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obezita 3. stupňa"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Nadváha"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Priemerné"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Zvýšené"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Nízke \n(ale zvýšené riziko \niných klinických problémov)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Stredné"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Vysoké"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Veľmi vysoké"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Podváha"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Údaje poskytnuté touto aplikáciou pochádzajú z databázy Open Food Facts. Nemožno zaručiť ich presnosť, úplnosť ani spoľahlivosť. Údaje sa poskytujú „tak, ako sú“ a pôvodný zdroj údajov (Open Food Facts) nezodpovedá za žiadne škody vyplývajúce z ich použitia."),
        "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Aký aktívny životný štýl vediete? (bez cvičení)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Zadajte dátum"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Kedy máte narodeniny?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Narodeniny"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Aké je vaše pohlavie?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Aký je váš aktuálny cieľ ohľadom hmotnosti?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("napr. 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("napr. 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Aká je vaša aktuálna výška?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Na začiatok potrebuje aplikácia o vás niekoľko informácií, aby mohla vypočítať váš denný kalorický cieľ.\nVšetky informácie o vás sú bezpečne uložené iba vo vašom zariadení."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kcal za deň"),
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Pre nebinárne osoby neexistuje publikovaná kalorická základňa, preto štandardne používame priemer mužského a ženského vzorca — východiskový bod, nie presný odhad. Kedykoľvek si to môžete doladiť v Nastavenia → Výpočty."),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Prehľad"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Nesprávny vstup, skúste to znova"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("napr. 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("napr. 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Aká je vaša aktuálna hmotnosť?"),
        "onboardingTargetWeightSubtitle":
            MessageLookupByLibrary.simpleMessage("Máš hmotnosť, ku ktorej smeruješ? Pole môžeš nechať prázdne alebo ho neskôr zmeniť v Profile."),
        "onboardingTargetWeightHintOptional":
            MessageLookupByLibrary.simpleMessage("Voliteľné"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Víta vás"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Zadajte správnu výšku"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Zadajte správnu hmotnosť"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Váš kalorický cieľ:"),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("Vaše ciele pre makroživiny:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("aktívne videohry"),
        "paActiveVideoGamesDesc":
            MessageLookupByLibrary.simpleMessage("Wii Sports, Dance Dance Revolution, všeobecne"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("americký futbal"),
        "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "kontaktný, bezkontaktný, všeobecne"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("lukostreľba"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("neloveckého charakteru"),
        "paAutoRacing":
            MessageLookupByLibrary.simpleMessage("automobilové preteky"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("formula"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("turistika s batohom"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("bedminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rekreačná dvojhra a štvorhra, všeobecne"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basketbal"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("cyklistika"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("cyklistika, horská"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("cyklistika, stacionárna"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("biliard"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("box"),
        "paBoxingBagDesc":
            MessageLookupByLibrary.simpleMessage("tréning s boxovacím vrecom"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("box"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("v ringu, všeobecne"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("kalistenika"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "ľahká alebo stredná záťaž, všeobecne (napr. cvičenie na chrbát)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kanoistika"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "veslovanie, pre potešenie, všeobecne"),
        "paCatch": MessageLookupByLibrary.simpleMessage("futbal alebo bejzbal"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("naháňačka s loptou"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage(
            "roztlieskavanie"),
        "paCheerleadingDesc":
            MessageLookupByLibrary.simpleMessage("gymnastické prvky, súťažné"),
        "paChildrenGame": MessageLookupByLibrary.simpleMessage("detské hry"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(napr. škôlka, štvorec, vybíjaná, prvky ihriska, t-ball, švihadlo na stĺpe, guľôčky, arkádové hry), stredná záťaž"),
        "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
            "stúpanie do kopcov, bez záťaže"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("bez záťaže"),
        "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
        "paCricketDesc": MessageLookupByLibrary.simpleMessage(
            "pálkovanie, nadhadzovanie, chytanie"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("beh na lyžiach"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("beh na lyžiach, všeobecne"),
        "paCurling":
            MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobik"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("všeobecný tanec"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "napr. disko, ľudový, írsky step, line dance, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("šípky"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("stena alebo trávnik"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("potápanie"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "freediving, scuba diving, všeobecne"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("skoky do vody"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("z mostíka alebo plošiny"),
        "paFencing": MessageLookupByLibrary.simpleMessage("šerm"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paFrisbee":
            MessageLookupByLibrary.simpleMessage("frisbee"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("gymnastika"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paHackySack":
            MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("hádzaná"),
        "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("závesné lietanie"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paHeadingBicycling":
            MessageLookupByLibrary.simpleMessage("cyklistika"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("kondičné cvičenie"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("tanec"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("beh"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("športy"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("chôdza"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("vodné aktivity"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("zimné aktivity"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "vysoko intenzívny intervalový tréning"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("stredná záťaž"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "vysoko intenzívny intervalový tréning"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "burpees, horolezci, drepy s výskokom, Tabata, vysoká záťaž"),
        "paHikingCrossCountry":
            MessageLookupByLibrary.simpleMessage("turistika"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("v teréne"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("hokej, pozemný"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("jazda na koni"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("ľadový hokej"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("korčuľovanie na ľade"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("žonglovanie"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kajak"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("stredná záťaž"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paLawnBowling":
            MessageLookupByLibrary.simpleMessage("trávnikový bowling"),
        "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
            "bocce, vonku"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("bojové umenia"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "rôzne druhy, stredné tempo (napr. judo, jiu-jitsu, karate, kickbox, taekwondo, tai-bo, thajský box)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("bojové umenia"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "rôzne druhy, pomalšie tempo, začiatočníci, nácvik"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("motokros"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "terénne motošporty, štvorkolky, všeobecne"),
        "paMountainClimbing":
            MessageLookupByLibrary.simpleMessage("horolezectvo"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("lezenie po skalách alebo horách"),
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("nordic walking"),
        "paOrienteering":
            MessageLookupByLibrary.simpleMessage("orientačný beh"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("paddleboarding"),
        "paPaddleBoardingDesc":
            MessageLookupByLibrary.simpleMessage("v stoji"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("šliapací čln"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("rekreačne, všeobecne"),
        "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
        "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("pólo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koni"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("silový tréning"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "vzpieranie, voľné činky, nautilus alebo univerzálne stroje"),
        "paResistanceTrainingVigorous":
            MessageLookupByLibrary.simpleMessage("silový tréning (intenzívny)"),
        "paResistanceTrainingVigorousDesc":
            MessageLookupByLibrary.simpleMessage("intenzívna záťaž, powerlifting alebo kulturistika"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("rodeo"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne, stredná záťaž"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("rollerblade"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("kolieskové korčule v rade"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("skákanie cez švihadlo"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "stredné tempo, 100 – 120 skokov/min, všeobecne, znožmo, základný skok"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("skákanie cez švihadlo"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("union, tímové, súťažné"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("dotykové, nesúťažné"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("beh"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("plachtenie"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "plachtenie na lodi a doske, windsurfing, plachtenie na ľade, všeobecne"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("skateboarding"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne, stredná záťaž"),
        "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
            "kolieskové korčuľovanie"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("lyžovanie"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("vodné lyžovanie"),
        "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
            "vodné lyžovanie alebo wakeboarding"),
        "paSkydiving":
            MessageLookupByLibrary.simpleMessage("skoky padákom"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "skoky padákom, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("šnorchlovanie"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("odhŕňanie snehu"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("ručne, stredná záťaž"),
        "paSnowshoeing":
            MessageLookupByLibrary.simpleMessage("chôdza na snežniciach"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("futbal"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("rekreačne, všeobecne"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softbal / bejzbal"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rýchly alebo pomalý nadhoz, všeobecne"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paStretching": MessageLookupByLibrary.simpleMessage("strečing"),
        "paStretchingDesc":
            MessageLookupByLibrary.simpleMessage("mierny, všeobecne"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surfovanie"),
        "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
            "telom alebo doskou, všeobecne"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("plávanie"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "šliapanie vody, stredná záťaž, všeobecne"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("stolný tenis"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("stolný tenis, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("atletika"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(napr. guľa, disk, kladivo)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(napr. skok do výšky, skok do diaľky, trojskok, oštep, žrď)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(napr. steeplechase, prekážky)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolína"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("rekreačne"),
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("beh na bežiacom páse"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("na bežiacom páse, všeobecne"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("jednokolka"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("volejbal"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "nesúťažný, tím 6 – 9 hráčov, všeobecne"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("chôdza"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("pre potešenie"),
        "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("venčenie psa"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("vodné cvičenie"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "vodný aerobik, vodná kalistenika"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("vodné pólo"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("vodný volejbal"),
        "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("vodný aerobik"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "vodný aerobik, vodná kalistenika"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("zápasenie"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("všeobecne"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Prevažne státie alebo chôdza v práci a aktívne voľnočasové činnosti"),
        "palActiveLabel":
            MessageLookupByLibrary.simpleMessage("Aktívny"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "napr. sedavá alebo stojaca práca a ľahké voľnočasové činnosti"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Mierne aktívny"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "napr. kancelárska práca a prevažne sedavé voľnočasové činnosti"),
        "palSedentaryLabel":
            MessageLookupByLibrary.simpleMessage("Sedavý"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Prevažne chôdza, beh alebo nosenie záťaže v práci a aktívne voľnočasové činnosti"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Veľmi aktívny"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Sem prilepte zdieľaný kód jedla"),
        "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Prilepiť kód"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Na 100 g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Na porciu"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("polynenasýtené tuky"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("draslík"),
        "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
            "Zásady ochrany súkromia"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "profileWeightHistoryTitle":
            MessageLookupByLibrary.simpleMessage("História hmotnosti"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("bielkoviny"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("b"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Množstvo"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Prečítal/a som si a súhlasím so zásadami ochrany súkromia."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Nedávno"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Pridať ingredienciu"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Predchádzajúce záznamy v denníku z tohto receptu zostanú zachované."),
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Zmazať recept?"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Popis (voliteľný)"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Množstvo"),
        "recipeIngredientCountLabel": m15,
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Jednotka"),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Ingrediencie"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Celková hmotnosť musí byť väčšia ako nula"),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Zaznamenať tento recept"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Názov receptu"),
        "recipeNameRequiredLabel":
            MessageLookupByLibrary.simpleMessage("Recept potrebuje názov"),
        "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
            "Pridajte aspoň jednu ingredienciu"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Zatiaľ žiadne ingrediencie"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("Na 100 g"),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Výživa (celkom)"),
        "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Recept sa nepodarilo uložiť."),
        "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
            "Zapnite, ak si chcete toto jedlo ponechať v uloženom zozname na nabudúce. Nechajte vypnuté pri jednorazovom jedle, ktoré už opäť nezjete."),
        "recipeSaveForLaterLabel":
            MessageLookupByLibrary.simpleMessage("Uložiť na nabudúce"),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Uložiť recept"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Umožní vám zaznamenať tento recept po porciách namiesto gramov."),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Porcie (voliteľné)"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Oddelené čiarkou, napr. „raňajky, vegánske“"),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Štítky"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "Predvolene súčet ingrediencií. Tekutiny sa približujú ako 1 ml ≈ 1 g."),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Celková hmotnosť (g)"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Postavte si jedlo z viacerých ingrediencií a používajte ho ako ktorúkoľvek inú potravinu."),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("Zatiaľ žiadne recepty"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("Všetky"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Recepty"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Recepty sa nepodarilo načítať. Skúste to neskôr."),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Chcete nahlásiť chybu vývojárovi?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Skúsiť znova"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("nasýtené tuky"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Naskenovať produkt"),
        "scannerManualEntryButton":
            MessageLookupByLibrary.simpleMessage("Zadať kód ručne"),
        "scannerManualEntryCancel":
            MessageLookupByLibrary.simpleMessage("Zrušiť"),
        "scannerManualEntryDialogTitle":
            MessageLookupByLibrary.simpleMessage("Zadajte čiarový kód"),
        "scannerManualEntryFieldHint":
            MessageLookupByLibrary.simpleMessage("8 až 14 číslic"),
        "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
            "Tento čiarový kód nevyzerá platne. Skontrolujte číslice a skúste to znova."),
        "scannerManualEntrySubmit":
            MessageLookupByLibrary.simpleMessage("Vyhľadať"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Zadajte prosím hľadané slovo"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Potraviny"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Vyhľadať"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkty"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Výsledky vyhľadávania"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Vyberte pohlavie"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Vyberte výšku"),
        "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
            "Vyberte úroveň aktivity"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Vyberte hmotnosť"),
        "selectionCountLabel": m17,
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Odosielať anonymné údaje o používaní"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Porcia"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Veľkosť porcie (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Veľkosť porcie (g/ml)"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("O aplikácii"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Spätná väzba"),
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Vlastné jedlá"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Upozornenie"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Zdroje a referencie"),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("Zobraziť zdroje"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker používa pre každý zobrazený výpočet zavedené, recenzované metódy. Nasledujúce odkazy vedú na pôvodné zdroje, takže si každé číslo môžete sami overiť."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Energetická potreba (TDEE, BMR a úroveň aktivity)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Denné kalorické ciele, bazálny metabolizmus a koeficienty fyzickej aktivity používajú rovnice Institute of Medicine. Zdroj: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, kapitola 5 a tabuľka 5-5."),
        "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
            "Index telesnej hmotnosti (BMI)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "BMI sa počíta ako hmotnosť (kg) delená druhou mocninou výšky (m²). Zdravotné kategórie (podváha, normálna hmotnosť, nadváha, obezita I. – III. stupňa) zodpovedajú klasifikácii BMI pre dospelých podľa Svetovej zdravotníckej organizácie."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Rozdelenie makroživín"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "Predvolené rozdelenie 60 % sacharidov, 25 % tukov a 15 % bielkovín spadá do odporúčaných rozsahov príjmu živín podľa WHO. V Nastavenia → Výpočty si ho môžete upraviť. Zdroj: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Kalórie z aktivity (hodnoty MET)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Kalórie spálené počas aktivity sa odhadujú ako MET × telesná hmotnosť (kg) × trvanie (hodiny) podľa hodnôt z Adult Compendium of Physical Activities."),
        "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage("Referenčné príjmy živín"),
        "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage("Denné referenčné hodnoty zobrazené v paneli živín v denníku pochádzajú zo súhrnu Dietary Reference Intakes Institute of Medicine, ktorý pokrýva ciele pre jednotlivé živiny u dospelých."),
        "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
            "Odhad kalórií pre nebinárne osoby"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "Výskum energetického výdaja historicky používal binárne pohlavné kategórie, takže pre nebinárne osoby neexistuje jediný validovaný vzorec TDEE. OpenNutriTracker vám preto v Nastavenia → Výpočty ponúka voľbu medzi spriemerovanou referenciou, estrogénovo-typickou referenciou a testosterónovo-typickou referenciou. Ak na presnom čísle pre vašu starostlivosť skutočne záleží, prosím poraďte sa s klinikom, ktorý pozná váš hormonálny stav."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("Zobraziť zdroj"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Vzdialenosť"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperiálne (lbs, ft, oz)"),
        "settingsKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Denná úprava kcal"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Nastavenia"),
        "settingsLanguageLabel":
            MessageLookupByLibrary.simpleMessage("Jazyk"),
        "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage("Použiť systémové farby"),
        "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage("Zladí aplikáciu s farbou tapety v Androide 12 a novšom."),
        "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage("Farba zvýraznenia"),
        "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage("Material You"),
        "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage("Vlastné"),
        "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage("Predvolené"),
        "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage("Vyberte farbu"),
        "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage("Vlastná farba…"),
        "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage("Otvorte posuvník odtieňa pre presný výber"),
        "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex kód"),
        "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage("Tento hex kód nevyzerá správne — šesť znakov, 0-9 a A-F."),
        "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage("Farba zvýraznenia"),
        "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage("Vypnite systémové farby, aby ste mohli vybrať vlastný akcent."),
        "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Obnoviť"),
        "settingsMacroSplitLabel":
            MessageLookupByLibrary.simpleMessage("Rozdelenie makroživín"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licencie"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Hmotnosť"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metrické (kg, cm, ml)"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Denná pripomienka"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("Povolenie pre upozornenia bolo zamietnuté."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Nezabudnite si dnes zapísať svoje jedlá!"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Nastavenia súkromia"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Nahlásiť chybu"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Zobraziť sledovanie aktivity"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Zobraziť makroživiny jedla"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Zobraziť mikroživiny"),
        "settingsDayStartLabel":
            MessageLookupByLibrary.simpleMessage("Deň začína o"),
        "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
            "Vyber hodinu, kedy sa začína tvoj deň. Jedlá a aktivity zaznamenané pred touto hodinou sa počítajú do predchádzajúceho dňa — hodí sa pri nočných smenách alebo neskorom jedle."),
        "settingsDayStartHourLabel": m25,
        "settingsDayStartHoursPickerLabel":
            MessageLookupByLibrary.simpleMessage("Hodiny"),
        "settingsDayStartMinutesPickerLabel":
            MessageLookupByLibrary.simpleMessage("Minúty"),
        "settingsDayStartTimeLabel": m26,
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Zdrojový kód"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Systém"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Tmavá"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Vzhľad"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Svetlá"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Podľa systému"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Jednotky"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Objem"),
        "shareActivityLabel":
            MessageLookupByLibrary.simpleMessage("Zdieľať tréning"),
        "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Zdieľať kód"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("Zdieľať jedlo"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Zdieľať recept"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "napr. jablko, zmrzlina, čokoláda ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Olovrant"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodík"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("cukor"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("prijaté"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("trans tuky"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Jednotka"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamín A"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamín B12"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamín B6"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamín C"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamín D"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Upozornenie"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Týždenné tempo"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Nenastavené"),
        "weightHistoryAddEntry":
            MessageLookupByLibrary.simpleMessage("Pridať záznam"),
        "weightHistoryChartEmptyState":
            MessageLookupByLibrary.simpleMessage("Zaznamenajte aspoň dva dni, aby ste videli svoj trend."),
        "weightHistoryDateLabel":
            MessageLookupByLibrary.simpleMessage("Dátum"),
        "weightHistoryNoEntries":
            MessageLookupByLibrary.simpleMessage("Zatiaľ žiadne záznamy o hmotnosti. Pridajte prvý a začnite sledovať trend."),
        "weightHistoryNoteLabel":
            MessageLookupByLibrary.simpleMessage("Poznámka (voliteľná)"),
        "weightHistoryWeightLabel":
            MessageLookupByLibrary.simpleMessage("Hmotnosť"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Hmotnosť"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("zinok"),
        "diaryNutrientPanelTitle":
            MessageLookupByLibrary.simpleMessage("Dnešné živiny"),
        "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
            "Tieto referenčné hodnoty pochádzajú z odporúčaných dietetických príjmov IOM pre dospelých a líšia sa podľa veku a pohlavia. Sú orientačné, nie cieľové — tvoje vlastné potreby sa môžu líšiť."),
        "driPanelInfoLinkLabel":
            MessageLookupByLibrary.simpleMessage("Zdroj: IOM Dietary Reference Intakes"),
        "driPanelInfoTitle":
            MessageLookupByLibrary.simpleMessage("Referenčný príjem"),
        "driPanelReferenceLabel": mDriRef,
        "nutrientPanelAllHiddenLabel":
            MessageLookupByLibrary.simpleMessage("Všetky živiny sú skryté — zapnite niektoré v Nastavenia → Živiny."),
        "nutrientPanelDayLabel":
            MessageLookupByLibrary.simpleMessage("Deň"),
        "nutrientPanelWeekLabel":
            MessageLookupByLibrary.simpleMessage("Týždeň"),
        "settingsNutrientsHelp":
            MessageLookupByLibrary.simpleMessage("Vyberte, ktoré živiny sa zobrazujú v dennom paneli. Skryté sa kedykoľvek dajú zapnúť späť."),
        "settingsNutrientsLabel":
            MessageLookupByLibrary.simpleMessage("Živiny"),
        "settingsNutrientsSubtitle":
            MessageLookupByLibrary.simpleMessage("Vyberte, ktoré živiny sa objavia v paneli denníka"),
        "settingsCalciumGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ vápnika v miligramoch. Predvolená referencia je 1000 mg."),
        "settingsCalciumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ vápnika"),
        "settingsFibreGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ vlákniny v gramoch. Predvolená referencia je 30 g."),
        "settingsFibreGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ vlákniny"),
        "settingsIronGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ železa v miligramoch. Predvolená referencia sa líši podľa pohlavia (8 mg muž, 18 mg žena, 14 mg inak)."),
        "settingsIronGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ železa"),
        "settingsMagnesiumGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ horčíka v miligramoch. Predvolená referencia sa líši podľa pohlavia (400 mg muž, 310 mg žena, 355 mg inak)."),
        "settingsMagnesiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ horčíka"),
        "settingsNutrientGoalsHint":
            MessageLookupByLibrary.simpleMessage("Osobné ciele pre každú živinu v dennom paneli. Denník ich použije namiesto predvolených denných referencií vždy, keď jednu nastavíte."),
        "settingsNutrientGoalsLabel":
            MessageLookupByLibrary.simpleMessage("Ciele živín"),
        "settingsPotassiumGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ draslíka v miligramoch. Predvolená referencia je 3500 mg."),
        "settingsPotassiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ draslíka"),
        "settingsSaturatedFatGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný limit nasýtených tukov v gramoch. Predvolená referencia je 20 g."),
        "settingsSaturatedFatGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ nasýtených tukov"),
        "settingsSodiumGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný limit sodíka v miligramoch. Predvolená referencia je 2300 mg."),
        "settingsSodiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ sodíka"),
        "settingsSugarsGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný limit cukrov v gramoch. Predvolená referencia je 50 g."),
        "settingsSugarsGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ cukrov"),
        "settingsVitaminB12GoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ vitamínu B12 v mikrogramoch. Predvolená referencia je 2,4 µg."),
        "settingsVitaminB12GoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ vitamínu B12"),
        "settingsVitaminDGoalDescription":
            MessageLookupByLibrary.simpleMessage("Denný cieľ vitamínu D v mikrogramoch. Predvolená referencia je 15 µg."),
        "settingsVitaminDGoalLabel":
            MessageLookupByLibrary.simpleMessage("Cieľ vitamínu D"),
        "diarySortByCarbs":
            MessageLookupByLibrary.simpleMessage("Sacharidy (od najvyšších)"),
        "diarySortByFat":
            MessageLookupByLibrary.simpleMessage("Tuky (od najvyšších)"),
        "diarySortByKcal":
            MessageLookupByLibrary.simpleMessage("Kalórie (od najvyšších)"),
        "diarySortByLabel":
            MessageLookupByLibrary.simpleMessage("Zoradiť podľa"),
        "diarySortByProtein":
            MessageLookupByLibrary.simpleMessage("Bielkoviny (od najvyšších)"),
        "diarySortByTime":
            MessageLookupByLibrary.simpleMessage("Času pridania"),
        "profileTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Cieľová hmotnosť"),
        "profileTargetWeightNotSetLabel":
            MessageLookupByLibrary.simpleMessage("Nenastavené"),
        "profileTargetWeightClearAction":
            MessageLookupByLibrary.simpleMessage("Vymazať"),
        "profileTargetWeightReached":
            MessageLookupByLibrary.simpleMessage("Dosiahli ste svoj cieľ"),
        "settingsCaloriesTaperDescription":
            MessageLookupByLibrary.simpleMessage("Postupne znižuje denný kalorický deficit, aby posledné kilá nepôsobili ako stena."),
        "settingsCaloriesTaperLabel":
            MessageLookupByLibrary.simpleMessage("Upraviť kalorický cieľ s blížením k cieľovej hmotnosti"),
        "profileTargetWeightToGo": m22,
        "barcodeInvalidEan13CheckDigit":
            MessageLookupByLibrary.simpleMessage("Tento 13-miestny čiarový kód vyzerá ako preklep: posledná číslica nesedí so zvyškom"),
        "customMealBarcodeHint":
            MessageLookupByLibrary.simpleMessage("Naskenujte alebo zadajte čiarový kód, aby ste si toto jedlo neskôr ľahko vyvolali"),
        "customMealBarcodeInvalid":
            MessageLookupByLibrary.simpleMessage("Čiarový kód musí mať 8 až 14 číslic"),
        "customMealBarcodeLabel":
            MessageLookupByLibrary.simpleMessage("Čiarový kód"),
        "customMealBarcodeScanButton":
            MessageLookupByLibrary.simpleMessage("Naskenovať kód"),
        "customActivityDescription":
            MessageLookupByLibrary.simpleMessage("Zadajte spálené kalórie priamo, pre tréningy ktoré nie sú v zozname, alebo údaje z fitness náramku"),
        "customActivityDescriptionKj":
            MessageLookupByLibrary.simpleMessage("Zadajte spálené kilojouly priamo, pre tréningy ktoré nie sú v zozname, alebo údaje z fitness náramku"),
        "customActivityKcalHint":
            MessageLookupByLibrary.simpleMessage("napr. 250"),
        "customActivityKcalLabel":
            MessageLookupByLibrary.simpleMessage("Spálené kalórie"),
        "customActivityName":
            MessageLookupByLibrary.simpleMessage("Vlastná aktivita"),
        "customActivityNameFieldHint":
            MessageLookupByLibrary.simpleMessage("napr. Bicykel domov z práce"),
        "customActivityNameFieldLabel":
            MessageLookupByLibrary.simpleMessage("Názov (voliteľný)"),
        "customActivityPickFromTemplate":
            MessageLookupByLibrary.simpleMessage("Vybrať z uložených šablón"),
        "customActivitySaveAsTemplate":
            MessageLookupByLibrary.simpleMessage("Uložiť ako šablónu na nabudúce"),
        "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
            "Zatiaľ ste si neuložili žiadne šablóny. Zaškrtnite „Uložiť ako šablónu na nabudúce\", ak chcete vlastnú aktivitu zapamätať."),
        "energyLeftLabel":
            MessageLookupByLibrary.simpleMessage("zostáva"),
        "energyTooMuchLabel":
            MessageLookupByLibrary.simpleMessage("navyše"),
        "energyUnitKcalLabel":
            MessageLookupByLibrary.simpleMessage("Kilokalórie (kcal)"),
        "energyUnitKjLabel":
            MessageLookupByLibrary.simpleMessage("Kilojouly (kJ)"),
        "kjLabel":
            MessageLookupByLibrary.simpleMessage("kJ"),
        "mealEnergyLabel":
            MessageLookupByLibrary.simpleMessage("Energia"),
        "onboardingKjPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kJ za deň"),
        "settingsEnergyUnitLabel":
            MessageLookupByLibrary.simpleMessage("Jednotka energie"),
        "customMealFormAdvanced":
            MessageLookupByLibrary.simpleMessage("Pokročilý"),
        "customMealFormAdvancedHelp":
            MessageLookupByLibrary.simpleMessage("Nastavte základné množstvo a hodnoty na 100, aby ste mohli presne škálovať."),
        "customMealFormModeLabel":
            MessageLookupByLibrary.simpleMessage("Režim zadávania"),
        "customMealFormSimple":
            MessageLookupByLibrary.simpleMessage("Jednoduchý"),
        "customMealFormSimpleFieldHelper": m24,
        "customMealFormSimpleHelp":
            MessageLookupByLibrary.simpleMessage("Zadajte celkové hodnoty pre jednu porciu."),
        "mealPatternFiveSmall":
            MessageLookupByLibrary.simpleMessage("Päť malých"),
        "mealPatternMediterranean":
            MessageLookupByLibrary.simpleMessage("Stredomorský"),
        "mealPatternOmad":
            MessageLookupByLibrary.simpleMessage("OMAD"),
        "mealPatternPresetsLabel":
            MessageLookupByLibrary.simpleMessage("Rýchle predvoľby"),
        "mealPatternStandard":
            MessageLookupByLibrary.simpleMessage("Štandardný"),
        "mealPatternTwoMeal":
            MessageLookupByLibrary.simpleMessage("Dvojjedlový"),
        "settingsPerMealKcalShareBreakfast":
            MessageLookupByLibrary.simpleMessage("Raňajky"),
        "settingsPerMealKcalShareDescription":
            MessageLookupByLibrary.simpleMessage("Rozdeľte svoj denný kcal cieľ medzi raňajky, obed, večeru a snacky. Podiely musia spolu dať 100 %."),
        "settingsPerMealKcalShareDinner":
            MessageLookupByLibrary.simpleMessage("Večera"),
        "settingsPerMealKcalShareLabel":
            MessageLookupByLibrary.simpleMessage("Podiel kcal na jedlo"),
        "settingsPerMealKcalShareLunch":
            MessageLookupByLibrary.simpleMessage("Obed"),
        "settingsPerMealKcalShareSnack":
            MessageLookupByLibrary.simpleMessage("Snack"),
        "diaryMealKcalConsumedOfTarget": m23,
        "logWaterAmountLabel": mLogWaterAmount,
        "logWaterDialogTitle":
            MessageLookupByLibrary.simpleMessage("Zaznamenať príjem vody"),
        "logWaterNothingToUndoLabel":
            MessageLookupByLibrary.simpleMessage("Nie je čo vrátiť"),
        "logWaterUndoLabel":
            MessageLookupByLibrary.simpleMessage("Vrátiť posledný"),
        "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
        "settingsWaterGoalDescription":
            MessageLookupByLibrary.simpleMessage(
                "Používa sa ukazovateľom vody na hlavnej obrazovke."),
        "settingsWaterGoalLabel":
            MessageLookupByLibrary.simpleMessage("Denný cieľ pitia vody"),
        "waterChipLabel": mWaterChip,
        "profileFastingEntry": MessageLookupByLibrary.simpleMessage('Časovač pôstu'),
        "fastingTitle": MessageLookupByLibrary.simpleMessage('Časovač pôstu'),
        "fastingSubtitle": MessageLookupByLibrary.simpleMessage('Jednoduchý časovač na sledovanie času medzi jedlami. Žiadne série, žiadne ciele, len hodiny.'),
        "fastingWarningTitle": MessageLookupByLibrary.simpleMessage('Skôr než začneš'),
        "fastingWarningBody": MessageLookupByLibrary.simpleMessage('Sledovanie času pôstu môže byť niekomu užitočné a niekoho zraniť, najmä ak má za sebou poruchu príjmu potravy. Ak si to ty, postaraj sa najprv o seba. Podporu poskytujú BEAT (UK) a NEDA (US).'),
        "fastingWarningDecline": MessageLookupByLibrary.simpleMessage('Nie je to pre mňa'),
        "fastingWarningAccept": MessageLookupByLibrary.simpleMessage('Rozumiem, zapnúť časovač'),
        "fastingPresetCustom": MessageLookupByLibrary.simpleMessage('Vlastné'),
        "fastingStart": MessageLookupByLibrary.simpleMessage('Spustiť časovač'),
        "fastingCancel": MessageLookupByLibrary.simpleMessage('Ukončiť pôst'),
        "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage('Ukončiť pôst teraz?'),
        "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage('Aktuálna relácia bude uzavretá.'),
        "fastingHomeChipBody": mFastingChipSk,
        "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage("Pôst dokončený"),
        "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage("Cieľový čas bol dosiahnutý."),
        "fastingComplete": MessageLookupByLibrary.simpleMessage('Relácia dokončená'),
        "fastingLinkBeat": MessageLookupByLibrary.simpleMessage('BEAT (UK)'),
        "fastingLinkNeda": MessageLookupByLibrary.simpleMessage('NEDA (US)'),
        "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage('Uplynulo'),
        "hoursLabel": MessageLookupByLibrary.simpleMessage('hodiny'),
        "dialogCloseLabel": MessageLookupByLibrary.simpleMessage('Zavrieť'),
        "fastingRemainingValue": mFastingRemaining,
        "fastingTargetValue": mFastingTarget,
      };
}
