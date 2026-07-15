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

  static String m0(sourceName) => "Maggiori informazioni su\n${sourceName}";

  static String m1(versionNumber) => "Versione ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% carboidrati, ${pctFats}% grassi, ${pctProteins}% proteine";

  static String m3(count, size) => "${count} elementi · ${size}";

  static String m4(imported, skipped) =>
      "Importati ${imported} pasti; ${skipped} righe ignorate per dati non validi.";

  static String m5(count) => "Importati ${count} pasti.";

  static String m6(unit) => "${unit} per porzione";

  static String m7(loser, winner) =>
      "Tutte le voci registrate con ${loser} verranno sostituite e mostrate come ${winner}, e ${loser} sarà rimosso dai tuoi alimenti personalizzati. Questa operazione non può essere annullata.";

  static String m8(winner) => "Unito — ${winner} ora ha 1 voce registrata.";

  static String m9(count, winner) =>
      "Unito — ${winner} ora ha ${count} voci registrate.";

  static String m10(count) => "Eliminare ${count} ricetta/e?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "rif. ${value}";

  static String m13(remaining) => "Digiuno · ${remaining} rimanenti";

  static String m14(value) => "${value} rimanenti";

  static String m15(value) => "Obiettivo: ${value}";

  static String m16(count) => "Importare ${count} attività?";

  static String m17(mealType) =>
      "Questi elementi verranno aggiunti a ${mealType}.";

  static String m18(count) => "Importare ${count} voci?";

  static String m19(count) =>
      "${count} elemento/i non è stato possibile recuperare da OpenFoodFacts.";

  static String m20(count) =>
      "Importare questa ricetta con ${count} ingrediente(i)?";

  static String m21(amount) => "Aggiungi ${amount} ml";

  static String m22(threshold) =>
      "Gli adulti non dovrebbero assumere meno di ${threshold} kcal al giorno per periodi prolungati senza una guida medica. Valuta di parlare con un professionista sanitario prima di mantenere un obiettivo così basso.";

  static String m23(kcal) => "(+${kcal} kcal selezione attuale)";

  static String m24(consumed, goal) =>
      "Totale giornaliero: ${consumed} / ${goal}";

  static String m25(qty, unit) => "Per ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'barretta', other: 'barrette')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'bottiglia', other: 'bottiglie')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'lattina', other: 'lattine')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'tazza', other: 'tazze')}";

  static String m30(count) =>
      "${Intl.plural(count, one: 'uovo', other: 'uova')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'confezione', other: 'confezioni')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'pezzo', other: 'pezzi')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'porzione', other: 'porzioni')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'porzione', other: 'porzioni')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'fetta', other: 'fette')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'cucchiaio', other: 'cucchiai')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'cucchiaino', other: 'cucchiaini')}";

  static String m38(riskValue) => "Rischio di comorbilità: ${riskValue}";

  static String m39(value) => "${value} al tuo obiettivo";

  static String m40(mealType) => "Aggiunto a ${mealType}";

  static String m41(count) => "${count} ingrediente/i";

  static String m42(count) => "${count} selezionati";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Orario promemoria: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/settimana";

  static String m48(rate) => "${rate} lbs/settimana";

  static String m49(age) => "${age} anni";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "es. corsa, bicicletta, yoga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Attività"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiungi nuovo alimento:",
    ),
    "addLabel": MessageLookupByLibrary.simpleMessage("Aggiungi"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Aggiungi profilo"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Informazioni fornite\ndal\n\'2024 Compendium\ndelle Attività Fisiche\'",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Alimento personalizzato",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Maggiori informazioni su\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Maggiori informazioni su\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Ricetta personalizzata",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Alimento sconosciuto",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Età"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tutti"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker è un tracker di calorie e nutrienti gratuito e open-source che rispetta la tua privacy.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("Licenza GPL-3.0"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Questo codice a barre a 13 cifre sembra digitato male, l\'ultima cifra non corrisponde alle altre",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Valori nutrizionali per",
    ),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "L\'Indice di Massa Corporea (BMI) è un indice per classificare sovrappeso e obesità negli adulti. È definito come peso in chilogrammi diviso per l\'altezza in metri al quadrato (kg/m²).\n\nIl BMI non differenzia tra massa grassa e muscolare e può essere fuorviante per alcune persone.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "es. cereali, latte, caffè ...",
    ),
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
          "Distribuzione dei macronutrienti",
        ),
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(consigliato)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Equazione dell\'Istituto di Medicina (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "Equazione TDEE",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Riferimento medio (predefinito)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Riferimento di tipo estrogenico",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Non esiste una base calorica pubblicata per persone non binarie — le equazioni di riferimento si basano su campioni maschili e femminili. Per impostazione predefinita usiamo la media delle due, un punto di partenza neutrale che non ti chiede di rivelare nulla in più sul tuo corpo. Il cursore kcal in Impostazioni è sempre disponibile per la regolazione fine; questo è un punto di partenza, non una stima precisa.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Riferimento calorie",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage(
          "Riferimento di tipo testosteronico",
        ),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("carboidrati"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("carboidrati"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("c"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("colesterolo"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ritmo peso settimanale",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Scegli obiettivo di peso",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Rimuove i risultati di ricerca e scansione memorizzati localmente da Open Food Facts e FDC. La cache si ricostruisce automaticamente quando cerchi e scansioni prodotti. I tuoi pasti personalizzati non vengono toccati.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Svuotare la cache?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage("Svuota cache"),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Codice copiato"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Pasto copiato nel profilo",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Copia"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Copia codice"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Quale tipo di pasto vuoi copiare?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Con \"Copia a oggi\" puoi duplicare il pasto nella giornata odierna. Con \"Elimina\" puoi rimuovere il pasto.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Cosa vuoi fare?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Copia nel profilo",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Vuoi creare un alimento personalizzato per il pasto?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Creare un alimento personalizzato?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage("Crea ricetta"),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Hai un codice a barre? Contribuisci il prodotto a Open Food Facts:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Impossibile leggere il file CSV. Controlla il formato e riprova.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Inserisci direttamente le calorie bruciate, per allenamenti non in elenco o letture da un fitness tracker",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Inserisci direttamente i kilojoule bruciati, per allenamenti non in elenco o letture da un fitness tracker",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("es. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Calorie bruciate",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Attività personalizzata",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "es. Tragitto serale in bici",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Nome (facoltativo)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Scegli da modelli salvati",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Salva come modello per la prossima volta",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Non hai ancora salvato modelli. Spunta «Salva come modello per la prossima volta» per ricordare un\'attività personalizzata da riutilizzare.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Scansiona o digita un codice a barre per richiamare questo pasto in seguito",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Il codice a barre deve avere da 8 a 14 cifre",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage(
      "Codice a barre",
    ),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Scansiona codice a barre",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage("Avanzato"),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Imposta le dimensioni e i valori per 100 g/ml per un calcolo preciso.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Vista del modulo",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Semplice"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Inserisci i totali per una porzione.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Tutte le voci del diario che utilizzano questo pasto verranno rimosse.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare il pasto personalizzato?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Nessun pasto personalizzato salvato.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Unisci a un altro alimento personalizzato",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Quale rimane?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Unisci",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Unire gli alimenti personalizzati?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Continua",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Scegli l\'alimento personalizzato da unire",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Altre azioni",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Regolazione kcal giornaliere:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Regolazione kJ giornalieri:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Invia segnalazioni di arresto anonime per aiutarci a correggere i bug. Non vengono inclusi diario alimentare, peso o dati personali.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profilo 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Elimina tutto"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Questa operazione elimina definitivamente il profilo e tutti i suoi dati e non può essere annullata.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare il profilo?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Vuoi eliminare l\'alimento selezionato?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Vuoi eliminare tutti gli elementi di questo pasto?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare gli elementi?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare l\'alimento?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ANNULLA"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Chiudi"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage("Copia a oggi"),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("ELIMINA"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Stai modificando una data futura",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Diario"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Vengono sommati solo i nutrienti registrati sui pasti che hai inserito. Un pasto senza un valore non contribuisce a quel nutriente — i totali potrebbero quindi essere sottostimati.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Nutrienti di oggi",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Carboidrati (dal più alto al più basso)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage(
      "Grassi (dal più alto al più basso)",
    ),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Calorie (dal più alto al più basso)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Ordina per"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Proteine (dal più alto al più basso)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Ora di aggiunta"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "es. zuppa, pollo, vino ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Cena"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Annulla",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Le modifiche non salvate andranno perse.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Annullare le modifiche?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker non è un\'applicazione medica. Tutti i dati forniti non sono validati e dovrebbero essere utilizzati con cautela. Mantieni uno stile di vita sano e consulta un professionista se hai problemi. L\'uso durante malattie, gravidanza o allattamento non è raccomandato. Per le fonti sottoposte a peer review di ogni calcolo, tocca l\'icona informativa nella schermata Home o Profilo.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Pasti di esempio (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Pasti di esempio (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Ricette di esempio (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Ricette di esempio (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Questi valori di riferimento provengono dai Dietary Reference Intakes dell\'IOM per adulti e variano in base a età e genere. Sono un riferimento, non un obiettivo — le tue esigenze possono essere diverse.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Fonte: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Apporto di riferimento",
    ),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Questo alimento è già stato aggiunto a questo pasto oggi. Aggiungerlo di nuovo?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Duplica"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(copia)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica alimento",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Modifica pasto"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage(
      "Modifica profilo",
    ),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage("Modifica ricetta"),
    "energyLabel": MessageLookupByLibrary.simpleMessage("energia"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("rimanenti"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("in eccesso"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilocalorie (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage("Kilojoule (kJ)"),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Errore durante il recupero dei dati del prodotto",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Errore durante il caricamento delle attività",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Errore durante il salvataggio del pasto. Hai inserito informazioni corrette?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Errore durante l\'apertura del browser",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Errore durante l\'apertura dell\'app email",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Prodotto non trovato",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Esporta"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Esporta / Importa dati app",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "Il CSV conserva attività, registro pasti e giorni tracciati. Le ricette e le foto allegate restano solo nel JSON — passa a JSON se vuoi includerle nel backup.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Puoi esportare i dati dell\'app in un file zip e importarli successivamente. Utile per backup o trasferimento su un altro dispositivo.\n\nL\'app non utilizza servizi cloud per memorizzare i tuoi dati.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Errore di esportazione / importazione",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Esportazione / Importazione riuscita",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Termina digiuno"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Chiuderà la sessione corrente.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Terminare il digiuno?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage(
      "Sessione completata",
    ),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Trascorso"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Notifiche occasionali quando un digiuno raggiunge il suo obiettivo.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Timer del digiuno",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Il tuo tempo obiettivo è stato raggiunto.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Sessione di digiuno completata",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage(
      "Personalizzato",
    ),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Avvia timer"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Un semplice timer per il tempo tra i pasti. Nessuna serie, nessun obiettivo, solo l\'orologio.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Timer di digiuno"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Ho capito, attiva il timer",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Tenere traccia dei tempi di digiuno può aiutare alcune persone e turbarne altre, in particolare chi ha alle spalle un disturbo alimentare. Se è il tuo caso, prenditi prima cura di te. Puoi trovare sostegno presso BEAT (UK) e NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "Non fa per me",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Prima di iniziare",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("grassi"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("g"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("fibre"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Sempre attivo",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "I risultati di ricerca provengono da questi database alimentari. Open Food Facts alimenta la ricerca di prodotti e codici a barre ed è sempre attivo.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("femmina"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Sesso"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("maschio"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("non binario"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Aumentare peso"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Obiettivo"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Perdere peso"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage(
      "Mantenere peso",
    ),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Altezza"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Tocca + per registrare il tuo primo pasto o attività",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Home"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("ore"),
    "importAction": MessageLookupByLibrary.simpleMessage("Importa"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Queste attività verranno aggiunte a oggi.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Importa allenamento condiviso",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Allenamento importato",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Importa i tuoi pasti da un file CSV o incollando JSON. Scarica un esempio per vedere la forma attesa e i campi obbligatori.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Importa dati alimentari personalizzati",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Codice QR non valido",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Importa pasto condiviso",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Pasto importato",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importa pasti (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importa pasti (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Impossibile leggere il codice della ricetta",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Importa ricetta",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Ricetta importata",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Importa ricette (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Importa ricette (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Questi valori non sembrano tornare — le calorie inserite non corrispondono all\'energia di carboidrati, grassi e proteine. Salvare comunque o controllare di nuovo?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Controlla di nuovo",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Salva comunque"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "I numeri non tornano",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Nuova attività aggiunta",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Nuova assunzione aggiunta",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("ferro"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage(
      "alimento eliminato",
    ),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Alimento aggiornato",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal rimanenti"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("kcal in eccesso"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Registra acqua bevuta",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Niente da annullare",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage("Annulla ultimo"),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Questo obiettivo giornaliero è piuttosto basso",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Mostra avviso",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "es. pizza, insalata, riso ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Pranzo"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Nome tradotto automaticamente",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Distribuzione dei macronutrienti:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnesio"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Gestisci profili",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marche"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Carboidrati"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Energia"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Grassi"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Aggiungi una foto"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Scegli dalla galleria",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Rimuovi foto"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage(
      "Sostituisci foto",
    ),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Scatta una foto",
    ),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal per"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nome pasto"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Il nome del pasto deve contenere almeno una lettera",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Quantità totale",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage(
      "Cinque piccoli",
    ),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Mediterranea",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("Un pasto"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Preset rapidi",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Standard"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("Due pasti"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Proteine"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage(
      "Dimensione confezione",
    ),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Dimensione confezione (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Unità pasto"),
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
      "Micronutrienti",
    ),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "Prodotto senza informazioni su kcal o macronutrienti",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "grassi monoinsaturi",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Nuovo alimento personalizzato",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("niacina (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Nessuna attività aggiunta di recente",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Nessun pasto aggiunto di recente",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Nessun risultato trovato",
    ),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/D"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Niente aggiunto",
    ),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Non dimenticare di registrare i tuoi pasti oggi!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Promemoria giornaliero per registrare i pasti",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Promemoria giornalieri"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Autorizzazione alle notifiche negata.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Tutti i nutrienti nascosti — attivane alcuni in Impostazioni → Nutrienti.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Giorno"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("limite"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Settimana"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Informazioni nutrizionali",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Peso normale",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Obesità di classe I",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Obesità di classe II",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Obesità di classe III",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Pre-obesità",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Medio",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Aumentato",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Basso\n(ma rischio di altri\nproblemi clinici aumentato)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Moderato",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Grave",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Molto grave",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Sottopeso",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "I dati forniti da questa app provengono dal database Open Food Facts. Non è possibile garantire l\'accuratezza, la completezza o l\'affidabilità delle informazioni fornite. I dati sono forniti \"così come sono\" e la fonte originale (Open Food Facts) non è responsabile per eventuali danni derivanti dall\'uso dei dati.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Quanto sei attivo? (senza allenamenti)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Inserisci data",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Quando è il tuo compleanno?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Data di nascita",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Come registri cibo e bevande",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Qual è il tuo sesso?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Qual è il tuo obiettivo di peso attuale?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "es. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "es. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Qual è la tua altezza attuale?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Per iniziare, l\'app ha bisogno di alcune informazioni su di te per calcolare il tuo obiettivo calorico giornaliero.\nTutte le informazioni su di te sono memorizzate in modo sicuro sul tuo dispositivo.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Consulta le fonti dei nostri calcoli medici",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kcal al giorno",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "kJ al giorno",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Non esiste una base calorica pubblicata per persone non binarie, quindi per impostazione predefinita usiamo una media delle formule maschili e femminili — un punto di partenza, non una stima precisa. Puoi regolare in qualsiasi momento da Impostazioni → Calcoli.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Altre opzioni",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Personalizza l\'app — potrai cambiare tutto in seguito nelle impostazioni",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage(
      "Panoramica",
    ),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Dati errati, riprova",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Facoltativo",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "C\'è un peso che vuoi raggiungere? Puoi lasciare vuoto o modificarlo più tardi dal Profilo.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "es. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "es. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Qual è il tuo peso attuale?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage(
      "Benvenuto in",
    ),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Inserisci un\'altezza corretta",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Inserisci un peso corretto",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Il tuo obiettivo calorico:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "I tuoi obiettivi di macronutrienti:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "videogiochi attivi",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, generale",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "football americano",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "touch, flag, generale",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage(
      "tiro con l\'arco",
    ),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "non per caccia",
    ),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("auto da corsa"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("open wheel"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage(
      "escursionismo",
    ),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "singoli e doppi sociali, generale",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage(
      "pallacanestro",
    ),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("ciclismo"),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "ciclismo, montagna",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "ciclismo, stazionario",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("biliardo"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("boxe"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("punching bag"),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boxe"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "nel ring, generale",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "calisthenics",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "sforzo leggero o moderato, generale (es. esercizi per la schiena)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("canoa"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "remare, per piacere, generale",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("football o baseball"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("giocare a palla"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("cheerleading"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "movimenti ginnici, competitivo",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage(
      "giochi per bambini",
    ),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(es. campana, 4-square, palla avvelenata, attrezzi da playground, t-ball, tetherball, biglie, giochi da sala), sforzo moderato",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "arrampicata su colline, senza carico",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "senza carico",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("cricket"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "battuta, lancio, fielding",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("croquet"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "sci di fondo",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "fondo, generale",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("aerobica"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("danza generale"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "es. disco, folk, danza irlandese, line dance, polka, contra, country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("freccette"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage(
      "da muro o da giardino",
    ),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("immersioni"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "apnea, subacquea, generale",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "tuffi",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "trampolino o piattaforma",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("scherma"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("giocare a frisbee"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("ginnastica"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("pallamano"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("deltaplano"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("ciclismo"),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "esercizi condizionali",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("danza"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("corsa"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("sport"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("camminata"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "attività acquatiche",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "attività invernali",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "allenamento intervallato ad alta intensità",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "sforzo moderato",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "allenamento intervallato ad alta intensità",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "burpees, mountain climber, squat jump, Tabata, sforzo intenso",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage(
      "escursionismo",
    ),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "escursionismo di fondo",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("hockey su prato"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage("equitazione"),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage(
      "hockey su ghiaccio",
    ),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage(
      "pattinaggio su ghiaccio",
    ),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("jogging"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("giocoleria"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kayak"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "sforzo moderato",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("calcio"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("lacrosse"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("bocce"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "bocce, all\'aperto",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "arti marziali",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "diversi tipi, ritmo moderato (es. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boxing)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage(
      "arti marziali",
    ),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "diversi tipi, ritmo lento, principianti, pratica",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("motocross"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "sport motoristici off-road, veicoli fuoristrada, generale",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("arrampicata"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "roccia o montagna",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("nordic walking"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("orienteering"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("paddle boarding"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("in piedi"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pedalò"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage(
      "casuale, generale",
    ),
    "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("a cavallo"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("racquetball"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "allenamento con i pesi",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "sollevamento pesi, pesi liberi, nautilus o universal",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "allenamento di forza (intenso)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "sforzo intenso, powerlifting o bodybuilding",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "sport da rodeo",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "generale, sforzo moderato",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage(
      "pattinaggio in linea",
    ),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "pattinaggio in linea",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "salto con la corda",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ritmo moderato, 100-120 salti/min, generale, salto a due piedi, rimbalzo semplice",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "salto della corda",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "union, squadra, competitivo",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "touch, non competitivo",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("corsa"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("vela"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "barca e windsurf, vela su ghiaccio, generale",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "skateboard",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale, sforzo moderato",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
      "pattinaggio a rotelle",
    ),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("sci"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "sci d\'acqua",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "acqua o wakeboard",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("paracadutismo"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "paracadutismo, base jumping, bungee jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("snorkeling"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "spalare neve",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "a mano, sforzo moderato",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage("racchette da neve"),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("calcio"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "casuale, generale",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "softball / baseball",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "lancio veloce o lento, generale",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paStretching": MessageLookupByLibrary.simpleMessage("stretching"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage(
      "leggero, generale",
    ),
    "paSurfing": MessageLookupByLibrary.simpleMessage("surf"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "body o board, generale",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("nuoto"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "stare a galla, sforzo moderato, generale",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage(
      "tennis da tavolo",
    ),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "tennis da tavolo, ping pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "tai chi, qi gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "generale",
    ),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tennis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("atletica leggera"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(es. peso, disco, martello)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(es. salto in alto, salto in lungo, triplo salto, giavellotto, salto con l\'asta)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(es. steeplechase, ostacoli)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trampolino"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage("ricreativo"),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "corsa sul tapis roulant",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "sul tapis roulant, generale",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("monociclo"),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("pallavolo"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "non competitivo, squadra da 6-9 membri, generale",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("camminata"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "per piacere",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage(
      "passeggiare con il cane",
    ),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage(
      "esercizi in acqua",
    ),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "acquagym, calistenia in acqua",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("pallanuoto"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage(
      "pallavolo in acqua",
    ),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "acquagym",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "acquagym, calistenia in acqua",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("wrestling"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("generale"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Lavoro prevalentemente in piedi o camminando e attività attive nel tempo libero",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Attivo"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "es. lavoro seduto o in piedi e attività leggere nel tempo libero",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Poco attivo"),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "es. lavoro d\'ufficio e tempo libero prevalentemente seduto",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sedentario"),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Lavoro prevalentemente camminando, correndo o trasportando pesi e attività attive nel tempo libero",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Molto attivo"),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Incolla qui il codice del pasto condiviso",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Incolla codice"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Per 100g/ml"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Per porzione"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosforo"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "grassi polinsaturi",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("potassio"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Privacy policy",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Attivo"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage(
      "Timer di digiuno",
    ),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiungi una foto",
    ),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage("Rimuovi foto"),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage("Cambia foto"),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profilo"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Nome profilo"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Nome"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Cancella",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Peso obiettivo",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Non impostato",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Hai raggiunto il tuo obiettivo",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Cronologia del peso",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("proteine"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantità"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Attività aggiunta",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Durata (min, facoltativo)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energia bruciata (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energia bruciata (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Nome (facoltativo)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiunta rapida attività",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Aggiunta rapida",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Carboidrati (g, opzionale)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiunta rapida",
    ),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage(
      "Aggiunta rapida",
    ),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Energia (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Energia (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Grassi (g, opzionale)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Proteine (g, opzionale)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Aggiungi"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Titolo"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Ho letto e accetto la privacy policy.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Recenti"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiungi ingrediente",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Le voci del diario registrate da questa ricetta saranno mantenute.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare ricetta?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Descrizione (opzionale)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiungi una foto",
    ),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Scegli dalla galleria",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage("Rimuovi foto"),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage(
      "Sostituisci foto",
    ),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Scatta una foto",
    ),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Quantità",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage("Unità"),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Ingredienti",
    ),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Il peso totale deve essere maggiore di zero",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Registra questa ricetta",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage(
      "Nome della ricetta",
    ),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "La ricetta ha bisogno di un nome",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiungi almeno un ingrediente",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Nessun ingrediente ancora",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "Per 100 g",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Nutrizione (totale)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Impossibile salvare la ricetta.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Attiva questa opzione per mantenere il pasto nella tua lista salvata per la prossima volta. Lasciala disattivata per un pasto occasionale che non mangerai più.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Salva per la prossima volta",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Salva ricetta"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Permette di registrare questa ricetta per porzioni invece che in grammi.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Porzioni (opzionale)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Separati da virgola, es. \"colazione, vegano\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Tag"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Predefinito come somma degli ingredienti. I liquidi sono approssimati a 1 ml ≈ 1 g.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Peso totale (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Crea un pasto da più ingredienti e riutilizzalo come qualsiasi altro alimento.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Nessuna ricetta ancora",
    ),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Tutti"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Ricette"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare le ricette. Riprova più tardi.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Vuoi segnalare un errore allo sviluppatore?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Riprova"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("grassi saturi"),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage(
      "Scansiona prodotto",
    ),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Blocca in verticale",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Inserisci il codice manualmente",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Inserisci il codice a barre",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "Da 8 a 14 cifre",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Questo codice a barre non sembra valido. Controlla le cifre e riprova.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage("Cerca"),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Consenti rotazione",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Inserisci una parola da cercare",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Cibo"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Cerca"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Prodotti"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Risultati di ricerca",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Seleziona sesso",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Seleziona altezza",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Seleziona livello di attività",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Seleziona peso",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Invia dati di utilizzo anonimi",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Porzione"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Una porzione (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Una porzione",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("Informazioni"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Feedback"),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Colore d\'accento",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Colore personalizzato…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Apri il selettore di tonalità per una scelta precisa",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Quel codice esadecimale non sembra giusto — sei caratteri, 0-9 e A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage(
      "Codice esadecimale",
    ),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Disattiva i colori di sistema per scegliere un accento personalizzato.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Reimposta"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Colore d\'accento",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Scegli un colore",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Personalizzato",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Predefinito",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Unità peso corporeo",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di calcio in milligrammi. Il valore di riferimento predefinito è 1000 mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo calcio",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Riduce gradualmente il deficit giornaliero così gli ultimi chili non sembrano un muro.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Adatta l\'obiettivo calorico mentre ti avvicini al tuo peso obiettivo",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage(
      "Informazioni",
    ),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Aspetto",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Dati"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage(
      "Visualizzazione",
    ),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Obiettivi e nutrizione",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Unità ed energia",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Pasti personalizzati",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Scegli l\'ora in cui inizia la tua giornata. I pasti e le attività registrati prima di questa ora verranno conteggiati nel giorno precedente — utile per chi lavora di notte o mangia tardi.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Ore",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Il giorno inizia alle",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Minuti",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Elimina tutto",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Questa operazione rimuove in modo permanente da questo dispositivo il tuo profilo, i pasti, le attività, la cronologia del peso e tutte le ricette personalizzate. I database di Open Food Facts e USDA Food Data Central non vengono modificati. L\'operazione non può essere annullata.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Eliminare tutti i tuoi dati?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Elimina tutti i miei dati",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profilo, pasti, attività e cronologia del peso",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Disclaimer",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Distanza"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Unità di energia",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di fibre in grammi. Il valore di riferimento predefinito è 30 g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo fibre",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Database alimentari",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Scegli da dove provengono i risultati di ricerca",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperiale (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Unità alimenti",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrico (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Imperiale (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Unità altezza",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrico (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Imperiale (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di ferro in milligrammi. Il valore predefinito dipende dal genere (8 mg uomo, 18 mg donna, 14 mg altrimenti).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo ferro",
    ),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Aggiustamento kcal giornaliero",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Impostazioni"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Lingua"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Licenze"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Distribuzione macro",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di magnesio in milligrammi. Il valore predefinito dipende dal genere (400 mg uomo, 310 mg donna, 355 mg altrimenti).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo magnesio",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Massa"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Riprende il colore d\'accento dello sfondo su Android 12 e versioni successive.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Usa i colori di sistema",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metrico (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Promemoria giornaliero",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Obiettivi personali per ogni nutriente del pannello giornaliero. Il diario li utilizza al posto dei valori di riferimento predefiniti ogni volta che ne imposti uno.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivi nutrizionali",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Scegli quali nutrienti sono visibili nel pannello giornaliero. Quelli nascosti possono essere riattivati in qualsiasi momento.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage("Nutrienti"),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Scegli quali nutrienti compaiono nel pannello del diario",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Colazione",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Distribuisci il tuo obiettivo giornaliero di kcal tra colazione, pranzo, cena e spuntini. Le quote devono sommare al 100%.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Cena",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Quota kcal per pasto",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Pranzo",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Spuntino",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di potassio in milligrammi. Il valore di riferimento predefinito è 3500 mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo potassio",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Impostazioni privacy",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Segnala errore",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Limite giornaliero di grassi saturi in grammi. Il valore di riferimento predefinito è 20 g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo grassi saturi",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Mostra tracciamento attività",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Mostra macro pasto",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Mostra micronutrienti",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Limite giornaliero di sodio in milligrammi. Il valore di riferimento predefinito è 2300 mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo sodio",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Codice sorgente",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Fonti e riferimenti",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Limite giornaliero di zuccheri in grammi. Il valore di riferimento predefinito è 50 g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo zuccheri",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Sistema"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Scuro"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Tema"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Chiaro"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Predefinito del sistema",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Unità"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di vitamina B12 in microgrammi. Il valore di riferimento predefinito è 2,4 µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo vitamina B12",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Obiettivo giornaliero di vitamina D in microgrammi. Il valore di riferimento predefinito è 15 µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo vitamina D",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Usato dal contatore d\'acqua nella schermata principale.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Obiettivo idrico giornaliero",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Condividi allenamento",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Condividi codice"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Condividi pasto"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Condividi ricetta",
    ),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "es. mela, gelato, cioccolato ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Spuntino"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodio"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Le calorie bruciate durante un\'attività si stimano come MET × peso corporeo (kg) × durata (ore), usando i valori dell\'Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Calorie dall\'attività (valori MET)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "Il BMI si calcola come peso (kg) diviso il quadrato dell\'altezza (m²). Le categorie di salute (sottopeso, normopeso, pre-obesità, obesità di classe I–III) seguono la classificazione del BMI per adulti dell\'Organizzazione Mondiale della Sanità.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Indice di Massa Corporea (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Gli obiettivi calorici giornalieri, il metabolismo basale e i coefficienti di attività fisica si basano sulle equazioni dell\'Institute of Medicine. Fonte: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, capitolo 5 e tabella 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Fabbisogno energetico (TDEE, BMR e livello di attività)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage("Vedi le fonti"),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "La distribuzione predefinita di 60% carboidrati, 25% grassi e 15% proteine rientra negli intervalli raccomandati dall\'OMS. Puoi modificarla in Impostazioni → Calcoli. Fonte: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Distribuzione dei macronutrienti",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "La ricerca sul dispendio energetico ha storicamente usato solo categorie binarie di sesso, quindi non esiste una formula TDEE validata per le persone non binarie. OpenNutriTracker permette quindi di scegliere tra un riferimento medio, un riferimento di tipo estrogenico e uno di tipo testosteronico in Impostazioni → Calcoli. Se per te è davvero importante un valore accurato, ti consigliamo di parlarne con un medico che conosca il tuo profilo ormonale.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Stima calorica per persone non binarie",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Gli apporti giornalieri mostrati nel pannello nutrienti del diario provengono dal rapporto di sintesi delle Dietary Reference Intakes dell\'Institute of Medicine, che copre gli obiettivi per ciascun nutriente negli adulti.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Apporti nutrizionali di riferimento",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Apri la fonte",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker utilizza per ogni calcolo metodologie consolidate e sottoposte a peer review. I riferimenti seguenti rimandano alle fonti originali, così puoi verificare ogni numero in autonomia.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("zuccheri"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("assunte"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Cambia profilo",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("grassi trans"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("record"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Calorie"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Media giornaliera",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage(
      "giorni di fila",
    ),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "giorni in linea questa settimana",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Andamento"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/settimana"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Acqua"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "settimane all\'obiettivo",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Unità"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("vitamina A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("vitamina B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("vitamina B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("vitamina C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("vitamina D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Avviso"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ritmo settimanale",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Non impostato",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage(
      "Aggiungi voce",
    ),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Registra almeno due giorni per vedere l\'andamento.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Data"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Nessuna registrazione del peso. Aggiungi la prima per iniziare a seguire l\'andamento.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Nota (facoltativa)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage("Peso"),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Peso"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Tu"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("zinco"),
  };
}
