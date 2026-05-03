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

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "np. bieganie, rower, joga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Aktywność"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Dodaj nową pozycję:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Dodaj"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informacje dostarczone\n przez\n\'Kompendium Aktywności\n Fizycznych z 2011\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Niestandardowy posiłek"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Więcej informacji na\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Więcej informacji na\nOpenFoodFacts"),
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
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Rozkład makroskładników"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(zalecane)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Równanie Institute of Medicine"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Równanie TDEE"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("węglowodany"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("węglowodany"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Wybierz cel wagowy"),
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
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Dzienna korekta Kcal:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Wspieraj rozwój, dostarczając anonimowe dane użytkowania"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Usuń wszystko"),
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
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Dziennik"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("np. zupa, kurczak, wino ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Kolacja"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker nie jest aplikacją medyczną. Wszystkie dostarczone dane nie są zweryfikowane i należy ich używać z ostrożnością. Prosimy o prowadzenie zdrowego stylu życia i skonsultowanie się z profesjonalistą w przypadku jakichkolwiek problemów. Używanie podczas choroby, ciąży lub karmienia piersią nie jest zalecane."),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Edytuj pozycję"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Edytuj posiłek"),
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
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Możesz wyeksportować dane aplikacji do pliku zip i zaimportować je później. Jest to przydatne, jeśli chcesz wykonać kopię zapasową danych lub przenieść je na inne urządzenie.\n\nAplikacja nie korzysta z żadnej usługi chmurowej do przechowywania danych."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Błąd eksportu / importu"),
        "exportImportLabel":
            MessageLookupByLibrary.simpleMessage("Eksport / Import danych"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Eksport / Import zakończony sukcesem"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("błonnik"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("♀ kobieta"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Płeć"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("♂ mężczyzna"),
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
        "importMealConfirmContent": m5,
        "importMealConfirmTitle": m4,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Nieprawidłowy kod QR"),
        "importMealLabel": MessageLookupByLibrary.simpleMessage(
            "Importuj udostępniony posiłek"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Posiłek zaimportowany"),
        "importOffFetchFailedLabel": m6,
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Dodano nową aktywność"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Dodano nowe spożycie"),
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
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marki"),
        "mealCarbsLabel":
            MessageLookupByLibrary.simpleMessage("węglowodany na"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("tłuszcze na"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal na"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nazwa posiłku"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("białko na 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Rozmiar posiłku (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Rozmiar posiłku (oz/fl oz)"),
        "mealUnitLabel":
            MessageLookupByLibrary.simpleMessage("Jednostka posiłku"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Brak wymaganych informacji o kaloryczności lub makroskładnikach produktu"),
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
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("na koniu"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("trening siłowy"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "podnoszenie ciężarów, wolne ciężary, nautilus lub uniwersalny"),
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
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("piłka nożna"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("rekreacyjna, ogólne"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "szybki lub wolny rzut, ogólne"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("ogólne"),
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
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Polityka prywatności"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("białko"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Ilość"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Przeczytałem i akceptuję politykę prywatności."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Ostatnie"),
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
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Zastrzeżenie"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Odległość"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperialny (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Ustawienia"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licencje"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Masa"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metryczny (kg, cm, ml)"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Ustawienia prywatności"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Zgłoś błąd"),
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
        "shareCodeLabel":
            MessageLookupByLibrary.simpleMessage("Udostępnij kod"),
        "shareMealLabel":
            MessageLookupByLibrary.simpleMessage("Udostępnij posiłek"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "np. jabłko, lody, czekolada ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Przekąska"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("cukier"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("dostarczone"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Jednostka"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Waga"),
        "yearsLabel": m3
      };
}
