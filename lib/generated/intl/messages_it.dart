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

  static String m8(rate) => "${rate} kg/settimana";

  static String m9(rate) => "${rate} lbs/settimana";

  static String m10(qty, unit) => "Per ${qty} ${unit}";

  static String m11(time) => "Orario promemoria: ${time}";

  static String m12(count) => "Importati ${count} pasti dal file CSV.";

  static String m13(imported, skipped) =>
      "Importati ${imported} pasti; ${skipped} righe ignorate per dati non validi.";

  static String m14(count, size) => "${count} elementi · ${size}";

  static String m15(count) => "${count} ingrediente/i";

  static String m16(count) =>
      "Importare questa ricetta con ${count} ingrediente(i)?";

  static String m17(count) => "${count} selezionati";

  static String m18(count) => "Eliminare ${count} ricetta/e?";


  static String m19(count) => "Importare ${count} attività?";

  static String m20(detail) => "Impossibile analizzare: ${detail}";

  static String m21(count, customCount) =>
      "Registrate ${count} dal JSON, ${customCount} salvate come pasti personalizzati";

  static String m22(value) => "${value} al tuo obiettivo";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "es. corsa, bicicletta, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Attività"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Aggiungi nuovo alimento:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Aggiungi"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informazioni fornite\ndal\n\'2024 Compendium\ndelle Attività Fisiche\'"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Alimento personalizzato"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Maggiori informazioni su\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Maggiori informazioni su\nOpenFoodFacts"),
        "additionalInfoLabelRecipe":
            MessageLookupByLibrary.simpleMessage("Ricetta personalizzata"),
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
        "calciumLabel": MessageLookupByLibrary.simpleMessage("calcio"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage(
                "Distribuzione dei macronutrienti"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(consigliato)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Equazione dell\'Istituto di Medicina (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Equazione TDEE"),
        "caloriesProfileAveragedLabel":
            MessageLookupByLibrary.simpleMessage("Riferimento medio (predefinito)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Riferimento di tipo estrogenico"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "Non esiste una base calorica pubblicata per persone non binarie — le equazioni di riferimento si basano su campioni maschili e femminili. Per impostazione predefinita usiamo la media delle due, un punto di partenza neutrale che non ti chiede di rivelare nulla in più sul tuo corpo. Il cursore kcal in Impostazioni è sempre disponibile per la regolazione fine; questo è un punto di partenza, non una stima precisa."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Riferimento calorie"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Riferimento di tipo testosteronico"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("carboidrati"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("carboidrati"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("c"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("colesterolo"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ritmo peso settimanale"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Scegli obiettivo di peso"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Rimuove i risultati di ricerca e scansione memorizzati localmente da Open Food Facts e FDC. La cache si ricostruisce automaticamente quando cerchi e scansioni prodotti. I tuoi pasti personalizzati non vengono toccati."),
        "clearOffCacheConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Svuotare la cache?"),
        "clearOffCacheLabel":
            MessageLookupByLibrary.simpleMessage("Svuota cache"),
        "clearOffCacheSubtitle": m14,
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
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Crea ricetta"),
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Hai un codice a barre? Contribuisci il prodotto a Open Food Facts:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Impossibile leggere il file CSV. Controlla il formato e riprova."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
            "Questo codice a barre a 13 cifre sembra digitato male, l\'ultima cifra non corrisponde alle altre"),
        "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
            "Scansiona o digita un codice a barre per richiamare questo pasto in seguito"),
        "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
            "Il codice a barre deve avere da 8 a 14 cifre"),
        "customMealBarcodeLabel":
            MessageLookupByLibrary.simpleMessage("Codice a barre"),
        "customMealBarcodeScanButton":
            MessageLookupByLibrary.simpleMessage("Scansiona codice a barre"),
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Tutte le voci del diario che utilizzano questo pasto verranno rimosse."),
        "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
            "Eliminare il pasto personalizzato?"),
        "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
            "Nessun pasto personalizzato salvato."),
        "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
            "Regolazione kcal giornaliere:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Supporta lo sviluppo inviando dati di utilizzo anonimi"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Elimina tutto"),
        "deleteSelectedRecipesConfirmTitle": m18,
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
        "diaryNutrientPanelDataDisclaimer":
            MessageLookupByLibrary.simpleMessage("Vengono sommati solo i nutrienti registrati sui pasti che hai inserito. Un pasto senza un valore non contribuisce a quel nutriente — i totali potrebbero quindi essere sottostimati."),
        "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
            "Stai modificando una data futura"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Diario"),
        "diaryNutrientPanelTitle":
            MessageLookupByLibrary.simpleMessage("Nutrienti di oggi"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("es. zuppa, pollo, vino ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Cena"),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Annulla"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Le modifiche non salvate andranno perse."),
        "discardChangesTitle":
            MessageLookupByLibrary.simpleMessage("Annullare le modifiche?"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker non è un\'applicazione medica. Tutti i dati forniti non sono validati e dovrebbero essere utilizzati con cautela. Mantieni uno stile di vita sano e consulta un professionista se hai problemi. L\'uso durante malattie, gravidanza o allattamento non è raccomandato. Per le fonti sottoposte a peer review di ogni calcolo, tocca l\'icona informativa nella schermata Home o Profilo."),
        "downloadSampleCsvAction":
            MessageLookupByLibrary.simpleMessage("Pasti di esempio (csv)"),
        "downloadSampleJsonAction":
            MessageLookupByLibrary.simpleMessage("Pasti di esempio (json)"),
        "importMealsJsonAction":
            MessageLookupByLibrary.simpleMessage("Importa pasti (json)"),
        "downloadSampleRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Ricette di esempio (json)"),
        "importRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Importa ricette (json)"),
        "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
            "Ricette di esempio (csv)"),
        "duplicateMealDialogContent":
            MessageLookupByLibrary.simpleMessage("Questo alimento è già stato aggiunto a questo pasto oggi. Aggiungerlo di nuovo?"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Duplica"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(copia)"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Modifica alimento"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Modifica pasto"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Modifica ricetta"),
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
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Esporta / Importa dati app"),
        "exportImportCsvRecipesNote":
            MessageLookupByLibrary.simpleMessage("Il CSV conserva attività, registro pasti e giorni tracciati. Le ricette e le foto allegate restano solo nel JSON — passa a JSON se vuoi includerle nel backup."),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Puoi esportare i dati dell\'app in un file zip e importarli successivamente. Utile per backup o trasferimento su un altro dispositivo.\n\nL\'app non utilizza servizi cloud per memorizzare i tuoi dati."),
        "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Errore di esportazione / importazione"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Esportazione / Importazione riuscita"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("grassi"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("g"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("fibre"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("femmina"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Sesso"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("maschio"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("non binario"),
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
        "importActivityConfirmContent":
            MessageLookupByLibrary.simpleMessage("Queste attività verranno aggiunte a oggi."),
        "importActivityConfirmTitle": m19,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Importa allenamento condiviso"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Allenamento importato"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Importa i tuoi pasti da un file CSV o incollando JSON. Scarica un esempio per vedere la forma attesa e i campi obbligatori."),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Importa dati alimentari personalizzati"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Codice QR non valido"),
        "importMealLabel":
            MessageLookupByLibrary.simpleMessage("Importa pasto condiviso"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Pasto importato"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Importa pasti (csv)"),
        "importOffFetchFailedLabel": m6,
        "importRecipeConfirmContent": m16,
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Impossibile leggere il codice della ricetta"),
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Importa ricetta"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Ricetta importata"),
        "importRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Importa ricette (csv)"),
        "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
            "Questi valori non sembrano tornare — le calorie inserite non corrispondono all'energia di carboidrati, grassi e proteine. Salvare comunque o controllare di nuovo?"),
        "inconsistentNutritionWarningEdit":
            MessageLookupByLibrary.simpleMessage("Controlla di nuovo"),
        "inconsistentNutritionWarningSaveAnyway":
            MessageLookupByLibrary.simpleMessage("Salva comunque"),
        "inconsistentNutritionWarningTitle":
            MessageLookupByLibrary.simpleMessage("I numeri non tornano"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Nuova attività aggiunta"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Nuova assunzione aggiunta"),
        "ironLabel": MessageLookupByLibrary.simpleMessage("ferro"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("alimento eliminato"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Alimento aggiornato"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal rimanenti"),
        "kcalTooMuchLabel":
            MessageLookupByLibrary.simpleMessage("kcal in eccesso"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "es. pizza, insalata, riso ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Pranzo"),
        "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
            "Distribuzione dei macronutrienti:"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnesio"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marche"),
        "mealCarbsLabel":
            MessageLookupByLibrary.simpleMessage("carboidrati per"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("grassi per"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal per"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nome pasto"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Il nome del pasto deve contenere almeno una lettera"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Quantità totale"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("proteine per 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Dimensione pasto (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Dimensione pasto (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Unità pasto"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Micronutrienti"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Prodotto senza informazioni su kcal o macronutrienti"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("grassi monoinsaturi"),
        "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
            "Nuovo alimento personalizzato"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("niacina (B3)"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Nessuna attività aggiunta di recente"),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Nessun pasto aggiunto di recente"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Nessun risultato trovato"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/D"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Niente aggiunto"),
        "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Giorno"),
        "nutrientPanelWeekLabel":
            MessageLookupByLibrary.simpleMessage("Settimana"),
        "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
            "Tutti i nutrienti nascosti — attivane alcuni in Impostazioni → Nutrienti."),
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
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Non esiste una base calorica pubblicata per persone non binarie, quindi per impostazione predefinita usiamo una media delle formule maschili e femminili — un punto di partenza, non una stima precisa. Puoi regolare in qualsiasi momento da Impostazioni → Calcoli."),
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
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("videogiochi attivi"),
        "paActiveVideoGamesDesc":
            MessageLookupByLibrary.simpleMessage("Wii Sports, Dance Dance Revolution, generale"),
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
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("sci di fondo"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("fondo, generale"),
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
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("camminata"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("attività acquatiche"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("attività invernali"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "allenamento intervallato ad alta intensità"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("sforzo moderato"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "allenamento intervallato ad alta intensità"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "burpees, mountain climber, squat jump, Tabata, sforzo intenso"),
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
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("nordic walking"),
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
        "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
        "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("a cavallo"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("allenamento con i pesi"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "sollevamento pesi, pesi liberi, nautilus o universal"),
        "paResistanceTrainingVigorous":
            MessageLookupByLibrary.simpleMessage("allenamento di forza (intenso)"),
        "paResistanceTrainingVigorousDesc":
            MessageLookupByLibrary.simpleMessage("sforzo intenso, powerlifting o bodybuilding"),
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
        "paSnowshoeing":
            MessageLookupByLibrary.simpleMessage("racchette da neve"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("calcio"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("casuale, generale"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softball / baseball"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "lancio veloce o lento, generale"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
        "paStretching": MessageLookupByLibrary.simpleMessage("stretching"),
        "paStretchingDesc":
            MessageLookupByLibrary.simpleMessage("leggero, generale"),
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
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("corsa sul tapis roulant"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("sul tapis roulant, generale"),
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
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Incolla qui il codice del pasto condiviso"),
        "pasteCodeLabel":
            MessageLookupByLibrary.simpleMessage("Incolla codice"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Per 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Per porzione"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosforo"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("grassi polinsaturi"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("potassio"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Privacy policy"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profilo"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("proteine"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantità"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Ho letto e accetto la privacy policy."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Recenti"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Aggiungi ingrediente"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Le voci del diario registrate da questa ricetta saranno mantenute."),
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Eliminare ricetta?"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Descrizione (opzionale)"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Quantità"),
        "recipeIngredientCountLabel": m15,
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Unità"),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Ingredienti"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Il peso totale deve essere maggiore di zero"),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Registra questa ricetta"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Nome della ricetta"),
        "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
            "La ricetta ha bisogno di un nome"),
        "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
            "Aggiungi almeno un ingrediente"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Nessun ingrediente ancora"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("Per 100 g"),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Nutrizione (totale)"),
        "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Impossibile salvare la ricetta."),
        "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
            "Attiva questa opzione per mantenere il pasto nella tua lista salvata per la prossima volta. Lasciala disattivata per un pasto occasionale che non mangerai più."),
        "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
            "Salva per la prossima volta"),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Salva ricetta"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Permette di registrare questa ricetta per porzioni invece che in grammi."),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Porzioni (opzionale)"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Separati da virgola, es. \"colazione, vegano\""),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tag"),
        "recipeImageLabel":
            MessageLookupByLibrary.simpleMessage("Aggiungi una foto"),
        "recipeImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Scegli dalla galleria"),
        "recipeImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Scatta una foto"),
        "recipeImageRemove":
            MessageLookupByLibrary.simpleMessage("Rimuovi foto"),
        "recipeImageReplace":
            MessageLookupByLibrary.simpleMessage("Sostituisci foto"),
        "mealImageLabel":
            MessageLookupByLibrary.simpleMessage("Aggiungi una foto"),
        "mealImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Scegli dalla galleria"),
        "mealImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Scatta una foto"),
        "mealImageRemove":
            MessageLookupByLibrary.simpleMessage("Rimuovi foto"),
        "mealImageReplace":
            MessageLookupByLibrary.simpleMessage("Sostituisci foto"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "Predefinito come somma degli ingredienti. I liquidi sono approssimati a 1 ml ≈ 1 g."),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Peso totale (g)"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Crea un pasto da più ingredienti e riutilizzalo come qualsiasi altro alimento."),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("Nessuna ricetta ancora"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("Tutti"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Ricette"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Impossibile caricare le ricette. Riprova più tardi."),
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
        "selectionCountLabel": m17,
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
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Pasti personalizzati"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Disclaimer"),
        "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di fibre in grammi. Il valore di riferimento predefinito è 30 g."),
        "settingsFibreGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo fibre"),
        "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
            "Obiettivi personali per ogni nutriente del pannello giornaliero. Il diario li utilizza al posto dei valori di riferimento predefiniti ogni volta che ne imposti uno."),
        "settingsNutrientGoalsLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivi nutrizionali"),
        "settingsSaturatedFatGoalDescription":
            MessageLookupByLibrary.simpleMessage(
                "Limite giornaliero di grassi saturi in grammi. Il valore di riferimento predefinito è 20 g."),
        "settingsSaturatedFatGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo grassi saturi"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Fonti e riferimenti"),
        "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Limite giornaliero di zuccheri in grammi. Il valore di riferimento predefinito è 50 g."),
        "settingsSugarsGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo zuccheri"),
        "settingsSodiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo sodio"),
        "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Limite giornaliero di sodio in milligrammi. Il valore di riferimento predefinito è 2300 mg."),
        "settingsCalciumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo calcio"),
        "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di calcio in milligrammi. Il valore di riferimento predefinito è 1000 mg."),
        "settingsIronGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo ferro"),
        "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di ferro in milligrammi. Il valore predefinito dipende dal genere (8 mg uomo, 18 mg donna, 14 mg altrimenti)."),
        "settingsPotassiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo potassio"),
        "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di potassio in milligrammi. Il valore di riferimento predefinito è 3500 mg."),
        "settingsMagnesiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo magnesio"),
        "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di magnesio in milligrammi. Il valore predefinito dipende dal genere (400 mg uomo, 310 mg donna, 355 mg altrimenti)."),
        "settingsVitaminDGoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo vitamina D"),
        "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di vitamina D in microgrammi. Il valore di riferimento predefinito è 15 µg."),
        "settingsVitaminB12GoalLabel":
            MessageLookupByLibrary.simpleMessage("Obiettivo vitamina B12"),
        "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
            "Obiettivo giornaliero di vitamina B12 in microgrammi. Il valore di riferimento predefinito è 2,4 µg."),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("Vedi le fonti"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker utilizza per ogni calcolo metodologie consolidate e sottoposte a peer review. I riferimenti seguenti rimandano alle fonti originali, così puoi verificare ogni numero in autonomia."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Fabbisogno energetico (TDEE, BMR e livello di attività)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Gli obiettivi calorici giornalieri, il metabolismo basale e i coefficienti di attività fisica si basano sulle equazioni dell\'Institute of Medicine. Fonte: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, capitolo 5 e tabella 5-5."),
        "sourcesBmiTitle":
            MessageLookupByLibrary.simpleMessage("Indice di Massa Corporea (BMI)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "Il BMI si calcola come peso (kg) diviso il quadrato dell\'altezza (m²). Le categorie di salute (sottopeso, normopeso, pre-obesità, obesità di classe I–III) seguono la classificazione del BMI per adulti dell\'Organizzazione Mondiale della Sanità."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Distribuzione dei macronutrienti"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "La distribuzione predefinita di 60% carboidrati, 25% grassi e 15% proteine rientra negli intervalli raccomandati dall\'OMS. Puoi modificarla in Impostazioni → Calcoli. Fonte: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Calorie dall\'attività (valori MET)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Le calorie bruciate durante un\'attività si stimano come MET × peso corporeo (kg) × durata (ore), usando i valori dell\'Adult Compendium of Physical Activities."),
        "sourcesNonBinaryTitle":
            MessageLookupByLibrary.simpleMessage("Stima calorica per persone non binarie"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "La ricerca sul dispendio energetico ha storicamente usato solo categorie binarie di sesso, quindi non esiste una formula TDEE validata per le persone non binarie. OpenNutriTracker permette quindi di scegliere tra un riferimento medio, un riferimento di tipo estrogenico e uno di tipo testosteronico in Impostazioni → Calcoli. Se per te è davvero importante un valore accurato, ti consigliamo di parlarne con un medico che conosca il tuo profilo ormonale."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("Apri la fonte"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Distanza"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Imperiale (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Impostazioni"),
        "settingsLanguageLabel":
            MessageLookupByLibrary.simpleMessage("Lingua"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licenze"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Massa"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metrico (kg, cm, ml)"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Promemoria giornaliero"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("Autorizzazione alle notifiche negata."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Non dimenticare di registrare i tuoi pasti oggi!"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Impostazioni privacy"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Segnala errore"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Mostra tracciamento attività"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Mostra macro pasto"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mostra micronutrienti"),
        "settingsNutrientsLabel":
            MessageLookupByLibrary.simpleMessage("Nutrienti"),
        "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
            "Scegli quali nutrienti compaiono nel pannello del diario"),
        "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
            "Scegli quali nutrienti sono visibili nel pannello giornaliero. Quelli nascosti possono essere riattivati in qualsiasi momento."),
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
        "shareActivityLabel":
            MessageLookupByLibrary.simpleMessage("Condividi allenamento"),
        "shareCodeLabel":
            MessageLookupByLibrary.simpleMessage("Condividi codice"),
        "shareMealLabel":
            MessageLookupByLibrary.simpleMessage("Condividi pasto"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Condividi ricetta"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "es. mela, gelato, cioccolato ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Spuntino"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodio"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("zuccheri"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("assunte"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("grassi trans"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Unità"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamina A"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamina B12"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamina B6"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamina C"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamina D"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Avviso"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ritmo settimanale"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Non impostato"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Peso"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("zinco"),
        "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
            "Carboidrati (dal più alto al più basso)"),
        "diarySortByFat": MessageLookupByLibrary.simpleMessage(
            "Grassi (dal più alto al più basso)"),
        "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
            "Calorie (dal più alto al più basso)"),
        "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Ordina per"),
        "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
            "Proteine (dal più alto al più basso)"),
        "diarySortByTime":
            MessageLookupByLibrary.simpleMessage("Ora di aggiunta"),
        "profileTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Peso obiettivo"),
        "profileTargetWeightNotSetLabel":
            MessageLookupByLibrary.simpleMessage("Non impostato"),
        "profileTargetWeightClearAction":
            MessageLookupByLibrary.simpleMessage("Cancella"),
        "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
            "Hai raggiunto il tuo obiettivo"),
        "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
            "Riduce gradualmente il deficit giornaliero così gli ultimi chili non sembrano un muro."),
        "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
            "Adatta l\'obiettivo calorico mentre ti avvicini al tuo peso obiettivo"),
        "settingsTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Peso obiettivo"),
        "profileTargetWeightToGo": m22,
      };
}
