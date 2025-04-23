// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
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
  String get localeName => 'fr';

  static String m0(versionNumber) => "Version ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% glucides, ${pctFats}% lipides, ${pctProteins}% protéines";

  static String m3(age) => "${age} ans";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "ex. : course, vélo, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Activité"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Ajouter un nouvel élément :"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Ajouter"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Informations fournies par\nle \'Compendium 2011\ndes activités physiques\'"),
        "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
            "Élément de repas personnalisé"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Plus d\'informations sur\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Plus d\'informations sur\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Élément de repas inconnu"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Âge"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tous"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker est un compteur de calories et de nutriments gratuit et open source qui respecte votre vie privée."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Licence GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Quantité de base (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Bêta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "L’Indice de Masse Corporelle (IMC) est un indicateur pour classer le surpoids et l’obésité chez l’adulte. Il est défini comme le poids en kilogrammes divisé par la taille au carré en mètres (kg/m²).\n\nL’IMC ne fait pas la distinction entre la masse grasse et la masse musculaire et peut être trompeur pour certaines personnes."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("IMC"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "ex. : céréales, lait, café ..."),
        "breakfastLabel":
            MessageLookupByLibrary.simpleMessage("Petit-déjeuner"),
        "burnedLabel": MessageLookupByLibrary.simpleMessage("brûlé"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("SUIVANT"),
        "buttonResetLabel":
            MessageLookupByLibrary.simpleMessage("Réinitialiser"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Enregistrer"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("COMMENCER"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("OUI"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage(
                "Répartition des macronutriments"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(recommandé)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Équation de l’Institut de Médecine"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Équation TDEE"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("glucides"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("glucides"),
        "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
            "Choisissez un objectif de poids"),
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Vers quel type de repas voulez-vous copier ?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Avec \"Copier à aujourd\'hui\", vous pouvez copier le repas à aujourd\'hui. Avec \"Supprimer\", vous pouvez supprimer le repas."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Que voulez-vous faire ?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Souhaitez-vous créer un élément de repas personnalisé ?"),
        "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Créer un élément de repas personnalisé ?"),
        "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
            "Ajustement quotidien des kcal :"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Soutenir le développement en fournissant des données anonymes"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Souhaitez-vous supprimer l’élément sélectionné ?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Supprimer l’élément ?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("ANNULER"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("COPIER À AUJOURD’HUI"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SUPPRIMER"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("OK"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Journal"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "ex. : soupe, poulet, vin ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Dîner"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker n’est pas une application médicale. Toutes les données fournies ne sont pas validées et doivent être utilisées avec prudence. Veuillez maintenir un mode de vie sain et consulter un professionnel si vous avez des problèmes. L\'utilisation pendant la maladie, la grossesse ou l\'allaitement n\'est pas recommandée.\n\n\nL’application est toujours en cours de développement. Des erreurs, bugs et plantages peuvent survenir."),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Modifier l’élément"),
        "editMealLabel":
            MessageLookupByLibrary.simpleMessage("Modifier le repas"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("énergie"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de l\'enregistrement du repas. Avez-vous saisi les informations correctement ?"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Exporter"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez exporter les données de l\'application dans un fichier zip et les importer plus tard. Cela est utile pour sauvegarder vos données ou les transférer vers un autre appareil.\n\nL\'application n\'utilise aucun service cloud pour stocker vos données."),
        "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Erreur lors de l\'exportation / importation"),
        "exportImportLabel": MessageLookupByLibrary.simpleMessage(
            "Exporter / Importer les données"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Exportation / Importation réussie"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("lipides"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("fibres"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("♀ femme"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Genre"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("♂ homme"),
        "goalGainWeight":
            MessageLookupByLibrary.simpleMessage("Prendre du poids"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Objectif"),
        "goalLoseWeight":
            MessageLookupByLibrary.simpleMessage("Perdre du poids"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Maintenir le poids"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Taille"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Accueil"),
        "importAction": MessageLookupByLibrary.simpleMessage("Importer"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Nouvelle activité ajoutée"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Nouvelle prise ajoutée"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Élément supprimé"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Élément mis à jour"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kcal restantes"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "ex. : pizza, salade, riz ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Déjeuner"),
        "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
            "Répartition des macronutriments :"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Marques"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("glucides par"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("lipides par"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal par"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Nom du repas"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("protéines pour 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Taille du repas (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Taille du repas (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Unité du repas"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Informations kcal ou macronutriments manquantes pour ce produit"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Aucune activité ajoutée récemment"),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Aucun repas ajouté récemment"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("N/D"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Aucun élément ajouté"),
        "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
            "Informations nutritionnelles"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Les données fournies par cette application proviennent de la base de données Open Food Facts. Aucune garantie ne peut être donnée quant à l’exactitude, l’exhaustivité ou la fiabilité des informations. Les données sont fournies « en l’état » et la source originale (Open Food Facts) n’est pas responsable des dommages liés à leur utilisation."),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Quel est votre niveau d’activité (hors entraînements) ?"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Entrer la date"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Quelle est votre date de naissance ?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Date de naissance"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Quel est votre genre ?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Quel est votre objectif de poids actuel ?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("ex. : 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("ex. : 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Quelle est votre taille actuelle ?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Pour commencer, l\'application a besoin de quelques informations vous concernant afin de calculer votre objectif calorique quotidien.\nToutes les informations vous concernant sont stockées en toute sécurité sur votre appareil."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("kcal par jour"),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Aperçu"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Entrée incorrecte, veuillez réessayer"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("ex. : 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("ex. : 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Quel est votre poids actuel ?"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Bienvenue sur"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Entrez une taille correcte"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Entrez un poids correct"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Votre objectif calorique :"),
        "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
            "Vos objectifs en macronutriments :"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Souvent debout ou en marche, activités actives"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Actif"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ex. : assis ou debout au travail, activités légères"),
        "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Peu actif"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ex. : travail de bureau et activités assises"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Sédentaire"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Souvent en marche, en course ou transport de charge"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Très actif"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("Par 100g/ml"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("Par portion"),
        "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
            "Politique de confidentialité"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("protéines"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Quantité"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "J’ai lu et j’accepte la politique de confidentialité."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Récemment"),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Souhaitez-vous signaler une erreur au développeur ?"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("gras saturés"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Scanner le produit"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Veuillez entrer un mot de recherche"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Aliments"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Rechercher"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Produits"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Résultats de recherche"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner le genre"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner la taille"),
        "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
            "Sélectionner un niveau d’activité"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Sélectionner le poids"),
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Envoyer des données d\'utilisation anonymes"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Portion"),
        "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
            "Taille de portion (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Taille de portion (g/ml)"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("À propos"),
        "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Retour"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Calculs"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Avertissement"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Distance"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("Impérial (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Paramètres"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Licences"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Masse"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Métrique (kg, cm, ml)"),
        "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
            "Paramètres de confidentialité"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Signaler une erreur"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Code source"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Système"),
        "settingsThemeDarkLabel":
            MessageLookupByLibrary.simpleMessage("Sombre"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Thème"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Clair"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Par défaut du système"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Unités"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Volume"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "ex. : pomme, glace, chocolat ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("En-cas"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("sucres"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("fourni"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Unité"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Poids"),
        "yearsLabel": m3
      };
}
