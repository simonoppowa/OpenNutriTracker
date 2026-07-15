// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a tr locale. All the
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
  String get localeName => 'tr';

  static String m0(sourceName) => "Daha fazla bilgi:\n${sourceName}";

  static String m1(versionNumber) => "Versiyon ${versionNumber}";

  static String m2(pctCarbs, pctFats, pctProteins) =>
      "%${pctCarbs} karbonhidrat, %${pctFats} yağ, %${pctProteins} protein";

  static String m3(count, size) => "${count} öğe · ${size}";

  static String m4(imported, skipped) =>
      "${imported} öğün içe aktarıldı; geçersiz veri nedeniyle ${skipped} satır atlandı.";

  static String m5(count) => "${count} öğün içe aktarıldı.";

  static String m6(unit) => "${unit} porsiyon başına";

  static String m7(loser, winner) =>
      "Bu işlem, ${loser} ile kaydedilen tüm girdileri değiştirip ${winner} olarak gösterir ve ${loser} özel yiyeceklerinden kaldırılır. Bu işlem geri alınamaz.";

  static String m8(winner) => "Birleştirildi — ${winner} artık 1 kayda sahip.";

  static String m9(count, winner) =>
      "Birleştirildi — ${winner} artık ${count} kayda sahip.";

  static String m10(count) => "${count} tarif silinsin mi?";

  static String m11(consumed, target) => "${consumed} / ${target} kcal";

  static String m12(value) => "ref. ${value}";

  static String m13(remaining) => "Oruç · ${remaining} kaldı";

  static String m14(value) => "${value} kaldı";

  static String m15(value) => "Hedef: ${value}";

  static String m16(count) => "${count} aktivite içe aktarılsın mı?";

  static String m17(mealType) =>
      "These items will be added to your ${mealType}.";

  static String m18(count) => "Import ${count} items?";

  static String m19(count) => "${count} öğe OpenFoodFacts\'ten alınamadı.";

  static String m20(count) =>
      "${count} malzeme içeren bu tarif içe aktarılsın mı?";

  static String m21(amount) => "${amount} ml ekle";

  static String m22(threshold) =>
      "Yetişkinler tıbbi gözetim olmadan uzun süreyle günde ${threshold} kcal\'nin altında beslenmemelidir. Bu kadar düşük bir hedefte kalmadan önce lütfen bir sağlık uzmanına danışmayı düşün.";

  static String m23(kcal) => "(+${kcal} kcal mevcut seçim)";

  static String m24(consumed, goal) => "Günlük toplam: ${consumed} / ${goal}";

  static String m25(qty, unit) => "${qty} ${unit} başına";

  static String m26(count) => "${Intl.plural(count, other: 'bar')}";

  static String m27(count) => "${Intl.plural(count, other: 'şişe')}";

  static String m28(count) => "${Intl.plural(count, other: 'kutu')}";

  static String m29(count) => "${Intl.plural(count, other: 'fincan')}";

  static String m30(count) => "${Intl.plural(count, other: 'yumurta')}";

  static String m31(count) => "${Intl.plural(count, other: 'paket')}";

  static String m32(count) => "${Intl.plural(count, other: 'parça')}";

  static String m33(count) => "${Intl.plural(count, other: 'porsiyon')}";

  static String m34(count) => "${Intl.plural(count, other: 'porsiyon')}";

  static String m35(count) => "${Intl.plural(count, other: 'dilim')}";

  static String m36(count) => "${Intl.plural(count, other: 'yemek kaşığı')}";

  static String m37(count) => "${Intl.plural(count, other: 'çay kaşığı')}";

  static String m38(riskValue) => "Eşlik eden hastalık riski: ${riskValue}";

  static String m39(value) => "Hedefine ${value} kaldı";

  static String m40(mealType) => "${mealType} öğününe eklendi";

  static String m41(count) => "${count} malzeme";

  static String m42(count) => "${count} seçildi";

  static String m43(hour) => "${hour}:00";

  static String m44(hour, minute) => "${hour}:${minute}";

  static String m45(time) => "Hatırlatma zamanı: ${time}";

  static String m46(current, goal) => "${current} / ${goal} ml";

  static String m47(rate) => "${rate} kg/hafta";

  static String m48(rate) => "${rate} lbs/hafta";

  static String m49(age) => "${age} yıl";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "activityExample": MessageLookupByLibrary.simpleMessage(
      "ör. koşu, bisiklet, yoga ...",
    ),
    "activityLabel": MessageLookupByLibrary.simpleMessage("Aktivite"),
    "addItemLabel": MessageLookupByLibrary.simpleMessage("Yeni Öğe Ekle:"),
    "addLabel": MessageLookupByLibrary.simpleMessage("Ekle"),
    "addProfileLabel": MessageLookupByLibrary.simpleMessage("Profil ekle"),
    "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
      "Bilgi\n\'2024 Compendium\n of Physical Activities\'\nden sağlanmıştır",
    ),
    "additionalInfoLabelCustom": MessageLookupByLibrary.simpleMessage(
      "Özel Yemek Öğesi",
    ),
    "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
      "Daha Fazla Bilgi\nFoodData Central\'da",
    ),
    "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
      "Daha Fazla Bilgi\nOpenFoodFacts\'te",
    ),
    "additionalInfoLabelRecipe": MessageLookupByLibrary.simpleMessage(
      "Özel Tarif",
    ),
    "additionalInfoLabelSource": m0,
    "additionalInfoLabelUnknown": MessageLookupByLibrary.simpleMessage(
      "Bilinmeyen Yemek Öğesi",
    ),
    "ageLabel": MessageLookupByLibrary.simpleMessage("Yaş"),
    "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tümü"),
    "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker, gizliliğinize saygı duyan ücretsiz ve açık kaynaklı bir kalori ve besin takipçisidir.",
    ),
    "appLicenseLabel": MessageLookupByLibrary.simpleMessage("GPL-3.0 lisansı"),
    "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
    "appVersionName": m1,
    "barcodeInvalidEan13CheckDigit": MessageLookupByLibrary.simpleMessage(
      "Bu 13 haneli barkod yanlış girilmiş gibi: son hane diğerleriyle uyuşmuyor",
    ),
    "baseQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Besin değeri başına",
    ),
    "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
    "bmiInfo": MessageLookupByLibrary.simpleMessage(
      "Vücut Kitle İndeksi (BMI), yetişkinlerde aşırı kiloyu ve obeziteyi sınıflandırmak için kullanılan bir indekstir. Kilogram cinsinden ağırlığın, metre cinsinden boyun karesine bölünmesiyle tanımlanır (kg/m²).\n\nBMI, yağ ve kas kütlesi arasında ayrım yapmaz ve bazı bireyler için yanıltıcı olabilir.",
    ),
    "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
    "breakfastExample": MessageLookupByLibrary.simpleMessage(
      "ör. mısır gevreği, süt, kahve ...",
    ),
    "breakfastLabel": MessageLookupByLibrary.simpleMessage("Kahvaltı"),
    "burnedLabel": MessageLookupByLibrary.simpleMessage("yakılan"),
    "buttonNextLabel": MessageLookupByLibrary.simpleMessage("İLERİ"),
    "buttonResetLabel": MessageLookupByLibrary.simpleMessage("Sıfırla"),
    "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("Kaydet"),
    "buttonStartLabel": MessageLookupByLibrary.simpleMessage("BAŞLA"),
    "buttonYesLabel": MessageLookupByLibrary.simpleMessage("EVET"),
    "calciumLabel": MessageLookupByLibrary.simpleMessage("kalsiyum"),
    "calculationsMacronutrientsDistributionLabel":
        MessageLookupByLibrary.simpleMessage("Makro besin dağılımı"),
    "calculationsMacrosDistribution": m2,
    "calculationsRecommendedLabel": MessageLookupByLibrary.simpleMessage(
      "(önerilen)",
    ),
    "calculationsTDEEIOM2006Label": MessageLookupByLibrary.simpleMessage(
      "Tıp Enstitüsü Denklemi (2005)",
    ),
    "calculationsTDEELabel": MessageLookupByLibrary.simpleMessage(
      "TDEE denklemi",
    ),
    "caloriesProfileAveragedLabel": MessageLookupByLibrary.simpleMessage(
      "Ortalanmış referans (varsayılan)",
    ),
    "caloriesProfileEstrogenTypicalLabel": MessageLookupByLibrary.simpleMessage(
      "Östrojen tipi referans",
    ),
    "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
      "Non-binary bireyler için yayımlanmış bir kalori temeli bulunmuyor — referans denklemler erkek ve kadın örneklerine dayanır. Varsayılan olarak ikisinin ortalamasını kullanıyoruz; vücudunuz hakkında daha fazlasını açıklamanızı istemeyen tarafsız bir başlangıç noktası. Ayarlar\'daki kcal kaydırıcısı ince ayar için her zaman kullanılabilir; bu kesin bir tahmin değil, bir başlangıç noktasıdır.",
    ),
    "caloriesProfileInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Kalori referansı",
    ),
    "caloriesProfileTestosteroneTypicalLabel":
        MessageLookupByLibrary.simpleMessage("Testosteron tipi referans"),
    "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("karbonhidrat"),
    "carbsLabel": MessageLookupByLibrary.simpleMessage("karbonhidrat"),
    "carbsLabelShort": MessageLookupByLibrary.simpleMessage("k"),
    "cholesterolLabel": MessageLookupByLibrary.simpleMessage("kolesterol"),
    "chooseWeeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Haftalık kilo oranı",
    ),
    "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilo Hedefini Seçin",
    ),
    "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Open Food Facts ve FDC\'den yerel olarak önbelleğe alınmış arama ve tarama sonuçlarını kaldırır. Önbellek, ürünleri aradıkça ve tarattıkça otomatik olarak yeniden oluşur. Özel öğünleriniz etkilenmez.",
    ),
    "clearOffCacheConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Önbelleği temizle?",
    ),
    "clearOffCacheLabel": MessageLookupByLibrary.simpleMessage(
      "Önbelleği temizle",
    ),
    "clearOffCacheSubtitle": m3,
    "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
    "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("Kod kopyalandı"),
    "copiedToProfileSnackbar": MessageLookupByLibrary.simpleMessage(
      "Öğün profile kopyalandı",
    ),
    "copyActionLabel": MessageLookupByLibrary.simpleMessage("Kopyala"),
    "copyCodeLabel": MessageLookupByLibrary.simpleMessage("Kodu kopyala"),
    "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Hangi yemek türüne kopyalamak istiyorsunuz?",
    ),
    "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "\"Bugüne Kopyala\" ile yemeği bugüne kopyalayabilirsiniz. \"Sil\" ile yemeği silebilirsiniz.",
    ),
    "copyOrDeleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Ne yapmak istiyorsunuz?",
    ),
    "copyToProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Profile kopyala",
    ),
    "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
      "Özel bir yemek öğesi oluşturmak istiyor musunuz?",
    ),
    "createCustomDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Özel yemek öğesi oluştur?",
    ),
    "createRecipeTitle": MessageLookupByLibrary.simpleMessage("Tarif Oluştur"),
    "csvImportContributeOffAndroidLink": MessageLookupByLibrary.simpleMessage(
      "Android",
    ),
    "csvImportContributeOffIosLink": MessageLookupByLibrary.simpleMessage(
      "iOS",
    ),
    "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
      "Barkod var mı? Ürünü Open Food Facts\'e katkıda bulunun:",
    ),
    "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "CSV dosyası okunamadı. Biçimi kontrol edin ve tekrar deneyin.",
    ),
    "csvImportPartialLabel": m4,
    "csvImportSuccessLabel": m5,
    "customActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Listede olmayan antrenmanlar veya bir fitness takip cihazından okumalar için yakılan kaloriyi doğrudan girin",
    ),
    "customActivityDescriptionKj": MessageLookupByLibrary.simpleMessage(
      "Listede olmayan antrenmanlar veya bir fitness takip cihazından okumalar için yakılan kilojulleri doğrudan girin",
    ),
    "customActivityKcalHint": MessageLookupByLibrary.simpleMessage("örn. 250"),
    "customActivityKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Yakılan kalori",
    ),
    "customActivityName": MessageLookupByLibrary.simpleMessage("Özel etkinlik"),
    "customActivityNameFieldHint": MessageLookupByLibrary.simpleMessage(
      "örn. Akşam bisiklet yolculuğu",
    ),
    "customActivityNameFieldLabel": MessageLookupByLibrary.simpleMessage(
      "Ad (isteğe bağlı)",
    ),
    "customActivityPickFromTemplate": MessageLookupByLibrary.simpleMessage(
      "Kaydedilmiş şablonlardan seç",
    ),
    "customActivitySaveAsTemplate": MessageLookupByLibrary.simpleMessage(
      "Bir sonraki sefer için şablon olarak kaydet",
    ),
    "customActivityTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "Henüz kaydedilmiş bir şablonun yok. Bir özel etkinliği sonradan hatırlamak için „Bir sonraki sefer için şablon olarak kaydet“ kutusunu işaretle.",
    ),
    "customMealBarcodeHint": MessageLookupByLibrary.simpleMessage(
      "Bu yemeği daha sonra hatırlamak için barkodu tarat veya yaz",
    ),
    "customMealBarcodeInvalid": MessageLookupByLibrary.simpleMessage(
      "Barkod 8 ile 14 hane arasında olmalı",
    ),
    "customMealBarcodeLabel": MessageLookupByLibrary.simpleMessage("Barkod"),
    "customMealBarcodeScanButton": MessageLookupByLibrary.simpleMessage(
      "Barkod tara",
    ),
    "customMealFormAdvanced": MessageLookupByLibrary.simpleMessage("Gelişmiş"),
    "customMealFormAdvancedHelp": MessageLookupByLibrary.simpleMessage(
      "Hassas ölçek için boyutları ve 100 g/ml değerlerini belirleyin.",
    ),
    "customMealFormModeLabel": MessageLookupByLibrary.simpleMessage(
      "Form görünümü",
    ),
    "customMealFormSimple": MessageLookupByLibrary.simpleMessage("Basit"),
    "customMealFormSimpleFieldHelper": m6,
    "customMealFormSimpleHelp": MessageLookupByLibrary.simpleMessage(
      "Bir porsiyon için toplam değerleri yazın.",
    ),
    "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Bu yemeği kullanan tüm günlük girişleri de kaldırılacak.",
    ),
    "customMealsDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Özel yemek silinsin mi?",
    ),
    "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Henüz özel yemek kaydedilmedi.",
    ),
    "customMealsMergeAction": MessageLookupByLibrary.simpleMessage(
      "Başka bir özel yiyecekle birleştir",
    ),
    "customMealsMergeChooseSurvivorTitle": MessageLookupByLibrary.simpleMessage(
      "Hangisi kalsın?",
    ),
    "customMealsMergeConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Birleştir",
    ),
    "customMealsMergeConfirmContent": m7,
    "customMealsMergeConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Özel yiyecekler birleştirilsin mi?",
    ),
    "customMealsMergeContinueAction": MessageLookupByLibrary.simpleMessage(
      "Devam et",
    ),
    "customMealsMergePickerTitle": MessageLookupByLibrary.simpleMessage(
      "Birleştirilecek özel yiyeceği seç",
    ),
    "customMealsMergeSuccessSnackbarOne": m8,
    "customMealsMergeSuccessSnackbarOther": m9,
    "customMealsRowMoreTooltip": MessageLookupByLibrary.simpleMessage(
      "Diğer eylemler",
    ),
    "dailyKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Günlük Kcal ayarı:",
    ),
    "dailyKjAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Günlük kJ ayarı:",
    ),
    "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
      "Hataların düzeltilmesine yardımcı olmak için anonim çökme raporları gönderin. Yemek günlüğü, kilo veya kişisel veriler dahil edilmez.",
    ),
    "defaultProfileName": MessageLookupByLibrary.simpleMessage("Profil 1"),
    "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Tümünü sil"),
    "deleteProfileConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Bu işlem profili ve tüm verilerini kalıcı olarak siler. Bu geri alınamaz.",
    ),
    "deleteProfileConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Profil silinsin mi?",
    ),
    "deleteSelectedRecipesConfirmTitle": m10,
    "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
      "Seçilen öğeyi silmek istiyor musunuz?",
    ),
    "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
      "Bu öğüne ait tüm girdileri silmek istiyor musunuz?",
    ),
    "deleteTimeDialogPluralTitle": MessageLookupByLibrary.simpleMessage(
      "Girdiler silinsin mi?",
    ),
    "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage("Öğeyi Sil?"),
    "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("İPTAL"),
    "dialogCloseLabel": MessageLookupByLibrary.simpleMessage("Kapat"),
    "dialogCopyLabel": MessageLookupByLibrary.simpleMessage("BUGÜNE KOPYALA"),
    "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SİL"),
    "dialogOKLabel": MessageLookupByLibrary.simpleMessage("TAMAM"),
    "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
      "Gelecekteki bir tarihi düzenliyorsunuz",
    ),
    "diaryLabel": MessageLookupByLibrary.simpleMessage("Günlük"),
    "diaryMealKcalConsumedOfTarget": m11,
    "diaryNutrientPanelDataDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Yalnızca kaydettiğin öğünlerde takip edilen besinler burada toplanır. Bir değeri eksik olan öğün o besine katkıda bulunmaz — bu nedenle toplamlar olduğundan az görünebilir.",
    ),
    "diaryNutrientPanelTitle": MessageLookupByLibrary.simpleMessage(
      "Bugünün besinleri",
    ),
    "diarySortByCarbs": MessageLookupByLibrary.simpleMessage(
      "Karbonhidrat (çoktan aza)",
    ),
    "diarySortByFat": MessageLookupByLibrary.simpleMessage("Yağ (çoktan aza)"),
    "diarySortByKcal": MessageLookupByLibrary.simpleMessage(
      "Kalori (çoktan aza)",
    ),
    "diarySortByLabel": MessageLookupByLibrary.simpleMessage("Sırala"),
    "diarySortByProtein": MessageLookupByLibrary.simpleMessage(
      "Protein (çoktan aza)",
    ),
    "diarySortByTime": MessageLookupByLibrary.simpleMessage("Eklenme zamanı"),
    "dinnerExample": MessageLookupByLibrary.simpleMessage(
      "ör. çorba, tavuk, şarap ...",
    ),
    "dinnerLabel": MessageLookupByLibrary.simpleMessage("Akşam Yemeği"),
    "discardChangesConfirmLabel": MessageLookupByLibrary.simpleMessage(
      "Vazgeç",
    ),
    "discardChangesContent": MessageLookupByLibrary.simpleMessage(
      "Kaydedilmemiş değişiklikleriniz kaybolacak.",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Değişiklikler iptal edilsin mi?",
    ),
    "disclaimerText": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker bir tıbbi uygulama değildir. Sağlanan tüm veriler doğrulanmamıştır ve dikkatle kullanılmalıdır. Lütfen sağlıklı bir yaşam tarzı sürdürün ve herhangi bir sorununuz varsa bir profesyonele danışın. Hastalık, hamilelik veya emzirme döneminde kullanımı önerilmez.\n\n\nUygulama hala geliştirme aşamasındadır. Hatalar, aksaklıklar ve çökmeler meydana gelebilir.\n\nHer hesaplamanın hakemli kaynaklarına Ana Sayfa veya Profil ekranındaki bilgi simgesine dokunarak ulaşabilirsin.",
    ),
    "downloadSampleCsvAction": MessageLookupByLibrary.simpleMessage(
      "Örnek yemekler (csv)",
    ),
    "downloadSampleJsonAction": MessageLookupByLibrary.simpleMessage(
      "Örnek yemekler (json)",
    ),
    "downloadSampleRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Örnek tarifler (csv)",
    ),
    "downloadSampleRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Örnek tarifler (json)",
    ),
    "driPanelInfoBody": MessageLookupByLibrary.simpleMessage(
      "Bu referans değerler, yetişkinler için IOM Diyet Referans Alımları\'ndan gelir ve yaşa ile cinsiyete göre değişir. Bir hedef değil, bir referans noktasıdır — kendi ihtiyaçların farklı olabilir.",
    ),
    "driPanelInfoLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Kaynak: IOM Dietary Reference Intakes",
    ),
    "driPanelInfoTitle": MessageLookupByLibrary.simpleMessage("Referans alım"),
    "driPanelReferenceLabel": m12,
    "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
      "Bu yiyecek bugün bu öğüne zaten eklenmiş. Tekrar eklensin mi?",
    ),
    "duplicateRecipeLabel": MessageLookupByLibrary.simpleMessage("Çoğalt"),
    "duplicateRecipeNameSuffix": MessageLookupByLibrary.simpleMessage(
      "(kopya)",
    ),
    "editItemDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Öğeyi Düzenle",
    ),
    "editMealLabel": MessageLookupByLibrary.simpleMessage("Yemeği Düzenle"),
    "editProfileTitle": MessageLookupByLibrary.simpleMessage("Profili düzenle"),
    "editRecipeTitle": MessageLookupByLibrary.simpleMessage("Tarifi Düzenle"),
    "energyLabel": MessageLookupByLibrary.simpleMessage("enerji"),
    "energyLeftLabel": MessageLookupByLibrary.simpleMessage("kalan"),
    "energyTooMuchLabel": MessageLookupByLibrary.simpleMessage("fazla"),
    "energyUnitKcalLabel": MessageLookupByLibrary.simpleMessage(
      "Kilokalori (kcal)",
    ),
    "energyUnitKjLabel": MessageLookupByLibrary.simpleMessage("Kilojul (kJ)"),
    "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
      "Ürün verileri alınırken hata oluştu",
    ),
    "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
      "Aktiviteler yüklenirken hata oluştu",
    ),
    "errorMealSave": MessageLookupByLibrary.simpleMessage(
      "Yemek kaydedilirken hata oluştu. Doğru yemek bilgilerini girdiniz mi?",
    ),
    "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
      "Tarayıcı uygulaması açılırken hata oluştu",
    ),
    "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
      "E-posta uygulaması açılırken hata oluştu",
    ),
    "errorProductNotFound": MessageLookupByLibrary.simpleMessage(
      "Ürün bulunamadı",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Dışa Aktar"),
    "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
      "Uygulama Verilerini Dışa / İçe Aktar",
    ),
    "exportImportCsvRecipesNote": MessageLookupByLibrary.simpleMessage(
      "CSV; etkinliklerinizi, öğün günlüğünüzü ve takip edilen günleri saklar. Tarifler ve eklediğiniz fotoğraflar yalnızca JSON\'da yer alır — yedeklemenizde olmalarını isterseniz JSON\'a geçin.",
    ),
    "exportImportDescription": MessageLookupByLibrary.simpleMessage(
      "Uygulama verilerini bir zip dosyasına dışa aktarabilir ve daha sonra içe aktarabilirsiniz. Bu, verilerinizi yedeklemek veya başka bir cihaza aktarmak istiyorsanız kullanışlıdır.\n\nUygulama, verilerinizi saklamak için herhangi bir bulut hizmeti kullanmaz.",
    ),
    "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Dışa Aktarma / İçe Aktarma hatası",
    ),
    "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Dışa Aktarma / İçe Aktarma başarılı",
    ),
    "fastingCancel": MessageLookupByLibrary.simpleMessage("Orucu sonlandır"),
    "fastingCancelConfirmBody": MessageLookupByLibrary.simpleMessage(
      "Bu, mevcut oturumu kapatacak.",
    ),
    "fastingCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Orucu şimdi sonlandırılsın mı?",
    ),
    "fastingComplete": MessageLookupByLibrary.simpleMessage(
      "Oturum tamamlandı",
    ),
    "fastingElapsedLabel": MessageLookupByLibrary.simpleMessage("Geçen"),
    "fastingHomeChipBody": m13,
    "fastingLinkBeat": MessageLookupByLibrary.simpleMessage("BEAT (UK)"),
    "fastingLinkNeda": MessageLookupByLibrary.simpleMessage("NEDA (US)"),
    "fastingNotificationChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Bir oruç hedefe ulaştığında tek seferlik bildirimler.",
        ),
    "fastingNotificationChannelName": MessageLookupByLibrary.simpleMessage(
      "Oruç zamanlayıcısı",
    ),
    "fastingNotificationCompleteBody": MessageLookupByLibrary.simpleMessage(
      "Hedef sürene ulaştın.",
    ),
    "fastingNotificationCompleteTitle": MessageLookupByLibrary.simpleMessage(
      "Oruç süresi tamamlandı",
    ),
    "fastingPresetCustom": MessageLookupByLibrary.simpleMessage("Özel"),
    "fastingRemainingValue": m14,
    "fastingStart": MessageLookupByLibrary.simpleMessage(
      "Zamanlayıcıyı başlat",
    ),
    "fastingSubtitle": MessageLookupByLibrary.simpleMessage(
      "Öğünler arası süreyi izlemek için basit bir zamanlayıcı. Seri yok, hedef yok, sadece saat.",
    ),
    "fastingTargetValue": m15,
    "fastingTitle": MessageLookupByLibrary.simpleMessage("Oruç zamanlayıcısı"),
    "fastingWarningAccept": MessageLookupByLibrary.simpleMessage(
      "Anladım, zamanlayıcıyı aç",
    ),
    "fastingWarningBody": MessageLookupByLibrary.simpleMessage(
      "Oruç sürelerini takip etmek bazı insanlara iyi gelirken, özellikle yeme bozukluğu geçmişi olanlar için zorlayıcı olabilir. Bu sen olabilirsen lütfen önce kendine iyi bak. Destek için BEAT (UK) ve NEDA (US) yardımcı olabilir.",
    ),
    "fastingWarningDecline": MessageLookupByLibrary.simpleMessage(
      "Bana göre değil",
    ),
    "fastingWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Başlamadan önce",
    ),
    "fatLabel": MessageLookupByLibrary.simpleMessage("yağ"),
    "fatLabelShort": MessageLookupByLibrary.simpleMessage("y"),
    "fiberLabel": MessageLookupByLibrary.simpleMessage("lif"),
    "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
    "foodSourcesAlwaysEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Her zaman etkin",
    ),
    "foodSourcesHelpText": MessageLookupByLibrary.simpleMessage(
      "Arama sonuçları bu gıda veritabanlarından gelir. Open Food Facts, ürün ve barkod aramasını sağlar ve her zaman etkindir.",
    ),
    "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
    "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("kadın"),
    "genderLabel": MessageLookupByLibrary.simpleMessage("Cinsiyet"),
    "genderMaleLabel": MessageLookupByLibrary.simpleMessage("erkek"),
    "genderNonBinaryLabel": MessageLookupByLibrary.simpleMessage(
      "ikili olmayan",
    ),
    "goalGainWeight": MessageLookupByLibrary.simpleMessage("Kilo Al"),
    "goalLabel": MessageLookupByLibrary.simpleMessage("Hedef"),
    "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Kilo Ver"),
    "goalMaintainWeight": MessageLookupByLibrary.simpleMessage("Kilo Koru"),
    "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
    "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
    "heightLabel": MessageLookupByLibrary.simpleMessage("Boy"),
    "homeFirstMealHint": MessageLookupByLibrary.simpleMessage(
      "İlk öğününü veya aktiviteni eklemek için + simgesine dokun",
    ),
    "homeLabel": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
    "hoursLabel": MessageLookupByLibrary.simpleMessage("saat"),
    "importAction": MessageLookupByLibrary.simpleMessage("İçe Aktar"),
    "importActivityConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Bu aktiviteler bugüne eklenecek.",
    ),
    "importActivityConfirmTitle": m16,
    "importActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Paylaşılan antrenmanı içe aktar",
    ),
    "importActivitySuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Antrenman içe aktarıldı",
    ),
    "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
      "Kendi yemeklerinizi bir CSV dosyasından veya JSON yapıştırarak içe aktarın. Beklenen şekli ve zorunlu alanları görmek için bir örnek indirin.",
    ),
    "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
      "Özel Gıda Verilerini İçe Aktar",
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
      "Yemekleri içe aktar (csv)",
    ),
    "importMealsJsonAction": MessageLookupByLibrary.simpleMessage(
      "Yemekleri içe aktar (json)",
    ),
    "importOffFetchFailedLabel": m19,
    "importRecipeConfirmContent": m20,
    "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Tarif kodu çözümlenemedi",
    ),
    "importRecipeLabel": MessageLookupByLibrary.simpleMessage(
      "Tarifi içe aktar",
    ),
    "importRecipeSuccessLabel": MessageLookupByLibrary.simpleMessage(
      "Tarif içe aktarıldı",
    ),
    "importRecipesCsvAction": MessageLookupByLibrary.simpleMessage(
      "Tarifleri içe aktar (csv)",
    ),
    "importRecipesJsonAction": MessageLookupByLibrary.simpleMessage(
      "Tarifleri içe aktar (json)",
    ),
    "inLabel": MessageLookupByLibrary.simpleMessage("in"),
    "inconsistentNutritionWarningBody": MessageLookupByLibrary.simpleMessage(
      "Bu değerler tam olarak uyuşmuyor — girdiğiniz kalori, karbonhidrat, yağ ve proteinin enerjisiyle örtüşmüyor. Yine de kaydedilsin mi, yoksa tekrar göz atmak ister misiniz?",
    ),
    "inconsistentNutritionWarningEdit": MessageLookupByLibrary.simpleMessage(
      "Tekrar bakayım",
    ),
    "inconsistentNutritionWarningSaveAnyway":
        MessageLookupByLibrary.simpleMessage("Yine de kaydet"),
    "inconsistentNutritionWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Sayılar pek uyuşmuyor",
    ),
    "infoAddedActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Yeni aktivite eklendi",
    ),
    "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage(
      "Yeni alım eklendi",
    ),
    "ironLabel": MessageLookupByLibrary.simpleMessage("demir"),
    "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage("Öğe silindi"),
    "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage(
      "Öğe güncellendi",
    ),
    "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kalan kcal"),
    "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("fazla kcal"),
    "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
    "kjLabel": MessageLookupByLibrary.simpleMessage("kJ"),
    "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
    "logWaterAmountLabel": m21,
    "logWaterDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Su alımını kaydet",
    ),
    "logWaterNothingToUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Geri alınacak bir şey yok",
    ),
    "logWaterUndoLabel": MessageLookupByLibrary.simpleMessage(
      "Sonuncuyu geri al",
    ),
    "lowKcalWarningBody": m22,
    "lowKcalWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Bu günlük hedef oldukça düşük",
    ),
    "lowKcalWarningViewDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Sorumluluk reddini görüntüle",
    ),
    "lunchExample": MessageLookupByLibrary.simpleMessage(
      "ör. pizza, salata, pirinç ...",
    ),
    "lunchLabel": MessageLookupByLibrary.simpleMessage("Öğle Yemeği"),
    "machineTranslatedNameHint": MessageLookupByLibrary.simpleMessage(
      "Ad otomatik olarak çevrildi",
    ),
    "macroDistributionLabel": MessageLookupByLibrary.simpleMessage(
      "Makro besin Dağılımı:",
    ),
    "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnezyum"),
    "manageProfilesLabel": MessageLookupByLibrary.simpleMessage(
      "Profilleri yönet",
    ),
    "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Markalar"),
    "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("Karbonhidrat"),
    "mealDetailCurrentSelectionLabel": m23,
    "mealDetailDayTotalLabel": m24,
    "mealEnergyLabel": MessageLookupByLibrary.simpleMessage("Enerji"),
    "mealFatLabel": MessageLookupByLibrary.simpleMessage("Yağ"),
    "mealImageLabel": MessageLookupByLibrary.simpleMessage("Fotoğraf ekle"),
    "mealImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Galeriden seç",
    ),
    "mealImageRemove": MessageLookupByLibrary.simpleMessage("Fotoğrafı kaldır"),
    "mealImageReplace": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafı değiştir",
    ),
    "mealImageTakePhoto": MessageLookupByLibrary.simpleMessage("Fotoğraf çek"),
    "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
    "mealNameLabel": MessageLookupByLibrary.simpleMessage("Yemek adı"),
    "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
      "Yemek adı en az bir harf içermelidir",
    ),
    "mealNutrientsPerQtyLabel": m25,
    "mealNutrientsTotalLabel": MessageLookupByLibrary.simpleMessage(
      "Toplam miktar",
    ),
    "mealPatternFiveSmall": MessageLookupByLibrary.simpleMessage("Beş küçük"),
    "mealPatternMediterranean": MessageLookupByLibrary.simpleMessage("Akdeniz"),
    "mealPatternOmad": MessageLookupByLibrary.simpleMessage("Tek öğün"),
    "mealPatternPresetsLabel": MessageLookupByLibrary.simpleMessage(
      "Hızlı şablonlar",
    ),
    "mealPatternStandard": MessageLookupByLibrary.simpleMessage("Standart"),
    "mealPatternTwoMeal": MessageLookupByLibrary.simpleMessage("İki öğün"),
    "mealProteinLabel": MessageLookupByLibrary.simpleMessage("Protein"),
    "mealSizeLabel": MessageLookupByLibrary.simpleMessage("Paket boyutu"),
    "mealSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Paket boyutu (oz/fl oz)",
    ),
    "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Yemek birimi"),
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
      "Mikro besinler",
    ),
    "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
    "missingProductInfo": MessageLookupByLibrary.simpleMessage(
      "Üründe gerekli kcal veya makro besin bilgileri eksik",
    ),
    "mlLabel": MessageLookupByLibrary.simpleMessage("ml"),
    "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "tekli doymamış yağ",
    ),
    "newCustomMealLabel": MessageLookupByLibrary.simpleMessage(
      "Yeni Özel Yiyecek",
    ),
    "niacinLabel": MessageLookupByLibrary.simpleMessage("niasin (B3)"),
    "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Son zamanlarda eklenen aktivite yok",
    ),
    "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Son zamanlarda eklenen yemek yok",
    ),
    "noResultsFound": MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
    "notAvailableLabel": MessageLookupByLibrary.simpleMessage("Mevcut Değil"),
    "nothingAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Hiçbir şey eklenmedi",
    ),
    "notificationsDailyReminderBody": MessageLookupByLibrary.simpleMessage(
      "Bugün öğünlerinizi kaydetmeyi unutmayın!",
    ),
    "notificationsDailyReminderChannelDescription":
        MessageLookupByLibrary.simpleMessage(
          "Öğünlerinizi kaydetmeniz için günlük hatırlatma",
        ),
    "notificationsDailyReminderChannelName":
        MessageLookupByLibrary.simpleMessage("Günlük hatırlatıcılar"),
    "notificationsDailyReminderTitle": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker",
    ),
    "notificationsPermissionDeniedSnack": MessageLookupByLibrary.simpleMessage(
      "Bildirim izni reddedildi.",
    ),
    "nutrientPanelAllHiddenLabel": MessageLookupByLibrary.simpleMessage(
      "Tüm besinler gizli — bazılarını Ayarlar → Besinler bölümünden aç.",
    ),
    "nutrientPanelDayLabel": MessageLookupByLibrary.simpleMessage("Gün"),
    "nutrientPanelLimitLabel": MessageLookupByLibrary.simpleMessage("sınır"),
    "nutrientPanelWeekLabel": MessageLookupByLibrary.simpleMessage("Hafta"),
    "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage(
      "Beslenme Bilgileri",
    ),
    "nutritionalStatusNormalWeight": MessageLookupByLibrary.simpleMessage(
      "Normal Kilo",
    ),
    "nutritionalStatusObeseClassI": MessageLookupByLibrary.simpleMessage(
      "Obezite Sınıf I",
    ),
    "nutritionalStatusObeseClassII": MessageLookupByLibrary.simpleMessage(
      "Obezite Sınıf II",
    ),
    "nutritionalStatusObeseClassIII": MessageLookupByLibrary.simpleMessage(
      "Obezite Sınıf III",
    ),
    "nutritionalStatusPreObesity": MessageLookupByLibrary.simpleMessage(
      "Obezite Öncesi",
    ),
    "nutritionalStatusRiskAverage": MessageLookupByLibrary.simpleMessage(
      "Ortalama",
    ),
    "nutritionalStatusRiskIncreased": MessageLookupByLibrary.simpleMessage(
      "Artmış",
    ),
    "nutritionalStatusRiskLabel": m38,
    "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
      "Düşük \n(ancak diğer \nklinik sorunların riski artmış)",
    ),
    "nutritionalStatusRiskModerate": MessageLookupByLibrary.simpleMessage(
      "Orta",
    ),
    "nutritionalStatusRiskSevere": MessageLookupByLibrary.simpleMessage(
      "Şiddetli",
    ),
    "nutritionalStatusRiskVerySevere": MessageLookupByLibrary.simpleMessage(
      "Çok şiddetli",
    ),
    "nutritionalStatusUnderweight": MessageLookupByLibrary.simpleMessage(
      "Düşük Kilolu",
    ),
    "offDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Bu uygulama tarafından size sağlanan veriler Open Food Facts veritabanından alınmaktadır. Sağlanan bilgilerin doğruluğu, eksiksizliği veya güvenilirliği konusunda hiçbir garanti verilmemektedir. Veriler \"olduğu gibi\" sağlanır ve verilerin kullanımıyla ilgili herhangi bir zarardan verilerin kaynağı (Open Food Facts) sorumlu tutulamaz.",
    ),
    "onboardingActivityQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ne kadar aktifsiz? (antrenmanlar hariç)",
    ),
    "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage(
      "Tarih Girin",
    ),
    "onboardingBirthdayQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Doğum gününüz ne zaman?",
    ),
    "onboardingEnterBirthdayLabel": MessageLookupByLibrary.simpleMessage(
      "Doğum Günü",
    ),
    "onboardingFoodUnitsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Yiyecek ve içecekleri nasıl kaydedersiniz",
    ),
    "onboardingGenderQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Cinsiyetiniz nedir?",
    ),
    "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Mevcut kilo hedefiniz nedir?",
    ),
    "onboardingHeightExampleHintCm": MessageLookupByLibrary.simpleMessage(
      "ör. 170",
    ),
    "onboardingHeightExampleHintFt": MessageLookupByLibrary.simpleMessage(
      "ör. 5.8",
    ),
    "onboardingHeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Mevcut boyunuz nedir?",
    ),
    "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
      "Başlamak için, uygulamanın günlük kalori hedefinizi hesaplamak için hakkınızda bazı bilgilere ihtiyacı var.\nHakkınızdaki tüm bilgiler cihazınızda güvenli bir şekilde saklanır.",
    ),
    "onboardingIntroSourcesLinkLabel": MessageLookupByLibrary.simpleMessage(
      "Tıbbi hesaplama kaynaklarımızı okuyun",
    ),
    "onboardingKcalPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "günlük kcal",
    ),
    "onboardingKjPerDayLabel": MessageLookupByLibrary.simpleMessage(
      "günlük kJ",
    ),
    "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
      "Non-binary bireyler için yayımlanmış bir kalori temeli bulunmuyor, bu nedenle varsayılan olarak erkek ve kadın formüllerinin ortalamasını kullanıyoruz — bir başlangıç noktası, kesin bir tahmin değil. Ayarlar → Hesaplamalar bölümünden istediğin zaman ince ayar yapabilirsin.",
    ),
    "onboardingOtherOptionsLabel": MessageLookupByLibrary.simpleMessage(
      "Diğer seçenekler",
    ),
    "onboardingOtherOptionsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Uygulamayı kişiselleştirin — her şeyi daha sonra ayarlardan değiştirebilirsiniz",
    ),
    "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage(
      "Genel Bakış",
    ),
    "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
      "Yanlış giriş, lütfen tekrar deneyin",
    ),
    "onboardingTargetWeightHintOptional": MessageLookupByLibrary.simpleMessage(
      "İsteğe bağlı",
    ),
    "onboardingTargetWeightSubtitle": MessageLookupByLibrary.simpleMessage(
      "Ulaşmak istediğin bir kilo var mı? Bu alanı boş bırakabilir veya daha sonra Profil\'den değiştirebilirsin.",
    ),
    "onboardingWeightExampleHintKg": MessageLookupByLibrary.simpleMessage(
      "ör. 60",
    ),
    "onboardingWeightExampleHintLbs": MessageLookupByLibrary.simpleMessage(
      "ör. 132",
    ),
    "onboardingWeightQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
      "Mevcut kilonuz nedir?",
    ),
    "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage(
      "Hoş geldiniz",
    ),
    "onboardingWrongHeightLabel": MessageLookupByLibrary.simpleMessage(
      "Doğru boy girin",
    ),
    "onboardingWrongWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Doğru kilo girin",
    ),
    "onboardingYourGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Kalori hedefiniz:",
    ),
    "onboardingYourMacrosGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Makro besin hedefleriniz:",
    ),
    "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
    "paActiveVideoGames": MessageLookupByLibrary.simpleMessage(
      "aktif video oyunları",
    ),
    "paActiveVideoGamesDesc": MessageLookupByLibrary.simpleMessage(
      "Wii Sports, Dance Dance Revolution, genel",
    ),
    "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage("futbol"),
    "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "dokunmatik, bayrak, genel",
    ),
    "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("okçuluk"),
    "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "avcılık dışı",
    ),
    "paAutoRacing": MessageLookupByLibrary.simpleMessage("otomobil yarışı"),
    "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("açık tekerlek"),
    "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage(
      "sırt çantasıyla gezme",
    ),
    "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
    "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "sosyal tekler ve çiftler, genel",
    ),
    "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("basketbol"),
    "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage(
      "bisiklet sürme",
    ),
    "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paBicyclingMountainGeneral": MessageLookupByLibrary.simpleMessage(
      "dağ bisikleti",
    ),
    "paBicyclingMountainGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "genel",
    ),
    "paBicyclingStationaryGeneral": MessageLookupByLibrary.simpleMessage(
      "sabit bisiklet",
    ),
    "paBicyclingStationaryGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "genel",
    ),
    "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("bilardo"),
    "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
    "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paBoxingBag": MessageLookupByLibrary.simpleMessage("boks"),
    "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("kum torbası"),
    "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boks"),
    "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ringde, genel",
    ),
    "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
    "paBroomballDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage("kalistenik"),
    "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "hafif veya orta derecede çaba, genel (ör. sırt egzersizleri)",
    ),
    "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kano"),
    "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "kürek çekme, zevk için, genel",
    ),
    "paCatch": MessageLookupByLibrary.simpleMessage("futbol veya beyzbol"),
    "paCatchDesc": MessageLookupByLibrary.simpleMessage("yakalama oyunu"),
    "paCheerleading": MessageLookupByLibrary.simpleMessage("amigo"),
    "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
      "jimnastik hareketleri, rekabetçi",
    ),
    "paChildrenGame": MessageLookupByLibrary.simpleMessage("çocuk oyunları"),
    "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
      "(ör. seksek, 4-kare, dodgeball, oyun alanı aletleri, t-ball, tetherball, misket, arcade oyunları), orta derecede çaba",
    ),
    "paClimbingHillsNoLoadGeneral": MessageLookupByLibrary.simpleMessage(
      "tepe tırmanma, yük yok",
    ),
    "paClimbingHillsNoLoadGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "yük yok",
    ),
    "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
    "paCricketDesc": MessageLookupByLibrary.simpleMessage(
      "vuruş, bowling, saha",
    ),
    "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
    "paCroquetDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paCrossCountrySkiing": MessageLookupByLibrary.simpleMessage(
      "kayaklı koşu",
    ),
    "paCrossCountrySkiingDesc": MessageLookupByLibrary.simpleMessage(
      "kayaklı koşu, genel",
    ),
    "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
    "paCurlingDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("aerobik"),
    "paDancingAerobicGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "genel",
    ),
    "paDancingGeneral": MessageLookupByLibrary.simpleMessage("genel dans"),
    "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "ör. disko, halk, İrlanda step dansı, hat dansı, polka, contra, country",
    ),
    "paDartsWall": MessageLookupByLibrary.simpleMessage("dart"),
    "paDartsWallDesc": MessageLookupByLibrary.simpleMessage("duvar veya çim"),
    "paDivingGeneral": MessageLookupByLibrary.simpleMessage("dalış"),
    "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "deri dalışı, scuba dalışı, genel",
    ),
    "paDivingSpringboardPlatform": MessageLookupByLibrary.simpleMessage(
      "dalış",
    ),
    "paDivingSpringboardPlatformDesc": MessageLookupByLibrary.simpleMessage(
      "trambolin veya platform",
    ),
    "paFencing": MessageLookupByLibrary.simpleMessage("eskrim"),
    "paFencingDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee oyunu"),
    "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
    "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("jimnastik"),
    "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
    "paHackySackDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paHandballGeneral": MessageLookupByLibrary.simpleMessage("hentbol"),
    "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paHangGliding": MessageLookupByLibrary.simpleMessage("yelken kanat"),
    "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paHeadingBicycling": MessageLookupByLibrary.simpleMessage(
      "bisiklet sürme",
    ),
    "paHeadingConditionalExercise": MessageLookupByLibrary.simpleMessage(
      "koşullandırma egzersizi",
    ),
    "paHeadingDancing": MessageLookupByLibrary.simpleMessage("dans"),
    "paHeadingRunning": MessageLookupByLibrary.simpleMessage("koşu"),
    "paHeadingSports": MessageLookupByLibrary.simpleMessage("spor"),
    "paHeadingWalking": MessageLookupByLibrary.simpleMessage("yürüyüş"),
    "paHeadingWaterActivities": MessageLookupByLibrary.simpleMessage(
      "su aktiviteleri",
    ),
    "paHeadingWinterActivities": MessageLookupByLibrary.simpleMessage(
      "kış aktiviteleri",
    ),
    "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
      "yüksek yoğunluklu interval antrenman",
    ),
    "paHighIntensityIntervalExerciseDesc": MessageLookupByLibrary.simpleMessage(
      "orta düzeyde efor",
    ),
    "paHighIntensityIntervalExerciseVigorous":
        MessageLookupByLibrary.simpleMessage(
          "yüksek yoğunluklu interval antrenman",
        ),
    "paHighIntensityIntervalExerciseVigorousDesc":
        MessageLookupByLibrary.simpleMessage(
          "burpees, dağcı, squat jump, Tabata, yüksek efor",
        ),
    "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("yürüyüş"),
    "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage(
      "kırsal alan",
    ),
    "paHockeyField": MessageLookupByLibrary.simpleMessage("çim hokeyi"),
    "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage("at binme"),
    "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage("buz hokeyi"),
    "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage("buz pateni"),
    "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
    "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("koşu"),
    "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paJuggling": MessageLookupByLibrary.simpleMessage("jonglörlük"),
    "paJugglingDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kano"),
    "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "orta derecede çaba",
    ),
    "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
    "paKickballDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
    "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paLawnBowling": MessageLookupByLibrary.simpleMessage("çim bowling"),
    "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage(
      "bocce topu, açık hava",
    ),
    "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage(
      "dövüş sanatları",
    ),
    "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
      "farklı tipler, orta tempo (ör. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boks)",
    ),
    "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage(
      "dövüş sanatları",
    ),
    "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
      "farklı tipler, daha yavaş tempo, acemi performansçılar, pratik",
    ),
    "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-kros"),
    "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
      "arazi motor sporları, arazi aracı, genel",
    ),
    "paMountainClimbing": MessageLookupByLibrary.simpleMessage("tırmanma"),
    "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage(
      "kaya veya dağ tırmanışı",
    ),
    "paNordicWalking": MessageLookupByLibrary.simpleMessage("nordik yürüyüş"),
    "paOrienteering": MessageLookupByLibrary.simpleMessage("oryantiring"),
    "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("kürek tahtası"),
    "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("ayakta"),
    "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pedallı tekne"),
    "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
    "paPaddleballDesc": MessageLookupByLibrary.simpleMessage("rahat, genel"),
    "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
    "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
    "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
    "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("at üzerinde"),
    "paRacquetball": MessageLookupByLibrary.simpleMessage("raketbol"),
    "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paResistanceTraining": MessageLookupByLibrary.simpleMessage(
      "direnç antrenmanı",
    ),
    "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
      "ağırlık kaldırma, serbest ağırlık, nautilus veya evrensel",
    ),
    "paResistanceTrainingVigorous": MessageLookupByLibrary.simpleMessage(
      "direnç antrenmanı (yoğun)",
    ),
    "paResistanceTrainingVigorousDesc": MessageLookupByLibrary.simpleMessage(
      "yoğun çaba, powerlifting veya bodybuilding",
    ),
    "paRodeoSportGeneralModerate": MessageLookupByLibrary.simpleMessage(
      "rodeo sporları",
    ),
    "paRodeoSportGeneralModerateDesc": MessageLookupByLibrary.simpleMessage(
      "genel, orta derecede çaba",
    ),
    "paRollerbladingLight": MessageLookupByLibrary.simpleMessage(
      "patenle kayma",
    ),
    "paRollerbladingLightDesc": MessageLookupByLibrary.simpleMessage(
      "sıralı paten",
    ),
    "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage("ip atlama"),
    "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "orta tempo, 100-120 atlama/dakika, genel, 2 ayak atlama, düz atlama",
    ),
    "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage("ip atlama"),
    "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "birlik, takım, rekabetçi",
    ),
    "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
    "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
      "dokunmatik, rekabetçi olmayan",
    ),
    "paRunningGeneral": MessageLookupByLibrary.simpleMessage("koşu"),
    "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paSailingGeneral": MessageLookupByLibrary.simpleMessage("yelken"),
    "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "tekne ve tahta yelken, rüzgar sörfü, buz yelken, genel",
    ),
    "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
    "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage("kaykay"),
    "paSkateboardingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "genel, orta derecede çaba",
    ),
    "paSkatingRoller": MessageLookupByLibrary.simpleMessage("paten kayma"),
    "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("kayak"),
    "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage(
      "su kayağı",
    ),
    "paSkiingWaterWakeboardingDesc": MessageLookupByLibrary.simpleMessage(
      "su veya wakeboarding",
    ),
    "paSkydiving": MessageLookupByLibrary.simpleMessage("paraşütle atlama"),
    "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
      "paraşütle atlama, base jumping, bungee jumping",
    ),
    "paSnorkeling": MessageLookupByLibrary.simpleMessage("şnorkelle dalış"),
    "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage("kar küreme"),
    "paSnowShovingModerateDesc": MessageLookupByLibrary.simpleMessage(
      "elle, orta derecede çaba",
    ),
    "paSnowshoeing": MessageLookupByLibrary.simpleMessage(
      "kar ayakkabısı yürüyüşü",
    ),
    "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("futbol"),
    "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage("rahat, genel"),
    "paSoftballBaseballGeneral": MessageLookupByLibrary.simpleMessage(
      "softbol / beyzbol",
    ),
    "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "hızlı veya yavaş atış, genel",
    ),
    "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
    "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paStretching": MessageLookupByLibrary.simpleMessage("esneme"),
    "paStretchingDesc": MessageLookupByLibrary.simpleMessage("hafif, genel"),
    "paSurfing": MessageLookupByLibrary.simpleMessage("sörf"),
    "paSurfingDesc": MessageLookupByLibrary.simpleMessage(
      "vücut veya tahta, genel",
    ),
    "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("yüzme"),
    "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "su üzerinde durma, orta derecede çaba, genel",
    ),
    "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage("masa tenisi"),
    "paTableTennisGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "masa tenisi, ping pong",
    ),
    "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage(
      "tai chi, qi gong",
    ),
    "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
    "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paTrackField": MessageLookupByLibrary.simpleMessage("atletizm"),
    "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
      "(ör. gülle, disk, çekiç atma)",
    ),
    "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
      "(ör. yüksek atlama, uzun atlama, üçlü atlama, cirit, sırıkla atlama)",
    ),
    "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
      "(ör. engelli koşu, engelli yarış)",
    ),
    "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trambolin"),
    "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage(
      "eğlence amaçlı",
    ),
    "paTreadmillRunning": MessageLookupByLibrary.simpleMessage(
      "koşu bandında koşu",
    ),
    "paTreadmillRunningDesc": MessageLookupByLibrary.simpleMessage(
      "koşu bandında, genel",
    ),
    "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage(
      "tek tekerlekli bisiklet",
    ),
    "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("voleybol"),
    "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
      "rekabetçi olmayan, 6 - 9 üyeli takım, genel",
    ),
    "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("yürüyüş"),
    "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage(
      "zevk için",
    ),
    "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("köpeği gezdirmek"),
    "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
    "paWallyballDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paWaterAerobics": MessageLookupByLibrary.simpleMessage("su egzersizi"),
    "paWaterAerobicsDesc": MessageLookupByLibrary.simpleMessage(
      "su aerobiği, su kalistenik",
    ),
    "paWaterPolo": MessageLookupByLibrary.simpleMessage("su topu"),
    "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paWaterVolleyball": MessageLookupByLibrary.simpleMessage("su voleybolu"),
    "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "paWateraerobicsCalisthenics": MessageLookupByLibrary.simpleMessage(
      "su aerobiği",
    ),
    "paWateraerobicsCalisthenicsDesc": MessageLookupByLibrary.simpleMessage(
      "su aerobiği, su kalistenik",
    ),
    "paWrestling": MessageLookupByLibrary.simpleMessage("güreş"),
    "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("genel"),
    "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "iş yerinde çoğunlukla ayakta durma veya yürüme ve aktif serbest zaman aktiviteleri",
    ),
    "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktif"),
    "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "ör. iş yerinde oturma veya ayakta durma ve hafif serbest zaman aktiviteleri",
    ),
    "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("Düşük Aktif"),
    "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "ör. ofis işi ve çoğunlukla oturarak geçirilen serbest zaman aktiviteleri",
    ),
    "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Hareketsiz"),
    "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "iş yerinde çoğunlukla yürüme, koşma veya ağırlık taşıma ve aktif serbest zaman aktiviteleri",
    ),
    "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Çok Aktif"),
    "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
      "Paylaşılan yemek kodunu buraya yapıştırın",
    ),
    "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("Kodu yapıştır"),
    "per100gmlLabel": MessageLookupByLibrary.simpleMessage("100g/ml başına"),
    "perServingLabel": MessageLookupByLibrary.simpleMessage("Porsiyon Başına"),
    "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
    "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage(
      "çoklu doymamış yağ",
    ),
    "potassiumLabel": MessageLookupByLibrary.simpleMessage("potasyum"),
    "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage(
      "Gizlilik politikası",
    ),
    "profileActiveLabel": MessageLookupByLibrary.simpleMessage("Etkin"),
    "profileFastingEntry": MessageLookupByLibrary.simpleMessage(
      "Oruç zamanlayıcısı",
    ),
    "profileImageLabel": MessageLookupByLibrary.simpleMessage("Fotoğraf ekle"),
    "profileImageRemove": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafı kaldır",
    ),
    "profileImageReplace": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafı değiştir",
    ),
    "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
    "profileNameHint": MessageLookupByLibrary.simpleMessage("Profil adı"),
    "profileNameLabel": MessageLookupByLibrary.simpleMessage("Ad"),
    "profileTargetWeightClearAction": MessageLookupByLibrary.simpleMessage(
      "Temizle",
    ),
    "profileTargetWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Hedef kilo",
    ),
    "profileTargetWeightNotSetLabel": MessageLookupByLibrary.simpleMessage(
      "Ayarlanmadı",
    ),
    "profileTargetWeightReached": MessageLookupByLibrary.simpleMessage(
      "Hedefine ulaştın",
    ),
    "profileTargetWeightToGo": m39,
    "profileWeightHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Kilo geçmişi",
    ),
    "proteinLabel": MessageLookupByLibrary.simpleMessage("protein"),
    "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
    "quantityLabel": MessageLookupByLibrary.simpleMessage("Miktar"),
    "quickAddActivityAddedSnack": MessageLookupByLibrary.simpleMessage(
      "Aktivite eklendi",
    ),
    "quickAddActivityDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Süre (dk, isteğe bağlı)",
    ),
    "quickAddActivityEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Yakılan enerji (kcal)",
    ),
    "quickAddActivityEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Yakılan enerji (kJ)",
    ),
    "quickAddActivityNameLabel": MessageLookupByLibrary.simpleMessage(
      "Ad (isteğe bağlı)",
    ),
    "quickAddActivityTitleLabel": MessageLookupByLibrary.simpleMessage(
      "Hızlı aktivite ekle",
    ),
    "quickAddAddedSnack": m40,
    "quickAddBottomSheetTitle": MessageLookupByLibrary.simpleMessage(
      "Hızlı ekle",
    ),
    "quickAddCarbsHint": MessageLookupByLibrary.simpleMessage(
      "Karbonhidrat (g, isteğe bağlı)",
    ),
    "quickAddCardLabel": MessageLookupByLibrary.simpleMessage("Hızlı ekle"),
    "quickAddDefaultName": MessageLookupByLibrary.simpleMessage("Hızlı ekle"),
    "quickAddEnergyLabelKcal": MessageLookupByLibrary.simpleMessage(
      "Enerji (kcal)",
    ),
    "quickAddEnergyLabelKj": MessageLookupByLibrary.simpleMessage(
      "Enerji (kJ)",
    ),
    "quickAddFatHint": MessageLookupByLibrary.simpleMessage(
      "Yağ (g, isteğe bağlı)",
    ),
    "quickAddProteinHint": MessageLookupByLibrary.simpleMessage(
      "Protein (g, isteğe bağlı)",
    ),
    "quickAddSubmitLabel": MessageLookupByLibrary.simpleMessage("Ekle"),
    "quickAddTitleHint": MessageLookupByLibrary.simpleMessage("Başlık"),
    "readLabel": MessageLookupByLibrary.simpleMessage(
      "Gizlilik politikasını okudum ve kabul ediyorum.",
    ),
    "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
      "Son Eklenenler",
    ),
    "recipeAddIngredientLabel": MessageLookupByLibrary.simpleMessage(
      "Malzeme Ekle",
    ),
    "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Bu tariften günlüğe eklenen önceki girdiler korunacaktır.",
    ),
    "recipeDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Tarif silinsin mi?",
    ),
    "recipeDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Açıklama (isteğe bağlı)",
    ),
    "recipeImageLabel": MessageLookupByLibrary.simpleMessage("Fotoğraf ekle"),
    "recipeImagePickFromGallery": MessageLookupByLibrary.simpleMessage(
      "Galeriden seç",
    ),
    "recipeImageRemove": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafı kaldır",
    ),
    "recipeImageReplace": MessageLookupByLibrary.simpleMessage(
      "Fotoğrafı değiştir",
    ),
    "recipeImageTakePhoto": MessageLookupByLibrary.simpleMessage(
      "Fotoğraf çek",
    ),
    "recipeIngredientAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Miktar",
    ),
    "recipeIngredientCountLabel": m41,
    "recipeIngredientUnitLabel": MessageLookupByLibrary.simpleMessage("Birim"),
    "recipeIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Malzemeler",
    ),
    "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Toplam ağırlık sıfırdan büyük olmalı",
    ),
    "recipeLogCtaLabel": MessageLookupByLibrary.simpleMessage(
      "Bu Tarifi Kaydet",
    ),
    "recipeNameLabel": MessageLookupByLibrary.simpleMessage("Tarif adı"),
    "recipeNameRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Tarif bir ad gerektirir",
    ),
    "recipeNeedsIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "En az bir malzeme ekleyin",
    ),
    "recipeNoIngredientsLabel": MessageLookupByLibrary.simpleMessage(
      "Henüz malzeme yok",
    ),
    "recipeNutritionPer100Label": MessageLookupByLibrary.simpleMessage(
      "100 g başına",
    ),
    "recipeNutritionPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Beslenme (toplam)",
    ),
    "recipeSaveErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Tarif kaydedilemedi.",
    ),
    "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
      "Bu yemeği bir dahaki sefere kaydedilenler listesinde tutmak için açın. Bir daha yemeyeceğiniz tek seferlik bir yemek için kapalı bırakın.",
    ),
    "recipeSaveForLaterLabel": MessageLookupByLibrary.simpleMessage(
      "Sonraki için kaydet",
    ),
    "recipeSaveLabel": MessageLookupByLibrary.simpleMessage("Tarifi Kaydet"),
    "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
      "Bu tarifi gram yerine porsiyon olarak kaydetmenize olanak tanır.",
    ),
    "recipeServingsCountLabel": MessageLookupByLibrary.simpleMessage(
      "Porsiyonlar (isteğe bağlı)",
    ),
    "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
      "Virgülle ayırın, örn. \"kahvaltı, vegan\"",
    ),
    "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Etiketler"),
    "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
      "Varsayılan olarak malzemelerin toplamı. Sıvılar yaklaşık 1 ml ≈ 1 g olarak hesaplanır.",
    ),
    "recipeTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
      "Toplam ağırlık (g)",
    ),
    "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Birden fazla malzemeden bir öğün oluşturun ve diğer yiyecekler gibi yeniden kullanın.",
    ),
    "recipesEmptyLabel": MessageLookupByLibrary.simpleMessage(
      "Henüz tarif yok",
    ),
    "recipesFilterAllLabel": MessageLookupByLibrary.simpleMessage("Tümü"),
    "recipesLabel": MessageLookupByLibrary.simpleMessage("Tarifler"),
    "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Tarifler yüklenemedi. Lütfen daha sonra tekrar deneyin.",
    ),
    "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
      "Geliştiriciye bir hata bildirmek istiyor musunuz?",
    ),
    "retryLabel": MessageLookupByLibrary.simpleMessage("Tekrar Dene"),
    "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("doymuş yağ"),
    "scanProductLabel": MessageLookupByLibrary.simpleMessage("Ürünü Tara"),
    "scannerLockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Dikey kilitle",
    ),
    "scannerManualEntryButton": MessageLookupByLibrary.simpleMessage(
      "Kodu elle gir",
    ),
    "scannerManualEntryCancel": MessageLookupByLibrary.simpleMessage("İptal"),
    "scannerManualEntryDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Barkodu girin",
    ),
    "scannerManualEntryFieldHint": MessageLookupByLibrary.simpleMessage(
      "8 ile 14 arasında rakam",
    ),
    "scannerManualEntryInvalid": MessageLookupByLibrary.simpleMessage(
      "Bu barkod geçerli görünmüyor. Lütfen rakamları kontrol edip tekrar deneyin.",
    ),
    "scannerManualEntrySubmit": MessageLookupByLibrary.simpleMessage("Ara"),
    "scannerUnlockOrientationTooltip": MessageLookupByLibrary.simpleMessage(
      "Döndürmeye izin ver",
    ),
    "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Lütfen bir arama kelimesi girin",
    ),
    "searchFoodPage": MessageLookupByLibrary.simpleMessage("Yiyecek"),
    "searchLabel": MessageLookupByLibrary.simpleMessage("Ara"),
    "searchProductsPage": MessageLookupByLibrary.simpleMessage("Ürünler"),
    "searchResultsLabel": MessageLookupByLibrary.simpleMessage(
      "Arama sonuçları",
    ),
    "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Cinsiyet Seçin",
    ),
    "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Boy Seçin",
    ),
    "selectPalCategoryLabel": MessageLookupByLibrary.simpleMessage(
      "Aktivite Seviyesini Seçin",
    ),
    "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage(
      "Kilo Seçin",
    ),
    "selectionCountLabel": m42,
    "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
      "Anonim kullanım verileri gönder",
    ),
    "servingLabel": MessageLookupByLibrary.simpleMessage("Porsiyon"),
    "servingSizeLabelImperial": MessageLookupByLibrary.simpleMessage(
      "Bir porsiyon (oz/fl oz)",
    ),
    "servingSizeLabelMetric": MessageLookupByLibrary.simpleMessage(
      "Bir porsiyon",
    ),
    "settingAboutLabel": MessageLookupByLibrary.simpleMessage("Hakkında"),
    "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage(
      "Geri Bildirim",
    ),
    "settingsAccentColourTitle": MessageLookupByLibrary.simpleMessage(
      "Vurgu rengi",
    ),
    "settingsAccentCustomColour": MessageLookupByLibrary.simpleMessage(
      "Özel renk…",
    ),
    "settingsAccentCustomSubtitle": MessageLookupByLibrary.simpleMessage(
      "Hassas seçim için ton kaydırıcısını aç",
    ),
    "settingsAccentHexInvalid": MessageLookupByLibrary.simpleMessage(
      "Bu hex kod doğru görünmüyor — altı karakter, 0-9 ve A-F.",
    ),
    "settingsAccentHexLabel": MessageLookupByLibrary.simpleMessage("Hex kod"),
    "settingsAccentHueDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Özel bir vurgu seçmek için sistem renklerini kapatın.",
    ),
    "settingsAccentHueReset": MessageLookupByLibrary.simpleMessage("Sıfırla"),
    "settingsAccentHueTitle": MessageLookupByLibrary.simpleMessage(
      "Vurgu rengi",
    ),
    "settingsAccentPresetsHeader": MessageLookupByLibrary.simpleMessage(
      "Bir renk seç",
    ),
    "settingsAccentSubtitleCustom": MessageLookupByLibrary.simpleMessage(
      "Özel",
    ),
    "settingsAccentSubtitleDefault": MessageLookupByLibrary.simpleMessage(
      "Varsayılan",
    ),
    "settingsAccentSubtitleMaterialYou": MessageLookupByLibrary.simpleMessage(
      "Material You",
    ),
    "settingsBodyWeightUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Vücut ağırlığı birimi",
    ),
    "settingsCalciumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük kalsiyum hedefi (miligram). Varsayılan referans 1000 mg.",
    ),
    "settingsCalciumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Kalsiyum hedefi",
    ),
    "settingsCaloriesTaperDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük açığı kademeli olarak azaltır, böylece son birkaç kilo bir duvar gibi hissettirmez.",
    ),
    "settingsCaloriesTaperLabel": MessageLookupByLibrary.simpleMessage(
      "Hedefine yaklaştıkça kalori hedefini ayarla",
    ),
    "settingsCategoryAbout": MessageLookupByLibrary.simpleMessage("Hakkında"),
    "settingsCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Görünüm",
    ),
    "settingsCategoryData": MessageLookupByLibrary.simpleMessage("Veriler"),
    "settingsCategoryDisplay": MessageLookupByLibrary.simpleMessage(
      "Görüntüleme",
    ),
    "settingsCategoryGoals": MessageLookupByLibrary.simpleMessage(
      "Hedefler ve beslenme",
    ),
    "settingsCategoryUnits": MessageLookupByLibrary.simpleMessage(
      "Birimler ve enerji",
    ),
    "settingsCustomMealsLabel": MessageLookupByLibrary.simpleMessage(
      "Özel Yemekler",
    ),
    "settingsDayStartDescription": MessageLookupByLibrary.simpleMessage(
      "Gününün başladığı saati seç. Bu saatten önce kaydedilen öğünler ve aktiviteler önceki güne sayılır — gece çalışanlar veya geç yemek yiyenler için kullanışlıdır.",
    ),
    "settingsDayStartHourLabel": m43,
    "settingsDayStartHoursPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Saat",
    ),
    "settingsDayStartLabel": MessageLookupByLibrary.simpleMessage(
      "Gün başlangıcı",
    ),
    "settingsDayStartMinutesPickerLabel": MessageLookupByLibrary.simpleMessage(
      "Dakika",
    ),
    "settingsDayStartTimeLabel": m44,
    "settingsDeleteAllDataConfirmAction": MessageLookupByLibrary.simpleMessage(
      "Hepsini sil",
    ),
    "settingsDeleteAllDataConfirmContent": MessageLookupByLibrary.simpleMessage(
      "Bu işlem profilinizi, öğünlerinizi, aktivitelerinizi, kilo geçmişinizi ve tüm özel tariflerinizi bu cihazdan kalıcı olarak siler. Open Food Facts ve USDA Food Data Central veritabanları bundan etkilenmez. Bu işlem geri alınamaz.",
    ),
    "settingsDeleteAllDataConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Tüm verileriniz silinsin mi?",
    ),
    "settingsDeleteAllDataLabel": MessageLookupByLibrary.simpleMessage(
      "Tüm verilerimi sil",
    ),
    "settingsDeleteAllDataSubtitle": MessageLookupByLibrary.simpleMessage(
      "Profil, öğünler, aktiviteler ve kilo geçmişi",
    ),
    "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage(
      "Sorumluluk Reddi",
    ),
    "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Mesafe"),
    "settingsEnergyUnitLabel": MessageLookupByLibrary.simpleMessage(
      "Enerji birimi",
    ),
    "settingsFibreGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük lif hedefi (gram). Varsayılan referans 30 g.",
    ),
    "settingsFibreGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Lif hedefi",
    ),
    "settingsFoodSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Gıda veritabanları",
    ),
    "settingsFoodSourcesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Arama sonuçlarının kaynağını seçin",
    ),
    "settingsFoodUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "İmperial (lbs, oz, fl oz)",
    ),
    "settingsFoodUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Besin birimleri",
    ),
    "settingsFoodUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrik (g, kg, ml, l)",
    ),
    "settingsHeightUnitsImperial": MessageLookupByLibrary.simpleMessage(
      "İmperial (ft, in)",
    ),
    "settingsHeightUnitsLabel": MessageLookupByLibrary.simpleMessage(
      "Boy birimi",
    ),
    "settingsHeightUnitsMetric": MessageLookupByLibrary.simpleMessage(
      "Metrik (mm, cm, m)",
    ),
    "settingsImperialLabel": MessageLookupByLibrary.simpleMessage(
      "İmperial (lbs, ft, oz)",
    ),
    "settingsIronGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük demir hedefi (miligram). Varsayılan değer cinsiyete göre değişir (8 mg erkek, 18 mg kadın, diğerleri için 14 mg).",
    ),
    "settingsIronGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Demir hedefi",
    ),
    "settingsKcalAdjustmentLabel": MessageLookupByLibrary.simpleMessage(
      "Günlük kcal ayarı",
    ),
    "settingsLabel": MessageLookupByLibrary.simpleMessage("Ayarlar"),
    "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Dil"),
    "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("Lisanslar"),
    "settingsMacroSplitLabel": MessageLookupByLibrary.simpleMessage(
      "Makro dağılımı",
    ),
    "settingsMagnesiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük magnezyum hedefi (miligram). Varsayılan değer cinsiyete göre değişir (400 mg erkek, 310 mg kadın, diğerleri için 355 mg).",
    ),
    "settingsMagnesiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Magnezyum hedefi",
    ),
    "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Kütle"),
    "settingsMaterialYouSubtitle": MessageLookupByLibrary.simpleMessage(
      "Android 12 ve daha yeni sürümlerde duvar kâğıdınızın vurgu rengiyle uyumlanır.",
    ),
    "settingsMaterialYouTitle": MessageLookupByLibrary.simpleMessage(
      "Sistem renklerini kullan",
    ),
    "settingsMetricLabel": MessageLookupByLibrary.simpleMessage(
      "Metrik (kg, cm, ml)",
    ),
    "settingsNotificationsLabel": MessageLookupByLibrary.simpleMessage(
      "Günlük Hatırlatıcı",
    ),
    "settingsNotificationsTimeLabel": m45,
    "settingsNutrientGoalsHint": MessageLookupByLibrary.simpleMessage(
      "Günlük paneldeki her besin için kişisel hedefler. Bir hedef belirlediğinde günlük, varsayılan günlük referanslar yerine bu değerleri kullanır.",
    ),
    "settingsNutrientGoalsLabel": MessageLookupByLibrary.simpleMessage(
      "Besin hedefleri",
    ),
    "settingsNutrientsHelp": MessageLookupByLibrary.simpleMessage(
      "Günlük panelde hangi besinlerin görüneceğini seç. Gizlenenler istediğin zaman tekrar açılabilir.",
    ),
    "settingsNutrientsLabel": MessageLookupByLibrary.simpleMessage("Besinler"),
    "settingsNutrientsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Günlük panelinde hangi besinlerin görüneceğini seç",
    ),
    "settingsPerMealKcalShareBreakfast": MessageLookupByLibrary.simpleMessage(
      "Kahvaltı",
    ),
    "settingsPerMealKcalShareDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük kcal hedefini kahvaltı, öğle yemeği, akşam yemeği ve atıştırmalıklara bölün. Paylar toplam %100 olmalıdır.",
    ),
    "settingsPerMealKcalShareDinner": MessageLookupByLibrary.simpleMessage(
      "Akşam Yemeği",
    ),
    "settingsPerMealKcalShareLabel": MessageLookupByLibrary.simpleMessage(
      "Öğün başına kcal payı",
    ),
    "settingsPerMealKcalShareLunch": MessageLookupByLibrary.simpleMessage(
      "Öğle Yemeği",
    ),
    "settingsPerMealKcalShareSnack": MessageLookupByLibrary.simpleMessage(
      "Atıştırmalık",
    ),
    "settingsPotassiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük potasyum hedefi (miligram). Varsayılan referans 3500 mg.",
    ),
    "settingsPotassiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Potasyum hedefi",
    ),
    "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage(
      "Gizlilik Ayarları",
    ),
    "settingsReportErrorLabel": MessageLookupByLibrary.simpleMessage(
      "Hata Bildir",
    ),
    "settingsSaturatedFatGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük doymuş yağ üst sınırı (gram). Varsayılan referans 20 g.",
    ),
    "settingsSaturatedFatGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Doymuş yağ hedefi",
    ),
    "settingsShowActivityTracking": MessageLookupByLibrary.simpleMessage(
      "Aktivite takibini göster",
    ),
    "settingsShowMealMacros": MessageLookupByLibrary.simpleMessage(
      "Öğün makrolarını göster",
    ),
    "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage(
      "Mikro besinleri göster",
    ),
    "settingsSodiumGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük sodyum üst sınırı (miligram). Varsayılan referans 2300 mg.",
    ),
    "settingsSodiumGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Sodyum hedefi",
    ),
    "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage(
      "Kaynak Kodu",
    ),
    "settingsSourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Kaynaklar ve Referanslar",
    ),
    "settingsSugarsGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük şeker üst sınırı (gram). Varsayılan referans 50 g.",
    ),
    "settingsSugarsGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Şeker hedefi",
    ),
    "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Sistem"),
    "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Koyu"),
    "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Tema"),
    "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Açık"),
    "settingsThemeSystemDefaultLabel": MessageLookupByLibrary.simpleMessage(
      "Sistem varsayılanı",
    ),
    "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Birimler"),
    "settingsVitaminB12GoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük B12 vitamini hedefi (mikrogram). Varsayılan referans 2,4 µg.",
    ),
    "settingsVitaminB12GoalLabel": MessageLookupByLibrary.simpleMessage(
      "B12 vitamini hedefi",
    ),
    "settingsVitaminDGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük D vitamini hedefi (mikrogram). Varsayılan referans 15 µg.",
    ),
    "settingsVitaminDGoalLabel": MessageLookupByLibrary.simpleMessage(
      "D vitamini hedefi",
    ),
    "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Hacim"),
    "settingsWaterGoalDescription": MessageLookupByLibrary.simpleMessage(
      "Ana ekrandaki su göstergesinin kullandığı hedef.",
    ),
    "settingsWaterGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Günlük su hedefi",
    ),
    "shareActivityLabel": MessageLookupByLibrary.simpleMessage(
      "Antrenmanı paylaş",
    ),
    "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Kodu paylaş"),
    "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
    "shareRecipeLabel": MessageLookupByLibrary.simpleMessage("Tarifi paylaş"),
    "snackExample": MessageLookupByLibrary.simpleMessage(
      "ör. elma, dondurma, çikolata ...",
    ),
    "snackLabel": MessageLookupByLibrary.simpleMessage("Atıştırmalık"),
    "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodyum"),
    "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
      "Bir aktivite sırasında yakılan kaloriler, Adult Compendium of Physical Activities\'teki değerler kullanılarak MET × vücut ağırlığı (kg) × süre (saat) olarak tahmin edilir.",
    ),
    "sourcesActivityTitle": MessageLookupByLibrary.simpleMessage(
      "Aktivite kalorileri (MET değerleri)",
    ),
    "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
      "BMI, kilogram cinsinden vücut ağırlığının metre cinsinden boyun karesine (m²) bölünmesiyle hesaplanır. Sağlık kategorileri (zayıf, normal, fazla kilolu, sınıf I–III obezite) Dünya Sağlık Örgütü\'nün yetişkin BMI sınıflandırmasına uyar.",
    ),
    "sourcesBmiTitle": MessageLookupByLibrary.simpleMessage(
      "Vücut Kitle İndeksi (BMI)",
    ),
    "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük kalori hedefleri, bazal metabolizma hızı ve fiziksel aktivite katsayıları Institute of Medicine denklemlerine dayanır. Kaynak: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Bölüm 5 ve Tablo 5-5.",
    ),
    "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
      "Enerji ihtiyacı (TDEE, BMR ve aktivite düzeyi)",
    ),
    "sourcesIconTooltip": MessageLookupByLibrary.simpleMessage(
      "Kaynakları görüntüle",
    ),
    "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
      "%60 karbonhidrat, %25 yağ ve %15 protein şeklindeki varsayılan dağılım, DSÖ\'nün önerdiği nüfus besin alımı aralıkları içinde kalır. Ayarlar → Hesaplamalar bölümünden değiştirebilirsin. Kaynak: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases.",
    ),
    "sourcesMacrosTitle": MessageLookupByLibrary.simpleMessage(
      "Makro besin dağılımı",
    ),
    "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
      "Enerji harcaması üzerine yapılan araştırmalar tarihsel olarak yalnızca ikili cinsiyet kategorilerini kullanmıştır; bu nedenle non-binary kişiler için doğrulanmış tek bir TDEE formülü yoktur. Bu yüzden OpenNutriTracker, Ayarlar → Hesaplamalar bölümünde ortalanmış bir referans, östrojen-tipik bir referans ve testosteron-tipik bir referans arasında seçim yapmanı sağlar. Bakımın için kesin bir değer gerçekten önemliyse lütfen hormon durumunu bilen bir klinisyenle görüş.",
    ),
    "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
      "Non-binary kişiler için kalori tahmini",
    ),
    "sourcesNutrientReferenceDescription": MessageLookupByLibrary.simpleMessage(
      "Günlük besin panelinde gösterilen referans değerleri, yetişkinler için besin başına hedefleri kapsayan Institute of Medicine\'ın Dietary Reference Intakes özetinden alınmıştır.",
    ),
    "sourcesNutrientReferenceTitle": MessageLookupByLibrary.simpleMessage(
      "Besin referans alımları",
    ),
    "sourcesOpenSourceLabel": MessageLookupByLibrary.simpleMessage(
      "Kaynağı aç",
    ),
    "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
      "OpenNutriTracker, gösterdiği her hesaplama için yerleşik ve hakemli yöntemler kullanır. Aşağıdaki kaynaklar orijinal yayınlara bağlanır, böylece her değeri kendin doğrulayabilirsin.",
    ),
    "stLabel": MessageLookupByLibrary.simpleMessage("st"),
    "sugarLabel": MessageLookupByLibrary.simpleMessage("şeker"),
    "suppliedLabel": MessageLookupByLibrary.simpleMessage("tüketilen"),
    "switchProfileLabel": MessageLookupByLibrary.simpleMessage(
      "Profil değiştir",
    ),
    "transFatLabel": MessageLookupByLibrary.simpleMessage("trans yağ"),
    "trendsBestStreakLabel": MessageLookupByLibrary.simpleMessage("rekor"),
    "trendsCaloriesLabel": MessageLookupByLibrary.simpleMessage("Kaloriler"),
    "trendsDailyAverageLabel": MessageLookupByLibrary.simpleMessage(
      "Günlük ortalama",
    ),
    "trendsDayStreakLabel": MessageLookupByLibrary.simpleMessage(
      "gün üst üste",
    ),
    "trendsDaysOnTrack": MessageLookupByLibrary.simpleMessage(
      "bu hafta hedefteki gün",
    ),
    "trendsLabel": MessageLookupByLibrary.simpleMessage("Eğilimler"),
    "trendsPerWeekSuffix": MessageLookupByLibrary.simpleMessage("/hafta"),
    "trendsWaterLabel": MessageLookupByLibrary.simpleMessage("Su"),
    "trendsWeeksToGoalLabel": MessageLookupByLibrary.simpleMessage(
      "hafta hedefe",
    ),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Birim"),
    "vitaminALabel": MessageLookupByLibrary.simpleMessage("A vitamini"),
    "vitaminB12Label": MessageLookupByLibrary.simpleMessage("B12 vitamini"),
    "vitaminB6Label": MessageLookupByLibrary.simpleMessage("B6 vitamini"),
    "vitaminCLabel": MessageLookupByLibrary.simpleMessage("C vitamini"),
    "vitaminDLabel": MessageLookupByLibrary.simpleMessage("D vitamini"),
    "warningLabel": MessageLookupByLibrary.simpleMessage("Uyarı"),
    "waterChipLabel": m46,
    "weeklyWeightGoalKgPerWeek": m47,
    "weeklyWeightGoalLabel": MessageLookupByLibrary.simpleMessage(
      "Haftalık oran",
    ),
    "weeklyWeightGoalLbsPerWeek": m48,
    "weeklyWeightGoalNoneLabel": MessageLookupByLibrary.simpleMessage(
      "Ayarlanmadı",
    ),
    "weightHistoryAddEntry": MessageLookupByLibrary.simpleMessage("Kayıt ekle"),
    "weightHistoryChartEmptyState": MessageLookupByLibrary.simpleMessage(
      "Eğilimini görmek için en az iki gün kaydet.",
    ),
    "weightHistoryDateLabel": MessageLookupByLibrary.simpleMessage("Tarih"),
    "weightHistoryNoEntries": MessageLookupByLibrary.simpleMessage(
      "Henüz kilo kaydı yok. Eğilimi izlemek için ilk kaydını ekle.",
    ),
    "weightHistoryNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Not (isteğe bağlı)",
    ),
    "weightHistoryWeightLabel": MessageLookupByLibrary.simpleMessage("Kilo"),
    "weightLabel": MessageLookupByLibrary.simpleMessage("Kilo"),
    "yearsLabel": m49,
    "youLabel": MessageLookupByLibrary.simpleMessage("Siz"),
    "zincLabel": MessageLookupByLibrary.simpleMessage("çinko"),
  };
}
