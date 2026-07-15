// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pl locale. All the
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
  String get localeName => 'pl';

  static String m0(sourceName) => "Więcej informacji na\n${sourceName}";

  static String m1(versionNumber) => "Wersja ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% węglowodany, ${pctFats}% tłuszcze, ${pctProteins}% białko";

  static String m3(count, size) => "${count} pozycji · ${size}";

  static String m4(imported, skipped) =>
      "Zaimportowano ${imported} posiłk(ów); pominięto ${skipped} wiersz(y) z powodu nieprawidłowych danych.";

  static String m5(count) => "Zaimportowano ${count} posiłk(ów).";

  static String m6(unit) => "${unit} w jednej porcji";

  static String m7(loser, winner) =>
      "Spowoduje to zastąpienie wszystkich wpisów zarejestrowanych z ${loser}, tak by pokazywały ${winner}, oraz usunie ${loser} z Twoich własnych produktów. Tej operacji nie można cofnąć.";

  static String m8(winner) => "Połączono — ${winner} ma teraz 1 wpis.";

  static String m9(count, winner) =>
      "Połączono — ${winner} ma teraz ${count} wpisów.";

  static String m10(count) => "Usunąć ${count} przepis(ów)?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "ref. ${value}";

  static String m13(remaining) => "Post · pozostało ${remaining}";

  static String m14(value) => "Pozostało ${value}";

  static String m15(value) => "Cel: ${value}";

  static String m16(count) => "Zaimportować ${count} aktywności?";

  static String m17(mealType) => "Te elementy zostaną dodane do: ${mealType}.";

  static String m18(count) => "Zaimportować ${count} elementów?";

  static String m19(count) =>
      "Nie udało się pobrać ${count} pozycji z OpenFoodFacts.";

  static String m20(count) =>
      "Zaimportować ten przepis z ${count} składnik(ami)?";

  static String m21(amount) => "Dodaj ${amount} ml";

  static String m22(threshold) =>
      "Osoby dorosłe nie powinny przez dłuższy czas spożywać mniej niż ${threshold} kcal dziennie bez nadzoru lekarza. Zanim utrzymasz tak niski cel, rozważ konsultację ze specjalistą.";

  static String m23(kcal) => "(+${kcal} kcal bieżący wybór)";

  static String m24(consumed, goal) => "Suma dzienna: ${consumed} / ${goal}";

  static String m25(qty, unit) => "Na ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'baton', few: 'batony', many: 'batonów', other: 'batona')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'butelka', few: 'butelki', many: 'butelek', other: 'butelki')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'puszka', few: 'puszki', many: 'puszek', other: 'puszki')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'filiżanka', few: 'filiżanki', many: 'filiżanek', other: 'filiżanki')}";

  static String m30(count) =>
      "${Intl.plural(count, one: 'jajko', few: 'jajka', many: 'jajek', other: 'jajka')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'opakowanie', few: 'opakowania', many: 'opakowań', other: 'opakowania')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'kawałek', few: 'kawałki', many: 'kawałków', other: 'kawałka')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'porcja', few: 'porcje', many: 'porcji', other: 'porcji')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'porcja', few: 'porcje', many: 'porcji', other: 'porcji')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'plasterek', few: 'plasterki', many: 'plasterków', other: 'plasterka')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'łyżka', few: 'łyżki', many: 'łyżek', other: 'łyżki')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'łyżeczka', few: 'łyżeczki', many: 'łyżeczek', other: 'łyżeczki')}";

  static String m38(riskValue) => "Ryzyko chorób towarzyszących: ${riskValue}";

  static String m39(value) => "${value} do celu";

  static String m40(mealType) => "Dodano do ${mealType}";

  static String m41(count) => "${count} składnik(ów)";

  static String m42(count) => "Wybrano: ${count}";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Czas przypomnienia: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/tydzień";

  static String m48(rate) => "${rate} lbs/tydzień";

  static String m49(age) => "${age} lat";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "np. bieganie, rower, joga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Aktywność"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage("Dodaj nową pozycję:"),
    "addLabel": MessageLookupByLibrary.simpleMessage("Dodaj"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Dodaj profil"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Informacje dostarczone\n przez\n\'Kompendium Aktywności\n Fizycznych z 2024\'",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Niestandardowy posiłek",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Więcej informacji na\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Więcej informacji na\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Własny przepis",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Nieznany posiłek",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Wiek"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Wszystkie"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker to darmowy tracker kalorii i składników odżywczych o otwartym kodzie źródłowym, który szanuje Twoją prywatność.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("Licencja GPL-3.0"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Ten 13-cyfrowy kod kreskowy wygląda na błędnie wpisany: ostatnia cyfra nie pasuje do pozostałych",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Wartości odżywcze na",
    ),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Wskaźnik Masy Ciała (BMI) to wskaźnik służący do klasyfikacji nadwagi i otyłości u dorosłych. Jest definiowany jako waga w kilogramach podzielona przez kwadrat wzrostu w metrach (kg/m²).\n\nBMI nie rozróżnia między tkanką tłuszczową a mięśniową i może być mylący dla niektórych osób.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "np. płatki, mleko, kawa ...",
    ),
    "breakfastLabel": MessageLookupByLibrary.simpleMessage("Śniadanie"),
    "burnedLabel": MessageLookupByLibrary.simpleMessage("spalone"),
    "buttonNextLabel": MessageLookupByLibrary.simpleMessage("DALEJ"),
    "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Resetuj"),
    "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Zapisz"),
    "buttonStartLabel": MessageLookupByLibrary.simpleMessage("START"),
    "buttonYesLabel": MessageLookupByLibrary.simpleMessage("TAK"),
    "calciumLabel": MessageLookupByLibrary.simpleMessage("wapń"),
    "calculationsMacronutrientsDistributionLabel":
        MessageLookupByLibrary.simpleMessage("Rozkład makroskładników"),
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(zalecane)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Równanie Institute of Medicine (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "Równanie TDEE",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Uśrednione odniesienie (domyślne)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Odniesienie estrogenowe",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Nie istnieje opublikowana kaloryczna wartość bazowa dla osób niebinarnych — równania referencyjne opierają się na próbach męskich i żeńskich. Domyślnie używamy średniej z obu, neutralnego punktu wyjścia, który nie wymaga ujawniania niczego więcej o twoim ciele. Suwak kcal w Ustawieniach jest zawsze dostępny do dokładnej regulacji; to punkt wyjścia, a nie precyzyjne oszacowanie.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Odniesienie kaloryczne",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Odniesienie testosteronowe"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("węglowodany"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("węglowodany"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("w"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Tygodniowe tempo wagi",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Wybierz cel wagowy",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Usuwa lokalnie zapisane wyniki wyszukiwania i skanowania z Open Food Facts i FDC. Pamięć podręczna odbuduje się automatycznie przy kolejnych wyszukiwaniach i skanowaniach. Twoje własne posiłki nie zostaną zmienione.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Wyczyścić pamięć podręczną?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Wyczyść pamięć podręczną",
    ),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Kod skopiowany"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Posiłek skopiowany do profilu",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Kopiuj"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kopiuj kod"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Do jakiego typu posiłku chcesz skopiować?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Za pomocą \"Skopiuj na dziś\" możesz skopiować posiłek na dzisiaj. Za pomocą \"Usuń\" możesz usunąć posiłek.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Co chcesz zrobić?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Kopiuj do profilu",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Czy chcesz utworzyć niestandardowy posiłek?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Utworzyć niestandardowy posiłek?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage("Utwórz przepis"),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Masz kod kreskowy? Dodaj produkt do Open Food Facts:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nie można odczytać pliku CSV. Sprawdź format i spróbuj ponownie.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Wprowadź spalone kalorie bezpośrednio – dla treningów spoza listy lub odczytów z opaski fitness",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Wprowadź spalone kilodżule bezpośrednio – dla treningów spoza listy lub odczytów z opaski fitness",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("np. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Spalone kalorie",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Aktywność niestandardowa",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "np. Wieczorny dojazd rowerem",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Nazwa (opcjonalnie)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Wybierz z zapisanych szablonów",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Zapisz jako szablon na później",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Nie masz jeszcze zapisanych szablonów. Zaznacz „Zapisz jako szablon na później”, aby zapamiętać aktywność niestandardową na przyszłość.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Zeskanuj lub wpisz kod kreskowy, aby później przywołać ten posiłek",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Kod kreskowy musi mieć od 8 do 14 cyfr",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage(
      "Kod kreskowy",
    ),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Skanuj kod kreskowy",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage(
      "Zaawansowany",
    ),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Ustaw rozmiary i wartości na 100 g/ml dla dokładnego przeliczenia.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Widok formularza",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Prosty"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Wpisz wartości dla jednej porcji.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Wszystkie wpisy w dzienniku używające tego posiłku zostaną również usunięte.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Usunąć własny posiłek?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Brak zapisanych własnych posiłków.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Połącz z innym własnym produktem",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Który zostaje?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Połącz",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Połączyć własne produkty?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Kontynuuj",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Wybierz własny produkt do połączenia",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Więcej akcji",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Dzienna korekta Kcal:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Dzienna korekta kJ:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Wysyłaj anonimowe raporty o awariach, aby pomóc w naprawianiu błędów. Nie są przesyłane dane o posiłkach, wadze ani dane osobowe.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profil 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Usuń wszystko"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Spowoduje to trwałe usunięcie profilu i wszystkich jego danych. Tej operacji nie można cofnąć.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Usunąć profil?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Czy chcesz usunąć wybraną pozycję?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Czy chcesz usunąć wszystkie pozycje tego posiłku?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Usunąć pozycje?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Usunąć pozycję?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ANULUJ"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Zamknij"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage("Skopiuj na dziś"),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("USUŃ"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Edytujesz przyszłą datę",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Dziennik"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Sumowane są tylko składniki odżywcze zapisane na zalogowanych posiłkach. Posiłek bez wartości nie wnosi nic do danego składnika — sumy mogą być więc zaniżone.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Dzisiejsze składniki odżywcze",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Węglowodany (malejąco)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage(
      "Tłuszcze (malejąco)",
    ),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Kalorie (malejąco)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Sortuj według"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Białko (malejąco)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Czasu dodania"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "np. zupa, kurczak, wino ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Kolacja"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Odrzuć",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Niezapisane zmiany zostaną utracone.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Odrzucić zmiany?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker nie jest aplikacją medyczną. Wszystkie dostarczone dane nie są zweryfikowane i należy ich używać z ostrożnością. Prosimy o prowadzenie zdrowego stylu życia i skonsultowanie się z profesjonalistą w przypadku jakichkolwiek problemów. Używanie podczas choroby, ciąży lub karmienia piersią nie jest zalecane. Recenzowane źródła dla każdego obliczenia znajdziesz po dotknięciu ikony informacji na ekranie głównym lub w Profilu.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Przykładowe posiłki (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Przykładowe posiłki (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Przykładowe przepisy (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Przykładowe przepisy (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Te wartości referencyjne pochodzą z zaleceń IOM dotyczących spożycia dla dorosłych i zależą od wieku oraz płci. Są punktem odniesienia, nie celem — twoje własne potrzeby mogą się różnić.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Źródło: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Spożycie referencyjne",
    ),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Ten produkt został już dziś dodany do tego posiłku. Dodać ponownie?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Duplikuj"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(kopia)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Edytuj pozycję",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Edytuj posiłek"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage("Edytuj profil"),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage("Edytuj przepis"),
    "energyLabel": MessageLookupByLibrary.simpleMessage("energia"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("pozostało"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("za dużo"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilokalorie (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage("Kilodżule (kJ)"),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Błąd podczas pobierania danych produktu",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Błąd podczas ładowania aktywności",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Błąd podczas zapisywania posiłku. Czy wprowadziłeś poprawne informacje o posiłku?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Błąd podczas otwierania przeglądarki",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Błąd podczas otwierania aplikacji e-mail",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Nie znaleziono produktu",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Eksportuj"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Eksportuj / Importuj dane aplikacji",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV przechowuje aktywność, dziennik posiłków i śledzone dni. Przepisy i dodane zdjęcia są zapisywane tylko w JSON — przełącz się na JSON, jeśli chcesz mieć je w kopii zapasowej.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Możesz wyeksportować dane aplikacji do pliku zip i zaimportować je później. Jest to przydatne, jeśli chcesz wykonać kopię zapasową danych lub przenieść je na inne urządzenie.\n\nAplikacja nie korzysta z żadnej usługi chmurowej do przechowywania danych.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Błąd eksportu / importu",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Eksport / Import zakończony sukcesem",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Zakończ post"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Bieżąca sesja zostanie zamknięta.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Zakończyć post teraz?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage("Sesja zakończona"),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Upłynęło"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Jednorazowe powiadomienia, gdy post osiągnie swój cel.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Minutnik postu",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Czas docelowy został osiągnięty.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Sesja postu zakończona",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Własny"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Uruchom minutnik"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Prosty minutnik do śledzenia czasu między posiłkami. Bez serii, bez celów, tylko zegar.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Minutnik postu"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Rozumiem, włącz minutnik",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Śledzenie czasu postu jednym pomaga, a innym może szkodzić, szczególnie osobom z historią zaburzeń odżywiania. Jeśli to o tobie, zadbaj najpierw o siebie. Wsparcie oferują BEAT (UK) i NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "To nie dla mnie",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Zanim zaczniesz",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("t"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("błonnik"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Zawsze włączone",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Wyniki wyszukiwania pochodzą z tych baz danych żywności. Open Food Facts obsługuje wyszukiwanie produktów i kodów kreskowych i jest zawsze włączona.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("kobieta"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Płeć"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("mężczyzna"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("niebinarny"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Przybrać na wadze"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Cel"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Schudnąć"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage("Utrzymać wagę"),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Wzrost"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Dotknij +, aby dodać swój pierwszy posiłek lub aktywność",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Strona główna"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("godziny"),
    "importAction": MessageLookupByLibrary.simpleMessage("Importuj"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Te aktywności zostaną dodane do dzisiaj.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Importuj udostępniony trening",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Trening zaimportowany",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Zaimportuj własne posiłki z pliku CSV lub wklejając JSON. Pobierz przykład, aby zobaczyć oczekiwany kształt i wymagane pola.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Importuj własne dane żywności",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nieprawidłowy kod QR",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Importuj udostępniony posiłek",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Posiłek zaimportowany",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importuj posiłki (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importuj posiłki (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nie udało się odczytać kodu przepisu",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Importuj przepis",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Przepis zaimportowany",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importuj przepisy (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importuj przepisy (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Te wartości nie do końca się zgadzają — wpisane kalorie nie odpowiadają energii z węglowodanów, tłuszczu i białka. Zapisać mimo to czy sprawdzić jeszcze raz?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Sprawdź jeszcze raz",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Zapisz mimo to"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Liczby do siebie nie pasują",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Dodano nową aktywność",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Dodano nowe spożycie",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("żelazo"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Pozycja usunięta",
    ),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Pozycja zaktualizowana",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal pozostało"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal za dużo"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Zapisz wypitą wodę",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Nic do cofnięcia",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage("Cofnij ostatni"),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Ten dzienny cel jest dość niski",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Pokaż zastrzeżenie",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "np. pizza, sałatka, ryż ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Obiad"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Nazwa przetłumaczona automatycznie",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Rozkład makroskładników:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnez"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Zarządzaj profilami",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marki"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Węglowodany"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energia"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Tłuszcze"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Dodaj zdjęcie"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Wybierz z galerii",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Usuń zdjęcie"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage("Zmień zdjęcie"),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage("Zrób zdjęcie"),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal na"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nazwa posiłku"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Nazwa posiłku musi zawierać co najmniej jedną literę",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Łączna ilość",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("5 małych"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Śródziemnomorski",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("1 posiłek"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Szybkie ustawienia",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Standardowy"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("2 posiłki"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Białko"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Rozmiar opakowania"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Rozmiar opakowania (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Jednostka posiłku"),
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
      "Mikroskładniki",
    ),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "Brak wymaganych informacji o kaloryczności lub makroskładnikach produktu",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "tłuszcze jednonienasycone",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Nowy własny produkt",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("niacyna (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Brak ostatnio dodanych aktywności",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Brak ostatnio dodanych posiłków",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Nie znaleziono wyników",
    ),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/D"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("Nic nie dodano"),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Nie zapomnij dziś zapisać swoich posiłków!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Codzienne przypomnienie o zapisaniu posiłków",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Codzienne przypomnienia"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Odmówiono dostępu do powiadomień.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Wszystkie składniki ukryte — włącz wybrane w Ustawienia → Składniki odżywcze.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Dzień"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("limit"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Tydzień"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Informacje odżywcze",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Prawidłowa waga",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Otyłość I stopnia",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Otyłość II stopnia",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Otyłość III stopnia",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Przedotyłość",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Średnie",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Zwiększone",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Niskie \n(ale ryzyko innych \nproblemów klinicznych zwiększone)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Umiarkowane",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Poważne",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Bardzo poważne",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Niedowaga",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Dane dostarczone przez tę aplikację są pobierane z bazy danych Open Food Facts. Nie można zagwarantować dokładności, kompletności ani wiarygodności dostarczonych informacji. Dane są dostarczane \"tak jak są\", a źródło pochodzenia danych (Open Food Facts) nie ponosi odpowiedzialności za jakiekolwiek szkody wynikające z użycia danych.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jak aktywny jesteś? (bez treningów)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Wprowadź datę",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Kiedy się urodziłeś?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Data urodzenia",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jak rejestrujesz jedzenie i napoje",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaka jest Twoja płeć?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaki jest Twój obecny cel wagowy?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "np. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "np. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaki jest Twój aktualny wzrost?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Na początek aplikacja potrzebuje kilku informacji o Tobie, aby obliczyć Twój dzienny cel kaloryczny.\nWszystkie informacje o Tobie są bezpiecznie przechowywane na Twoim urządzeniu.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Przeczytaj źródła naszych obliczeń medycznych",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kcal dziennie",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kJ dziennie",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Nie istnieje opublikowana kaloryczna wartość bazowa dla osób niebinarnych, więc domyślnie używamy średniej z formuł męskiej i żeńskiej — to punkt wyjścia, a nie precyzyjne oszacowanie. Możesz to skorygować w każdej chwili w Ustawieniach → Obliczenia.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Inne opcje",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Spersonalizuj aplikację — wszystko możesz później zmienić w ustawieniach",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage("Przegląd"),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Nieprawidłowe dane, spróbuj ponownie",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Opcjonalnie",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Czy masz wagę, do której dążysz? Możesz zostawić to pole puste lub zmienić je później w Profilu.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "np. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "np. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Jaka jest Twoja aktualna waga?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage("Witaj w"),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Wprowadź poprawny wzrost",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Wprowadź poprawną wagę",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Twój cel kaloryczny:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Twoje cele makroskładników:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "aktywne gry wideo",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, ogólnie",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "futbol amerykański",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "touch, flag, ogólne",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("łucznictwo"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nie związane z polowaniem",
    ),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("wyścigi samochodowe"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("formuła"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage(
      "wędrówka z plecakiem",
    ),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "singiel i debel towarzyski, ogólne",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("koszykówka"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage(
      "jazda na rowerze",
    ),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "jazda na rowerze górskim",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ogólne",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "rower stacjonarny",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ogólne",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("bilard"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("kręgle"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("boks"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("worek treningowy"),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boks"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "na ringu, ogólne",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "kalistenika",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "lekki lub umiarkowany wysiłek, ogólne (np. ćwiczenia pleców)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kajakarstwo"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "wiosłowanie, dla przyjemności, ogólne",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("futbol lub baseball"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("gra w łapanie"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "ruchy gimnastyczne, zawodowy",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("gry dziecięce"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(np. klasy, cztery pola, zbijak, plac zabaw, t-ball, tetherball, kulki, gry zręcznościowe), umiarkowany wysiłek",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "wspinaczka na wzgórza bez obciążenia",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "bez obciążenia",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("krykiet"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "odbijanie, rzucanie, obrona",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("krokiet"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "narciarstwo biegowe",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "biegówki, ogólnie",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("aerobik"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ogólne",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("taniec ogólny"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "np. disco, ludowy, irlandzki step, line dancing, polka, contra, country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("rzutki"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage(
      "ściana lub trawnik",
    ),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("nurkowanie"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nurkowanie z rurką, nurkowanie z butlą, ogólne",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "skoki do wody",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "trampolina lub platforma",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("szermierka"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("gra w frisbee"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("gimnastyka"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("piłka ręczna"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("lotnie"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage(
      "jazda na rowerze",
    ),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "ćwiczenia kondycyjne",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("taniec"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("bieganie"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("sporty"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("chodzenie"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "aktywności wodne",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "aktywności zimowe",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "trening interwałowy o wysokiej intensywności",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "umiarkowany wysiłek",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "trening interwałowy o wysokiej intensywności",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "burpees, mountain climbers, przysiady z wyskokiem, Tabata, intensywny wysiłek",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("wędrówka"),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "cross country",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("hokej na trawie"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage("jazda konna"),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage(
      "hokej na lodzie",
    ),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage("łyżwiarstwo"),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("żonglerka"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kajaki"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "umiarkowany wysiłek",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("bowls"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "bocce ball, na zewnątrz",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "sztuki walki",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "różne typy, umiarkowane tempo (np. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage("sztuki walki"),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "różne typy, wolniejsze tempo, nowicjusze, trening",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("motocross"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "sporty motorowe terenowe, pojazd terenowy, ogólne",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("wspinaczka"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "wspinaczka skałkowa lub górska",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("nordic walking"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage(
      "bieg na orientację",
    ),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("paddle boarding"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("stojące"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("rower wodny"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage(
      "rekreacyjne, ogólne",
    ),
    "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koniu"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "trening siłowy",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "podnoszenie ciężarów, wolne ciężary, nautilus lub uniwersalny",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "trening siłowy (intensywny)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "intensywny wysiłek, trójbój siłowy lub kulturystyka",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "sporty rodeo",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "ogólne, umiarkowany wysiłek",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage("rolki"),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "rolki inline",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "skakanie na skakance",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "umiarkowane tempo, 100-120 skoków/min, ogólne, dwunożny skok, zwykły odbicie",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "skakanie na skakance",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "związek, drużynowe, zawodowe",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "touch, niezawodowe",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("bieganie"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("żeglarstwo"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "żaglówka i deska, windsurfing, żeglowanie na lodzie, ogólne",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "jazda na deskorolce",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ogólne, umiarkowany wysiłek",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
      "jazda na wrotkach",
    ),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("narciarstwo"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "narty wodne",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "narty wodne lub wakeboarding",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("spadochroniarstwo"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "skoki spadochronowe, base jumping, bungee jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("nurkowanie z rurką"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "odśnieżanie",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "ręcznie, umiarkowany wysiłek",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage("rakiety śnieżne"),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("piłka nożna"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rekreacyjna, ogólne",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "softball / baseball",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "szybki lub wolny rzut, ogólne",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paStretching": MessageLookupByLibrary.simpleMessage("stretching"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage(
      "umiarkowane, ogólnie",
    ),
    "paSurfing": MessageLookupByLibrary.simpleMessage("surfing"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "body lub deska, ogólne",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("pływanie"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "utrzymywanie się na wodzie, umiarkowany wysiłek, ogólne",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage(
      "tenis stołowy",
    ),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "tenis stołowy, ping pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "tai chi, qi gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("lekkoatletyka"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(np. pchnięcie kulą, rzut dyskiem, rzut młotem)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(np. skok wzwyż, skok w dal, trójskok, rzut oszczepem, skok o tyczce)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(np. bieg z przeszkodami, płotki)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolina"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage(
      "rekreacyjna",
    ),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "bieganie na bieżni",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "na bieżni, ogólnie",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage(
      "jazda na monocyklu",
    ),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("siatkówka"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "niezawodowa, drużyna 6-9 osobowa, ogólne",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("spacer"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "dla przyjemności",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("spacer z psem"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("ćwiczenia wodne"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "aerobik wodny, kalistenika wodna",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("piłka wodna"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage(
      "siatkówka wodna",
    ),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "aerobik wodny",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "aerobik wodny, kalistenika wodna",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("zapasy"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Głównie stanie lub chodzenie w pracy oraz aktywne zajęcia w wolnym czasie",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktywny"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "np. praca siedząca lub stojąca oraz lekkie zajęcia w wolnym czasie",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Mało aktywny"),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "np. praca biurowa i głównie siedzące zajęcia w wolnym czasie",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Siedzący"),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Głównie chodzenie, bieganie lub dźwiganie ciężarów w pracy oraz aktywne zajęcia w wolnym czasie",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Bardzo aktywny",
    ),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Wklej tutaj kod udostępnionego posiłku",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Wklej kod"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Na 100g/ml"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Na porcję"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "tłuszcze wielonienasycone",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("potas"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Polityka prywatności",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Aktywny"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage(
      "Minutnik postu",
    ),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage("Dodaj zdjęcie"),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage("Usuń zdjęcie"),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage(
      "Zmień zdjęcie",
    ),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Nazwa profilu"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Imię"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Wyczyść",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Docelowa waga",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Nieustawiony",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Osiągnięto wagę docelową",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Historia wagi",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("białko"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("b"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Ilość"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Dodano aktywność",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Czas trwania (min, opcjonalnie)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Spalona energia (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Spalona energia (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Nazwa (opcjonalnie)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Szybkie dodawanie aktywności",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Szybkie dodawanie",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Węglowodany (g, opcjonalnie)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage(
      "Szybkie dodawanie",
    ),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage(
      "Szybkie dodawanie",
    ),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energia (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energia (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Tłuszcze (g, opcjonalnie)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Białko (g, opcjonalnie)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Dodaj"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Tytuł"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Przeczytałem i akceptuję politykę prywatności.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Ostatnie"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Dodaj składnik",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Wcześniejsze wpisy w dzienniku z tego przepisu zostaną zachowane.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Usunąć przepis?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Opis (opcjonalnie)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage("Dodaj zdjęcie"),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Wybierz z galerii",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage("Usuń zdjęcie"),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage("Zmień zdjęcie"),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Zrób zdjęcie",
    ),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Ilość",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednostka",
    ),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage("Składniki"),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Waga całkowita musi być większa od zera",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Zarejestruj ten przepis",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Nazwa przepisu"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Przepis wymaga nazwy",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Dodaj co najmniej jeden składnik",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Brak składników",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "Na 100 g",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Wartości odżywcze (suma)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nie udało się zapisać przepisu.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Włącz, aby zachować ten posiłek na liście zapisanych na później. Pozostaw wyłączone dla jednorazowego posiłku, którego już nie zjesz.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Zapisz na później",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Zapisz przepis"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Pozwala rejestrować ten przepis na porcje zamiast w gramach.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Porcje (opcjonalnie)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Oddzielone przecinkami, np. \"śniadanie, wegańskie\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tagi"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Domyślnie suma składników. Płyny przybliżone jako 1 ml ≈ 1 g.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Waga całkowita (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Stwórz danie z kilku składników i używaj go jak każdego innego produktu.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage("Brak przepisów"),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Wszystkie"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Przepisy"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Nie udało się załadować przepisów. Spróbuj ponownie później.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Czy chcesz zgłosić błąd deweloperowi?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Ponów"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "tłuszcze nasycone",
    ),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage("Skanuj produkt"),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Zablokuj w pionie",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Wpisz kod ręcznie",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage("Anuluj"),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Wprowadź kod kreskowy",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "Od 8 do 14 cyfr",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Ten kod kreskowy wygląda na nieprawidłowy. Sprawdź cyfry i spróbuj ponownie.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage(
      "Wyszukaj",
    ),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Zezwól na obrót",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Wprowadź słowo do wyszukania",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Jedzenie"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Szukaj"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkty"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Wyniki wyszukiwania",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Wybierz płeć",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Wybierz wzrost",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Wybierz poziom aktywności",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Wybierz wagę",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Wyślij anonimowe dane użytkowania",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Porcja"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Jedna porcja (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Jedna porcja",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("O aplikacji"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Opinia"),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Kolor akcentu",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Kolor niestandardowy…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Otwórz suwak odcienia, aby wybrać precyzyjnie",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Ten kod hex nie wygląda dobrze — sześć znaków, 0-9 i A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Kod hex"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Wyłącz kolory systemowe, aby wybrać własny akcent.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Zresetuj"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Kolor akcentu",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Wybierz kolor",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Niestandardowy",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Domyślny",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednostka masy ciała",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel wapnia w miligramach. Wartość referencyjna to 1000 mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel wapnia",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Stopniowo zmniejsza dzienny deficyt, aby ostatnie kilogramy nie wydawały się ścianą.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Dostosuj cel kaloryczny w miarę zbliżania się do celu",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage(
      "O aplikacji",
    ),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Wygląd",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Dane"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage(
      "Wyświetlanie",
    ),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Cele i odżywianie",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Jednostki i energia",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Własne posiłki",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Wybierz godzinę, o której zaczyna się Twój dzień. Posiłki i aktywności zarejestrowane przed tą godziną zaliczają się do poprzedniego dnia — przydatne przy pracy nocnej lub późnym jedzeniu.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Godziny",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Dzień zaczyna się o",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Minuty",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Usuń wszystko",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Spowoduje to trwałe usunięcie z tego urządzenia Twojego profilu, posiłków, aktywności, historii wagi oraz wszystkich własnych przepisów. Bazy danych Open Food Facts i USDA Food Data Central pozostają nienaruszone. Tej operacji nie można cofnąć.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Usunąć wszystkie Twoje dane?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Usuń wszystkie moje dane",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profil, posiłki, aktywność i historia wagi",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Zastrzeżenie",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Odległość"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Jednostka energii",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel błonnika w gramach. Wartość referencyjna to 30 g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel błonnika",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Bazy danych żywności",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wybierz, skąd pochodzą wyniki wyszukiwania",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperialny (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Jednostki żywności",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metryczny (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperialny (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Jednostki wzrostu",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metryczny (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Imperialny (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel żelaza w miligramach. Wartość domyślna zależy od płci (8 mg mężczyzna, 18 mg kobieta, 14 mg w pozostałych przypadkach).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage("Cel żelaza"),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Dzienna korekta kcal",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Ustawienia"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Język"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Licencje"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Podział makroskładników",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel magnezu w miligramach. Wartość domyślna zależy od płci (400 mg mężczyzna, 310 mg kobieta, 355 mg w pozostałych przypadkach).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel magnezu",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Masa"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Dopasowuje aplikację do akcentu tapety w systemie Android 12 i nowszym.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Użyj kolorów systemu",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metryczny (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Codzienne przypomnienie",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Osobiste cele dla każdego składnika odżywczego w panelu dziennym. Dziennik używa ich zamiast domyślnych wartości referencyjnych za każdym razem, gdy któryś ustawisz.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Cele składników odżywczych",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Wybierz, które składniki są widoczne w panelu dziennym. Ukryte możesz w każdej chwili włączyć ponownie.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Składniki odżywcze",
    ),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Wybierz, które składniki pojawiają się w panelu dziennika",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Śniadanie",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Rozłóż dzienny cel kcal na śniadanie, obiad, kolację i przekąski. Udziały muszą sumować się do 100%.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Kolacja",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Udział kcal na posiłek",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Obiad",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Przekąska",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel potasu w miligramach. Wartość referencyjna to 3500 mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel potasu",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Ustawienia prywatności",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Zgłoś błąd",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny limit tłuszczów nasyconych w gramach. Wartość referencyjna to 20 g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel tłuszczów nasyconych",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Pokaż śledzenie aktywności",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Pokaż makro posiłku",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Pokaż mikroskładniki",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny limit sodu w miligramach. Wartość referencyjna to 2300 mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage("Cel sodu"),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Kod źródłowy",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Źródła i odniesienia",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny limit cukrów w gramach. Wartość referencyjna to 50 g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel cukrów",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("System"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Ciemny"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Motyw"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Jasny"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Domyślny systemu",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Jednostki"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel witaminy B12 w mikrogramach. Wartość referencyjna to 2,4 µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel witaminy B12",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel witaminy D w mikrogramach. Wartość referencyjna to 15 µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Cel witaminy D",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Objętość"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Używane przez wskaźnik wody na ekranie głównym.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Dzienny cel wody",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Udostępnij trening",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Udostępnij kod"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage(
      "Udostępnij posiłek",
    ),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Udostępnij przepis",
    ),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "np. jabłko, lody, czekolada ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Przekąska"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("sód"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Kalorie spalone podczas aktywności są szacowane jako MET × masa ciała (kg) × czas trwania (godziny), na podstawie wartości z Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Kalorie z aktywności (wartości MET)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "BMI oblicza się jako masę ciała (kg) podzieloną przez kwadrat wzrostu (m²). Kategorie zdrowotne (niedowaga, waga prawidłowa, nadwaga, otyłość I–III stopnia) są zgodne z klasyfikacją BMI dla osób dorosłych Światowej Organizacji Zdrowia.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Wskaźnik masy ciała (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienne cele kaloryczne, podstawowa przemiana materii oraz współczynniki aktywności fizycznej opierają się na równaniach Institute of Medicine. Źródło: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, rozdział 5 i tabela 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Zapotrzebowanie energetyczne (TDEE, BMR i poziom aktywności)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage("Zobacz źródła"),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "Domyślny podział 60% węglowodanów, 25% tłuszczu i 15% białka mieści się w zakresach spożycia rekomendowanych przez WHO. Możesz go zmienić w Ustawienia → Obliczenia. Źródło: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Rozkład makroskładników",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Badania nad wydatkiem energetycznym historycznie korzystały wyłącznie z binarnych kategorii płci, dlatego nie istnieje jeden zwalidowany wzór TDEE dla osób niebinarnych. OpenNutriTracker oferuje więc w Ustawienia → Obliczenia wybór między uśrednioną referencją, referencją typową dla estrogenu oraz referencją typową dla testosteronu. Jeśli dokładna wartość jest dla ciebie naprawdę istotna, skonsultuj się z lekarzem znającym twój profil hormonalny.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Obliczanie kalorii dla osób niebinarnych",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Dzienne wartości referencyjne pokazywane w panelu składników odżywczych w dzienniku pochodzą z podsumowania Dietary Reference Intakes Institute of Medicine, obejmującego cele dla poszczególnych składników u osób dorosłych.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Wartości referencyjne składników odżywczych",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Otwórz źródło",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker stosuje dla każdego obliczenia uznane, recenzowane metody. Poniższe odnośniki prowadzą do oryginalnych źródeł, dzięki czemu możesz samodzielnie zweryfikować dowolną wartość.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("cukier"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("dostarczone"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Przełącz profil",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze trans"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("rekord"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Kalorie"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Średnia dzienna",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage("dni z rzędu"),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "dni zgodnie z planem w tym tygodniu",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Trendy"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/tydzień"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Woda"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "tygodni do celu",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Jednostka"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("witamina A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("witamina B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("witamina B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("witamina C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("witamina D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Ostrzeżenie"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Tygodniowe tempo",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Nie ustawiono",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage("Dodaj wpis"),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Zapisz wagę z co najmniej dwóch dni, aby zobaczyć trend.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Data"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Brak zapisów wagi. Dodaj pierwszy, aby śledzić zmiany.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Notatka (opcjonalna)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage("Waga"),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Waga"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Ty"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("cynk"),
  };
}
