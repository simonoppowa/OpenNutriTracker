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

  static String m8(rate) => "${rate} кг/тиждень";

  static String m9(rate) => "${rate} фунт/тиждень";

  static String m10(qty, unit) => "На ${qty} ${unit}";

  static String m11(time) => "Час нагадування: ${time}";

  static String m12(count) => "З CSV файлу імпортовано ${count} страв.";

  static String m13(imported, skipped) =>
      "Імпортовано ${imported} страв; ${skipped} рядків пропущено через неправильні дані.";

  static String m14(count, size) => "${count} елементів · ${size}";

  static String m15(count) => "${count} інгредієнт(ів)";

  static String m16(count) =>
      "Імпортувати цей рецепт з ${count} інгредієнт(ами)?";

  static String m17(count) => "Вибрано: ${count}";

  static String m18(count) => "Видалити ${count} рецепт(ів)?";


  static String m19(count) => "Імпортувати ${count} активностей?";

  static String m20(detail) => "Не вдалося розпарсити: ${detail}";

  static String m21(count, customCount) =>
      "Записано ${count} з JSON, ${customCount} збережено як власні страви";

  static String m22(value) => "Залишилось ${value} до цілі";

  static String m23(consumed, target) => "${consumed} / ${target} kcal";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, біг, їзда на велосипеді, йога ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Активність"),
        "addItemLabel":
            MessageLookupByLibrary.simpleMessage("Додати новий елемент:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Додати"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Інформація надана\n \"2024 Compendium\n of Physical Activities\""),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Власний елемент їжі"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Більше інформації на\nFoodData Central"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Більше інформації на\nOpenFoodFacts"),
        "additionalInfoLabelRecipe":
            MessageLookupByLibrary.simpleMessage("Власний рецепт"),
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
        "calciumLabel": MessageLookupByLibrary.simpleMessage("кальцій"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Розподіл макроелементів"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(рекомендовано)"),
        "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
            "Розрахунок Інституту Медицини (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("Розрахунок TDEE"),
        "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
            "Усереднена референція (за замовчуванням)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Естрогенова референція"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "Опублікованої калорійної основи для небінарних людей не існує — рівняння-зразки побудовані на чоловічих і жіночих вибірках. За замовчуванням ми використовуємо середнє двох — нейтральну відправну точку, яка не вимагає від вас розкривати більше про ваше тіло. Повзунок ккал у Налаштуваннях завжди доступний для тонкого налаштування; це відправна точка, а не точна оцінка."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Калорійна референція"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Тестостеронова референція"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("вуглеводи"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("вуглеводи"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("в"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("холестерин"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Тижневий темп ваги"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Виберіть ціль ваги"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Видаляє локально збережені результати пошуку та сканування з Open Food Facts та FDC. Кеш автоматично відновлюється під час пошуку та сканування. Ваші власні страви не зачіпаються."),
        "clearOffCacheConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Очистити кеш?"),
        "clearOffCacheLabel":
            MessageLookupByLibrary.simpleMessage("Очистити кеш"),
        "clearOffCacheSubtitle": m14,
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
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Створити рецепт"),
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Маєте штрих-код? Додайте продукт до Open Food Facts:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Не вдалося прочитати CSV файл. Перевірте формат і спробуйте знову."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
            "Цей 13-значний штрих-код, схоже, введено з помилкою: остання цифра не збігається з рештою"),
        "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
            "Скануй або введи штрих-код, щоб згодом знайти цю страву"),
        "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
            "Штрих-код має містити від 8 до 14 цифр"),
        "customMealBarcodeLabel":
            MessageLookupByLibrary.simpleMessage("Штрих-код"),
        "customMealBarcodeScanButton":
            MessageLookupByLibrary.simpleMessage("Сканувати штрих-код"),
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Усі записи в щоденнику, що використовують цю страву, також буде видалено."),
        "customMealsDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Видалити власну страву?"),
        "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
            "Ще немає збережених власних страв."),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Щоденна корекція калорій:"),
        "dailyKjAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Щоденна корекція кДж:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Підтримайте розробку, надаючи анонімні дані про використання"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Видалити все"),
        "deleteSelectedRecipesConfirmTitle": m18,
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
        "diaryNutrientPanelDataDisclaimer":
            MessageLookupByLibrary.simpleMessage("Тут підсумовуються лише ті поживні речовини, які записані для зареєстрованих страв. Страва без значення не додає нічого до відповідного показника — тож суми можуть бути занижені."),
        "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
            "Ви редагуєте майбутню дату"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Щоденник"),
        "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
            "Поживні речовини за сьогодні"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, суп, курка, вино ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Вечеря"),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Скасувати"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Ваші незбережені зміни будуть втрачені."),
        "discardChangesTitle":
            MessageLookupByLibrary.simpleMessage("Скасувати зміни?"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker не є медичним додатком. Всі надані дані не перевіряються і повинні використовуватися з обережністю. Будь ласка, ведіть здоровий спосіб життя і консультуйтеся з фахівцем, якщо у вас виникли проблеми. Використання під час хвороби, вагітності або лактації не рекомендується. Рецензовані джерела для кожного розрахунку відкриваються через піктограму інформації на екрані Головна або Профіль."),
        "downloadSampleCsvAction":
            MessageLookupByLibrary.simpleMessage("Зразкові страви (csv)"),
        "downloadSampleJsonAction":
            MessageLookupByLibrary.simpleMessage("Зразкові страви (json)"),
        "importMealsJsonAction":
            MessageLookupByLibrary.simpleMessage("Імпортувати страви (json)"),
        "downloadSampleRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Зразкові рецепти (json)"),
        "importRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Імпортувати рецепти (json)"),
        "downloadSampleRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Зразкові рецепти (csv)"),
        "duplicateMealDialogContent":
            MessageLookupByLibrary.simpleMessage("Цю їжу вже додано до цього прийому їжі сьогодні. Додати ще раз?"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Дублювати"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(копія)"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Редагувати елемент"),
        "editMealLabel":
            MessageLookupByLibrary.simpleMessage("Редагувати страву"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Редагувати рецепт"),
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
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Експортувати / Імпортувати дані застосунку"),
        "exportImportCsvRecipesNote":
            MessageLookupByLibrary.simpleMessage("CSV зберігає активність, журнал прийомів їжі та відстежувані дні. Рецепти й додані фото зберігаються лише в JSON — перейдіть на JSON, якщо хочете залишити їх у резервній копії."),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Ви можете експортувати дані додатка у zip-файл і імпортувати їх пізніше. Це корисно, якщо ви хочете зробити резервну копію або перенести дані на інший пристрій. Додаток не використовує жодних хмарних сервісів для зберігання ваших даних."),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Помилка експорту / імпорту"),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Експорт / Імпорт успішний"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("жири"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("ж"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("клітковина"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("рідка унція"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("фут"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("жінка"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Стать"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("чоловік"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("небінарний"),
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
        "importActivityConfirmContent":
            MessageLookupByLibrary.simpleMessage("Ці активності буде додано на сьогодні."),
        "importActivityConfirmTitle": m19,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Імпортувати спільне тренування"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Тренування імпортовано"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Імпортуйте власні страви з CSV-файлу або вставивши JSON. Завантажте зразок, щоб побачити очікувану форму та обовʼязкові поля."),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Імпортувати власні дані про їжу"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Invalid QR code"),
        "importMealLabel":
            MessageLookupByLibrary.simpleMessage("Import shared meal"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Meal imported"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Імпортувати страви (csv)"),
        "importOffFetchFailedLabel": m6,
        "importRecipeConfirmContent": m16,
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Не вдалося розпізнати код рецепта"),
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Імпортувати рецепт"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Рецепт імпортовано"),
        "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
            "Імпортувати рецепти (csv)"),
        "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
            "Ці значення не зовсім сходяться — введені калорії не відповідають енергії з вуглеводів, жирів і білків. Зберегти все одно чи переглянути ще раз?"),
        "inconsistentNutritionWarningEdit":
            MessageLookupByLibrary.simpleMessage("Переглянути ще раз"),
        "inconsistentNutritionWarningSaveAnyway":
            MessageLookupByLibrary.simpleMessage("Зберегти все одно"),
        "inconsistentNutritionWarningTitle":
            MessageLookupByLibrary.simpleMessage("Числа не зовсім сходяться"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Додано нову активність"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Додано новий прийом їжі"),
        "ironLabel": MessageLookupByLibrary.simpleMessage("залізо"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Елемент видалено"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Елемент оновлено"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("ккал"),
        "kjLabel": MessageLookupByLibrary.simpleMessage("кДж"),
        "kcalLeftLabel":
            MessageLookupByLibrary.simpleMessage("залишилось ккал"),
        "kcalTooMuchLabel":
            MessageLookupByLibrary.simpleMessage("ккал понад норму"),
        "energyLeftLabel": MessageLookupByLibrary.simpleMessage("залишилось"),
        "energyTooMuchLabel":
            MessageLookupByLibrary.simpleMessage("понад норму"),
        "settingsEnergyUnitLabel":
            MessageLookupByLibrary.simpleMessage("Одиниця енергії"),
        "energyUnitKcalLabel":
            MessageLookupByLibrary.simpleMessage("Кілокалорії (ккал)"),
        "energyUnitKjLabel":
            MessageLookupByLibrary.simpleMessage("Кілоджоулі (кДж)"),
        "onboardingKjPerDayLabel":
            MessageLookupByLibrary.simpleMessage("кДж на день"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("кг"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("фунт"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, піца, салат, рис ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Обід"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Розподіл макроелементів:"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("магній"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Бренди"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("вуглеводи на"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("жири на"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("ккал на"),
        "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Енергія"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Назва страви"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Назва страви повинна містити принаймні одну літеру"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Загальна кількість"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("білки на 100 г/мл"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Розмір страви (г/мл)"),
        "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
            "Розмір страви (унція/рідка унція)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Одиниця страви"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Мікроелементи"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("мл"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "У продукту відсутня необхідна інформація про ккал або макроелементи"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("мононенасичені жири"),
        "newCustomMealLabel":
            MessageLookupByLibrary.simpleMessage("Новий власний продукт"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("ніацин (B3)"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Нещодавно не додано активності"),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("Нещодавно не додано страв"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Нічого не знайдено"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("Н/Д"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Нічого не додано"),
        "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("День"),
        "nutrientPanelWeekLabel":
            MessageLookupByLibrary.simpleMessage("Тиждень"),
        "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
            "Усі поживні речовини приховано — увімкни деякі в Налаштування → Поживні речовини."),
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
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Опублікованої калорійної основи для небінарних людей не існує, тож за замовчуванням ми використовуємо середнє чоловічої та жіночої формул — це відправна точка, а не точна оцінка. Ти можеш скоригувати це у Налаштування → Розрахунки в будь-який час."),
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
        "onboardingTargetWeightSubtitle":
            MessageLookupByLibrary.simpleMessage("Чи є вага, до якої ти прагнеш? Це поле можна залишити порожнім або змінити пізніше у Профілі."),
        "onboardingTargetWeightHintOptional":
            MessageLookupByLibrary.simpleMessage("Необов\'язково"),
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
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("активні відеоігри"),
        "paActiveVideoGamesDesc":
            MessageLookupByLibrary.simpleMessage("Wii Sports, Dance Dance Revolution, загалом"),
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
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("біг на лижах"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("біг на лижах, загалом"),
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
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("ходьба"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("водні види спорту"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("зимові види спорту"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "високоінтенсивне інтервальне тренування"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("помірне зусилля"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "високоінтенсивне інтервальне тренування"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "берпі, скелелаз, вистрибування з присіду, Табата, інтенсивне зусилля"),
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
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("скандинавська ходьба"),
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
        "paPickleball": MessageLookupByLibrary.simpleMessage("пікльбол"),
        "paPilates": MessageLookupByLibrary.simpleMessage("пілатес"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("поло"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("на коні"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("ракетбол"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("силові тренування"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "підняття ваги, вільна вага, Nautilus або Universal"),
        "paResistanceTrainingVigorous":
            MessageLookupByLibrary.simpleMessage("силове тренування (інтенсивне)"),
        "paResistanceTrainingVigorousDesc":
            MessageLookupByLibrary.simpleMessage("інтенсивне зусилля, пауерліфтинг або бодибілдинг"),
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
        "paSnowshoeing":
            MessageLookupByLibrary.simpleMessage("ходьба на снігоступах"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("футбол"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("невимушено, загальне"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("софтбол / бейсбол"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "швидка або повільна подача, загальне"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("сквош"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
        "paStretching": MessageLookupByLibrary.simpleMessage("розтяжка"),
        "paStretchingDesc":
            MessageLookupByLibrary.simpleMessage("помірне, загалом"),
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
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("біг на біговій доріжці"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("на біговій доріжці, загалом"),
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
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Вставте сюди код спільного прийому їжі"),
        "pasteCodeLabel":
            MessageLookupByLibrary.simpleMessage("Вставити код"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("На 100 г/мл"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("На порцію"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("фосфор"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("поліненасичені жири"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("калій"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Політика конфіденційності"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Профіль"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("білки"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("б"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Кількість"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Я прочитав і приймаю політику конфіденційності."),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Нещодавно"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Додати інгредієнт"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Попередні записи щоденника з цього рецепта залишаться."),
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Видалити рецепт?"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Опис (необов'язково)"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Кількість"),
        "recipeIngredientCountLabel": m15,
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Одиниця"),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Інгредієнти"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Загальна вага має бути більшою за нуль"),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Записати цей рецепт"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Назва рецепта"),
        "recipeNameRequiredLabel":
            MessageLookupByLibrary.simpleMessage("Рецепт потребує назви"),
        "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
            "Додайте хоча б один інгредієнт"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Поки немає інгредієнтів"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("На 100 г"),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Поживність (загалом)"),
        "recipeSaveErrorLabel":
            MessageLookupByLibrary.simpleMessage("Не вдалося зберегти рецепт."),
        "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
            "Увімкніть, щоб ця страва залишилася у вашому збереженому списку на наступний раз. Залиште вимкненим для одноразової страви, яку ви більше не їстимете."),
        "recipeSaveForLaterLabel":
            MessageLookupByLibrary.simpleMessage("Зберегти на потім"),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Зберегти рецепт"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Дозволяє реєструвати цей рецепт у порціях замість грамів."),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Порції (необов'язково)"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Через кому, напр. \"сніданок, веганське\""),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Теги"),
        "recipeImageLabel":
            MessageLookupByLibrary.simpleMessage("Додати фото"),
        "recipeImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Вибрати з галереї"),
        "recipeImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Зробити фото"),
        "recipeImageRemove":
            MessageLookupByLibrary.simpleMessage("Видалити фото"),
        "recipeImageReplace":
            MessageLookupByLibrary.simpleMessage("Замінити фото"),
        "mealImageLabel":
            MessageLookupByLibrary.simpleMessage("Додати фото"),
        "mealImagePickFromGallery":
            MessageLookupByLibrary.simpleMessage("Вибрати з галереї"),
        "mealImageTakePhoto":
            MessageLookupByLibrary.simpleMessage("Зробити фото"),
        "mealImageRemove":
            MessageLookupByLibrary.simpleMessage("Видалити фото"),
        "mealImageReplace":
            MessageLookupByLibrary.simpleMessage("Замінити фото"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "За замовчуванням сума інгредієнтів. Рідини приблизно як 1 мл ≈ 1 г."),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Загальна вага (г)"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Створіть страву з кількох інгредієнтів і використовуйте її як будь-який інший продукт."),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("Поки немає рецептів"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("Усі"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Рецепти"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Не вдалося завантажити рецепти. Спробуйте пізніше."),
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
        "selectionCountLabel": m17,
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
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Власні страви"),
        "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
            "Відмова від відповідальності"),
        "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль клітковини в грамах. Стандартне значення — 30 г."),
        "settingsFibreGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль клітковини"),
        "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
            "Особисті цілі для кожної поживної речовини в щоденній панелі. Щоденник використовує їх замість стандартних добових норм щоразу, коли ти задаєш будь-яку з них."),
        "settingsNutrientGoalsLabel":
            MessageLookupByLibrary.simpleMessage("Цілі поживних речовин"),
        "settingsSaturatedFatGoalDescription":
            MessageLookupByLibrary.simpleMessage(
                "Денний ліміт насичених жирів у грамах. Стандартне значення — 20 г."),
        "settingsSaturatedFatGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль насичених жирів"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Джерела та посилання"),
        "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денний ліміт цукрів у грамах. Стандартне значення — 50 г."),
        "settingsSugarsGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль цукрів"),
        "settingsSodiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль натрію"),
        "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денний ліміт натрію в міліграмах. Стандартне значення — 2300 мг."),
        "settingsCalciumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль кальцію"),
        "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль кальцію в міліграмах. Стандартне значення — 1000 мг."),
        "settingsIronGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль заліза"),
        "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль заліза в міліграмах. Стандартне значення залежить від статі (8 мг чоловік, 18 мг жінка, інакше 14 мг)."),
        "settingsPotassiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль калію"),
        "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль калію в міліграмах. Стандартне значення — 3500 мг."),
        "settingsMagnesiumGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль магнію"),
        "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль магнію в міліграмах. Стандартне значення залежить від статі (400 мг чоловік, 310 мг жінка, інакше 355 мг)."),
        "settingsVitaminDGoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль вітаміну D"),
        "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль вітаміну D в мікрограмах. Стандартне значення — 15 мкг."),
        "settingsVitaminB12GoalLabel":
            MessageLookupByLibrary.simpleMessage("Ціль вітаміну B12"),
        "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
            "Денна ціль вітаміну B12 в мікрограмах. Стандартне значення — 2,4 мкг."),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("Переглянути джерела"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker використовує для кожного розрахунку усталені, рецензовані методики. Наведені нижче посилання ведуть до оригінальних джерел, щоб ти могла самостійно перевірити будь-яке число."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Енергетичні потреби (TDEE, BMR та рівень активності)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Денні цілі за калоріями, основний обмін та коефіцієнти фізичної активності базуються на рівняннях Institute of Medicine. Джерело: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, розділ 5 і таблиця 5-5."),
        "sourcesBmiTitle":
            MessageLookupByLibrary.simpleMessage("Індекс маси тіла (ІМТ)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "ІМТ обчислюється як маса (кг), поділена на квадрат зросту (м²). Категорії здоров\'я (недостатня вага, нормальна вага, передожиріння, ожиріння I–III ступеня) відповідають класифікації ІМТ для дорослих Всесвітньої організації охорони здоров\'я."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Розподіл макроелементів"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "Стандартний розподіл 60% вуглеводів, 25% жирів і 15% білків входить у діапазони споживання поживних речовин, рекомендовані ВООЗ. Ти можеш змінити його в Налаштування → Розрахунки. Джерело: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Калорії від активності (значення MET)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Калорії, спалені під час активності, оцінюються як MET × маса тіла (кг) × тривалість (години) на основі значень з Adult Compendium of Physical Activities."),
        "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
            "Розрахунок калорій для небінарних осіб"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "Дослідження енергетичних витрат історично використовували лише бінарні категорії статі, тому для небінарних осіб не існує єдиної підтвердженої формули TDEE. Тому OpenNutriTracker у Налаштування → Розрахунки пропонує вибір між усередненим орієнтиром, орієнтиром, типовим для естрогену, та орієнтиром, типовим для тестостерону. Якщо точне значення є дійсно важливим для тебе, будь ласка, поговори з лікарем, який знає твій гормональний стан."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("Відкрити джерело"),
        "settingsDistanceLabel":
            MessageLookupByLibrary.simpleMessage("Відстань"),
        "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
            "Імперська (фунти, фут, унції)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Налаштування"),
        "settingsLanguageLabel":
            MessageLookupByLibrary.simpleMessage("Мова"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Ліцензії"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Маса"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Метрична (кг, см, мл)"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Щоденне нагадування"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("У дозволі на сповіщення відмовлено."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Не забудьте сьогодні записати свої страви!"),
        "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
            "Налаштування конфіденційності"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Повідомити про помилку"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Показати відстеження активності"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Показати макроси страви"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Показувати мікроелементи"),
        "settingsNutrientsLabel":
            MessageLookupByLibrary.simpleMessage("Поживні речовини"),
        "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
            "Обери, які поживні речовини показувати на панелі щоденника"),
        "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
            "Обери, які поживні речовини видимі на щоденній панелі. Приховані можна знову увімкнути будь-коли."),
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
        "shareActivityLabel":
            MessageLookupByLibrary.simpleMessage("Поділитися тренуванням"),
        "shareCodeLabel":
            MessageLookupByLibrary.simpleMessage("Поділитися кодом"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Поділитися рецептом"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "наприклад, яблуко, морозиво, шоколад ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Перекус"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("натрій"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("цукор"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("спожито"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("трансжири"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Одиниця"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("вітамін A"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("вітамін B12"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("вітамін B6"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("вітамін C"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("вітамін D"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Попередження"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Тижневий темп"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Не встановлено"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Вага"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("цинк"),
        "profileWeightHistoryTitle":
            MessageLookupByLibrary.simpleMessage("Історія ваги"),
        "weightHistoryAddEntry":
            MessageLookupByLibrary.simpleMessage("Додати запис"),
        "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
            "Поки немає записів ваги. Додай перший, щоб бачити динаміку."),
        "weightHistoryDateLabel":
            MessageLookupByLibrary.simpleMessage("Дата"),
        "weightHistoryWeightLabel":
            MessageLookupByLibrary.simpleMessage("Вага"),
        "weightHistoryNoteLabel":
            MessageLookupByLibrary.simpleMessage("Нотатка (необов\'язково)"),
        "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
            "Запиши вагу принаймні за два дні, щоб побачити динаміку."),
        "diarySortByCarbs":
            MessageLookupByLibrary.simpleMessage("Вуглеводи (за спаданням)"),
        "diarySortByFat":
            MessageLookupByLibrary.simpleMessage("Жири (за спаданням)"),
        "diarySortByKcal":
            MessageLookupByLibrary.simpleMessage("Калорії (за спаданням)"),
        "diarySortByLabel":
            MessageLookupByLibrary.simpleMessage("Сортувати за"),
        "diarySortByProtein":
            MessageLookupByLibrary.simpleMessage("Білки (за спаданням)"),
        "diarySortByTime":
            MessageLookupByLibrary.simpleMessage("Часом додавання"),
        "profileTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Цільова вага"),
        "profileTargetWeightNotSetLabel":
            MessageLookupByLibrary.simpleMessage("Не задано"),
        "profileTargetWeightClearAction":
            MessageLookupByLibrary.simpleMessage("Очистити"),
        "profileTargetWeightReached":
            MessageLookupByLibrary.simpleMessage("Ви досягли своєї цілі"),
        "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
            "Поступово зменшує щоденний дефіцит, щоб останні кілограми не здавалися стіною."),
        "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
            "Коригувати калорійну ціль у міру наближення до цілі"),
        "settingsTargetWeightLabel":
            MessageLookupByLibrary.simpleMessage("Цільова вага"),
        "profileTargetWeightToGo": m22,
        "customActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Введіть спалені калорії безпосередньо — для тренувань, яких немає у списку, або показників із фітнес-трекера"),
        "customActivityDescriptionKj":
            MessageLookupByLibrary.simpleMessage("Введіть спалені кілоджоулі безпосередньо — для тренувань, яких немає у списку, або показників із фітнес-трекера"),
        "customActivityKcalHint":
            MessageLookupByLibrary.simpleMessage("напр. 250"),
        "customActivityKcalLabel":
            MessageLookupByLibrary.simpleMessage("Спалені калорії"),
        "customActivityName":
            MessageLookupByLibrary.simpleMessage("Власна активність"),
        "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
            "напр. Вечірня поїздка на велосипеді"),
        "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
            "Назва (необов\'язково)"),
        "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
            "Вибрати зі збережених шаблонів"),
        "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
            "Зберегти як шаблон на майбутнє"),
        "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
            "Ви ще не зберегли жодного шаблону. Поставте позначку «Зберегти як шаблон на майбутнє», щоб запам\'ятати власну активність для пізнішого використання."),
        "mealPatternFiveSmall":
            MessageLookupByLibrary.simpleMessage("5 малих"),
        "mealPatternMediterranean":
            MessageLookupByLibrary.simpleMessage("Середземноморський"),
        "mealPatternOmad":
            MessageLookupByLibrary.simpleMessage("1 прийом"),
        "mealPatternPresetsLabel":
            MessageLookupByLibrary.simpleMessage("Швидкі шаблони"),
        "mealPatternStandard":
            MessageLookupByLibrary.simpleMessage("Стандарт"),
        "mealPatternTwoMeal":
            MessageLookupByLibrary.simpleMessage("2 прийоми"),
        "settingsPerMealKcalShareBreakfast":
            MessageLookupByLibrary.simpleMessage("Сніданок"),
        "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
            "Розподіліть денну ціль у ккал між сніданком, обідом, вечерею та перекусами. Частки мають у сумі давати 100 %."),
        "settingsPerMealKcalShareDinner":
            MessageLookupByLibrary.simpleMessage("Вечеря"),
        "settingsPerMealKcalShareLabel":
            MessageLookupByLibrary.simpleMessage("Частка ккал на прийом їжі"),
        "settingsPerMealKcalShareLunch":
            MessageLookupByLibrary.simpleMessage("Обід"),
        "settingsPerMealKcalShareSnack":
            MessageLookupByLibrary.simpleMessage("Перекус"),
        "diaryMealKcalConsumedOfTarget": m23,
      };
}
