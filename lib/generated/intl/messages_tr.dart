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

  static String m0(versionNumber) => "Versiyon ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "%${pctCarbs} karbonhidrat, %${pctFats} yağ, %${pctProteins} protein";

  static String m2(riskValue) => "Eşlik eden hastalık riski: ${riskValue}";

  static String m3(age) => "${age} yıl";

  static String m4(mealType) =>
      "These items will be added to your ${mealType}.";

  static String m5(count) => "Import ${count} items?";

  static String m6(count) =>
      "${count} öğe OpenFoodFacts'ten alınamadı.";

  static String m7(count) => "Import ${count} activities?";

  static String m8(rate) => "${rate} kg/hafta";

  static String m9(rate) => "${rate} lbs/hafta";

  static String m10(qty, unit) => "${qty} ${unit} başına";

  static String m11(time) => "Hatırlatma zamanı: ${time}";

  static String m12(count) => "CSV dosyasından ${count} öğün içe aktarıldı.";

  static String m13(imported, skipped) =>
      "${imported} öğün içe aktarıldı; geçersiz veri nedeniyle ${skipped} satır atlandı.";

  static String m14(count, size) => "${count} öğe · ${size}";

  static String m15(count) => "${count} malzeme";

  static String m16(count) =>
      "${count} malzeme içeren bu tarif içe aktarılsın mı?";

  static String m17(count) => "${count} seçildi";

  static String m18(count) => "${count} tarif silinsin mi?";


  static String m19(count) => "${count} aktivite içe aktarılsın mı?";

  static String m20(detail) => "Çözümlenemedi: ${detail}";

  static String m21(count, customCount) =>
      "JSON\'dan ${count} kayıt eklendi, ${customCount} özel öğün olarak kaydedildi";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample": MessageLookupByLibrary.simpleMessage(
            "ör. koşu, bisiklet, yoga ..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("Aktivite"),
        "addItemLabel": MessageLookupByLibrary.simpleMessage("Yeni Öğe Ekle:"),
        "addLabel": MessageLookupByLibrary.simpleMessage("Ekle"),
        "additionalInfoLabelCompendium2011": MessageLookupByLibrary.simpleMessage(
            "Bilgi\n\'2024 Compendium\n of Physical Activities\'\nden sağlanmıştır"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("Özel Yemek Öğesi"),
        "additionalInfoLabelFDC": MessageLookupByLibrary.simpleMessage(
            "Daha Fazla Bilgi\nFoodData Central\'da"),
        "additionalInfoLabelOFF": MessageLookupByLibrary.simpleMessage(
            "Daha Fazla Bilgi\nOpenFoodFacts\'te"),
        "additionalInfoLabelRecipe":
            MessageLookupByLibrary.simpleMessage("Özel Tarif"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("Bilinmeyen Yemek Öğesi"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("Yaş"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("Tümü"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker, gizliliğinize saygı duyan ücretsiz ve açık kaynaklı bir kalori ve besin takipçisidir."),
        "appLicenseLabel":
            MessageLookupByLibrary.simpleMessage("GPL-3.0 lisansı"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("Temel miktar (g/ml)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "Vücut Kitle İndeksi (BMI), yetişkinlerde aşırı kiloyu ve obeziteyi sınıflandırmak için kullanılan bir indekstir. Kilogram cinsinden ağırlığın, metre cinsinden boyun karesine bölünmesiyle tanımlanır (kg/m²).\n\nBMI, yağ ve kas kütlesi arasında ayrım yapmaz ve bazı bireyler için yanıltıcı olabilir."),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample": MessageLookupByLibrary.simpleMessage(
            "ör. mısır gevreği, süt, kahve ..."),
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
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("(önerilen)"),
        "calculationsTDEEIOM2006Label":
            MessageLookupByLibrary.simpleMessage("Tıp Enstitüsü Denklemi (2005)"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("TDEE denklemi"),
        "caloriesProfileAveragedLabel":
            MessageLookupByLibrary.simpleMessage("Ortalanmış referans (varsayılan)"),
        "caloriesProfileEstrogenTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Östrojen tipi referans"),
        "caloriesProfileInfoBody": MessageLookupByLibrary.simpleMessage(
            "Non-binary bireyler için yayımlanmış bir kalori temeli bulunmuyor — referans denklemler erkek ve kadın örneklerine dayanır. Varsayılan olarak ikisinin ortalamasını kullanıyoruz; vücudunuz hakkında daha fazlasını açıklamanızı istemeyen tarafsız bir başlangıç noktası. Ayarlar\'daki kcal kaydırıcısı ince ayar için her zaman kullanılabilir; bu kesin bir tahmin değil, bir başlangıç noktasıdır."),
        "caloriesProfileInfoTitle":
            MessageLookupByLibrary.simpleMessage("Kalori referansı"),
        "caloriesProfileTestosteroneTypicalLabel":
            MessageLookupByLibrary.simpleMessage("Testosteron tipi referans"),
        "carbohydrateLabel":
            MessageLookupByLibrary.simpleMessage("karbonhidrat"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("karbonhidrat"),
        "carbsLabelShort": MessageLookupByLibrary.simpleMessage("k"),
        "cholesterolLabel": MessageLookupByLibrary.simpleMessage("kolesterol"),
        "chooseWeeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Haftalık kilo oranı"),
        "chooseWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Kilo Hedefini Seçin"),
        "clearOffCacheConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Open Food Facts ve FDC'den yerel olarak önbelleğe alınmış arama ve tarama sonuçlarını kaldırır. Önbellek, ürünleri aradıkça ve tarattıkça otomatik olarak yeniden oluşur. Özel öğünleriniz etkilenmez."),
        "clearOffCacheConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Önbelleği temizle?"),
        "clearOffCacheLabel":
            MessageLookupByLibrary.simpleMessage("Önbelleği temizle"),
        "clearOffCacheSubtitle": m14,
        "cmLabel": MessageLookupByLibrary.simpleMessage("cm"),
        "codeCopiedLabel":
            MessageLookupByLibrary.simpleMessage("Kod kopyalandı"),
        "copyCodeLabel":
            MessageLookupByLibrary.simpleMessage("Kodu kopyala"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage(
            "Hangi yemek türüne kopyalamak istiyorsunuz?"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "\"Bugüne Kopyala\" ile yemeği bugüne kopyalayabilirsiniz. \"Sil\" ile yemeği silebilirsiniz."),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Ne yapmak istiyorsunuz?"),
        "createCustomDialogContent": MessageLookupByLibrary.simpleMessage(
            "Özel bir yemek öğesi oluşturmak istiyor musunuz?"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("Özel yemek öğesi oluştur?"),
        "createRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Tarif Oluştur"),
        "csvImportContributeOffAndroidLink":
            MessageLookupByLibrary.simpleMessage("Android"),
        "csvImportContributeOffIosLink":
            MessageLookupByLibrary.simpleMessage("iOS"),
        "csvImportContributeOffPrefix": MessageLookupByLibrary.simpleMessage(
            "Barkod var mı? Ürünü Open Food Facts'e katkıda bulunun:"),
        "csvImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "CSV dosyası okunamadı. Biçimi kontrol edin ve tekrar deneyin."),
        "csvImportPartialLabel": m13,
        "csvImportSuccessLabel": m12,
        "customMealsDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Bu yemeği kullanan tüm günlük girişleri de kaldırılacak."),
        "customMealsDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Özel yemek silinsin mi?"),
        "customMealsEmptyLabel": MessageLookupByLibrary.simpleMessage(
            "Henüz özel yemek kaydedilmedi."),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("Günlük Kcal ayarı:"),
        "dataCollectionLabel": MessageLookupByLibrary.simpleMessage(
            "Anonim kullanım verileri sağlayarak geliştirmeyi destekleyin"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("Tümünü sil"),
        "deleteSelectedRecipesConfirmTitle": m18,
        "deleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "Seçilen öğeyi silmek istiyor musunuz?"),
        "deleteTimeDialogPluralContent": MessageLookupByLibrary.simpleMessage(
            "Bu öğüne ait tüm girdileri silmek istiyor musunuz?"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("Girdiler silinsin mi?"),
        "deleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("Öğeyi Sil?"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("İPTAL"),
        "dialogCopyLabel":
            MessageLookupByLibrary.simpleMessage("BUGÜNE KOPYALA"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("SİL"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("TAMAM"),
        "diaryFutureDateWarning": MessageLookupByLibrary.simpleMessage(
            "Gelecekteki bir tarihi düzenliyorsunuz"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("Günlük"),
        "dinnerExample":
            MessageLookupByLibrary.simpleMessage("ör. çorba, tavuk, şarap ..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("Akşam Yemeği"),
        "discardChangesConfirmLabel":
            MessageLookupByLibrary.simpleMessage("Vazgeç"),
        "discardChangesContent": MessageLookupByLibrary.simpleMessage(
            "Kaydedilmemiş değişiklikleriniz kaybolacak."),
        "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
            "Değişiklikler iptal edilsin mi?"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker bir tıbbi uygulama değildir. Sağlanan tüm veriler doğrulanmamıştır ve dikkatle kullanılmalıdır. Lütfen sağlıklı bir yaşam tarzı sürdürün ve herhangi bir sorununuz varsa bir profesyonele danışın. Hastalık, hamilelik veya emzirme döneminde kullanımı önerilmez.\n\n\nUygulama hala geliştirme aşamasındadır. Hatalar, aksaklıklar ve çökmeler meydana gelebilir.\n\nHer hesaplamanın hakemli kaynaklarına Ana Sayfa veya Profil ekranındaki bilgi simgesine dokunarak ulaşabilirsin."),
        "downloadSampleCsvAction":
            MessageLookupByLibrary.simpleMessage("Örnek yemekler (csv)"),
        "downloadSampleJsonAction":
            MessageLookupByLibrary.simpleMessage("Örnek yemekler (json)"),
        "importMealsJsonAction":
            MessageLookupByLibrary.simpleMessage("Yemekleri içe aktar (json)"),
        "downloadSampleRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Örnek tarifler (json)"),
        "importRecipesJsonAction":
            MessageLookupByLibrary.simpleMessage("Tarifleri içe aktar (json)"),
        "downloadSampleRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Örnek tarifler (csv)"),
        "duplicateMealDialogContent": MessageLookupByLibrary.simpleMessage(
            "Bu yiyecek bugün bu öğüne zaten eklenmiş. Tekrar eklensin mi?"),
        "duplicateRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Çoğalt"),
        "duplicateRecipeNameSuffix":
            MessageLookupByLibrary.simpleMessage("(kopya)"),
        "editItemDialogTitle":
            MessageLookupByLibrary.simpleMessage("Öğeyi Düzenle"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("Yemeği Düzenle"),
        "editRecipeTitle":
            MessageLookupByLibrary.simpleMessage("Tarifi Düzenle"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("enerji"),
        "errorFetchingProductData": MessageLookupByLibrary.simpleMessage(
            "Ürün verileri alınırken hata oluştu"),
        "errorLoadingActivities": MessageLookupByLibrary.simpleMessage(
            "Aktiviteler yüklenirken hata oluştu"),
        "errorMealSave": MessageLookupByLibrary.simpleMessage(
            "Yemek kaydedilirken hata oluştu. Doğru yemek bilgilerini girdiniz mi?"),
        "errorOpeningBrowser": MessageLookupByLibrary.simpleMessage(
            "Tarayıcı uygulaması açılırken hata oluştu"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage(
            "E-posta uygulaması açılırken hata oluştu"),
        "errorProductNotFound":
            MessageLookupByLibrary.simpleMessage("Ürün bulunamadı"),
        "exportAction": MessageLookupByLibrary.simpleMessage("Dışa Aktar"),
        "exportImportAppDataLabel": MessageLookupByLibrary.simpleMessage(
            "Uygulama Verilerini Dışa / İçe Aktar"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "Uygulama verilerini bir zip dosyasına dışa aktarabilir ve daha sonra içe aktarabilirsiniz. Bu, verilerinizi yedeklemek veya başka bir cihaza aktarmak istiyorsanız kullanışlıdır.\n\nUygulama, verilerinizi saklamak için herhangi bir bulut hizmeti kullanmaz."),
        "exportImportErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Dışa Aktarma / İçe Aktarma hatası"),
        "exportImportSuccessLabel": MessageLookupByLibrary.simpleMessage(
            "Dışa Aktarma / İçe Aktarma başarılı"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("yağ"),
        "fatLabelShort": MessageLookupByLibrary.simpleMessage("y"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("lif"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("ft"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("kadın"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("Cinsiyet"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("erkek"),
        "genderNonBinaryLabel":
            MessageLookupByLibrary.simpleMessage("ikili olmayan"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("Kilo Al"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("Hedef"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("Kilo Ver"),
        "goalMaintainWeight": MessageLookupByLibrary.simpleMessage("Kilo Koru"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("Boy"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("Ana Sayfa"),
        "importAction": MessageLookupByLibrary.simpleMessage("İçe Aktar"),
        "importActivityConfirmContent":
            MessageLookupByLibrary.simpleMessage("Bu aktiviteler bugüne eklenecek."),
        "importActivityConfirmTitle": m19,
        "importActivityLabel":
            MessageLookupByLibrary.simpleMessage("Paylaşılan antrenmanı içe aktar"),
        "importActivitySuccessLabel":
            MessageLookupByLibrary.simpleMessage("Antrenman içe aktarıldı"),
        "importCustomFoodDataDescription": MessageLookupByLibrary.simpleMessage(
            "Kendi yemeklerinizi bir CSV dosyasından veya JSON yapıştırarak içe aktarın. Beklenen şekli ve zorunlu alanları görmek için bir örnek indirin."),
        "importCustomFoodDataLabel": MessageLookupByLibrary.simpleMessage(
            "Özel Gıda Verilerini İçe Aktar"),
        "importMealConfirmContent": m4,
        "importMealConfirmTitle": m5,
        "importMealErrorLabel":
            MessageLookupByLibrary.simpleMessage("Invalid QR code"),
        "importMealLabel":
            MessageLookupByLibrary.simpleMessage("Import shared meal"),
        "importMealSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Meal imported"),
        "importMealsCsvAction":
            MessageLookupByLibrary.simpleMessage("Yemekleri içe aktar (csv)"),
        "importOffFetchFailedLabel": m6,
        "importRecipeConfirmContent": m16,
        "importRecipeErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Tarif kodu çözümlenemedi"),
        "importRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Tarifi içe aktar"),
        "importRecipeSuccessLabel":
            MessageLookupByLibrary.simpleMessage("Tarif içe aktarıldı"),
        "importRecipesCsvAction":
            MessageLookupByLibrary.simpleMessage("Tarifleri içe aktar (csv)"),
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("Yeni aktivite eklendi"),
        "infoAddedIntakeLabel":
            MessageLookupByLibrary.simpleMessage("Yeni alım eklendi"),
        "ironLabel": MessageLookupByLibrary.simpleMessage("demir"),
        "itemDeletedSnackbar":
            MessageLookupByLibrary.simpleMessage("Öğe silindi"),
        "itemUpdatedSnackbar":
            MessageLookupByLibrary.simpleMessage("Öğe güncellendi"),
        "kcalExceededLabel": MessageLookupByLibrary.simpleMessage("kcal aşıldı"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("kcal"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("kalan kcal"),
        "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("fazla kcal"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("kg"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("lbs"),
        "lunchExample": MessageLookupByLibrary.simpleMessage(
            "ör. pizza, salata, pirinç ..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("Öğle Yemeği"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("Makro besin Dağılımı:"),
        "magnesiumLabel": MessageLookupByLibrary.simpleMessage("magnezyum"),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("Markalar"),
        "mealCarbsLabel":
            MessageLookupByLibrary.simpleMessage("karbonhidrat başına"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("yağ başına"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("kcal başına"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("Yemek adı"),
        "mealNameValidationError": MessageLookupByLibrary.simpleMessage(
            "Yemek adı en az bir harf içermelidir"),
        "mealNutrientsPerQtyLabel": m10,
        "mealNutrientsTotalLabel":
            MessageLookupByLibrary.simpleMessage("Toplam miktar"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("protein başına 100 g/ml"),
        "mealSizeLabel":
            MessageLookupByLibrary.simpleMessage("Yemek boyutu (g/ml)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Yemek boyutu (oz/fl oz)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("Yemek birimi"),
        "micronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mikro besinler"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo": MessageLookupByLibrary.simpleMessage(
            "Üründe gerekli kcal veya makro besin bilgileri eksik"),
        "monounsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("tekli doymamış yağ"),
        "newCustomMealLabel":
            MessageLookupByLibrary.simpleMessage("Yeni Özel Yiyecek"),
        "niacinLabel": MessageLookupByLibrary.simpleMessage("niasin (B3)"),
        "noActivityRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Son zamanlarda eklenen aktivite yok"),
        "noMealsRecentlyAddedLabel": MessageLookupByLibrary.simpleMessage(
            "Son zamanlarda eklenen yemek yok"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("Sonuç bulunamadı"),
        "notAvailableLabel":
            MessageLookupByLibrary.simpleMessage("Mevcut Değil"),
        "nothingAddedLabel":
            MessageLookupByLibrary.simpleMessage("Hiçbir şey eklenmedi"),
        "nutritionInfoLabel":
            MessageLookupByLibrary.simpleMessage("Beslenme Bilgileri"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("Normal Kilo"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("Obezite Sınıf I"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("Obezite Sınıf II"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("Obezite Sınıf III"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("Obezite Öncesi"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("Ortalama"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("Artmış"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow": MessageLookupByLibrary.simpleMessage(
            "Düşük \n(ancak diğer \nklinik sorunların riski artmış)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("Orta"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("Şiddetli"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("Çok şiddetli"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("Düşük Kilolu"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Bu uygulama tarafından size sağlanan veriler Open Food Facts veritabanından alınmaktadır. Sağlanan bilgilerin doğruluğu, eksiksizliği veya güvenilirliği konusunda hiçbir garanti verilmemektedir. Veriler \"olduğu gibi\" sağlanır ve verilerin kullanımıyla ilgili herhangi bir zarardan verilerin kaynağı (Open Food Facts) sorumlu tutulamaz."),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage(
                "Ne kadar aktifsiz? (antrenmanlar hariç)"),
        "onboardingBirthdayHint":
            MessageLookupByLibrary.simpleMessage("Tarih Girin"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Doğum gününüz ne zaman?"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("Doğum Günü"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Cinsiyetiniz nedir?"),
        "onboardingGoalQuestionSubtitle": MessageLookupByLibrary.simpleMessage(
            "Mevcut kilo hedefiniz nedir?"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("ör. 170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("ör. 5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Mevcut boyunuz nedir?"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "Başlamak için, uygulamanın günlük kalori hedefinizi hesaplamak için hakkınızda bazı bilgilere ihtiyacı var.\nHakkınızdaki tüm bilgiler cihazınızda güvenli bir şekilde saklanır."),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("günlük kcal"),
        "onboardingNonBinaryDisclaimer": MessageLookupByLibrary.simpleMessage(
            "Non-binary bireyler için yayımlanmış bir kalori temeli bulunmuyor, bu nedenle varsayılan olarak erkek ve kadın formüllerinin ortalamasını kullanıyoruz — bir başlangıç noktası, kesin bir tahmin değil. Ayarlar → Hesaplamalar bölümünden istediğin zaman ince ayar yapabilirsin."),
        "onboardingOverviewLabel":
            MessageLookupByLibrary.simpleMessage("Genel Bakış"),
        "onboardingSaveUserError": MessageLookupByLibrary.simpleMessage(
            "Yanlış giriş, lütfen tekrar deneyin"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("ör. 60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("ör. 132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("Mevcut kilonuz nedir?"),
        "onboardingWelcomeLabel":
            MessageLookupByLibrary.simpleMessage("Hoş geldiniz"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("Doğru boy girin"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("Doğru kilo girin"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("Kalori hedefiniz:"),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("Makro besin hedefleriniz:"),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paActiveVideoGames":
            MessageLookupByLibrary.simpleMessage("aktif video oyunları"),
        "paActiveVideoGamesDesc":
            MessageLookupByLibrary.simpleMessage("Wii Sports, Dance Dance Revolution, genel"),
        "paAmericanFootballGeneral":
            MessageLookupByLibrary.simpleMessage("futbol"),
        "paAmericanFootballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("dokunmatik, bayrak, genel"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("okçuluk"),
        "paArcheryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("avcılık dışı"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("otomobil yarışı"),
        "paAutoRacingDesc":
            MessageLookupByLibrary.simpleMessage("açık tekerlek"),
        "paBackpackingGeneral":
            MessageLookupByLibrary.simpleMessage("sırt çantasıyla gezme"),
        "paBackpackingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("badminton"),
        "paBadmintonGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "sosyal tekler ve çiftler, genel"),
        "paBasketballGeneral":
            MessageLookupByLibrary.simpleMessage("basketbol"),
        "paBasketballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("bisiklet sürme"),
        "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("dağ bisikleti"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("sabit bisiklet"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("bilardo"),
        "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("bowling"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("boks"),
        "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("kum torbası"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("boks"),
        "paBoxingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("ringde, genel"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("broomball"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paCalisthenicsGeneral":
            MessageLookupByLibrary.simpleMessage("kalistenik"),
        "paCalisthenicsGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "hafif veya orta derecede çaba, genel (ör. sırt egzersizleri)"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("kano"),
        "paCanoeingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "kürek çekme, zevk için, genel"),
        "paCatch": MessageLookupByLibrary.simpleMessage("futbol veya beyzbol"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("yakalama oyunu"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("amigo"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage(
            "jimnastik hareketleri, rekabetçi"),
        "paChildrenGame":
            MessageLookupByLibrary.simpleMessage("çocuk oyunları"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "(ör. seksek, 4-kare, dodgeball, oyun alanı aletleri, t-ball, tetherball, misket, arcade oyunları), orta derecede çaba"),
        "paClimbingHillsNoLoadGeneral":
            MessageLookupByLibrary.simpleMessage("tepe tırmanma, yük yok"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("yük yok"),
        "paCricket": MessageLookupByLibrary.simpleMessage("kriket"),
        "paCricketDesc":
            MessageLookupByLibrary.simpleMessage("vuruş, bowling, saha"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("kroket"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paCrossCountrySkiing":
            MessageLookupByLibrary.simpleMessage("kayaklı koşu"),
        "paCrossCountrySkiingDesc":
            MessageLookupByLibrary.simpleMessage("kayaklı koşu, genel"),
        "paCurling": MessageLookupByLibrary.simpleMessage("curling"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paDancingAerobicGeneral":
            MessageLookupByLibrary.simpleMessage("aerobik"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paDancingGeneral": MessageLookupByLibrary.simpleMessage("genel dans"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "ör. disko, halk, İrlanda step dansı, hat dansı, polka, contra, country"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("dart"),
        "paDartsWallDesc":
            MessageLookupByLibrary.simpleMessage("duvar veya çim"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("dalış"),
        "paDivingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "deri dalışı, scuba dalışı, genel"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("dalış"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("trambolin veya platform"),
        "paFencing": MessageLookupByLibrary.simpleMessage("eskrim"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("frisbee oyunu"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("golf"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paGymnasticsGeneral":
            MessageLookupByLibrary.simpleMessage("jimnastik"),
        "paGymnasticsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("hacky sack"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("hentbol"),
        "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("yelken kanat"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHeadingBicycling":
            MessageLookupByLibrary.simpleMessage("bisiklet sürme"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("koşullandırma egzersizi"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("dans"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("koşu"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("spor"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("yürüyüş"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("su aktiviteleri"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("kış aktiviteleri"),
        "paHighIntensityIntervalExercise": MessageLookupByLibrary.simpleMessage(
            "yüksek yoğunluklu interval antrenman"),
        "paHighIntensityIntervalExerciseDesc":
            MessageLookupByLibrary.simpleMessage("orta düzeyde efor"),
        "paHighIntensityIntervalExerciseVigorous":
            MessageLookupByLibrary.simpleMessage(
                "yüksek yoğunluklu interval antrenman"),
        "paHighIntensityIntervalExerciseVigorousDesc":
            MessageLookupByLibrary.simpleMessage(
                "burpees, dağcı, squat jump, Tabata, yüksek efor"),
        "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("yürüyüş"),
        "paHikingCrossCountryDesc":
            MessageLookupByLibrary.simpleMessage("kırsal alan"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("çim hokeyi"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paHorseRidingGeneral":
            MessageLookupByLibrary.simpleMessage("at binme"),
        "paHorseRidingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paIceHockeyGeneral":
            MessageLookupByLibrary.simpleMessage("buz hokeyi"),
        "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paIceSkatingGeneral":
            MessageLookupByLibrary.simpleMessage("buz pateni"),
        "paIceSkatingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("jai alai"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("koşu"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("jonglörlük"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("kano"),
        "paKayakingModerateDesc":
            MessageLookupByLibrary.simpleMessage("orta derecede çaba"),
        "paKickball": MessageLookupByLibrary.simpleMessage("kickball"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("lakros"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("çim bowling"),
        "paLawnBowlingDesc":
            MessageLookupByLibrary.simpleMessage("bocce topu, açık hava"),
        "paMartialArtsModerate":
            MessageLookupByLibrary.simpleMessage("dövüş sanatları"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "farklı tipler, orta tempo (ör. judo, jujitsu, karate, kick boxing, tae kwan do, tai-bo, Muay Thai boks)"),
        "paMartialArtsSlower":
            MessageLookupByLibrary.simpleMessage("dövüş sanatları"),
        "paMartialArtsSlowerDesc": MessageLookupByLibrary.simpleMessage(
            "farklı tipler, daha yavaş tempo, acemi performansçılar, pratik"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("moto-kros"),
        "paMotoCrossDesc": MessageLookupByLibrary.simpleMessage(
            "arazi motor sporları, arazi aracı, genel"),
        "paMountainClimbing": MessageLookupByLibrary.simpleMessage("tırmanma"),
        "paMountainClimbingDesc":
            MessageLookupByLibrary.simpleMessage("kaya veya dağ tırmanışı"),
        "paNordicWalking":
            MessageLookupByLibrary.simpleMessage("nordik yürüyüş"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("oryantiring"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paPaddleBoarding":
            MessageLookupByLibrary.simpleMessage("kürek tahtası"),
        "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("ayakta"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("pedallı tekne"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage("paddleball"),
        "paPaddleballDesc":
            MessageLookupByLibrary.simpleMessage("rahat, genel"),
        "paPickleball": MessageLookupByLibrary.simpleMessage("pickleball"),
        "paPilates": MessageLookupByLibrary.simpleMessage("pilates"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("polo"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("at üzerinde"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("raketbol"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paResistanceTraining":
            MessageLookupByLibrary.simpleMessage("direnç antrenmanı"),
        "paResistanceTrainingDesc": MessageLookupByLibrary.simpleMessage(
            "ağırlık kaldırma, serbest ağırlık, nautilus veya evrensel"),
        "paResistanceTrainingVigorous":
            MessageLookupByLibrary.simpleMessage("direnç antrenmanı (yoğun)"),
        "paResistanceTrainingVigorousDesc":
            MessageLookupByLibrary.simpleMessage("yoğun çaba, powerlifting veya bodybuilding"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("rodeo sporları"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("genel, orta derecede çaba"),
        "paRollerbladingLight":
            MessageLookupByLibrary.simpleMessage("patenle kayma"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("sıralı paten"),
        "paRopeJumpingGeneral":
            MessageLookupByLibrary.simpleMessage("ip atlama"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "orta tempo, 100-120 atlama/dakika, genel, 2 ayak atlama, düz atlama"),
        "paRopeSkippingGeneral":
            MessageLookupByLibrary.simpleMessage("ip atlama"),
        "paRopeSkippingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("birlik, takım, rekabetçi"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("rugby"),
        "paRugbyNonCompetitiveDesc": MessageLookupByLibrary.simpleMessage(
            "dokunmatik, rekabetçi olmayan"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("koşu"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("yelken"),
        "paSailingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "tekne ve tahta yelken, rüzgar sörfü, buz yelken, genel"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("shuffleboard"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSkateboardingGeneral":
            MessageLookupByLibrary.simpleMessage("kaykay"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel, orta derecede çaba"),
        "paSkatingRoller": MessageLookupByLibrary.simpleMessage("paten kayma"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("kayak"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSkiingWaterWakeboarding":
            MessageLookupByLibrary.simpleMessage("su kayağı"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("su veya wakeboarding"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("paraşütle atlama"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage(
            "paraşütle atlama, base jumping, bungee jumping"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("şnorkelle dalış"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paSnowShovingModerate":
            MessageLookupByLibrary.simpleMessage("kar küreme"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("elle, orta derecede çaba"),
        "paSnowshoeing":
            MessageLookupByLibrary.simpleMessage("kar ayakkabısı yürüyüşü"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("futbol"),
        "paSoccerGeneralDesc":
            MessageLookupByLibrary.simpleMessage("rahat, genel"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("softbol / beyzbol"),
        "paSoftballBaseballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "hızlı veya yavaş atış, genel"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("squash"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paStretching": MessageLookupByLibrary.simpleMessage("esneme"),
        "paStretchingDesc":
            MessageLookupByLibrary.simpleMessage("hafif, genel"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("sörf"),
        "paSurfingDesc":
            MessageLookupByLibrary.simpleMessage("vücut veya tahta, genel"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("yüzme"),
        "paSwimmingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "su üzerinde durma, orta derecede çaba, genel"),
        "paTableTennisGeneral":
            MessageLookupByLibrary.simpleMessage("masa tenisi"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("masa tenisi, ping pong"),
        "paTaiChiQiGongGeneral":
            MessageLookupByLibrary.simpleMessage("tai chi, qi gong"),
        "paTaiChiQiGongGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("tenis"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("atletizm"),
        "paTrackField1Desc": MessageLookupByLibrary.simpleMessage(
            "(ör. gülle, disk, çekiç atma)"),
        "paTrackField2Desc": MessageLookupByLibrary.simpleMessage(
            "(ör. yüksek atlama, uzun atlama, üçlü atlama, cirit, sırıkla atlama)"),
        "paTrackField3Desc": MessageLookupByLibrary.simpleMessage(
            "(ör. engelli koşu, engelli yarış)"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("trambolin"),
        "paTrampolineLightDesc":
            MessageLookupByLibrary.simpleMessage("eğlence amaçlı"),
        "paTreadmillRunning":
            MessageLookupByLibrary.simpleMessage("koşu bandında koşu"),
        "paTreadmillRunningDesc":
            MessageLookupByLibrary.simpleMessage("koşu bandında, genel"),
        "paUnicyclingGeneral":
            MessageLookupByLibrary.simpleMessage("tek tekerlekli bisiklet"),
        "paUnicyclingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("genel"),
        "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("voleybol"),
        "paVolleyballGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "rekabetçi olmayan, 6 - 9 üyeli takım, genel"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("yürüyüş"),
        "paWalkingForPleasureDesc":
            MessageLookupByLibrary.simpleMessage("zevk için"),
        "paWalkingTheDog":
            MessageLookupByLibrary.simpleMessage("köpeği gezdirmek"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("wallyball"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWaterAerobics": MessageLookupByLibrary.simpleMessage("su egzersizi"),
        "paWaterAerobicsDesc":
            MessageLookupByLibrary.simpleMessage("su aerobiği, su kalistenik"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("su topu"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWaterVolleyball":
            MessageLookupByLibrary.simpleMessage("su voleybolu"),
        "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("su aerobiği"),
        "paWateraerobicsCalisthenicsDesc":
            MessageLookupByLibrary.simpleMessage("su aerobiği, su kalistenik"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("güreş"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("genel"),
        "palActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "iş yerinde çoğunlukla ayakta durma veya yürüme ve aktif serbest zaman aktiviteleri"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("Aktif"),
        "palLowActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ör. iş yerinde oturma veya ayakta durma ve hafif serbest zaman aktiviteleri"),
        "palLowLActiveLabel":
            MessageLookupByLibrary.simpleMessage("Düşük Aktif"),
        "palSedentaryDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "ör. ofis işi ve çoğunlukla oturarak geçirilen serbest zaman aktiviteleri"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("Hareketsiz"),
        "palVeryActiveDescriptionLabel": MessageLookupByLibrary.simpleMessage(
            "iş yerinde çoğunlukla yürüme, koşma veya ağırlık taşıma ve aktif serbest zaman aktiviteleri"),
        "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("Çok Aktif"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage(
            "Paylaşılan yemek kodunu buraya yapıştırın"),
        "pasteCodeLabel":
            MessageLookupByLibrary.simpleMessage("Kodu yapıştır"),
        "per100gmlLabel":
            MessageLookupByLibrary.simpleMessage("100g/ml başına"),
        "perServingLabel":
            MessageLookupByLibrary.simpleMessage("Porsiyon Başına"),
        "phosphorusLabel": MessageLookupByLibrary.simpleMessage("fosfor"),
        "polyunsaturatedFatLabel": MessageLookupByLibrary.simpleMessage("çoklu doymamış yağ"),
        "potassiumLabel": MessageLookupByLibrary.simpleMessage("potasyum"),
        "privacyPolicyLabel":
            MessageLookupByLibrary.simpleMessage("Gizlilik politikası"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("Profil"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("protein"),
        "proteinLabelShort": MessageLookupByLibrary.simpleMessage("p"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("Miktar"),
        "readLabel": MessageLookupByLibrary.simpleMessage(
            "Gizlilik politikasını okudum ve kabul ediyorum."),
        "recentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("Son Eklenenler"),
        "recipeAddIngredientLabel":
            MessageLookupByLibrary.simpleMessage("Malzeme Ekle"),
        "recipeDeleteConfirmContent": MessageLookupByLibrary.simpleMessage(
            "Bu tariften günlüğe eklenen önceki girdiler korunacaktır."),
        "recipeDeleteConfirmTitle":
            MessageLookupByLibrary.simpleMessage("Tarif silinsin mi?"),
        "recipeDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("Açıklama (isteğe bağlı)"),
        "recipeIngredientAmountLabel":
            MessageLookupByLibrary.simpleMessage("Miktar"),
        "recipeIngredientCountLabel": m15,
        "recipeIngredientUnitLabel":
            MessageLookupByLibrary.simpleMessage("Birim"),
        "recipeIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Malzemeler"),
        "recipeInvalidTotalWeightLabel": MessageLookupByLibrary.simpleMessage(
            "Toplam ağırlık sıfırdan büyük olmalı"),
        "recipeLogCtaLabel":
            MessageLookupByLibrary.simpleMessage("Bu Tarifi Kaydet"),
        "recipeNameLabel":
            MessageLookupByLibrary.simpleMessage("Tarif adı"),
        "recipeNameRequiredLabel":
            MessageLookupByLibrary.simpleMessage("Tarif bir ad gerektirir"),
        "recipeNeedsIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("En az bir malzeme ekleyin"),
        "recipeNoIngredientsLabel":
            MessageLookupByLibrary.simpleMessage("Henüz malzeme yok"),
        "recipeNutritionPer100Label":
            MessageLookupByLibrary.simpleMessage("100 g başına"),
        "recipeNutritionPreviewLabel":
            MessageLookupByLibrary.simpleMessage("Beslenme (toplam)"),
        "recipeSaveErrorLabel":
            MessageLookupByLibrary.simpleMessage("Tarif kaydedilemedi."),
        "recipeSaveForLaterDescription": MessageLookupByLibrary.simpleMessage(
            "Bu yemeği bir dahaki sefere kaydedilenler listesinde tutmak için açın. Bir daha yemeyeceğiniz tek seferlik bir yemek için kapalı bırakın."),
        "recipeSaveForLaterLabel":
            MessageLookupByLibrary.simpleMessage("Sonraki için kaydet"),
        "recipeSaveLabel":
            MessageLookupByLibrary.simpleMessage("Tarifi Kaydet"),
        "recipeServingsCountHelper": MessageLookupByLibrary.simpleMessage(
            "Bu tarifi gram yerine porsiyon olarak kaydetmenize olanak tanır."),
        "recipeServingsCountLabel":
            MessageLookupByLibrary.simpleMessage("Porsiyonlar (isteğe bağlı)"),
        "recipeTagsHelper": MessageLookupByLibrary.simpleMessage(
            "Virgülle ayırın, örn. \"kahvaltı, vegan\""),
        "recipeTagsLabel": MessageLookupByLibrary.simpleMessage("Etiketler"),
        "recipeTotalWeightHelper": MessageLookupByLibrary.simpleMessage(
            "Varsayılan olarak malzemelerin toplamı. Sıvılar yaklaşık 1 ml ≈ 1 g olarak hesaplanır."),
        "recipeTotalWeightLabel":
            MessageLookupByLibrary.simpleMessage("Toplam ağırlık (g)"),
        "recipesEmptyHint": MessageLookupByLibrary.simpleMessage(
            "Birden fazla malzemeden bir öğün oluşturun ve diğer yiyecekler gibi yeniden kullanın."),
        "recipesEmptyLabel":
            MessageLookupByLibrary.simpleMessage("Henüz tarif yok"),
        "recipesFilterAllLabel":
            MessageLookupByLibrary.simpleMessage("Tümü"),
        "recipesLabel": MessageLookupByLibrary.simpleMessage("Tarifler"),
        "recipesLoadErrorLabel": MessageLookupByLibrary.simpleMessage(
            "Tarifler yüklenemedi. Lütfen daha sonra tekrar deneyin."),
        "reportErrorDialogText": MessageLookupByLibrary.simpleMessage(
            "Geliştiriciye bir hata bildirmek istiyor musunuz?"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("Tekrar Dene"),
        "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("doymuş yağ"),
        "scanProductLabel": MessageLookupByLibrary.simpleMessage("Ürünü Tara"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage(
            "Lütfen bir arama kelimesi girin"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("Yiyecek"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("Ara"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("Ürünler"),
        "searchResultsLabel":
            MessageLookupByLibrary.simpleMessage("Arama sonuçları"),
        "selectGenderDialogLabel":
            MessageLookupByLibrary.simpleMessage("Cinsiyet Seçin"),
        "selectHeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Boy Seçin"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("Aktivite Seviyesini Seçin"),
        "selectWeightDialogLabel":
            MessageLookupByLibrary.simpleMessage("Kilo Seçin"),
        "selectionCountLabel": m17,
        "sendAnonymousUserData": MessageLookupByLibrary.simpleMessage(
            "Anonim kullanım verileri gönder"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("Porsiyon"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("Porsiyon boyutu (oz/fl oz)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("Porsiyon boyutu (g/ml)"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("Hakkında"),
        "settingFeedbackLabel":
            MessageLookupByLibrary.simpleMessage("Geri Bildirim"),
        "settingsCalculationsLabel":
            MessageLookupByLibrary.simpleMessage("Hesaplamalar"),
        "settingsCustomMealsLabel":
            MessageLookupByLibrary.simpleMessage("Özel Yemekler"),
        "settingsDisclaimerLabel":
            MessageLookupByLibrary.simpleMessage("Sorumluluk Reddi"),
        "settingsSourcesLabel":
            MessageLookupByLibrary.simpleMessage("Kaynaklar ve Referanslar"),
        "sourcesIconTooltip":
            MessageLookupByLibrary.simpleMessage("Kaynakları görüntüle"),
        "sourcesScreenIntro": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker, gösterdiği her hesaplama için yerleşik ve hakemli yöntemler kullanır. Aşağıdaki kaynaklar orijinal yayınlara bağlanır, böylece her değeri kendin doğrulayabilirsin."),
        "sourcesEnergyTitle": MessageLookupByLibrary.simpleMessage(
            "Enerji ihtiyacı (TDEE, BMR ve aktivite düzeyi)"),
        "sourcesEnergyDescription": MessageLookupByLibrary.simpleMessage(
            "Günlük kalori hedefleri, bazal metabolizma hızı ve fiziksel aktivite katsayıları Institute of Medicine denklemlerine dayanır. Kaynak: Institute of Medicine (2005). Dietary Reference Intakes for Energy, Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and Amino Acids, Bölüm 5 ve Tablo 5-5."),
        "sourcesBmiTitle":
            MessageLookupByLibrary.simpleMessage("Vücut Kitle İndeksi (BMI)"),
        "sourcesBmiDescription": MessageLookupByLibrary.simpleMessage(
            "BMI, kilogram cinsinden vücut ağırlığının metre cinsinden boyun karesine (m²) bölünmesiyle hesaplanır. Sağlık kategorileri (zayıf, normal, fazla kilolu, sınıf I–III obezite) Dünya Sağlık Örgütü\'nün yetişkin BMI sınıflandırmasına uyar."),
        "sourcesMacrosTitle":
            MessageLookupByLibrary.simpleMessage("Makro besin dağılımı"),
        "sourcesMacrosDescription": MessageLookupByLibrary.simpleMessage(
            "%60 karbonhidrat, %25 yağ ve %15 protein şeklindeki varsayılan dağılım, DSÖ\'nün önerdiği nüfus besin alımı aralıkları içinde kalır. Ayarlar → Hesaplamalar bölümünden değiştirebilirsin. Kaynak: WHO Technical Report Series 916 (2003), Diet, Nutrition and the Prevention of Chronic Diseases."),
        "sourcesActivityTitle":
            MessageLookupByLibrary.simpleMessage("Aktivite kalorileri (MET değerleri)"),
        "sourcesActivityDescription": MessageLookupByLibrary.simpleMessage(
            "Bir aktivite sırasında yakılan kaloriler, Adult Compendium of Physical Activities\'teki değerler kullanılarak MET × vücut ağırlığı (kg) × süre (saat) olarak tahmin edilir."),
        "sourcesNonBinaryTitle": MessageLookupByLibrary.simpleMessage(
            "Non-binary kişiler için kalori tahmini"),
        "sourcesNonBinaryDescription": MessageLookupByLibrary.simpleMessage(
            "Enerji harcaması üzerine yapılan araştırmalar tarihsel olarak yalnızca ikili cinsiyet kategorilerini kullanmıştır; bu nedenle non-binary kişiler için doğrulanmış tek bir TDEE formülü yoktur. Bu yüzden OpenNutriTracker, Ayarlar → Hesaplamalar bölümünde ortalanmış bir referans, östrojen-tipik bir referans ve testosteron-tipik bir referans arasında seçim yapmanı sağlar. Bakımın için kesin bir değer gerçekten önemliyse lütfen hormon durumunu bilen bir klinisyenle görüş."),
        "sourcesOpenSourceLabel":
            MessageLookupByLibrary.simpleMessage("Kaynağı aç"),
        "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("Mesafe"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("İmperial (lbs, ft, oz)"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("Ayarlar"),
        "settingsLanguageLabel": MessageLookupByLibrary.simpleMessage("Dil"),
        "settingsLicensesLabel":
            MessageLookupByLibrary.simpleMessage("Lisanslar"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("Kütle"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("Metrik (kg, cm, ml)"),
        "settingsNotificationsLabel":
            MessageLookupByLibrary.simpleMessage("Günlük Hatırlatıcı"),
        "settingsNotificationsTimeLabel": m11,
        "notificationsPermissionDeniedSnack":
            MessageLookupByLibrary.simpleMessage("Bildirim izni reddedildi."),
        "notificationsDailyReminderTitle":
            MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "notificationsDailyReminderBody":
            MessageLookupByLibrary.simpleMessage("Bugün öğünlerinizi kaydetmeyi unutmayın!"),
        "settingsPrivacySettings":
            MessageLookupByLibrary.simpleMessage("Gizlilik Ayarları"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("Hata Bildir"),
        "settingsShowActivityTracking":
            MessageLookupByLibrary.simpleMessage("Aktivite takibini göster"),
        "settingsShowMealMacros":
            MessageLookupByLibrary.simpleMessage("Öğün makrolarını göster"),
        "settingsShowMicronutrientsLabel": MessageLookupByLibrary.simpleMessage("Mikro besinleri göster"),
        "settingsSourceCodeLabel":
            MessageLookupByLibrary.simpleMessage("Kaynak Kodu"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("Sistem"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("Koyu"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("Tema"),
        "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("Açık"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("Sistem varsayılanı"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("Birimler"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("Hacim"),
        "shareActivityLabel":
            MessageLookupByLibrary.simpleMessage("Antrenmanı paylaş"),
        "shareCodeLabel": MessageLookupByLibrary.simpleMessage("Kodu paylaş"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("Share meal"),
        "shareRecipeLabel":
            MessageLookupByLibrary.simpleMessage("Tarifi paylaş"),
        "snackExample": MessageLookupByLibrary.simpleMessage(
            "ör. elma, dondurma, çikolata ..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("Atıştırmalık"),
        "sodiumLabel": MessageLookupByLibrary.simpleMessage("sodyum"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("şeker"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("tüketilen"),
        "transFatLabel": MessageLookupByLibrary.simpleMessage("trans yağ"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("Birim"),
        "vitaminALabel": MessageLookupByLibrary.simpleMessage("A vitamini"),
        "vitaminB12Label": MessageLookupByLibrary.simpleMessage("B12 vitamini"),
        "vitaminB6Label": MessageLookupByLibrary.simpleMessage("B6 vitamini"),
        "vitaminCLabel": MessageLookupByLibrary.simpleMessage("C vitamini"),
        "vitaminDLabel": MessageLookupByLibrary.simpleMessage("D vitamini"),
        "warningLabel": MessageLookupByLibrary.simpleMessage("Uyarı"),
        "weeklyWeightGoalKgPerWeek": m8,
        "weeklyWeightGoalLabel":
            MessageLookupByLibrary.simpleMessage("Haftalık oran"),
        "weeklyWeightGoalLbsPerWeek": m9,
        "weeklyWeightGoalNoneLabel":
            MessageLookupByLibrary.simpleMessage("Ayarlanmadı"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("Kilo"),
        "yearsLabel": m3,
        "zincLabel": MessageLookupByLibrary.simpleMessage("çinko"),
      };
}
