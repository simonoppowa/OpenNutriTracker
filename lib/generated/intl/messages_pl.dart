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

  static String m0(versionNumber) => "Wersja ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% węglowodany, ${pctFats}% tłuszcze, ${pctProteins}% białko";

  static String m2(riskValue) => "Ryzyko chorób towarzyszących: ${riskValue}";

  static String m3(age) => "${age} lat";

  static String m4(count) => "Zaimportować ${count} elementów?";

  static String m5(mealType) => "Te elementy zostaną dodane do: ${mealType}.";

  static String m6(count) =>
      "Nie udało się pobrać ${count} pozycji z OpenFoodFacts.";

  static String m8(rate) => "${rate} kg/tydzień";

  static String m9(rate) => "${rate} lbs/tydzień";

  static String m10(qty, unit) => "Na ${qty} ${unit}";

  static String m11(time) => "Czas przypomnienia: ${time}";

  static String m12(count) =>
      "Zaimportowano ${count} posiłk(ów) z pliku CSV.";

  static String m13(imported, skipped) =>
      "Zaimportowano ${imported} posiłk(ów); pominięto ${skipped} wiersz(y) z powodu nieprawidłowych danych.";

  static String m14(count, size) => "${count} pozycji · ${size}";

  static String m15(count) => "${count} składnik(ów)";

  static String m16(count) =>
      "Zaimportować ten przepis z ${count} składnik(ami)?";

  static String m17(count) => "Wybrano: ${count}";

  static String m18(count) => "Usunąć ${count} przepis(ów)?";


  static String m19(count) => "Zaimportować ${count} aktywności?";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "np. bieganie, rower, joga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Aktywność"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Dodaj nową pozycję:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Dodaj"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informacje dostarczone\n przez\n\'Kompendium Aktywności\n Fizycznych z 2024\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Niestandardowy posiłek"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Więcej informacji na\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Więcej informacji na\nOpenFoodFacts"),
        "additionalInfoLabelRecipe":
            MessageLookupByLibrary.simpleMessage("Własny przepis"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Nieznany posiłek"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Wiek"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Wszystkie"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker to darmowy tracker kalorii i składników odżywczych o otwartym kodzie źródłowym, który szanuje Twoją prywatność."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Licencja GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Podstawowa ilość (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Wskaźnik Masy Ciała (BMI) to wskaźnik służący do klasyfikacji nadwagi i otyłości u dorosłych. Jest definiowany jako waga w kilogramach podzielona przez kwadrat wzrostu w metrach (kg/m²).\n\nBMI nie rozróżnia między tkanką tłuszczową a mięśniową i może być mylący dla niektórych osób."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample":
            MessageLookupByLibrary.simpleMessage("np. płatki, mleko, kawa ..."),
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
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(zalecane)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Równanie Institute of Medicine (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Równanie TDEE"),
        "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
            "Uśrednione odniesienie (domyślne)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Odniesienie estrogenowe"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "Nie istnieje opublikowana kaloryczna wartość bazowa dla osób niebinarnych — równania referencyjne opierają się na próbach męskich i żeńskich. Domyślnie używamy średniej z obu, neutralnego punktu wyjścia, który nie wymaga ujawniania niczego więcej o twoim ciele. Suwak kcal w Ustawieniach jest zawsze dostępny do dokładnej regulacji; to punkt wyjścia, a nie precyzyjne oszacowanie."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Odniesienie kaloryczne"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Odniesienie testosteronowe"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("węglowodany"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("węglowodany"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("w"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("cholesterol"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Tygodniowe tempo wagi"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Wybierz cel wagowy"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Usuwa lokalnie zapisane wyniki wyszukiwania i skanowania z Open Food Facts i FDC. Pamięć podręczna odbuduje się automatycznie przy kolejnych wyszukiwaniach i skanowaniach. Twoje własne posiłki nie zostaną zmienione."),
        "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
            "Wyczyścić pamięć podręczną?"),
        "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage(
            "Wyczyść pamięć podręczną"),
        "clearOffCacheSubtitle": m14,
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "codeCopiedLabel":
            MessageLookupByLibrary.simpleMessage("Kod skopiowany"),
        "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kopiuj kod"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Do jakiego typu posiłku chcesz skopiować?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Za pomocą \"Skopiuj na dziś\" możesz skopiować posiłek na dzisiaj. Za pomocą \"Usuń\" możesz usunąć posiłek."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Co chcesz zrobić?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Czy chcesz utworzyć niestandardowy posiłek?"),
        "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Utworzyć niestandardowy posiłek?"),
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Utwórz przepis"),
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Masz kod kreskowy? Dodaj produkt do Open Food Facts:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Nie można odczytać pliku CSV. Sprawdź format i spróbuj ponownie."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Wszystkie wpisy w dzienniku używające tego posiłku zostaną również usunięte."),
        "customMealsDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Usunąć własny posiłek?"),
        "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
            "Brak zapisanych własnych posiłków."),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Dzienna korekta Kcal:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Wspieraj rozwój, dostarczając anonimowe dane użytkowania"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Usuń wszystko"),
        "deleteSelectedRecipesConfirmTitle": m18,
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Czy chcesz usunąć wybraną pozycję?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Czy chcesz usunąć wszystkie pozycje tego posiłku?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Usunąć pozycje?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Usunąć pozycję?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ANULUJ"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Skopiuj na dziś"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("USUŃ"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryFutureDateWarning":
            MessageLookupByLibrary.simpleMessage("Edytujesz przyszłą datę"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Dziennik"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("np. zupa, kurczak, wino ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Kolacja"),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Odrzuć"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Niezapisane zmiany zostaną utracone."),
        "discardChangesTitle":
            MessageLookupByLibrary.simpleMessage("Odrzucić zmiany?"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker nie jest aplikacją medyczną. Wszystkie dostarczone dane nie są zweryfikowane i należy ich używać z ostrożnością. Prosimy o prowadzenie zdrowego stylu życia i skonsultowanie się z profesjonalistą w przypadku jakichkolwiek problemów. Używanie podczas choroby, ciąży lub karmienia piersią nie jest zalecane. Recenzowane źródła dla każdego obliczenia znajdziesz po dotknięciu ikony informacji na ekranie głównym lub w Profilu."),
        "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
            "Przykładowe posiłki (csv)"),
        "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
            "Przykładowe przepisy (csv)"),
        "duplicateMealDialogContent":
            MessageLookupByLibrary.simpleMessage("Ten produkt został już dziś dodany do tego posiłku. Dodać ponownie?"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Duplikuj"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(kopia)"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Edytuj pozycję"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Edytuj posiłek"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Edytuj przepis"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("energia"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Błąd podczas pobierania danych produktu"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Błąd podczas ładowania aktywności"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Błąd podczas zapisywania posiłku. Czy wprowadziłeś poprawne informacje o posiłku?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Błąd podczas otwierania przeglądarki"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Błąd podczas otwierania aplikacji e-mail"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Nie znaleziono produktu"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Eksportuj"),
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Eksportuj / Importuj dane aplikacji"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Możesz wyeksportować dane aplikacji do pliku zip i zaimportować je później. Jest to przydatne, jeśli chcesz wykonać kopię zapasową danych lub przenieść je na inne urządzenie.\n\nAplikacja nie korzysta z żadnej usługi chmurowej do przechowywania danych."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Błąd eksportu / importu"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Eksport / Import zakończony sukcesem"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("t"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("błonnik"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("kobieta"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Płeć"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("mężczyzna"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("niebinarny"),
        "goalGainWeight":
            MessageLookupByLibrary.simpleMessage("Przybrać na wadze"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Cel"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Schudnąć"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Utrzymać wagę"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Wzrost"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Strona główna"),
        "importAction": MessageLookupByLibrary.simpleMessage("Importuj"),
        "importActivityConfirmContent":
            MessageLookupByLibrary.simpleMessage("Te aktywności zostaną dodane do dzisiaj."),
        "importActivityConfirmTitle": m19,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Importuj udostępniony trening"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Trening zaimportowany"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Importuj własne posiłki z pliku CSV. Pobierz przykład, aby zobaczyć oczekiwany format kolumn i wymagane pola."),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Importuj własne dane żywności"),
        "importMealConfirmContent": m5,
        "importMealConfirmTitle": m4,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Nieprawidłowy kod QR"),
        "importMealLabel": MessageLookupByLibrary.simpleMessage(
            "Importuj udostępniony posiłek"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Posiłek zaimportowany"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Importuj posiłki (csv)"),
        "importOffFetchFailedLabel": m6,
        "importRecipeConfirmContent": m16,
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Nie udało się odczytać kodu przepisu"),
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Importuj przepis"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Przepis zaimportowany"),
        "importRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Importuj przepisy (csv)"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Dodano nową aktywność"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Dodano nowe spożycie"),
        "ironLabel": MessageLookupByLibrary.simpleMessage("żelazo"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Pozycja usunięta"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Pozycja zaktualizowana"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal pozostało"),
        "kcalTooMuchLabel":
            MessageLookupByLibrary.simpleMessage("kcal za dużo"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample":
            MessageLookupByLibrary.simpleMessage("np. pizza, sałatka, ryż ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Obiad"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Rozkład makroskładników:"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnez"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marki"),
        "mealCarbsLabel":
            MessageLookupByLibrary.simpleMessage("węglowodany na"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze na"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal na"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nazwa posiłku"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Nazwa posiłku musi zawierać co najmniej jedną literę"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Łączna ilość"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("białko na 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Rozmiar posiłku (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Rozmiar posiłku (oz/fl oz)"),
        "mealUnitLabel":
            MessageLookupByLibrary.simpleMessage("Jednostka posiłku"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mikroskładniki"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Brak wymaganych informacji o kaloryczności lub makroskładnikach produktu"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze jednonienasycone"),
        "newCustomMealLabel":
            MessageLookupByLibrary.simpleMessage("Nowy własny produkt"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("niacyna (B3)"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Brak ostatnio dodanych aktywności"),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Brak ostatnio dodanych posiłków"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nie znaleziono wyników"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/D"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Nic nie dodano"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Informacje odżywcze"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Prawidłowa waga"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Otyłość I stopnia"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Otyłość II stopnia"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Otyłość III stopnia"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Przedotyłość"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Średnie"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Zwiększone"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Niskie \n(ale ryzyko innych \nproblemów klinicznych zwiększone)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Umiarkowane"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Poważne"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Bardzo poważne"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Niedowaga"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Dane dostarczone przez tę aplikację są pobierane z bazy danych Open Food Facts. Nie można zagwarantować dokładności, kompletności ani wiarygodności dostarczonych informacji. Dane są dostarczane \"tak jak są\", a źródło pochodzenia danych (Open Food Facts) nie ponosi odpowiedzialności za jakiekolwiek szkody wynikające z użycia danych."),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Jak aktywny jesteś? (bez treningów)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Wprowadź datę"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Kiedy się urodziłeś?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Data urodzenia"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Jaka jest Twoja płeć?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Jaki jest Twój obecny cel wagowy?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("np. 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("np. 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Jaki jest Twój aktualny wzrost?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Na początek aplikacja potrzebuje kilku informacji o Tobie, aby obliczyć Twój dzienny cel kaloryczny.\nWszystkie informacje o Tobie są bezpiecznie przechowywane na Twoim urządzeniu."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kcal dziennie"),
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Nie istnieje opublikowana kaloryczna wartość bazowa dla osób niebinarnych, więc domyślnie używamy średniej z formuł męskiej i żeńskiej — to punkt wyjścia, a nie precyzyjne oszacowanie. Możesz to skorygować w każdej chwili w Ustawieniach → Obliczenia."),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Przegląd"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Nieprawidłowe dane, spróbuj ponownie"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("np. 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("np. 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Jaka jest Twoja aktualna waga?"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Witaj w"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Wprowadź poprawny wzrost"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Wprowadź poprawną wagę"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Twój cel kaloryczny:"),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("Twoje cele makroskładników:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("aktywne gry wideo"),
        "paActiveVideoGamesDesc":
            MessageLookupByLibrary.simpleMessage("Wii Sports, Dance Dance Revolution, ogólnie"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("futbol amerykański"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("touch, flag, ogólne"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("łucznictwo"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("nie związane z polowaniem"),
        "paAutoRacing":
            MessageLookupByLibrary.simpleMessage("wyścigi samochodowe"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("formuła"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("wędrówka z plecakiem"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "singiel i debel towarzyski, ogólne"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("koszykówka"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("jazda na rowerze"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("jazda na rowerze górskim"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("rower stacjonarny"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("bilard"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("kręgle"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boks"),
        "paBoxingBagDesc":
            MessageLookupByLibrary.simpleMessage("worek treningowy"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boks"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("na ringu, ogólne"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("kalistenika"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "lekki lub umiarkowany wysiłek, ogólne (np. ćwiczenia pleców)"),
        "paCanoeingGeneral":
            MessageLookupByLibrary.simpleMessage("kajakarstwo"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "wiosłowanie, dla przyjemności, ogólne"),
        "paCatch": MessageLookupByLibrary.simpleMessage("futbol lub baseball"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("gra w łapanie"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "ruchy gimnastyczne, zawodowy"),
        "paChildrenGame": MessageLookupByLibrary.simpleMessage("gry dziecięce"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(np. klasy, cztery pola, zbijak, plac zabaw, t-ball, tetherball, kulki, gry zręcznościowe), umiarkowany wysiłek"),
        "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
            "wspinaczka na wzgórza bez obciążenia"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("bez obciążenia"),
        "paCricket": MessageLookupByLibrary.simpleMessage("krykiet"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("odbijanie, rzucanie, obrona"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("krokiet"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("narciarstwo biegowe"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("biegówki, ogólnie"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobik"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("taniec ogólny"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "np. disco, ludowy, irlandzki step, line dancing, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("rzutki"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("ściana lub trawnik"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("nurkowanie"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "nurkowanie z rurką, nurkowanie z butlą, ogólne"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("skoki do wody"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("trampolina lub platforma"),
        "paFencing": MessageLookupByLibrary.simpleMessage("szermierka"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("gra w frisbee"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("gimnastyka"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paHandballGeneral":
            MessageLookupByLibrary.simpleMessage("piłka ręczna"),
        "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("lotnie"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paHeadingBicycling":
            MessageLookupByLibrary.simpleMessage("jazda na rowerze"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("ćwiczenia kondycyjne"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("taniec"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("bieganie"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("sporty"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("chodzenie"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("aktywności wodne"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("aktywności zimowe"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "trening interwałowy o wysokiej intensywności"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("umiarkowany wysiłek"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "trening interwałowy o wysokiej intensywności"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "burpees, mountain climbers, przysiady z wyskokiem, Tabata, intensywny wysiłek"),
        "paHikingCrossCountry":
            MessageLookupByLibrary.simpleMessage("wędrówka"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("cross country"),
        "paHockeyField":
            MessageLookupByLibrary.simpleMessage("hokej na trawie"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("jazda konna"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("hokej na lodzie"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("łyżwiarstwo"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("żonglerka"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kajaki"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("umiarkowany wysiłek"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("bowls"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("bocce ball, na zewnątrz"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("sztuki walki"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "różne typy, umiarkowane tempo (np. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("sztuki walki"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "różne typy, wolniejsze tempo, nowicjusze, trening"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("motocross"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "sporty motorowe terenowe, pojazd terenowy, ogólne"),
        "paMountainClimbing":
            MessageLookupByLibrary.simpleMessage("wspinaczka"),
        "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
            "wspinaczka skałkowa lub górska"),
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("nordic walking"),
        "paOrienteering":
            MessageLookupByLibrary.simpleMessage("bieg na orientację"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("paddle boarding"),
        "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("stojące"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("rower wodny"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("rekreacyjne, ogólne"),
        "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
        "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koniu"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("trening siłowy"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "podnoszenie ciężarów, wolne ciężary, nautilus lub uniwersalny"),
        "paResistanceTrainingVigorous":
            MessageLookupByLibrary.simpleMessage("trening siłowy (intensywny)"),
        "paResistanceTrainingVigorousDesc":
            MessageLookupByLibrary.simpleMessage("intensywny wysiłek, trójbój siłowy lub kulturystyka"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("sporty rodeo"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("ogólne, umiarkowany wysiłek"),
        "paRollerbladingLight": MessageLookupByLibrary.simpleMessage("rolki"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("rolki inline"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("skakanie na skakance"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "umiarkowane tempo, 100-120 skoków/min, ogólne, dwunożny skok, zwykły odbicie"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("skakanie na skakance"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
            "związek, drużynowe, zawodowe"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("touch, niezawodowe"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("bieganie"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("żeglarstwo"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "żaglówka i deska, windsurfing, żeglowanie na lodzie, ogólne"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("jazda na deskorolce"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne, umiarkowany wysiłek"),
        "paSkatingRoller":
            MessageLookupByLibrary.simpleMessage("jazda na wrotkach"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("narciarstwo"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("narty wodne"),
        "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
            "narty wodne lub wakeboarding"),
        "paSkydiving":
            MessageLookupByLibrary.simpleMessage("spadochroniarstwo"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "skoki spadochronowe, base jumping, bungee jumping"),
        "paSnorkeling":
            MessageLookupByLibrary.simpleMessage("nurkowanie z rurką"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("odśnieżanie"),
        "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
            "ręcznie, umiarkowany wysiłek"),
        "paSnowshoeing":
            MessageLookupByLibrary.simpleMessage("rakiety śnieżne"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("piłka nożna"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("rekreacyjna, ogólne"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "szybki lub wolny rzut, ogólne"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paStretching": MessageLookupByLibrary.simpleMessage("stretching"),
        "paStretchingDesc":
            MessageLookupByLibrary.simpleMessage("umiarkowane, ogólnie"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surfing"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("body lub deska, ogólne"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("pływanie"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "utrzymywanie się na wodzie, umiarkowany wysiłek, ogólne"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("tenis stołowy"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("tenis stołowy, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("lekkoatletyka"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(np. pchnięcie kulą, rzut dyskiem, rzut młotem)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(np. skok wzwyż, skok w dal, trójskok, rzut oszczepem, skok o tyczce)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(np. bieg z przeszkodami, płotki)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolina"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("rekreacyjna"),
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("bieganie na bieżni"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("na bieżni, ogólnie"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("jazda na monocyklu"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ogólne"),
        "paVolleyballGeneral":
            MessageLookupByLibrary.simpleMessage("siatkówka"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "niezawodowa, drużyna 6-9 osobowa, ogólne"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("spacer"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("dla przyjemności"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("spacer z psem"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("ćwiczenia wodne"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "aerobik wodny, kalistenika wodna"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("piłka wodna"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("siatkówka wodna"),
        "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("aerobik wodny"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "aerobik wodny, kalistenika wodna"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("zapasy"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Głównie stanie lub chodzenie w pracy oraz aktywne zajęcia w wolnym czasie"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktywny"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "np. praca siedząca lub stojąca oraz lekkie zajęcia w wolnym czasie"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Mało aktywny"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "np. praca biurowa i głównie siedzące zajęcia w wolnym czasie"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Siedzący"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Głównie chodzenie, bieganie lub dźwiganie ciężarów w pracy oraz aktywne zajęcia w wolnym czasie"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Bardzo aktywny"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Wklej tutaj kod udostępnionego posiłku"),
        "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Wklej kod"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Na 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Na porcję"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze wielonienasycone"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("potas"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Polityka prywatności"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("białko"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("b"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Ilość"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Przeczytałem i akceptuję politykę prywatności."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Ostatnie"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Dodaj składnik"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Wcześniejsze wpisy w dzienniku z tego przepisu zostaną zachowane."),
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Usunąć przepis?"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Opis (opcjonalnie)"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Ilość"),
        "recipeIngredientCountLabel": m15,
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Jednostka"),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Składniki"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Waga całkowita musi być większa od zera"),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Zarejestruj ten przepis"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Nazwa przepisu"),
        "recipeNameRequiredLabel":
            MessageLookupByLibrary.simpleMessage("Przepis wymaga nazwy"),
        "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
            "Dodaj co najmniej jeden składnik"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Brak składników"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("Na 100 g"),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Wartości odżywcze (suma)"),
        "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Nie udało się zapisać przepisu."),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Zapisz przepis"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Pozwala rejestrować ten przepis na porcje zamiast w gramach."),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Porcje (opcjonalnie)"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Oddzielone przecinkami, np. \"śniadanie, wegańskie\""),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tagi"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "Domyślnie suma składników. Płyny przybliżone jako 1 ml ≈ 1 g."),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Waga całkowita (g)"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Stwórz danie z kilku składników i używaj go jak każdego innego produktu."),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("Brak przepisów"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("Wszystkie"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Przepisy"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Nie udało się załadować przepisów. Spróbuj ponownie później."),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Czy chcesz zgłosić błąd deweloperowi?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Ponów"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("tłuszcze nasycone"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Skanuj produkt"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Wprowadź słowo do wyszukania"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Jedzenie"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Szukaj"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produkty"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Wyniki wyszukiwania"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Wybierz płeć"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Wybierz wzrost"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Wybierz poziom aktywności"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Wybierz wagę"),
        "selectionCountLabel": m17,
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Wyślij anonimowe dane użytkowania"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Porcja"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Rozmiar porcji (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Rozmiar porcji (g/ml)"),
        "settingAboutLabel":
            MessageLookupByLibrary.simpleMessage("O aplikacji"),
        "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Opinia"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Obliczenia"),
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Własne posiłki"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Zastrzeżenie"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Źródła i odniesienia"),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("Zobacz źródła"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker stosuje dla każdego obliczenia uznane, recenzowane metody. Poniższe odnośniki prowadzą do oryginalnych źródeł, dzięki czemu możesz samodzielnie zweryfikować dowolną wartość."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Zapotrzebowanie energetyczne (TDEE, BMR i poziom aktywności)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Dzienne cele kaloryczne, podstawowa przemiana materii oraz współczynniki aktywności fizycznej opierają się na równaniach Institute of Medicine. Źródło: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, rozdział 5 i tabela 5-5."),
        "sourcesBmiTitle":
            MessageLookupByLibrary.simpleMessage("Wskaźnik masy ciała (BMI)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "BMI oblicza się jako masę ciała (kg) podzieloną przez kwadrat wzrostu (m²). Kategorie zdrowotne (niedowaga, waga prawidłowa, nadwaga, otyłość I–III stopnia) są zgodne z klasyfikacją BMI dla osób dorosłych Światowej Organizacji Zdrowia."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Rozkład makroskładników"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "Domyślny podział 60% węglowodanów, 25% tłuszczu i 15% białka mieści się w zakresach spożycia rekomendowanych przez WHO. Możesz go zmienić w Ustawienia → Obliczenia. Źródło: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Kalorie z aktywności (wartości MET)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Kalorie spalone podczas aktywności są szacowane jako MET × masa ciała (kg) × czas trwania (godziny), na podstawie wartości z Adult Compendium of Physical Activities."),
        "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
            "Obliczanie kalorii dla osób niebinarnych"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "Badania nad wydatkiem energetycznym historycznie korzystały wyłącznie z binarnych kategorii płci, dlatego nie istnieje jeden zwalidowany wzór TDEE dla osób niebinarnych. OpenNutriTracker oferuje więc w Ustawienia → Obliczenia wybór między uśrednioną referencją, referencją typową dla estrogenu oraz referencją typową dla testosteronu. Jeśli dokładna wartość jest dla ciebie naprawdę istotna, skonsultuj się z lekarzem znającym twój profil hormonalny. Źródło: Linsenmeyer W, Waters J. Sex and gender differences in nutrition research: considerations with the transgender and gender nonconforming population. Nutrition Journal 2021;20:6."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("Otwórz źródło"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Odległość"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperialny (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Ustawienia"),
        "settingsLanguageLabel":
            MessageLookupByLibrary.simpleMessage("Język"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licencje"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Masa"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metryczny (kg, cm, ml)"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Codzienne przypomnienie"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("Odmówiono dostępu do powiadomień."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Nie zapomnij dziś zapisać swoich posiłków!"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Ustawienia prywatności"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Zgłoś błąd"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Pokaż śledzenie aktywności"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Pokaż makro posiłku"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Pokaż mikroskładniki"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Kod źródłowy"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("System"),
        "settingsThemeDarkLabel":
            MessageLookupByLibrary.simpleMessage("Ciemny"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Motyw"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Jasny"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Domyślny systemu"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Jednostki"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Objętość"),
        "shareActivityLabel":
            MessageLookupByLibrary.simpleMessage("Udostępnij trening"),
        "shareCodeLabel":
            MessageLookupByLibrary.simpleMessage("Udostępnij kod"),
        "shareMealLabel":
            MessageLookupByLibrary.simpleMessage("Udostępnij posiłek"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Udostępnij przepis"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "np. jabłko, lody, czekolada ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Przekąska"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("sód"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("cukier"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("dostarczone"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze trans"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Jednostka"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("witamina A"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("witamina B12"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("witamina B6"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("witamina C"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("witamina D"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Ostrzeżenie"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Tygodniowe tempo"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Nie ustawiono"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Waga"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("cynk"),
      };
}
