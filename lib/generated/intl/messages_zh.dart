// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  static String m0(versionNumber) => "版本 ${versionNumber}";

  static String m1(pctCarbs, pctFats, pctProteins) =>
      "${pctCarbs}% 碳水，${pctFats}% 脂肪，${pctProteins}% 蛋白质";

  static String m2(riskValue) => "并发症风险：${riskValue}";

  static String m3(age) => "${age} 岁";

  static String m4(count) => "导入 ${count} 个项目？";

  static String m5(mealType) => "这些项目将添加到：${mealType}。";

  static String m6(count) => "无法从OpenFoodFacts获取 ${count} 个项目。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "activityExample":
            MessageLookupByLibrary.simpleMessage("例如：跑步、骑车、瑜伽..."),
        "activityLabel": MessageLookupByLibrary.simpleMessage("活动"),
        "addItemLabel": MessageLookupByLibrary.simpleMessage("添加新项目："),
        "addLabel": MessageLookupByLibrary.simpleMessage("添加"),
        "additionalInfoLabelCompendium2011":
            MessageLookupByLibrary.simpleMessage("信息由\n\'2011年体力活动指南\'\n提供"),
        "additionalInfoLabelCustom":
            MessageLookupByLibrary.simpleMessage("自定义餐食项目"),
        "additionalInfoLabelFDC":
            MessageLookupByLibrary.simpleMessage("更多信息请查看\nFoodData Central"),
        "additionalInfoLabelOFF":
            MessageLookupByLibrary.simpleMessage("更多信息请查看\nOpenFoodFacts"),
        "additionalInfoLabelUnknown":
            MessageLookupByLibrary.simpleMessage("未知餐食项目"),
        "ageLabel": MessageLookupByLibrary.simpleMessage("年龄"),
        "allItemsLabel": MessageLookupByLibrary.simpleMessage("全部"),
        "alphaVersionName": MessageLookupByLibrary.simpleMessage("[Alpha]"),
        "appDescription": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker是一款免费开源的卡路里和营养追踪应用，尊重您的隐私。"),
        "appLicenseLabel": MessageLookupByLibrary.simpleMessage("GPL-3.0 许可证"),
        "appTitle": MessageLookupByLibrary.simpleMessage("OpenNutriTracker"),
        "appVersionName": m0,
        "baseQuantityLabel":
            MessageLookupByLibrary.simpleMessage("基础数量 (克/毫升)"),
        "betaVersionName": MessageLookupByLibrary.simpleMessage("[Beta]"),
        "bmiInfo": MessageLookupByLibrary.simpleMessage(
            "体重指数（BMI）是用于分类成人超重和肥胖的指标。它定义为体重（千克）除以身高（米）的平方（kg/m²）。\n\nBMI不区分脂肪和肌肉质量，对某些人可能有误导性。"),
        "bmiLabel": MessageLookupByLibrary.simpleMessage("BMI"),
        "breakfastExample":
            MessageLookupByLibrary.simpleMessage("例如： cereal、牛奶、咖啡..."),
        "breakfastLabel": MessageLookupByLibrary.simpleMessage("早餐"),
        "burnedLabel": MessageLookupByLibrary.simpleMessage("消耗"),
        "buttonNextLabel": MessageLookupByLibrary.simpleMessage("下一步"),
        "buttonResetLabel": MessageLookupByLibrary.simpleMessage("重置"),
        "buttonSaveLabel": MessageLookupByLibrary.simpleMessage("保存"),
        "buttonStartLabel": MessageLookupByLibrary.simpleMessage("开始"),
        "buttonYesLabel": MessageLookupByLibrary.simpleMessage("是"),
        "calculationsMacronutrientsDistributionLabel":
            MessageLookupByLibrary.simpleMessage("宏量营养素分布"),
        "calculationsMacrosDistribution": m1,
        "calculationsRecommendedLabel":
            MessageLookupByLibrary.simpleMessage("（推荐）"),
        "calculationsTDEEIOM2006Label":
            MessageLookupByLibrary.simpleMessage("医学研究所方程式"),
        "calculationsTDEELabel":
            MessageLookupByLibrary.simpleMessage("TDEE方程式"),
        "carbohydrateLabel": MessageLookupByLibrary.simpleMessage("碳水化合物"),
        "carbsLabel": MessageLookupByLibrary.simpleMessage("碳水"),
        "chooseWeightGoalLabel": MessageLookupByLibrary.simpleMessage("选择体重目标"),
        "cmLabel": MessageLookupByLibrary.simpleMessage("厘米"),
        "codeCopiedLabel": MessageLookupByLibrary.simpleMessage("代码已复制"),
        "copyCodeLabel": MessageLookupByLibrary.simpleMessage("复制代码"),
        "copyDialogTitle": MessageLookupByLibrary.simpleMessage("您想复制到哪种餐食类型？"),
        "copyOrDeleteTimeDialogContent": MessageLookupByLibrary.simpleMessage(
            "使用\"复制到今天\"可以将餐食复制到今天。使用\"删除\"可以删除餐食。"),
        "copyOrDeleteTimeDialogTitle":
            MessageLookupByLibrary.simpleMessage("您想做什么？"),
        "createCustomDialogContent":
            MessageLookupByLibrary.simpleMessage("您想创建自定义餐食项目吗？"),
        "createCustomDialogTitle":
            MessageLookupByLibrary.simpleMessage("创建自定义餐食项目？"),
        "dailyKcalAdjustmentLabel":
            MessageLookupByLibrary.simpleMessage("每日卡路里调整："),
        "dataCollectionLabel":
            MessageLookupByLibrary.simpleMessage("通过提供匿名使用数据支持开发"),
        "deleteAllLabel": MessageLookupByLibrary.simpleMessage("删除全部"),
        "deleteTimeDialogContent":
            MessageLookupByLibrary.simpleMessage("您想删除选定的项目吗？"),
        "deleteTimeDialogPluralContent":
            MessageLookupByLibrary.simpleMessage("您想删除此餐食的所有项目吗？"),
        "deleteTimeDialogPluralTitle":
            MessageLookupByLibrary.simpleMessage("删除项目？"),
        "deleteTimeDialogTitle": MessageLookupByLibrary.simpleMessage("删除项目？"),
        "dialogCancelLabel": MessageLookupByLibrary.simpleMessage("取消"),
        "dialogCopyLabel": MessageLookupByLibrary.simpleMessage("复制到今天"),
        "dialogDeleteLabel": MessageLookupByLibrary.simpleMessage("删除"),
        "dialogOKLabel": MessageLookupByLibrary.simpleMessage("确定"),
        "diaryLabel": MessageLookupByLibrary.simpleMessage("日记"),
        "dinnerExample": MessageLookupByLibrary.simpleMessage("例如：汤、鸡肉、葡萄酒..."),
        "dinnerLabel": MessageLookupByLibrary.simpleMessage("晚餐"),
        "disclaimerText": MessageLookupByLibrary.simpleMessage(
            "OpenNutriTracker不是医疗应用程序。提供的所有数据均未经验证，应谨慎使用。请保持健康的生活方式，如有任何问题请咨询专业人士。不建议在患病、怀孕或哺乳期使用。"),
        "editItemDialogTitle": MessageLookupByLibrary.simpleMessage("编辑项目"),
        "editMealLabel": MessageLookupByLibrary.simpleMessage("编辑餐食"),
        "energyLabel": MessageLookupByLibrary.simpleMessage("能量"),
        "errorFetchingProductData":
            MessageLookupByLibrary.simpleMessage("获取产品数据时出错"),
        "errorLoadingActivities":
            MessageLookupByLibrary.simpleMessage("加载活动时出错"),
        "errorMealSave":
            MessageLookupByLibrary.simpleMessage("保存餐食时出错。您是否输入了正确的餐食信息？"),
        "errorOpeningBrowser":
            MessageLookupByLibrary.simpleMessage("打开浏览器应用时出错"),
        "errorOpeningEmail": MessageLookupByLibrary.simpleMessage("打开邮件应用时出错"),
        "errorProductNotFound": MessageLookupByLibrary.simpleMessage("未找到产品"),
        "exportAction": MessageLookupByLibrary.simpleMessage("导出"),
        "exportImportDescription": MessageLookupByLibrary.simpleMessage(
            "您可以将应用数据导出到zip文件并稍后导入。这在您想要备份数据或传输到另一台设备时很有用。\n\n应用不会使用任何云服务存储您的数据。"),
        "exportImportErrorLabel":
            MessageLookupByLibrary.simpleMessage("导出/导入错误"),
        "exportImportLabel": MessageLookupByLibrary.simpleMessage("导出/导入数据"),
        "exportImportSuccessLabel":
            MessageLookupByLibrary.simpleMessage("导出/导入成功"),
        "fatLabel": MessageLookupByLibrary.simpleMessage("脂肪"),
        "fiberLabel": MessageLookupByLibrary.simpleMessage("膳食纤维"),
        "flOzUnit": MessageLookupByLibrary.simpleMessage("fl.oz"),
        "ftLabel": MessageLookupByLibrary.simpleMessage("英尺"),
        "genderFemaleLabel": MessageLookupByLibrary.simpleMessage("♀ 女性"),
        "genderLabel": MessageLookupByLibrary.simpleMessage("性别"),
        "genderMaleLabel": MessageLookupByLibrary.simpleMessage("♂ 男性"),
        "goalGainWeight": MessageLookupByLibrary.simpleMessage("增重"),
        "goalLabel": MessageLookupByLibrary.simpleMessage("目标"),
        "goalLoseWeight": MessageLookupByLibrary.simpleMessage("减重"),
        "goalMaintainWeight": MessageLookupByLibrary.simpleMessage("维持体重"),
        "gramMilliliterUnit": MessageLookupByLibrary.simpleMessage("g/ml"),
        "gramUnit": MessageLookupByLibrary.simpleMessage("g"),
        "heightLabel": MessageLookupByLibrary.simpleMessage("身高"),
        "homeLabel": MessageLookupByLibrary.simpleMessage("主页"),
        "importAction": MessageLookupByLibrary.simpleMessage("导入"),
        "importMealConfirmContent": m5,
        "importMealConfirmTitle": m4,
        "importMealErrorLabel": MessageLookupByLibrary.simpleMessage("无效的二维码"),
        "importMealLabel": MessageLookupByLibrary.simpleMessage("导入分享的餐食"),
        "importMealSuccessLabel": MessageLookupByLibrary.simpleMessage("餐食已导入"),
        "importOffFetchFailedLabel": m6,
        "infoAddedActivityLabel":
            MessageLookupByLibrary.simpleMessage("添加了新活动"),
        "infoAddedIntakeLabel": MessageLookupByLibrary.simpleMessage("添加了新摄入"),
        "itemDeletedSnackbar": MessageLookupByLibrary.simpleMessage("项目已删除"),
        "itemUpdatedSnackbar": MessageLookupByLibrary.simpleMessage("项目已更新"),
        "kcalLabel": MessageLookupByLibrary.simpleMessage("卡路里"),
        "kcalLeftLabel": MessageLookupByLibrary.simpleMessage("剩余卡路里"),
        "kcalTooMuchLabel": MessageLookupByLibrary.simpleMessage("卡路里过多"),
        "kgLabel": MessageLookupByLibrary.simpleMessage("千克"),
        "lbsLabel": MessageLookupByLibrary.simpleMessage("磅"),
        "lunchExample": MessageLookupByLibrary.simpleMessage("例如：披萨、沙拉、米饭..."),
        "lunchLabel": MessageLookupByLibrary.simpleMessage("午餐"),
        "macroDistributionLabel":
            MessageLookupByLibrary.simpleMessage("宏量营养素分布："),
        "mealBrandsLabel": MessageLookupByLibrary.simpleMessage("品牌"),
        "mealCarbsLabel": MessageLookupByLibrary.simpleMessage("碳水每"),
        "mealFatLabel": MessageLookupByLibrary.simpleMessage("脂肪每"),
        "mealKcalLabel": MessageLookupByLibrary.simpleMessage("卡路里每"),
        "mealNameLabel": MessageLookupByLibrary.simpleMessage("餐食名称"),
        "mealProteinLabel":
            MessageLookupByLibrary.simpleMessage("蛋白质每 100 克/毫升"),
        "mealSizeLabel": MessageLookupByLibrary.simpleMessage("餐食大小 (克/毫升)"),
        "mealSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("餐食大小 (盎司/液量盎司)"),
        "mealUnitLabel": MessageLookupByLibrary.simpleMessage("餐食单位"),
        "milliliterUnit": MessageLookupByLibrary.simpleMessage("ml"),
        "missingProductInfo":
            MessageLookupByLibrary.simpleMessage("产品缺少必要的卡路里或宏量营养素信息"),
        "noActivityRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("最近未添加活动"),
        "noMealsRecentlyAddedLabel":
            MessageLookupByLibrary.simpleMessage("最近未添加餐食"),
        "noResultsFound": MessageLookupByLibrary.simpleMessage("未找到结果"),
        "notAvailableLabel": MessageLookupByLibrary.simpleMessage("不可用"),
        "nothingAddedLabel": MessageLookupByLibrary.simpleMessage("未添加任何内容"),
        "nutritionInfoLabel": MessageLookupByLibrary.simpleMessage("营养信息"),
        "nutritionalStatusNormalWeight":
            MessageLookupByLibrary.simpleMessage("正常体重"),
        "nutritionalStatusObeseClassI":
            MessageLookupByLibrary.simpleMessage("肥胖 I 级"),
        "nutritionalStatusObeseClassII":
            MessageLookupByLibrary.simpleMessage("肥胖 II 级"),
        "nutritionalStatusObeseClassIII":
            MessageLookupByLibrary.simpleMessage("肥胖 III 级"),
        "nutritionalStatusPreObesity":
            MessageLookupByLibrary.simpleMessage("超重"),
        "nutritionalStatusRiskAverage":
            MessageLookupByLibrary.simpleMessage("平均"),
        "nutritionalStatusRiskIncreased":
            MessageLookupByLibrary.simpleMessage("增加"),
        "nutritionalStatusRiskLabel": m2,
        "nutritionalStatusRiskLow":
            MessageLookupByLibrary.simpleMessage("低 \n(但其他 \n临床问题风险增加)"),
        "nutritionalStatusRiskModerate":
            MessageLookupByLibrary.simpleMessage("中等"),
        "nutritionalStatusRiskSevere":
            MessageLookupByLibrary.simpleMessage("严重"),
        "nutritionalStatusRiskVerySevere":
            MessageLookupByLibrary.simpleMessage("非常严重"),
        "nutritionalStatusUnderweight":
            MessageLookupByLibrary.simpleMessage("体重过轻"),
        "offDisclaimer": MessageLookupByLibrary.simpleMessage(
            "本应用提供的数据来自Open Food Facts数据库。无法保证所提供信息的准确性、完整性或可靠性。数据按\"原样\"提供，数据的原始来源（Open Food Facts）不对因使用数据而产生的任何损害承担责任。"),
        "onboardingActivityQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("您的活动水平如何？（不包括锻炼）"),
        "onboardingBirthdayHint": MessageLookupByLibrary.simpleMessage("输入日期"),
        "onboardingBirthdayQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("您的生日是什么时候？"),
        "onboardingEnterBirthdayLabel":
            MessageLookupByLibrary.simpleMessage("生日"),
        "onboardingGenderQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("您的性别是什么？"),
        "onboardingGoalQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("您当前的体重目标是什么？"),
        "onboardingHeightExampleHintCm":
            MessageLookupByLibrary.simpleMessage("例如：170"),
        "onboardingHeightExampleHintFt":
            MessageLookupByLibrary.simpleMessage("例如：5.8"),
        "onboardingHeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("您当前的身高是多少？"),
        "onboardingIntroDescription": MessageLookupByLibrary.simpleMessage(
            "开始使用前，应用需要一些关于您的信息来计算您的每日卡路里目标。\n所有关于您的信息都安全存储在您的设备上。"),
        "onboardingKcalPerDayLabel":
            MessageLookupByLibrary.simpleMessage("每日卡路里"),
        "onboardingOverviewLabel": MessageLookupByLibrary.simpleMessage("概览"),
        "onboardingSaveUserError":
            MessageLookupByLibrary.simpleMessage("输入错误，请重试"),
        "onboardingWeightExampleHintKg":
            MessageLookupByLibrary.simpleMessage("例如：60"),
        "onboardingWeightExampleHintLbs":
            MessageLookupByLibrary.simpleMessage("例如：132"),
        "onboardingWeightQuestionSubtitle":
            MessageLookupByLibrary.simpleMessage("您当前的体重是多少？"),
        "onboardingWelcomeLabel": MessageLookupByLibrary.simpleMessage("欢迎使用"),
        "onboardingWrongHeightLabel":
            MessageLookupByLibrary.simpleMessage("请输入正确的身高"),
        "onboardingWrongWeightLabel":
            MessageLookupByLibrary.simpleMessage("请输入正确的体重"),
        "onboardingYourGoalLabel":
            MessageLookupByLibrary.simpleMessage("您的卡路里目标："),
        "onboardingYourMacrosGoalLabel":
            MessageLookupByLibrary.simpleMessage("您的宏量营养素目标："),
        "ozUnit": MessageLookupByLibrary.simpleMessage("oz"),
        "paArcheryGeneral": MessageLookupByLibrary.simpleMessage("射箭"),
        "paArcheryGeneralDesc": MessageLookupByLibrary.simpleMessage("非狩猎"),
        "paAutoRacing": MessageLookupByLibrary.simpleMessage("赛车"),
        "paAutoRacingDesc": MessageLookupByLibrary.simpleMessage("开轮式"),
        "paBackpackingGeneral": MessageLookupByLibrary.simpleMessage("背包旅行"),
        "paBackpackingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paBadmintonGeneral": MessageLookupByLibrary.simpleMessage("羽毛球"),
        "paBadmintonGeneralDesc":
            MessageLookupByLibrary.simpleMessage("社交单打和双打，一般"),
        "paBasketballGeneral": MessageLookupByLibrary.simpleMessage("篮球"),
        "paBasketballGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paBicyclingGeneral": MessageLookupByLibrary.simpleMessage("骑自行车"),
        "paBicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paBicyclingMountainGeneral":
            MessageLookupByLibrary.simpleMessage("山地自行车"),
        "paBicyclingMountainGeneralDesc":
            MessageLookupByLibrary.simpleMessage("一般"),
        "paBicyclingStationaryGeneral":
            MessageLookupByLibrary.simpleMessage("固定自行车"),
        "paBicyclingStationaryGeneralDesc":
            MessageLookupByLibrary.simpleMessage("一般"),
        "paBilliardsGeneral": MessageLookupByLibrary.simpleMessage("台球"),
        "paBilliardsGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paBowlingGeneral": MessageLookupByLibrary.simpleMessage("保龄球"),
        "paBowlingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paBoxingBag": MessageLookupByLibrary.simpleMessage("拳击"),
        "paBoxingBagDesc": MessageLookupByLibrary.simpleMessage("沙袋"),
        "paBoxingGeneral": MessageLookupByLibrary.simpleMessage("拳击"),
        "paBoxingGeneralDesc": MessageLookupByLibrary.simpleMessage("场内，一般"),
        "paBroomball": MessageLookupByLibrary.simpleMessage("扫帚球"),
        "paBroomballDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paCalisthenicsGeneral": MessageLookupByLibrary.simpleMessage("健美操"),
        "paCalisthenicsGeneralDesc":
            MessageLookupByLibrary.simpleMessage("轻度或中度强度，一般（例如：背部练习）"),
        "paCanoeingGeneral": MessageLookupByLibrary.simpleMessage("独木舟"),
        "paCanoeingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("划船，休闲，一般"),
        "paCatch": MessageLookupByLibrary.simpleMessage("足球或棒球"),
        "paCatchDesc": MessageLookupByLibrary.simpleMessage("传球练习"),
        "paCheerleading": MessageLookupByLibrary.simpleMessage("啦啦队"),
        "paCheerleadingDesc": MessageLookupByLibrary.simpleMessage("体操动作，竞技"),
        "paChildrenGame": MessageLookupByLibrary.simpleMessage("儿童游戏"),
        "paChildrenGameDesc": MessageLookupByLibrary.simpleMessage(
            "（例如：跳房子、四人方块、躲避球、 playground器械、T球、 tetherball、弹珠、街机游戏），中等强度"),
        "paClimbingHillsNoLoadGeneral":
            MessageLookupByLibrary.simpleMessage("爬山，无负重"),
        "paClimbingHillsNoLoadGeneralDesc":
            MessageLookupByLibrary.simpleMessage("无负重"),
        "paCricket": MessageLookupByLibrary.simpleMessage("板球"),
        "paCricketDesc": MessageLookupByLibrary.simpleMessage("击球、投球、防守"),
        "paCroquet": MessageLookupByLibrary.simpleMessage("槌球"),
        "paCroquetDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paCurling": MessageLookupByLibrary.simpleMessage("冰壶"),
        "paCurlingDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paDancingAerobicGeneral": MessageLookupByLibrary.simpleMessage("有氧舞蹈"),
        "paDancingAerobicGeneralDesc":
            MessageLookupByLibrary.simpleMessage("一般"),
        "paDancingGeneral": MessageLookupByLibrary.simpleMessage("一般舞蹈"),
        "paDancingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "例如：迪斯科、民间舞、爱尔兰踢踏舞、排舞、波尔卡、对舞、乡村舞"),
        "paDartsWall": MessageLookupByLibrary.simpleMessage("飞镖"),
        "paDartsWallDesc": MessageLookupByLibrary.simpleMessage("墙式或草坪"),
        "paDivingGeneral": MessageLookupByLibrary.simpleMessage("潜水"),
        "paDivingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("自由潜水、水肺潜水，一般"),
        "paDivingSpringboardPlatform":
            MessageLookupByLibrary.simpleMessage("跳水"),
        "paDivingSpringboardPlatformDesc":
            MessageLookupByLibrary.simpleMessage("跳板或跳台"),
        "paFencing": MessageLookupByLibrary.simpleMessage("击剑"),
        "paFencingDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paAmericanFootballGeneral": MessageLookupByLibrary.simpleMessage("美式橄榄球"),
        "paAmericanFootballGeneralDesc": MessageLookupByLibrary.simpleMessage("触身赛、旗式足球，一般"),
        "paFrisbee": MessageLookupByLibrary.simpleMessage("飞盘"),
        "paFrisbeeDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paGolfGeneral": MessageLookupByLibrary.simpleMessage("高尔夫"),
        "paGolfGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paGymnasticsGeneral": MessageLookupByLibrary.simpleMessage("体操"),
        "paGymnasticsGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paHackySack": MessageLookupByLibrary.simpleMessage("踢沙包"),
        "paHackySackDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paHandballGeneral": MessageLookupByLibrary.simpleMessage("手球"),
        "paHandballGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paHangGliding": MessageLookupByLibrary.simpleMessage("悬挂滑翔"),
        "paHangGlidingDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paHeadingBicycling": MessageLookupByLibrary.simpleMessage("骑自行车"),
        "paHeadingConditionalExercise":
            MessageLookupByLibrary.simpleMessage("调节性运动"),
        "paHeadingDancing": MessageLookupByLibrary.simpleMessage("舞蹈"),
        "paHeadingRunning": MessageLookupByLibrary.simpleMessage("跑步"),
        "paHeadingSports": MessageLookupByLibrary.simpleMessage("运动"),
        "paHeadingWalking": MessageLookupByLibrary.simpleMessage("步行"),
        "paHeadingWaterActivities":
            MessageLookupByLibrary.simpleMessage("水上活动"),
        "paHeadingWinterActivities":
            MessageLookupByLibrary.simpleMessage("冬季活动"),
        "paHikingCrossCountry": MessageLookupByLibrary.simpleMessage("徒步"),
        "paHikingCrossCountryDesc": MessageLookupByLibrary.simpleMessage("越野"),
        "paHockeyField": MessageLookupByLibrary.simpleMessage("场地曲棍球"),
        "paHockeyFieldDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paHorseRidingGeneral": MessageLookupByLibrary.simpleMessage("骑马"),
        "paHorseRidingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paIceHockeyGeneral": MessageLookupByLibrary.simpleMessage("冰球"),
        "paIceHockeyGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paIceSkatingGeneral": MessageLookupByLibrary.simpleMessage("滑冰"),
        "paIceSkatingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paJaiAlai": MessageLookupByLibrary.simpleMessage("回力球"),
        "paJaiAlaiDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paJoggingGeneral": MessageLookupByLibrary.simpleMessage("慢跑"),
        "paJoggingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paJuggling": MessageLookupByLibrary.simpleMessage("杂耍"),
        "paJugglingDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paKayakingModerate": MessageLookupByLibrary.simpleMessage("皮划艇"),
        "paKayakingModerateDesc": MessageLookupByLibrary.simpleMessage("中等强度"),
        "paKickball": MessageLookupByLibrary.simpleMessage("踢踢球"),
        "paKickballDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paLacrosse": MessageLookupByLibrary.simpleMessage("长曲棍球"),
        "paLacrosseDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paLawnBowling": MessageLookupByLibrary.simpleMessage("草地滚球"),
        "paLawnBowlingDesc": MessageLookupByLibrary.simpleMessage("室外地掷球"),
        "paMartialArtsModerate": MessageLookupByLibrary.simpleMessage("武术"),
        "paMartialArtsModerateDesc": MessageLookupByLibrary.simpleMessage(
            "不同类型，中等速度（例如：柔道、柔术、空手道、踢拳、跆拳道、跆搏、泰拳）"),
        "paMartialArtsSlower": MessageLookupByLibrary.simpleMessage("武术"),
        "paMartialArtsSlowerDesc":
            MessageLookupByLibrary.simpleMessage("不同类型，较慢速度，初学者，练习"),
        "paMotoCross": MessageLookupByLibrary.simpleMessage("越野摩托车"),
        "paMotoCrossDesc":
            MessageLookupByLibrary.simpleMessage("越野摩托运动，全地形车，一般"),
        "paMountainClimbing": MessageLookupByLibrary.simpleMessage("攀岩"),
        "paMountainClimbingDesc": MessageLookupByLibrary.simpleMessage("攀岩或登山"),
        "paOrienteering": MessageLookupByLibrary.simpleMessage("定向越野"),
        "paOrienteeringDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paPaddleBoarding": MessageLookupByLibrary.simpleMessage("桨板"),
        "paPaddleBoardingDesc": MessageLookupByLibrary.simpleMessage("站立式"),
        "paPaddleBoat": MessageLookupByLibrary.simpleMessage("脚踏船"),
        "paPaddleBoatDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paPaddleball": MessageLookupByLibrary.simpleMessage(" paddleball"),
        "paPaddleballDesc": MessageLookupByLibrary.simpleMessage("休闲，一般"),
        "paPoloHorse": MessageLookupByLibrary.simpleMessage("马球"),
        "paPoloHorseDesc": MessageLookupByLibrary.simpleMessage("骑马"),
        "paRacquetball": MessageLookupByLibrary.simpleMessage("壁球"),
        "paRacquetballDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paResistanceTraining": MessageLookupByLibrary.simpleMessage("阻力训练"),
        "paResistanceTrainingDesc":
            MessageLookupByLibrary.simpleMessage("举重，自由重量，诺德士或万能器材"),
        "paRodeoSportGeneralModerate":
            MessageLookupByLibrary.simpleMessage("牛仔竞技"),
        "paRodeoSportGeneralModerateDesc":
            MessageLookupByLibrary.simpleMessage("一般，中等强度"),
        "paRollerbladingLight": MessageLookupByLibrary.simpleMessage("直排轮滑"),
        "paRollerbladingLightDesc":
            MessageLookupByLibrary.simpleMessage("直排轮滑"),
        "paRopeJumpingGeneral": MessageLookupByLibrary.simpleMessage("跳绳"),
        "paRopeJumpingGeneralDesc": MessageLookupByLibrary.simpleMessage(
            "中等速度，100-120次/分钟，一般，双脚跳，普通弹跳"),
        "paRopeSkippingGeneral": MessageLookupByLibrary.simpleMessage("跳绳"),
        "paRopeSkippingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paRugbyCompetitive": MessageLookupByLibrary.simpleMessage("橄榄球"),
        "paRugbyCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("联盟，团队，竞技"),
        "paRugbyNonCompetitive": MessageLookupByLibrary.simpleMessage("橄榄球"),
        "paRugbyNonCompetitiveDesc":
            MessageLookupByLibrary.simpleMessage("触式，非竞技"),
        "paRunningGeneral": MessageLookupByLibrary.simpleMessage("跑步"),
        "paRunningGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paSailingGeneral": MessageLookupByLibrary.simpleMessage("帆船"),
        "paSailingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("船和板帆船，帆板，冰上帆船，一般"),
        "paShuffleboard": MessageLookupByLibrary.simpleMessage("沙壶球"),
        "paShuffleboardDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paSkateboardingGeneral": MessageLookupByLibrary.simpleMessage("滑板"),
        "paSkateboardingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("一般，中等强度"),
        "paSkatingRoller": MessageLookupByLibrary.simpleMessage("轮滑"),
        "paSkatingRollerDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paSkiingGeneral": MessageLookupByLibrary.simpleMessage("滑雪"),
        "paSkiingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paSkiingWaterWakeboarding": MessageLookupByLibrary.simpleMessage("滑水"),
        "paSkiingWaterWakeboardingDesc":
            MessageLookupByLibrary.simpleMessage("滑水或尾波滑水"),
        "paSkydiving": MessageLookupByLibrary.simpleMessage("跳伞"),
        "paSkydivingDesc": MessageLookupByLibrary.simpleMessage("跳伞，定点跳伞，蹦极"),
        "paSnorkeling": MessageLookupByLibrary.simpleMessage("浮潜"),
        "paSnorkelingDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paSnowShovingModerate": MessageLookupByLibrary.simpleMessage("铲雪"),
        "paSnowShovingModerateDesc":
            MessageLookupByLibrary.simpleMessage("手工，中等强度"),
        "paSoccerGeneral": MessageLookupByLibrary.simpleMessage("足球"),
        "paSoccerGeneralDesc": MessageLookupByLibrary.simpleMessage("休闲，一般"),
        "paSoftballBaseballGeneral":
            MessageLookupByLibrary.simpleMessage("垒球/棒球"),
        "paSoftballBaseballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("快投或慢投，一般"),
        "paSquashGeneral": MessageLookupByLibrary.simpleMessage("壁球"),
        "paSquashGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paSurfing": MessageLookupByLibrary.simpleMessage("冲浪"),
        "paSurfingDesc": MessageLookupByLibrary.simpleMessage("身体或板，一般"),
        "paSwimmingGeneral": MessageLookupByLibrary.simpleMessage("游泳"),
        "paSwimmingGeneralDesc":
            MessageLookupByLibrary.simpleMessage("踩水，中等强度，一般"),
        "paTableTennisGeneral": MessageLookupByLibrary.simpleMessage("乒乓球"),
        "paTableTennisGeneralDesc":
            MessageLookupByLibrary.simpleMessage("乒乓球，桌球"),
        "paTaiChiQiGongGeneral": MessageLookupByLibrary.simpleMessage("太极，气功"),
        "paTaiChiQiGongGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paTennisGeneral": MessageLookupByLibrary.simpleMessage("网球"),
        "paTennisGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paTrackField": MessageLookupByLibrary.simpleMessage("田径"),
        "paTrackField1Desc":
            MessageLookupByLibrary.simpleMessage("（例如：铅球、铁饼、链球）"),
        "paTrackField2Desc":
            MessageLookupByLibrary.simpleMessage("（例如：跳高、跳远、三级跳、标枪、撑杆跳）"),
        "paTrackField3Desc":
            MessageLookupByLibrary.simpleMessage("（例如：障碍跑、跨栏）"),
        "paTrampolineLight": MessageLookupByLibrary.simpleMessage("蹦床"),
        "paTrampolineLightDesc": MessageLookupByLibrary.simpleMessage("娱乐"),
        "paUnicyclingGeneral": MessageLookupByLibrary.simpleMessage("独轮车"),
        "paUnicyclingGeneralDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paVolleyballGeneral": MessageLookupByLibrary.simpleMessage("排球"),
        "paVolleyballGeneralDesc":
            MessageLookupByLibrary.simpleMessage("非竞技，6-9人团队，一般"),
        "paWalkingForPleasure": MessageLookupByLibrary.simpleMessage("步行"),
        "paWalkingForPleasureDesc": MessageLookupByLibrary.simpleMessage("休闲"),
        "paWalkingTheDog": MessageLookupByLibrary.simpleMessage("遛狗"),
        "paWalkingTheDogDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paWallyball": MessageLookupByLibrary.simpleMessage("墙排球"),
        "paWallyballDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paWaterAerobics": MessageLookupByLibrary.simpleMessage("水中运动"),
        "paWaterAerobicsDesc":
            MessageLookupByLibrary.simpleMessage("水中有氧运动，水中健美操"),
        "paWaterPolo": MessageLookupByLibrary.simpleMessage("水球"),
        "paWaterPoloDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paWaterVolleyball": MessageLookupByLibrary.simpleMessage("水中排球"),
        "paWaterVolleyballDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "paWateraerobicsCalisthenics":
            MessageLookupByLibrary.simpleMessage("水中有氧运动"),
        "paWateraerobicsCalisthenicsDesc":
            MessageLookupByLibrary.simpleMessage("水中有氧运动，水中健美操"),
        "paWrestling": MessageLookupByLibrary.simpleMessage("摔跤"),
        "paWrestlingDesc": MessageLookupByLibrary.simpleMessage("一般"),
        "palActiveDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("工作中大部分时间站立或行走，空闲时间活动活跃"),
        "palActiveLabel": MessageLookupByLibrary.simpleMessage("活跃"),
        "palLowActiveDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("例如：工作中坐着或站立，空闲时间活动轻微"),
        "palLowLActiveLabel": MessageLookupByLibrary.simpleMessage("低活跃"),
        "palSedentaryDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("例如：办公室工作，空闲时间大部分坐着"),
        "palSedentaryLabel": MessageLookupByLibrary.simpleMessage("久坐"),
        "palVeryActiveDescriptionLabel":
            MessageLookupByLibrary.simpleMessage("工作中大部分时间行走、跑步或负重，空闲时间活动活跃"),
        "palVeryActiveLabel": MessageLookupByLibrary.simpleMessage("非常活跃"),
        "pasteCodeHint": MessageLookupByLibrary.simpleMessage("在此粘贴分享的餐食代码"),
        "pasteCodeLabel": MessageLookupByLibrary.simpleMessage("粘贴代码"),
        "per100gmlLabel": MessageLookupByLibrary.simpleMessage("每 100克/毫升"),
        "perServingLabel": MessageLookupByLibrary.simpleMessage("每份量"),
        "privacyPolicyLabel": MessageLookupByLibrary.simpleMessage("隐私政策"),
        "profileLabel": MessageLookupByLibrary.simpleMessage("个人资料"),
        "proteinLabel": MessageLookupByLibrary.simpleMessage("蛋白质"),
        "quantityLabel": MessageLookupByLibrary.simpleMessage("数量"),
        "readLabel": MessageLookupByLibrary.simpleMessage("我已阅读并接受隐私政策。"),
        "recentlyAddedLabel": MessageLookupByLibrary.simpleMessage("最近"),
        "reportErrorDialogText":
            MessageLookupByLibrary.simpleMessage("您想向开发者报告错误吗？"),
        "retryLabel": MessageLookupByLibrary.simpleMessage("重试"),
        "saturatedFatLabel": MessageLookupByLibrary.simpleMessage("饱和脂肪"),
        "scanProductLabel": MessageLookupByLibrary.simpleMessage("扫描产品"),
        "searchDefaultLabel": MessageLookupByLibrary.simpleMessage("请输入搜索词"),
        "searchFoodPage": MessageLookupByLibrary.simpleMessage("食物"),
        "searchLabel": MessageLookupByLibrary.simpleMessage("搜索"),
        "searchProductsPage": MessageLookupByLibrary.simpleMessage("产品"),
        "searchResultsLabel": MessageLookupByLibrary.simpleMessage("搜索结果"),
        "selectGenderDialogLabel": MessageLookupByLibrary.simpleMessage("选择性别"),
        "selectHeightDialogLabel": MessageLookupByLibrary.simpleMessage("选择身高"),
        "selectPalCategoryLabel":
            MessageLookupByLibrary.simpleMessage("选择活动水平"),
        "selectWeightDialogLabel": MessageLookupByLibrary.simpleMessage("选择体重"),
        "sendAnonymousUserData":
            MessageLookupByLibrary.simpleMessage("发送匿名使用数据"),
        "servingLabel": MessageLookupByLibrary.simpleMessage("份量"),
        "servingSizeLabelImperial":
            MessageLookupByLibrary.simpleMessage("份量大小 (盎司/液量盎司)"),
        "servingSizeLabelMetric":
            MessageLookupByLibrary.simpleMessage("份量大小 (克/毫升)"),
        "settingAboutLabel": MessageLookupByLibrary.simpleMessage("关于"),
        "settingFeedbackLabel": MessageLookupByLibrary.simpleMessage("反馈"),
        "settingsCalculationsLabel": MessageLookupByLibrary.simpleMessage("计算"),
        "settingsDisclaimerLabel": MessageLookupByLibrary.simpleMessage("免责声明"),
        "settingsDistanceLabel": MessageLookupByLibrary.simpleMessage("距离"),
        "settingsImperialLabel":
            MessageLookupByLibrary.simpleMessage("英制（磅、英尺、盎司）"),
        "settingsLabel": MessageLookupByLibrary.simpleMessage("设置"),
        "settingsLicensesLabel": MessageLookupByLibrary.simpleMessage("许可证"),
        "settingsMassLabel": MessageLookupByLibrary.simpleMessage("质量"),
        "settingsMetricLabel":
            MessageLookupByLibrary.simpleMessage("公制（千克、厘米、毫升）"),
        "settingsPrivacySettings": MessageLookupByLibrary.simpleMessage("隐私设置"),
        "settingsReportErrorLabel":
            MessageLookupByLibrary.simpleMessage("报告错误"),
        "settingsSourceCodeLabel": MessageLookupByLibrary.simpleMessage("源代码"),
        "settingsSystemLabel": MessageLookupByLibrary.simpleMessage("系统"),
        "settingsThemeDarkLabel": MessageLookupByLibrary.simpleMessage("深色"),
        "settingsThemeLabel": MessageLookupByLibrary.simpleMessage("主题"),
        "settingsThemeLightLabel": MessageLookupByLibrary.simpleMessage("浅色"),
        "settingsThemeSystemDefaultLabel":
            MessageLookupByLibrary.simpleMessage("系统默认"),
        "settingsUnitsLabel": MessageLookupByLibrary.simpleMessage("单位"),
        "settingsVolumeLabel": MessageLookupByLibrary.simpleMessage("体积"),
        "shareCodeLabel": MessageLookupByLibrary.simpleMessage("分享代码"),
        "shareMealLabel": MessageLookupByLibrary.simpleMessage("分享餐食"),
        "snackExample":
            MessageLookupByLibrary.simpleMessage("例如：苹果、冰淇淋、巧克力..."),
        "snackLabel": MessageLookupByLibrary.simpleMessage("零食"),
        "sugarLabel": MessageLookupByLibrary.simpleMessage("糖"),
        "suppliedLabel": MessageLookupByLibrary.simpleMessage("提供"),
        "unitLabel": MessageLookupByLibrary.simpleMessage("单位"),
        "weightLabel": MessageLookupByLibrary.simpleMessage("体重"),
        "yearsLabel": m3
      };
}
