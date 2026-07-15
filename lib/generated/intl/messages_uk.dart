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

  static String m0(sourceName) => "Більше інформації на\n${sourceName}";

  static String m1(versionNumber) => "Версія ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% вуглеводи, ${pctFats}% жири, ${pctProteins}% білки";

  static String m3(count, size) => "${count} елементів · ${size}";

  static String m4(imported, skipped) =>
      "Імпортовано ${imported} страв; ${skipped} рядків пропущено через неправильні дані.";

  static String m5(count) => "Імпортовано ${count} страв.";

  static String m6(unit) => "${unit} в одній порції";

  static String m7(loser, winner) =>
      "Це замінить усі записи, додані з ${loser}, щоб вони показували ${winner}, і видалить ${loser} з ваших власних страв. Цю дію не можна скасувати.";

  static String m8(winner) => "Об\'єднано — ${winner} тепер має 1 запис.";

  static String m9(count, winner) =>
      "Об\'єднано — ${winner} тепер має ${count} записів.";

  static String m10(count) => "Видалити ${count} рецепт(ів)?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "орієнт. ${value}";

  static String m13(remaining) => "Голодування · залишилось ${remaining}";

  static String m14(value) => "Залишилося ${value}";

  static String m15(value) => "Ціль: ${value}";

  static String m16(count) => "Імпортувати ${count} активностей?";

  static String m17(mealType) =>
      "These items will be added to your ${mealType}.";

  static String m18(count) => "Import ${count} items?";

  static String m19(count) =>
      "${count} елемент(ів) не вдалося отримати з OpenFoodFacts.";

  static String m20(count) =>
      "Імпортувати цей рецепт з ${count} інгредієнт(ами)?";

  static String m21(amount) => "Додати ${amount} мл";

  static String m22(threshold) =>
      "Дорослим без медичного нагляду не варто тривало споживати менше ніж ${threshold} ккал на день. Будь ласка, перш ніж залишати такий низький рівень, проконсультуйтеся з лікарем.";

  static String m23(kcal) => "(+${kcal} kcal поточний вибір)";

  static String m24(consumed, goal) => "Денний підсумок: ${consumed} / ${goal}";

  static String m25(qty, unit) => "На ${qty} ${unit}";

  static String m26(count) =>
      "${Intl.plural(count, one: 'батончик', few: 'батончики', many: 'батончиків', other: 'батончика')}";

  static String m27(count) =>
      "${Intl.plural(count, one: 'пляшка', few: 'пляшки', many: 'пляшок', other: 'пляшки')}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'банка', few: 'банки', many: 'банок', other: 'банки')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'чашка', few: 'чашки', many: 'чашок', other: 'чашки')}";

  static String m30(count) =>
      "${Intl.plural(count, one: 'яйце', few: 'яйця', many: 'яєць', other: 'яйця')}";

  static String m31(count) =>
      "${Intl.plural(count, one: 'упаковка', few: 'упаковки', many: 'упаковок', other: 'упаковки')}";

  static String m32(count) =>
      "${Intl.plural(count, one: 'шматок', few: 'шматки', many: 'шматків', other: 'шматка')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'порція', few: 'порції', many: 'порцій', other: 'порції')}";

  static String m34(count) =>
      "${Intl.plural(count, one: 'порція', few: 'порції', many: 'порцій', other: 'порції')}";

  static String m35(count) =>
      "${Intl.plural(count, one: 'скибка', few: 'скибки', many: 'скибок', other: 'скибки')}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'столова ложка', few: 'столові ложки', many: 'столових ложок', other: 'столової ложки')}";

  static String m37(count) =>
      "${Intl.plural(count, one: 'чайна ложка', few: 'чайні ложки', many: 'чайних ложок', other: 'чайної ложки')}";

  static String m38(riskValue) => "Ризик супутніх захворювань: ${riskValue}";

  static String m39(value) => "Залишилось ${value} до цілі";

  static String m40(mealType) => "Додано до ${mealType}";

  static String m41(count) => "${count} інгредієнт(ів)";

  static String m42(count) => "Вибрано: ${count}";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Час нагадування: ${time}";

  static String m46(current, goal) => "${current} / ${goal} мл";

  static String m47(rate) => "${rate} кг/тиждень";

  static String m48(rate) => "${rate} фунт/тиждень";

  static String m49(age) => "${age} років";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "наприклад, біг, їзда на велосипеді, йога ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Активність"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage(
      "Додати новий елемент:",
    ),
    "addLabel": MessageLookupByLibrary.simpleMessage("Додати"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Додати профіль"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Інформація надана\n \"2024 Compendium\n of Physical Activities\"",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Власний елемент їжі",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Більше інформації на\nFoodData Central",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Більше інформації на\nOpenFoodFacts",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Власний рецепт",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Невідомий елемент їжі",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Вік"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Всі"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Альфа]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker — це безкоштовний трекер калорій та поживних речовин з відкритим кодом, який поважає вашу конфіденційність і не містить реклами",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("Ліцензія GPL-3.0"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Цей 13-значний штрих-код, схоже, введено з помилкою: остання цифра не збігається з рештою",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage("Поживність на"),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Бета]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Індекс маси тіла (ІМТ) — це індекс для класифікації надмірної ваги та ожиріння у дорослих. Визначається як вага в кілограмах, поділена на квадрат зросту в метрах (кг/м²). ІМТ не розрізняє жирову і м\'язову масу і може бути неточним для деяких людей.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("ІМТ"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "наприклад, пластівці, молоко, кава ...",
    ),
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
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(рекомендовано)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Розрахунок Інституту Медицини (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "Розрахунок TDEE",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Усереднена референція (за замовчуванням)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Естрогенова референція",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Опублікованої калорійної основи для небінарних людей не існує — рівняння-зразки побудовані на чоловічих і жіночих вибірках. За замовчуванням ми використовуємо середнє двох — нейтральну відправну точку, яка не вимагає від вас розкривати більше про ваше тіло. Повзунок ккал у Налаштуваннях завжди доступний для тонкого налаштування; це відправна точка, а не точна оцінка.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Калорійна референція",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Тестостеронова референція"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("вуглеводи"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("вуглеводи"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("в"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("холестерин"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Тижневий темп ваги",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Виберіть ціль ваги",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Видаляє локально збережені результати пошуку та сканування з Open Food Facts та FDC. Кеш автоматично відновлюється під час пошуку та сканування. Ваші власні страви не зачіпаються.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Очистити кеш?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage("Очистити кеш"),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("см"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Код скопійовано"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Прийом їжі скопійовано в профіль",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Копіювати"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Копіювати код"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "До якого типу страви скопіювати?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "За допомогою \"Скопіювати на сьогодні\" ви можете скопіювати страву на сьогодні. За допомогою \"Видалити\" ви можете видалити страву.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Що ви хочете зробити?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Копіювати в профіль",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Бажаєте створити власну їжу?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Створити власну їжу?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage(
      "Створити рецепт",
    ),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Маєте штрих-код? Додайте продукт до Open Food Facts:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Не вдалося прочитати CSV файл. Перевірте формат і спробуйте знову.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Введіть спалені калорії безпосередньо — для тренувань, яких немає у списку, або показників із фітнес-трекера",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Введіть спалені кілоджоулі безпосередньо — для тренувань, яких немає у списку, або показників із фітнес-трекера",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("напр. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Спалені калорії",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage(
      "Власна активність",
    ),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "напр. Вечірня поїздка на велосипеді",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Назва (необов\'язково)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Вибрати зі збережених шаблонів",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Зберегти як шаблон на майбутнє",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Ви ще не зберегли жодного шаблону. Поставте позначку «Зберегти як шаблон на майбутнє», щоб запам\'ятати власну активність для пізнішого використання.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Скануй або введи штрих-код, щоб згодом знайти цю страву",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Штрих-код має містити від 8 до 14 цифр",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage("Штрих-код"),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Сканувати штрих-код",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage(
      "Розширений",
    ),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Вкажіть розміри і значення на 100 г/мл для точного перерахунку.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Вигляд форми",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Простий"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Введіть значення для однієї порції.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Усі записи в щоденнику, що використовують цю страву, також буде видалено.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Видалити власну страву?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Ще немає збережених власних страв.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Об’єднати з іншою власною стравою",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Яка залишається?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Об’єднати",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Об’єднати власні страви?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Продовжити",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Виберіть власну страву для об’єднання",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Більше дій",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Щоденна корекція калорій:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Щоденна корекція кДж:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Надсилати анонімні звіти про збої, щоб допомогти виправляти помилки. Жодні дані про їжу, вагу чи особисті дані не передаються.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Профіль 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Видалити все"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Це назавжди видалить профіль та всі його дані. Цю дію не можна скасувати.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Видалити профіль?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Ви хочете видалити вибраний елемент?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Ви хочете видалити всі елементи цієї страви?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Видалити елементи?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Видалити елемент?",
    ),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("Скасувати"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Закрити"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage(
      "Скопіювати на сьогодні",
    ),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("ВИДАЛИТИ"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("ОК"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Ви редагуєте майбутню дату",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Щоденник"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Тут підсумовуються лише ті поживні речовини, які записані для зареєстрованих страв. Страва без значення не додає нічого до відповідного показника — тож суми можуть бути занижені.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Поживні речовини за сьогодні",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Вуглеводи (за спаданням)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage(
      "Жири (за спаданням)",
    ),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Калорії (за спаданням)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Сортувати за"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Білки (за спаданням)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Часом додавання"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "наприклад, суп, курка, вино ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Вечеря"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Скасувати",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Ваші незбережені зміни будуть втрачені.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Скасувати зміни?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker не є медичним додатком. Всі надані дані не перевіряються і повинні використовуватися з обережністю. Будь ласка, ведіть здоровий спосіб життя і консультуйтеся з фахівцем, якщо у вас виникли проблеми. Використання під час хвороби, вагітності або лактації не рекомендується. Рецензовані джерела для кожного розрахунку відкриваються через піктограму інформації на екрані Головна або Профіль.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Зразкові страви (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Зразкові страви (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Зразкові рецепти (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Зразкові рецепти (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Ці орієнтовні значення взято з рекомендованих норм споживання IOM для дорослих і вони залежать від віку та статі. Це точка відліку, а не мета — твої власні потреби можуть бути іншими.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Джерело: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Орієнтовне споживання",
    ),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Цю їжу вже додано до цього прийому їжі сьогодні. Додати ще раз?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Дублювати"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(копія)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Редагувати елемент",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Редагувати страву"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage(
      "Редагувати профіль",
    ),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage(
      "Редагувати рецепт",
    ),
    "energyLabel": MessageLookupByLibrary.simpleMessage("енергія"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("залишилось"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("понад норму"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Кілокалорії (ккал)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage(
      "Кілоджоулі (кДж)",
    ),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Помилка при отриманні даних про продукт",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Помилка при завантаженні активностей",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Помилка при збереженні страви. Ви ввели коректну інформацію?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Помилка при відкритті браузера",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "Помилка при відкритті поштової програми",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Продукт не знайдено",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Експортувати"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Експортувати / Імпортувати дані застосунку",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV зберігає активність, журнал прийомів їжі та відстежувані дні. Рецепти й додані фото зберігаються лише в JSON — перейдіть на JSON, якщо хочете залишити їх у резервній копії.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Ви можете експортувати дані додатка у zip-файл і імпортувати їх пізніше. Це корисно, якщо ви хочете зробити резервну копію або перенести дані на інший пристрій. Додаток не використовує жодних хмарних сервісів для зберігання ваших даних.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Помилка експорту / імпорту",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Експорт / Імпорт успішний",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Завершити піст"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Поточну сесію буде закрито.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Завершити піст зараз?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage("Сесію завершено"),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Минуло"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Одноразові сповіщення, коли голодування досягає своєї мети.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Таймер голодування",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Цільовий час досягнуто.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Сесія голодування завершена",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Власний"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage("Запустити таймер"),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Простий таймер для часу між прийомами їжі. Без серій, без цілей, лише годинник.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Таймер посту"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Розумію, увімкнути таймер",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Відстеження часу посту комусь допомагає, а декому може шкодити, особливо людям із досвідом розладів харчової поведінки. Якщо це про вас, будь ласка, спершу подбайте про себе. Підтримку надають BEAT (UK) і NEDA (US).",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "Це не для мене",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Перш ніж почати",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("жири"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("ж"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("клітковина"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("рідка унція"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Завжди ввімкнено",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Результати пошуку надходять із цих баз даних продуктів. Open Food Facts забезпечує пошук продуктів і штрих-кодів і завжди ввімкнена.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("фут"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("жінка"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Стать"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("чоловік"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage("небінарний"),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Набрати вагу"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Ціль"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Схуднути"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage(
      "Підтримувати вагу",
    ),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("г/мл"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("г"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Зріст"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "Натисніть +, щоб додати першу їжу чи активність",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Головна"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("години"),
    "importAction": MessageLookupByLibrary.simpleMessage("Імпортувати"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Ці активності буде додано на сьогодні.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Імпортувати спільне тренування",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Тренування імпортовано",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Імпортуйте власні страви з CSV-файлу або вставивши JSON. Завантажте зразок, щоб побачити очікувану форму та обовʼязкові поля.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Імпортувати власні дані про їжу",
    ),
    "importMealConfirmContent": m17,
    "importMealConfirmTitle": m18,
    "importMealErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Invalid QR code",
    ),
    "importMealLabel": MessageLookupByLibrary.simpleMessage(
      "Import shared meal",
    ),
    "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Meal imported",
    ),
    "importMealsCsvAction": MessageLookupByLibrary.simpleMessage(
      "Імпортувати страви (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Імпортувати страви (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Не вдалося розпізнати код рецепта",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Імпортувати рецепт",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Рецепт імпортовано",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Імпортувати рецепти (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Імпортувати рецепти (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("дюйм"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Ці значення не зовсім сходяться — введені калорії не відповідають енергії з вуглеводів, жирів і білків. Зберегти все одно чи переглянути ще раз?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Переглянути ще раз",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Зберегти все одно"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Числа не зовсім сходяться",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Додано нову активність",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Додано новий прийом їжі",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("залізо"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Елемент видалено",
    ),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Елемент оновлено",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("ккал"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("залишилось ккал"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage(
      "ккал понад норму",
    ),
    "kgLabel": MessageLookupByLibrary.simpleMessage("кг"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("кДж"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("фунт"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Записати спожиту воду",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Немає що скасовувати",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Скасувати останнє",
    ),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Ця денна ціль доволі низька",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Переглянути застереження",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "наприклад, піца, салат, рис ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Обід"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Назву перекладено автоматично",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Розподіл макроелементів:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("магній"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Керувати профілями",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Бренди"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Вуглеводи"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Енергія"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Жири"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Додати фото"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Вибрати з галереї",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Видалити фото"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage("Замінити фото"),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage("Зробити фото"),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("ккал на"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Назва страви"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Назва страви повинна містити принаймні одну літеру",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Загальна кількість",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("5 малих"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage(
      "Середземноморський",
    ),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("1 прийом"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Швидкі шаблони",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Стандарт"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("2 прийоми"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Білки"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Розмір упаковки"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Розмір упаковки (унція/рідка унція)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Одиниця страви"),
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
      "Мікроелементи",
    ),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("мл"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "У продукту відсутня необхідна інформація про ккал або макроелементи",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("мл"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "мононенасичені жири",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Новий власний продукт",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("ніацин (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Нещодавно не додано активності",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Нещодавно не додано страв",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage(
      "Нічого не знайдено",
    ),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("Н/Д"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Нічого не додано",
    ),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Не забудьте сьогодні записати свої страви!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Щоденне нагадування записати прийоми їжі",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Щоденні нагадування"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "У дозволі на сповіщення відмовлено.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Усі поживні речовини приховано — увімкни деякі в Налаштування → Поживні речовини.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("День"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("ліміт"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Тиждень"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Інформація про харчування",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Нормальна вага",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Ожиріння I класу",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Ожиріння II класу",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Ожиріння III класу",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Передожиріння",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Середній",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Підвищений",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Низький (але ризик інших клінічних проблем підвищений)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Помірний",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Серйозний",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Дуже серйозний",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Недостатня вага",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Дані, які надає цей додаток, отримані з бази даних Open Food Facts. Не гарантується точність, повнота або надійність наданої інформації. Дані надаються “як є”, і джерело даних (Open Food Facts) не несе відповідальності за будь-які збитки, що виникають внаслідок використання даних.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Наскільки ви активні? (без тренувань)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Введіть дату",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Коли у вас день народження?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "День народження",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Як ви записуєте їжу та напої",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ваша стать?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Яка ваша поточна ціль ваги?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "наприклад, 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "наприклад, 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Який ваш поточний зріст?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Для початку додаток потребує деяку інформацію про вас, щоб розрахувати вашу щоденну ціль калорій.\nВся інформація про вас зберігається безпечно на вашому пристрої.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Переглянути джерела наших медичних обчислень",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "ккал на день",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "кДж на день",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Опублікованої калорійної основи для небінарних людей не існує, тож за замовчуванням ми використовуємо середнє чоловічої та жіночої формул — це відправна точка, а не точна оцінка. Ти можеш скоригувати це у Налаштування → Розрахунки в будь-який час.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Інші параметри",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Налаштуйте застосунок — усе можна змінити пізніше в налаштуваннях",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage("Огляд"),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Неправильне введення, спробуйте ще раз",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "Необов\'язково",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Чи є вага, до якої ти прагнеш? Це поле можна залишити порожнім або змінити пізніше у Профілі.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "наприклад, 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "наприклад, 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Яка ваша поточна вага?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage(
      "Ласкаво просимо до",
    ),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Введіть коректний зріст",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Введіть коректну вагу",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ваша ціль калорій:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ваші цілі макроелементів:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("унція"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "активні відеоігри",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, загалом",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage(
      "американський футбол",
    ),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "безконтактний, з прапорцями, загальний",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("стрільба з лука"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "не на полюванні",
    ),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("автогонки"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage(
      "з відкритими колесами",
    ),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage(
      "піший туризм з рюкзаком",
    ),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("бадмінтон"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "соціальний одиночний та парний розряд, загальний",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("баскетбол"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage(
      "їзда на велосипеді",
    ),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "гірський велосипед",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "стаціонарний велосипед",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("більярд"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("боулінг"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("бокс"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage(
      "на боксерській груші",
    ),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("бокс"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "на ринзі, загальне",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("брумбол"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage(
      "калістеніка",
    ),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "легкі або помірні зусилля, загальне (наприклад, вправи для спини)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage(
      "веслування на каное",
    ),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "веслування, для задоволення, загальне",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("футбол або бейсбол"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("гра в ловлю"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("чирлідинг"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "гімнастичні рухи, змагальний",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("дитячі ігри"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(наприклад, класики, 4-квадрат, вишибали, ігровий майданчик, т-бол, tetherball, марбли, аркадні ігри), помірні зусилля",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "підйом на пагорби, без навантаження",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "без навантаження",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("крикет"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "відбивання, подача, гра в полі",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("крокет"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "біг на лижах",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "біг на лижах, загалом",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("керлінг"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("аеробні"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("загальні танці"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "наприклад, диско, народні, ірландські, лінійні, полька, контра, кантрі",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("дартс"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage(
      "настінний або газонний",
    ),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("дайвінг"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "підводне плавання, дайвінг з аквалангом, загальне",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "стрибки у воду",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "з трампліна або платформи",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("фехтування"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("гра у фрісбі"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("гольф"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("гімнастика"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paHackySack": MessageLookupByLibrary.simpleMessage("гакі-сак"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("гандбол"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("дельтапланеризм"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage(
      "їзда на велосипеді",
    ),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "аеробне тренування",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("танці"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("біг"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("спорт"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("ходьба"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "водні види спорту",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "зимові види спорту",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "високоінтенсивне інтервальне тренування",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "помірне зусилля",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "високоінтенсивне інтервальне тренування",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "берпі, скелелаз, вистрибування з присіду, Табата, інтенсивне зусилля",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("похід"),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "пересіченою місцевістю",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("хокей на траві"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage(
      "верхова їзда",
    ),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage(
      "хокей на льоду",
    ),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage(
      "катання на ковзанах",
    ),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("хай-алай"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("пробіжка"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("жонглювання"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage(
      "веслування на байдарці",
    ),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "помірні зусилля",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("кікбол"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("лакрос"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage(
      "гра в боулінг на газоні",
    ),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "бочче, на відкритому повітрі",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "бойові мистецтва",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "різні види, помірний темп (наприклад, дзюдо, джиу-джитсу, карате, кікбоксинг, тхеквондо, тай-бо, муай-тай)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage(
      "бойові мистецтва",
    ),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "різні види, повільний темп, для початківців, тренування",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("мотокрос"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "позашляхові мотоспорт, всюдихід, загальне",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("скелелазіння"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "скелелазіння або альпінізм",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage(
      "скандинавська ходьба",
    ),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("орієнтування"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("паддлбординг"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage(
      "паддлбординг стоячи",
    ),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("катамаран"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("падлбол"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage(
      "невимушено, загальне",
    ),
    "paPickleball": MessageLookupByLibrary.simpleMessage("пікльбол"),
    "paPilates": MessageLookupByLibrary.simpleMessage("пілатес"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("поло"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("на коні"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("ракетбол"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "силові тренування",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "підняття ваги, вільна вага, Nautilus або Universal",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "силове тренування (інтенсивне)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "інтенсивне зусилля, пауерліфтинг або бодибілдинг",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "спорт родео",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "загальний, помірні зусилля",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage(
      "катання на роликах",
    ),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "катання на роликах",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage(
      "стрибки зі скакалкою",
    ),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "помірний темп, 100-120 стрибків/хв, загальне, стрибки на двох ногах, звичайний відскок",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage(
      "стрибки зі скакалкою",
    ),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("регбі"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "союз, команда, змагальний",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("регбі"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "безконтактний, незмагальний",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("біг"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage(
      "вітрильний спорт",
    ),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "вітрильний спорт на човні та дошці, віндсерфінг, вітрильний спорт на льоду, загальне",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("шаффлборд"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage(
      "скейтбординг",
    ),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальний, помірні зусилля",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage(
      "катання на роликах",
    ),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("лижний спорт"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "водні лижі",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "водні лижі або вейкбординг",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("скайдайвінг"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "скайдайвінг, бейс-джампінг, банджі-джампінг",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("сноркелінг"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage(
      "розчищення снігу",
    ),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "Розчишення снігу, помірні зусилля",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage(
      "ходьба на снігоступах",
    ),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("футбол"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "невимушено, загальне",
    ),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "софтбол / бейсбол",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "швидка або повільна подача, загальне",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("сквош"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paStretching": MessageLookupByLibrary.simpleMessage("розтяжка"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage(
      "помірне, загалом",
    ),
    "paSurfing": MessageLookupByLibrary.simpleMessage("серфінг"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "бодісерфінг або серфінг на дошці, загальне",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("плавання"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "плавання, помірні зусилля, загальне",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage(
      "настільний теніс",
    ),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "настільний теніс, пінг-понг",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "тай-чі, цигун",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "загальне",
    ),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("теніс"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("легка атлетика"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(наприклад, штовхання ядра, метання диска, метання молота)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(наприклад, стрибки у висоту, стрибки в довжину, потрійний стрибок, метання списа, стрибки з жердиною)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(наприклад, стипль-чез, біг з бар\'єрами)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("батут"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage(
      "розважальний",
    ),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "біг на біговій доріжці",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "на біговій доріжці, загалом",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("уніцикл"),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("волейбол"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "незмагальний, команда з 6 - 9 гравців, загальне",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("прогулянка"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "прогулянка для задоволення",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("вигул собаки"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("вигул собак"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("воллібол"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("водні вправи"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "водна аеробіка, водна калістеніка",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("водне поло"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage(
      "водний волейбол",
    ),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "водна аеробіка",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "водна аеробіка, водна калістеніка",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("боротьба"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("загальне"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Переважно стояча або ходьба на роботі і активний відпочинок",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Активний"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "наприклад, сидяча або стояча робота і легкі активності у вільний час",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Малоактивний"),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "наприклад, офісна робота і переважно сидячий відпочинок",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage(
      "Сидячий спосіб життя",
    ),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Переважно ходьба, біг або носіння ваги на роботі і активний відпочинок",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Дуже активний"),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Вставте сюди код спільного прийому їжі",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Вставити код"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("На 100 г/мл"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("На порцію"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("фосфор"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "поліненасичені жири",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("калій"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Політика конфіденційності",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Активний"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage("Таймер посту"),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage("Додати фото"),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage("Видалити фото"),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage("Змінити фото"),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Профіль"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Назва профілю"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Ім\'я"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Очистити",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Цільова вага",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Не задано",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Ви досягли своєї цілі",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Історія ваги",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("білки"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("б"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Кількість"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Активність додано",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Тривалість (хв, необов\'язково)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Спалена енергія (ккал)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Спалена енергія (кДж)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Назва (необов\'язково)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Швидке додавання активності",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Швидке додавання",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Вуглеводи (г, необов\'язково)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage(
      "Швидке додавання",
    ),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage(
      "Швидке додавання",
    ),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Енергія (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Енергія (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Жири (г, необов\'язково)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Білки (г, необов\'язково)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Додати"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Назва"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Я прочитав і приймаю політику конфіденційності.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("Нещодавно"),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Додати інгредієнт",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Попередні записи щоденника з цього рецепта залишаться.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Видалити рецепт?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Опис (необов\'язково)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage("Додати фото"),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Вибрати з галереї",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage("Видалити фото"),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage("Замінити фото"),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Зробити фото",
    ),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Кількість",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Одиниця",
    ),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Інгредієнти",
    ),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Загальна вага має бути більшою за нуль",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Записати цей рецепт",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Назва рецепта"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Рецепт потребує назви",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Додайте хоча б один інгредієнт",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Поки немає інгредієнтів",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "На 100 г",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Поживність (загалом)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Не вдалося зберегти рецепт.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Увімкніть, щоб ця страва залишилася у вашому збереженому списку на наступний раз. Залиште вимкненим для одноразової страви, яку ви більше не їстимете.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Зберегти на потім",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Зберегти рецепт"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Дозволяє реєструвати цей рецепт у порціях замість грамів.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Порції (необов\'язково)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Через кому, напр. \"сніданок, веганське\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Теги"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "За замовчуванням сума інгредієнтів. Рідини приблизно як 1 мл ≈ 1 г.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Загальна вага (г)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Створіть страву з кількох інгредієнтів і використовуйте її як будь-який інший продукт.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Поки немає рецептів",
    ),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Усі"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Рецепти"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Не вдалося завантажити рецепти. Спробуйте пізніше.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Бажаєте повідомити про помилку розробнику?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Повторити"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("насичені жири"),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage(
      "Сканувати продукт",
    ),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Зафіксувати вертикально",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Ввести код вручну",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage(
      "Скасувати",
    ),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Введіть штрихкод",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "Від 8 до 14 цифр",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Цей штрихкод виглядає недійсним. Будь ласка, перевірте цифри та спробуйте знову.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage("Знайти"),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Дозволити обертання",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Введіть слово для пошуку",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Їжа"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Пошук"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Продукти"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Результати пошуку",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Виберіть стать",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Виберіть зріст",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Виберіть рівень активності",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Виберіть вагу",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Надсилати анонімні дані про використання",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Порція"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Одна порція (унція/рідка унція)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Одна порція",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("Про додаток"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("Відгук"),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Акцентний колір",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Власний колір…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Відкрити повзунок відтінку для точного вибору",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Цей hex код виглядає неправильно — шість символів, 0-9 і A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex код"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Вимкніть системні кольори, щоб обрати власний акцент.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Скинути"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Акцентний колір",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Виберіть колір",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Власний",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Стандартний",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Одиниця ваги тіла",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль кальцію в міліграмах. Стандартне значення — 1000 мг.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль кальцію",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Поступово зменшує щоденний дефіцит, щоб останні кілограми не здавалися стіною.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Коригувати калорійну ціль у міру наближення до цілі",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage(
      "Про застосунок",
    ),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Вигляд",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Дані"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage(
      "Відображення",
    ),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Цілі та харчування",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Одиниці та енергія",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Власні страви",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Обери годину, з якої починається твій день. Прийоми їжі та активності, записані до цієї години, зараховуються до попереднього дня — зручно, якщо ти працюєш у нічну зміну або пізно вечеряєш.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Години",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "День починається о",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Хвилини",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Видалити все",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Це остаточно видалить з цього пристрою ваш профіль, прийоми їжі, активності, історію ваги та всі власні рецепти. Бази Open Food Facts та USDA Food Data Central залишаться без змін. Цю дію не можна скасувати.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Видалити всі ваші дані?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Видалити всі мої дані",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Профіль, прийоми їжі, активності та історію ваги",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Відмова від відповідальності",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Відстань"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Одиниця енергії",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль клітковини в грамах. Стандартне значення — 30 г.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль клітковини",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Бази даних продуктів",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Виберіть, звідки надходять результати пошуку",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Імперська (фунти, унції, рідкі унції)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Одиниці їжі",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Метрична (г, кг, мл, л)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "Імперська (фут, дюйми)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Одиниці зросту",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Метрична (мм, см, м)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "Імперська (фунти, фут, унції)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль заліза в міліграмах. Стандартне значення залежить від статі (8 мг чоловік, 18 мг жінка, інакше 14 мг).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль заліза",
    ),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Щоденне коригування ккал",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Налаштування"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Мова"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Ліцензії"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Розподіл макросів",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль магнію в міліграмах. Стандартне значення залежить від статі (400 мг чоловік, 310 мг жінка, інакше 355 мг).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль магнію",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Маса"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Підхоплює акцентний колір ваших шпалер на Android 12 і новіших версіях.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Використовувати системні кольори",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Метрична (кг, см, мл)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Щоденне нагадування",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Особисті цілі для кожної поживної речовини в щоденній панелі. Щоденник використовує їх замість стандартних добових норм щоразу, коли ти задаєш будь-яку з них.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Цілі поживних речовин",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Обери, які поживні речовини видимі на щоденній панелі. Приховані можна знову увімкнути будь-коли.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Поживні речовини",
    ),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Обери, які поживні речовини показувати на панелі щоденника",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Сніданок",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Розподіліть денну ціль у ккал між сніданком, обідом, вечерею та перекусами. Частки мають у сумі давати 100 %.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Вечеря",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Частка ккал на прийом їжі",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Обід",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Перекус",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль калію в міліграмах. Стандартне значення — 3500 мг.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль калію",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Налаштування конфіденційності",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Повідомити про помилку",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денний ліміт насичених жирів у грамах. Стандартне значення — 20 г.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль насичених жирів",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Показати відстеження активності",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Показати макроси страви",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Показувати мікроелементи",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денний ліміт натрію в міліграмах. Стандартне значення — 2300 мг.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль натрію",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Вихідний код",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Джерела та посилання",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денний ліміт цукрів у грамах. Стандартне значення — 50 г.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль цукрів",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Система"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Темна"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Тема"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Світла"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Системна за замовчуванням",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Одиниці вимірювання",
    ),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль вітаміну B12 в мікрограмах. Стандартне значення — 2,4 мкг.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль вітаміну B12",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Денна ціль вітаміну D в мікрограмах. Стандартне значення — 15 мкг.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Ціль вітаміну D",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Об\'єм"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Використовується індикатором води на головному екрані.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Денна ціль вживання води",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Поділитися тренуванням",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Поділитися кодом"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Поділитися рецептом",
    ),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "наприклад, яблуко, морозиво, шоколад ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Перекус"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("натрій"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Калорії, спалені під час активності, оцінюються як MET × маса тіла (кг) × тривалість (години) на основі значень з Adult Compendium of Physical Activities.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Калорії від активності (значення MET)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "ІМТ обчислюється як маса (кг), поділена на квадрат зросту (м²). Категорії здоров\'я (недостатня вага, нормальна вага, передожиріння, ожиріння I–III ступеня) відповідають класифікації ІМТ для дорослих Всесвітньої організації охорони здоров\'я.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Індекс маси тіла (ІМТ)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Денні цілі за калоріями, основний обмін та коефіцієнти фізичної активності базуються на рівняннях Institute of Medicine. Джерело: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, розділ 5 і таблиця 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Енергетичні потреби (TDEE, BMR та рівень активності)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage(
      "Переглянути джерела",
    ),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "Стандартний розподіл 60% вуглеводів, 25% жирів і 15% білків входить у діапазони споживання поживних речовин, рекомендовані ВООЗ. Ти можеш змінити його в Налаштування → Розрахунки. Джерело: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Розподіл макроелементів",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Дослідження енергетичних витрат історично використовували лише бінарні категорії статі, тому для небінарних осіб не існує єдиної підтвердженої формули TDEE. Тому OpenNutriTracker у Налаштування → Розрахунки пропонує вибір між усередненим орієнтиром, орієнтиром, типовим для естрогену, та орієнтиром, типовим для тестостерону. Якщо точне значення є дійсно важливим для тебе, будь ласка, поговори з лікарем, який знає твій гормональний стан.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Розрахунок калорій для небінарних осіб",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Щоденні референсні значення, показані в панелі поживних речовин щоденника, взяті зі зведеного звіту Dietary Reference Intakes Institute of Medicine, який охоплює цільові показники для кожної поживної речовини у дорослих.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Референсні норми споживання поживних речовин",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Відкрити джерело",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker використовує для кожного розрахунку усталені, рецензовані методики. Наведені нижче посилання ведуть до оригінальних джерел, щоб ти могла самостійно перевірити будь-яке число.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("стоун"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("цукор"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("спожито"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Змінити профіль",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("трансжири"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("рекорд"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Калорії"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Середнє за день",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage(
      "днів поспіль",
    ),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "днів у нормі цього тижня",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Тренди"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/тиждень"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Вода"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "тижнів до мети",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Одиниця"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("вітамін A"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("вітамін B12"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("вітамін B6"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("вітамін C"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("вітамін D"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Попередження"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Тижневий темп",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Не встановлено",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage(
      "Додати запис",
    ),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Запиши вагу принаймні за два дні, щоб побачити динаміку.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Дата"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Поки немає записів ваги. Додай перший, щоб бачити динаміку.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Нотатка (необов\'язково)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage("Вага"),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Вага"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Ви"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("цинк"),
  };
}
