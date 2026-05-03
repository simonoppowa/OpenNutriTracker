// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a uk locale. All the
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
  String get localeName => 'uk';

  static String m0(versionNumber) => "Версія ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% вуглеводи, ${pctFats}% жири, ${pctProteins}% білки";

  static String m2(riskValue) => "Ризик супутніх захворювань: ${riskValue}";

  static String m3(age) => "${age} років";

  static String m4(mealType) =>
      "These items will be added to your ${mealType}.";

  static String m5(count) => "Import ${count} items?";

  static String m6(count) =>
      "${count} елемент(ів) не вдалося отримати з OpenFoodFacts.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, біг, їзда на велосипеді, йога ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Активність"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Додати новий елемент:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Додати"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Інформація надана\n \"2011 Compendium\n of Physical Activities\""),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Власний елемент їжі"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Більше інформації на\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Більше інформації на\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Невідомий елемент їжі"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Вік"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Всі"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Альфа]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker — це безкоштовний трекер калорій та поживних речовин з відкритим кодом, який поважає вашу конфіденційність і не містить реклами"),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("Ліцензія GPL-3.0"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Базова кількість (г/мл)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Бета]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Індекс маси тіла (ІМТ) — це індекс для класифікації надмірної ваги та ожиріння у дорослих. Визначається як вага в кілограмах, поділена на квадрат зросту в метрах (кг/м²). ІМТ не розрізняє жирову і м\'язову масу і може бути неточним для деяких людей."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("ІМТ"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, пластівці, молоко, кава ..."),
        "breakfastLabel": MessageLookupByLibrary.simpleMessage("Сніданок"),
        "burnedLabel": MessageLookupByLibrary.simpleMessage("спалено"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("Далі"),
        "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Скинути"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Зберегти"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("Почати"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("Так"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Розподіл макроелементів"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(рекомендовано)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Розрахунок Інституту Медицини"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Розрахунок TDEE"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("вуглеводи"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("вуглеводи"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Виберіть ціль ваги"),
        "cmLabel": MessageLookupByLibrary.simpleMessage("см"),
        "codeCopiedLabel":
            MessageLookupByLibrary.simpleMessage("Код скопійовано"),
        "copyCodeLabel":
            MessageLookupByLibrary.simpleMessage("Копіювати код"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "До якого типу страви скопіювати?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "За допомогою \"Скопіювати на сьогодні\" ви можете скопіювати страву на сьогодні. За допомогою \"Видалити\" ви можете видалити страву."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Що ви хочете зробити?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Бажаєте створити власну їжу?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Створити власну їжу?"),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Щоденна корекція калорій:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Підтримайте розробку, надаючи анонімні дані про використання"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Видалити все"),
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Ви хочете видалити вибраний елемент?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Ви хочете видалити всі елементи цієї страви?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Видалити елементи?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Видалити елемент?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("Скасувати"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("Скопіювати на сьогодні"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("ВИДАЛИТИ"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("ОК"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Щоденник"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, суп, курка, вино ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Вечеря"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker не є медичним додатком. Всі надані дані не перевіряються і повинні використовуватися з обережністю. Будь ласка, ведіть здоровий спосіб життя і консультуйтеся з фахівцем, якщо у вас виникли проблеми. Використання під час хвороби, вагітності або лактації не рекомендується."),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Редагувати елемент"),
        "editMealLabel":
            MessageLookupByLibrary.simpleMessage("Редагувати страву"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("енергія"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Помилка при отриманні даних про продукт"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Помилка при завантаженні активностей"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Помилка при збереженні страви. Ви ввели коректну інформацію?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Помилка при відкритті браузера"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "Помилка при відкритті поштової програми"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Продукт не знайдено"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Експортувати"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Ви можете експортувати дані додатка у zip-файл і імпортувати їх пізніше. Це корисно, якщо ви хочете зробити резервну копію або перенести дані на інший пристрій. Додаток не використовує жодних хмарних сервісів для зберігання ваших даних."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Помилка експорту / імпорту"),
        "exportImportLabel":
            MessageLookupByLibrary.simpleMessage("Експорт / Імпорт даних"),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Експорт / Імпорт успішний"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("жири"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("клітковина"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("рідка унція"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("фут"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("♀ жінка"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Стать"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("♂ чоловік"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Набрати вагу"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Ціль"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Схуднути"),
        "goalMaintainWeight":
            MessageLookupByLibrary.simpleMessage("Підтримувати вагу"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("г/мл"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("г"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Зріст"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Головна"),
        "importAction": MessageLookupByLibrary.simpleMessage("Імпортувати"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Invalid QR code"),
        "importMealLabel":
            MessageLookupByLibrary.simpleMessage("Import shared meal"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Meal imported"),
        "importOffFetchFailedLabel": m6,
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Додано нову активність"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Додано новий прийом їжі"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Елемент видалено"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Елемент оновлено"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("ккал"),
        "kcalLeftLabel":
            MessageLookupByLibrary.simpleMessage("залишилось ккал"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("кг"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("фунт"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, піца, салат, рис ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Обід"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Розподіл макроелементів:"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Бренди"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("вуглеводи на"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("жири на"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("ккал на"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Назва страви"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("білки на 100 г/мл"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Розмір страви (г/мл)"),
        "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
            "Розмір страви (унція/рідка унція)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Одиниця страви"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("мл"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "У продукту відсутня необхідна інформація про ккал або макроелементи"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Нещодавно не додано активності"),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("Нещодавно не додано страв"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Нічого не знайдено"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("Н/Д"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Нічого не додано"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Інформація про харчування"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Нормальна вага"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Ожиріння I класу"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Ожиріння II класу"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Ожиріння III класу"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Передожиріння"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Середній"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Підвищений"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Низький (але ризик інших клінічних проблем підвищений)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Помірний"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Серйозний"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Дуже серйозний"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Недостатня вага"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Дані, які надає цей додаток, отримані з бази даних Open Food Facts. Не гарантується точність, повнота або надійність наданої інформації. Дані надаються “як є”, і джерело даних (Open Food Facts) не несе відповідальності за будь-які збитки, що виникають внаслідок використання даних."),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Наскільки ви активні? (без тренувань)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Введіть дату"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Коли у вас день народження?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("День народження"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Ваша стать?"),
        "onboardingGoalQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Яка ваша поточна ціль ваги?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("наприклад, 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("наприклад, 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Який ваш поточний зріст?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Для початку додаток потребує деяку інформацію про вас, щоб розрахувати вашу щоденну ціль калорій.\nВся інформація про вас зберігається безпечно на вашому пристрої."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("ккал на день"),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Огляд"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Неправильне введення, спробуйте ще раз"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("наприклад, 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("наприклад, 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Яка ваша поточна вага?"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Ласкаво просимо до"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Введіть коректний зріст"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Введіть коректну вагу"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ваша ціль калорій:"),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ваші цілі макроелементів:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("унція"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("американський футбол"),
        "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "безконтактний, з прапорцями, загальний"),
        "paArcheryGeneral":
            MessageLookupByLibrary.simpleMessage("стрільба з лука"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("не на полюванні"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("автогонки"),
        "paAutoRacingDesc":
            MessageLookupByLibrary.simpleMessage("з відкритими колесами"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("піший туризм з рюкзаком"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("бадмінтон"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "соціальний одиночний та парний розряд, загальний"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("баскетбол"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("їзда на велосипеді"),
        "paBicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("гірський велосипед"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("стаціонарний велосипед"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("більярд"),
        "paBilliardsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("боулінг"),
        "paBowlingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("бокс"),
        "paBoxingBagDesc":
            MessageLookupByLibrary.simpleMessage("на боксерській груші"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("бокс"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("на ринзі, загальне"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("брумбол"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("калістеніка"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "легкі або помірні зусилля, загальне (наприклад, вправи для спини)"),
        "paCanoeingGeneral":
            MessageLookupByLibrary.simpleMessage("веслування на каное"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "веслування, для задоволення, загальне"),
        "paCatch": MessageLookupByLibrary.simpleMessage("футбол або бейсбол"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("гра в ловлю"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("чирлідинг"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "гімнастичні рухи, змагальний"),
        "paChildrenGame": MessageLookupByLibrary.simpleMessage("дитячі ігри"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(наприклад, класики, 4-квадрат, вишибали, ігровий майданчик, т-бол, tetherball, марбли, аркадні ігри), помірні зусилля"),
        "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
            "підйом на пагорби, без навантаження"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("без навантаження"),
        "paCricket": MessageLookupByLibrary.simpleMessage("крикет"),
        "paCricketDesc": MessageLookupByLibrary.simpleMessage(
            "відбивання, подача, гра в полі"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("крокет"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paCurling": MessageLookupByLibrary.simpleMessage("керлінг"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("аеробні"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paDancingGeneral":
            MessageLookupByLibrary.simpleMessage("загальні танці"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "наприклад, диско, народні, ірландські, лінійні, полька, контра, кантрі"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("дартс"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("настінний або газонний"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("дайвінг"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "підводне плавання, дайвінг з аквалангом, загальне"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("стрибки у воду"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("з трампліна або платформи"),
        "paFencing": MessageLookupByLibrary.simpleMessage("фехтування"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("гра у фрісбі"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("гольф"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("гімнастика"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("гакі-сак"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("гандбол"),
        "paHandballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paHangGliding":
            MessageLookupByLibrary.simpleMessage("дельтапланеризм"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paHeadingBicycling":
            MessageLookupByLibrary.simpleMessage("їзда на велосипеді"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("аеробне тренування"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("танці"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("біг"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("спорт"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Вставте сюди код спільного прийому їжі"),
        "pasteCodeLabel":
            MessageLookupByLibrary.simpleMessage("Вставити код"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("ходьба"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("водні види спорту"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("зимові види спорту"),
        "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("похід"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("пересіченою місцевістю"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("хокей на траві"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("верхова їзда"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("хокей на льоду"),
        "paIceHockeyGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("катання на ковзанах"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("хай-алай"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("пробіжка"),
        "paJoggingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("жонглювання"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paKayakingModerate":
            MessageLookupByLibrary.simpleMessage("веслування на байдарці"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("помірні зусилля"),
        "paKickball": MessageLookupByLibrary.simpleMessage("кікбол"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("лакрос"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paLawnBowling":
            MessageLookupByLibrary.simpleMessage("гра в боулінг на газоні"),
        "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
            "бочче, на відкритому повітрі"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("бойові мистецтва"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "різні види, помірний темп (наприклад, дзюдо, джиу-джитсу, карате, кікбоксинг, тхеквондо, тай-бо, муай-тай)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("бойові мистецтва"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "різні види, повільний темп, для початківців, тренування"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("мотокрос"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "позашляхові мотоспорт, всюдихід, загальне"),
        "paMountainClimbing":
            MessageLookupByLibrary.simpleMessage("скелелазіння"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("скелелазіння або альпінізм"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("орієнтування"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("паддлбординг"),
        "paPaddleBoardingDesc":
            MessageLookupByLibrary.simpleMessage("паддлбординг стоячи"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("катамаран"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("падлбол"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("невимушено, загальне"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("поло"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("на коні"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("ракетбол"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("силові тренування"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "підняття ваги, вільна вага, Nautilus або Universal"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("спорт родео"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("загальний, помірні зусилля"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("катання на роликах"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("катання на роликах"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("стрибки зі скакалкою"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "помірний темп, 100-120 стрибків/хв, загальне, стрибки на двох ногах, звичайний відскок"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("стрибки зі скакалкою"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("регбі"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("союз, команда, змагальний"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("регбі"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("безконтактний, незмагальний"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("біг"),
        "paRunningGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paSailingGeneral":
            MessageLookupByLibrary.simpleMessage("вітрильний спорт"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "вітрильний спорт на човні та дошці, віндсерфінг, вітрильний спорт на льоду, загальне"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("шаффлборд"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("скейтбординг"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальний, помірні зусилля"),
        "paSkatingRoller":
            MessageLookupByLibrary.simpleMessage("катання на роликах"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("лижний спорт"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("водні лижі"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("водні лижі або вейкбординг"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("скайдайвінг"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "скайдайвінг, бейс-джампінг, банджі-джампінг"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("сноркелінг"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("розчищення снігу"),
        "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
            "Розчишення снігу, помірні зусилля"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("футбол"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("невимушено, загальне"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("софтбол / бейсбол"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "швидка або повільна подача, загальне"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("сквош"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("серфінг"),
        "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
            "бодісерфінг або серфінг на дошці, загальне"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("плавання"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "плавання, помірні зусилля, загальне"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("настільний теніс"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("настільний теніс, пінг-понг"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("тай-чі, цигун"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("теніс"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("легка атлетика"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(наприклад, штовхання ядра, метання диска, метання молота)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(наприклад, стрибки у висоту, стрибки в довжину, потрійний стрибок, метання списа, стрибки з жердиною)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(наприклад, стипль-чез, біг з бар\'єрами)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("батут"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("розважальний"),
        "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("уніцикл"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("волейбол"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "незмагальний, команда з 6 - 9 гравців, загальне"),
        "paWalkingForPleasure":
            MessageLookupByLibrary.simpleMessage("прогулянка"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("прогулянка для задоволення"),
        "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("вигул собаки"),
        "paWalkingTheDogDesc":
            MessageLookupByLibrary.simpleMessage("вигул собак"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("воллібол"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paWaterAerobics": MessageLookupByLibrary.simpleMessage("водні вправи"),
        "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
            "водна аеробіка, водна калістеніка"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("водне поло"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("водний волейбол"),
        "paWaterVolleyballDesc":
            MessageLookupByLibrary.simpleMessage("загальне"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("водна аеробіка"),
        "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
            "водна аеробіка, водна калістеніка"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("боротьба"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Переважно стояча або ходьба на роботі і активний відпочинок"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Активний"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "наприклад, сидяча або стояча робота і легкі активності у вільний час"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Малоактивний"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "наприклад, офісна робота і переважно сидячий відпочинок"),
        "palSedentaryLabel":
            MessageLookupByLibrary.simpleMessage("Сидячий спосіб життя"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "Переважно ходьба, біг або носіння ваги на роботі і активний відпочинок"),
        "palVeryActiveLabel":
            MessageLookupByLibrary.simpleMessage("Дуже активний"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("На 100 г/мл"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("На порцію"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Політика конфіденційності"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Профіль"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("білки"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Кількість"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Я прочитав і приймаю політику конфіденційності."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Нещодавно"),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Бажаєте повідомити про помилку розробнику?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Повторити"),
        "saturatedFatLabel":
            MessageLookupByLibrary.simpleMessage("насичені жири"),
        "scanProductLabel":
            MessageLookupByLibrary.simpleMessage("Сканувати продукт"),
        "searchDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Введіть слово для пошуку"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Їжа"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Пошук"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Продукти"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Результати пошуку"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Виберіть стать"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Виберіть зріст"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Виберіть рівень активності"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Виберіть вагу"),
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Надсилати анонімні дані про використання"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Порція"),
        "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
            "Розмір порції (унція/рідка унція)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Розмір порції (г/мл)"),
        "settingAboutLabel":
            MessageLookupByLibrary.simpleMessage("Про додаток"),
        "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Відгук"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Розрахунки"),
        "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
            "Відмова від відповідальності"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Відстань"),
        "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
            "Імперська (фунти, фут, унції)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Налаштування"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Ліцензії"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Маса"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Метрична (кг, см, мл)"),
        "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
            "Налаштування конфіденційності"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Повідомити про помилку"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Вихідний код"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Система"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Темна"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Тема"),
        "settingsThemeLightLabel":
            MessageLookupByLibrary.simpleMessage("Світла"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Системна за замовчуванням"),
        "settingsUnitsLabel":
            MessageLookupByLibrary.simpleMessage("Одиниці вимірювання"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Об\'єм"),
        "shareCodeLabel":
            MessageLookupByLibrary.simpleMessage("Поділитися кодом"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, яблуко, морозиво, шоколад ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Перекус"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("цукор"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("спожито"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Одиниця"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Вага"),
        "yearsLabel": m3
      };
}
