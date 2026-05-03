// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it locale. All the
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
  String get localeName => 'it';

  static String m0(versionNumber) => "Versione ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% carboidrati, ${pctFats}% grassi, ${pctProteins}% proteine";

  static String m2(riskValue) => "Rischio di comorbilità: ${riskValue}";

  static String m3(age) => "${age} anni";

  static String m4(mealType) =>
      "Questi elementi verranno aggiunti a ${mealType}.";

  static String m5(count) => "Importare ${count} voci?";

  static String m6(count) =>
      "${count} elemento/i non è stato possibile recuperare da OpenFoodFacts.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "es. corsa, bicicletta, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Attività"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Aggiungi nuovo alimento:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Aggiungi"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informazioni fornite\ndal\n\'2011 Compendium\ndelle Attività Fisiche\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Alimento personalizzato"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Maggiori informazioni su\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Maggiori informazioni su\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Alimento sconosciuto"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Età"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tutti"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker è un tracker di calorie e nutrienti gratuito e open-source che rispetta la tua privacy."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Licenza GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Quantità base (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "L\'Indice di Massa Corporea (BMI) è un indice per classificare sovrappeso e obesità negli adulti. È definito come peso in chilogrammi diviso per l\'altezza in metri al quadrato (kg/m²).\n\nIl BMI non differenzia tra massa grassa e muscolare e può essere fuorviante per alcune persone."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "es. cereali, latte, caffè ..."),
        "breakfastLabel": MessageLookupByLibrary.simpleMessage("Colazione"),
        "burnedLabel": MessageLookupByLibrary.simpleMessage("bruciate"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("AVANTI"),
        "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Resetta"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Salva"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("INIZIA"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("SI"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage(
                "Distribuzione dei macronutrienti"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(consigliato)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Equazione dell\'Istituto di Medicina"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Equazione TDEE"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("carboidrati"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("carboidrati"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Scegli obiettivo di peso"),
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "codeCopiedLabel":
            MessageLookupByLibrary.simpleMessage("Codice copiato"),
        "copyCodeLabel":
            MessageLookupByLibrary.simpleMessage("Copia codice"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Quale tipo di pasto vuoi copiare?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Con \"Copia a oggi\" puoi duplicare il pasto nella giornata odierna. Con \"Elimina\" puoi rimuovere il pasto."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Cosa vuoi fare?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Vuoi creare un alimento personalizzato per il pasto?"),
        "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Creare un alimento personalizzato?"),
        "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
            "Regolazione kcal giornaliere:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Supporta lo sviluppo inviando dati di utilizzo anonimi"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Elimina tutto"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Vuoi eliminare l\'alimento selezionato?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Vuoi eliminare tutti gli elementi di questo pasto?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Eliminare gli elementi?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Eliminare l\'alimento?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ANNULLA"),
        "dialogCopyLabel": MessageLookupByLibrary.simpleMessage("Copia a oggi"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("ELIMINA"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Diario"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("es. zuppa, pollo, vino ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Cena"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker non è un\'applicazione medica. Tutti i dati forniti non sono validati e dovrebbero essere utilizzati con cautela. Mantieni uno stile di vita sano e consulta un professionista se hai problemi. L\'uso durante malattie, gravidanza o allattamento non è raccomandato."),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Modifica alimento"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Modifica pasto"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("energia"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Errore durante il recupero dei dati del prodotto"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Errore durante il caricamento delle attività"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Errore durante il salvataggio del pasto. Hai inserito informazioni corrette?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Errore durante l\'apertura del browser"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Errore durante l\'apertura dell\'app email"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Prodotto non trovato"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Esporta"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Puoi esportare i dati dell\'app in un file zip e importarli successivamente. Utile per backup o trasferimento su un altro dispositivo.\n\nL\'app non utilizza servizi cloud per memorizzare i tuoi dati."),
        "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Errore di esportazione / importazione"),
        "exportImportLabel":
            MessageLookupByLibrary.simpleMessage("Esporta / Importa dati"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Esportazione / Importazione riuscita"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("grassi"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("fibre"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("♀ femmina"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Sesso"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("♂ maschio"),
        "goalGainWeight":
            MessageLookupByLibrary.simpleMessage("Aumentare peso"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Obiettivo"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Perdere peso"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Mantenere peso"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Altezza"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Home"),
        "importAction": MessageLookupByLibrary.simpleMessage("Importa"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Codice QR non valido"),
        "importMealLabel":
            MessageLookupByLibrary.simpleMessage("Importa pasto condiviso"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Pasto importato"),
        "importOffFetchFailedLabel": m6,
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Nuova attività aggiunta"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Nuova assunzione aggiunta"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("alimento eliminato"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Alimento aggiornato"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal rimanenti"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "es. pizza, insalata, riso ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Pranzo"),
        "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
            "Distribuzione dei macronutrienti:"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marche"),
        "mealCarbsLabel":
            MessageLookupByLibrary.simpleMessage("carboidrati per"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("grassi per"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal per"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nome pasto"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("proteine per 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Dimensione pasto (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Dimensione pasto (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Unità pasto"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Prodotto senza informazioni su kcal o macronutrienti"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Nessuna attività aggiunta di recente"),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Nessun pasto aggiunto di recente"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nessun risultato trovato"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/D"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Niente aggiunto"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Informazioni nutrizionali"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Peso normale"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obesità di classe I"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obesità di classe II"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obesità di classe III"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Pre-obesità"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Medio"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Aumentato"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Basso\n(ma rischio di altri\nproblemi clinici aumentato)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Moderato"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Grave"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Molto grave"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Sottopeso"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "I dati forniti da questa app provengono dal database Open Food Facts. Non è possibile garantire l\'accuratezza, la completezza o l\'affidabilità delle informazioni fornite. I dati sono forniti \"così come sono\" e la fonte originale (Open Food Facts) non è responsabile per eventuali danni derivanti dall\'uso dei dati."),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Quanto sei attivo? (senza allenamenti)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Inserisci data"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Quando è il tuo compleanno?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Data di nascita"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Qual è il tuo sesso?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Qual è il tuo obiettivo di peso attuale?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("es. 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("es. 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Qual è la tua altezza attuale?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Per iniziare, l\'app ha bisogno di alcune informazioni su di te per calcolare il tuo obiettivo calorico giornaliero.\nTutte le informazioni su di te sono memorizzate in modo sicuro sul tuo dispositivo."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kcal al giorno"),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Panoramica"),
        "onboardingSaveUserError":
            MessageLookupByLibrary.simpleMessage("Dati errati, riprova"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("es. 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("es. 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Qual è il tuo peso attuale?"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Benvenuto in"),
        "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
            "Inserisci un\'altezza corretta"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Inserisci un peso corretto"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Il tuo obiettivo calorico:"),
        "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
            "I tuoi obiettivi di macronutrienti:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("football americano"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("touch, flag, generale"),
        "paArcheryGeneral":
            MessageLookupByLibrary.simpleMessage("tiro con l\'arco"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("non per caccia"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("auto da corsa"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("open wheel"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("escursionismo"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "singoli e doppi sociali, generale"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("pallacanestro"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("ciclismo"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("ciclismo, montagna"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("ciclismo, stazionario"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("biliardo"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boxe"),
        "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("punching bag"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boxe"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("nel ring, generale"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("calisthenics"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "sforzo leggero o moderato, generale (es. esercizi per la schiena)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("canoa"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "remare, per piacere, generale"),
        "paCatch": MessageLookupByLibrary.simpleMessage("football o baseball"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("giocare a palla"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "movimenti ginnici, competitivo"),
        "paChildrenGame":
            MessageLookupByLibrary.simpleMessage("giochi per bambini"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(es. campana, 4-square, palla avvelenata, attrezzi da playground, t-ball, tetherball, biglie, giochi da sala), sforzo moderato"),
        "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
            "arrampicata su colline, senza carico"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("senza carico"),
        "paCricket": MessageLookupByLibrary.simpleMessage("cricket"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("battuta, lancio, fielding"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("croquet"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobica"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("danza generale"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "es. disco, folk, danza irlandese, line dance, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("freccette"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("da muro o da giardino"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("immersioni"),
        "paDivingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("apnea, subacquea, generale"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("tuffi"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("trampolino o piattaforma"),
        "paFencing": MessageLookupByLibrary.simpleMessage("scherma"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("giocare a frisbee"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("ginnastica"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("pallamano"),
        "paHandballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("deltaplano"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("ciclismo"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("esercizi condizionali"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("danza"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("corsa"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("sport"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Incolla qui il codice del pasto condiviso"),
        "pasteCodeLabel":
            MessageLookupByLibrary.simpleMessage("Incolla codice"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("camminata"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("attività acquatiche"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("attività invernali"),
        "paHikingCrossCountry":
            MessageLookupByLibrary.simpleMessage("escursionismo"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("escursionismo di fondo"),
        "paHockeyField":
            MessageLookupByLibrary.simpleMessage("hockey su prato"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("equitazione"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("hockey su ghiaccio"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("pattinaggio su ghiaccio"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
        "paJoggingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("giocoleria"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kayak"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("sforzo moderato"),
        "paKickball": MessageLookupByLibrary.simpleMessage("calcio"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("bocce"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("bocce, all\'aperto"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("arti marziali"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "diversi tipi, ritmo moderato (es. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("arti marziali"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "diversi tipi, ritmo lento, principianti, pratica"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("motocross"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "sport motoristici off-road, veicoli fuoristrada, generale"),
        "paMountainClimbing":
            MessageLookupByLibrary.simpleMessage("arrampicata"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("roccia o montagna"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("orienteering"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("paddle boarding"),
        "paPaddleBoardingDesc":
            MessageLookupByLibrary.simpleMessage("in piedi"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pedalò"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("casuale, generale"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("a cavallo"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("allenamento con i pesi"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "sollevamento pesi, pesi liberi, nautilus o universal"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("sport da rodeo"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("generale, sforzo moderato"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("pattinaggio in linea"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("pattinaggio in linea"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("salto con la corda"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "ritmo moderato, 100-120 salti/min, generale, salto a due piedi, rimbalzo semplice"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("salto della corda"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("union, squadra, competitivo"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("touch, non competitivo"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("corsa"),
        "paRunningGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("vela"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "barca e windsurf, vela su ghiaccio, generale"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("skateboard"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale, sforzo moderato"),
        "paSkatingRoller":
            MessageLookupByLibrary.simpleMessage("pattinaggio a rotelle"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("sci"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("sci d\'acqua"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("acqua o wakeboard"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("paracadutismo"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "paracadutismo, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("snorkeling"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("spalare neve"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("a mano, sforzo moderato"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("calcio"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("casuale, generale"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "lancio veloce o lento, generale"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("surf"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("body o board, generale"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("nuoto"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "stare a galla, sforzo moderato, generale"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("tennis da tavolo"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("tennis da tavolo, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tennis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paTrackField":
            MessageLookupByLibrary.simpleMessage("atletica leggera"),
        "paTrackField1Desc":
            MessageLookupByLibrary.simpleMessage("(es. peso, disco, martello)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(es. salto in alto, salto in lungo, triplo salto, giavellotto, salto con l\'asta)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(es. steeplechase, ostacoli)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolino"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("ricreativo"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("monociclo"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paVolleyballGeneral":
            MessageLookupByLibrary.simpleMessage("pallavolo"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "non competitivo, squadra da 6-9 membri, generale"),
        "paWalkingForPleasure":
            MessageLookupByLibrary.simpleMessage("camminata"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("per piacere"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("passeggiare con il cane"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paWaterAerobics":
            MessageLookupByLibrary.simpleMessage("esercizi in acqua"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "acquagym, calistenia in acqua"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("pallanuoto"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("pallavolo in acqua"),
        "paWaterVolleyballDesc":
            MessageLookupByLibrary.simpleMessage("generale"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("acquagym"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "acquagym, calistenia in acqua"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Lavoro prevalentemente in piedi o camminando e attività attive nel tempo libero"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Attivo"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "es. lavoro seduto o in piedi e attività leggere nel tempo libero"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Poco attivo"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "es. lavoro d\'ufficio e tempo libero prevalentemente seduto"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sedentario"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Lavoro prevalentemente camminando, correndo o trasportando pesi e attività attive nel tempo libero"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Molto attivo"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Per 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Per porzione"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Privacy policy"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profilo"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("proteine"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantità"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Ho letto e accetto la privacy policy."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Recenti"),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Vuoi segnalare un errore allo sviluppatore?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Riprova"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("grassi saturi"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Scansiona prodotto"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Inserisci una parola da cercare"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Cibo"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Cerca"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Prodotti"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Risultati di ricerca"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Seleziona sesso"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Seleziona altezza"),
        "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
            "Seleziona livello di attività"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Seleziona peso"),
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Invia dati di utilizzo anonimi"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Porzione"),
        "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
            "Dimensione porzione (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Dimensione porzione (g/ml)"),
        "settingAboutLabel":
            MessageLookupByLibrary.simpleMessage("Informazioni"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Feedback"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Calcoli"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Disclaimer"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Distanza"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperiale (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Impostazioni"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licenze"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Massa"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metrico (kg, cm, ml)"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Impostazioni privacy"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Segnala errore"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Codice sorgente"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Sistema"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Scuro"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Tema"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Chiaro"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Predefinito del sistema"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Unità"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
        "shareCodeLabel":
            MessageLookupByLibrary.simpleMessage("Condividi codice"),
        "shareMealLabel":
            MessageLookupByLibrary.simpleMessage("Condividi pasto"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "es. mela, gelato, cioccolato ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Spuntino"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("zuccheri"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("assunte"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Unità"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Peso"),
        "yearsLabel": m3
      };
}
