class FDCConst {
  static const _pageSize = "20";

  // URL
  static const fdcWebsiteUrl = "https://fdc.nal.usda.gov/fdc-app.html#";
  static const _fdcFoodDetailPath = "/food-details/";
  static const _fdcFoodDetailNutrientsPath = "/nutrients";
  static const _fdcBaseUrl = "api.nal.usda.gov";
  static const _fdcFoodSearchPath = "/fdc/v1/foods/search";

  static const _fdcQueryTag = "query";
  static const _fdcPageSizeTag = "pageSize";
  static const _fdcDataTypeTag = "dataType";

  // static const _fdcDataTypeBrandedValue = "Branded";
  static const _fdcDataTypeFoundationValue = "Foundation";
  static const _fdcDataTypeSRLegacyValue = "SR Legacy";
  static const _fdcSortOrderTag = "sortOrder";
  static const _fdcSortOrderAscValue = "asc";
  static const _fdcApiKeyTag = "api_key";

  static const _dataTypeParams = [
    _fdcDataTypeFoundationValue,
    _fdcDataTypeSRLegacyValue
  ];

  static const fdcDefaultUnit = 'g/ml';

  // TODO Make translation keys
  static const Map<int, String> measureUnits = {
    1000: "cup",
    1001: "tablespoon",
    1002: "teaspoon",
    1003: "liter",
    1004: "milliliter",
    1005: "cubic inch",
    1006: "cubic centimeter",
    1007: "gallon",
    1008: "pint",
    1009: "fl oz",
    1010: "paired cooked w",
    1011: "paired raw w",
    1012: "dripping w",
    1013: "bar",
    1014: "bird",
    1015: "biscuit",
    1016: "bottle",
    1017: "box",
    1018: "breast",
    1019: "can",
    1020: "chicken",
    1021: "chop",
    1022: "cookie",
    1023: "container",
    1024: "cracker",
    1025: "drink",
    1026: "drumstick",
    1027: "fillet",
    1028: "fruit",
    1029: "large",
    1030: "lb",
    1031: "leaf",
    1032: "leg",
    1033: "link",
    1034: "links",
    1035: "loaf",
    1036: "medium",
    1037: "muffin",
    1038: "oz",
    1039: "package",
    1040: "packet",
    1041: "patty",
    1042: "patties",
    1043: "piece",
    1044: "pieces",
    1045: "quart",
    1046: "roast",
    1047: "sausage",
    1048: "scoop",
    1049: "serving",
    1050: "slice",
    1051: "slices",
    1052: "small",
    1053: "stalk",
    1054: "steak",
    1055: "stick",
    1056: "strip",
    1057: "tablet",
    1058: "thigh",
    1059: "unit",
    1060: "wedge",
    1061: "orig ckd g",
    1062: "orig rw g",
    1063: "medallion",
    1064: "pie",
    1065: "wing",
    1066: "back",
    1067: "olive",
    1068: "pocket",
    1069: "order",
    1070: "shrimp",
    1071: "each",
    1072: "filet",
    1073: "plantain",
    1074: "nugget",
    1075: "pretzel",
    1076: "corndog",
    1077: "spear",
    1078: "sandwich",
    1079: "tortilla",
    1080: "burrito",
    1081: "taco",
    1082: "tomatoes",
    1083: "chips",
    1084: "shell",
    1085: "bun",
    1086: "crust",
    1087: "sheet",
    1088: "bag",
    1089: "bagel",
    1090: "bowl",
    1091: "breadstick",
    1092: "bulb",
    1093: "cake",
    1094: "carton",
    1095: "chunk",
    1096: "contents",
    1097: "cutlet",
    1098: "doughnut",
    1099: "egg",
    1100: "fish",
    1101: "foreshank",
    1102: "frankfurter",
    1103: "fries",
    1104: "head",
    1105: "jar",
    1106: "loin",
    1107: "pancake",
    1108: "pizza",
    1109: "rack",
    1110: "ribs",
    1111: "roll",
    1112: "shank",
    1113: "shoulder",
    1114: "skin",
    1115: "wafers",
    1116: "wrap",
    1117: "bunch",
    1118: "Tablespoons",
    1119: "Banana",
    1120: "Onion",
    9999: "portion", // undetermined
  };

  static String getFoodDetailUrlString(String? code) {
    if (code == null) {
      return _fdcBaseUrl;
    } else {
      return fdcWebsiteUrl +
          _fdcFoodDetailPath +
          code +
          _fdcFoodDetailNutrientsPath;
    }
  }

  static String _getDataTypeParams() => _dataTypeParams.join(",");

  static Uri getFDCWordSearchUrl(String searchString, String apiKey) {
    final queryParameters = {
      _fdcQueryTag: searchString,
      _fdcPageSizeTag: _pageSize,
      _fdcDataTypeTag: _getDataTypeParams(),
      _fdcSortOrderTag: _fdcSortOrderAscValue,
      _fdcApiKeyTag: apiKey
    };

    return Uri.https(_fdcBaseUrl, _fdcFoodSearchPath, queryParameters);
  }

  // Nutriment codes
  static const fdcTotalKcalId = 1008;
  static const fdcKcalAtwaterGeneralId = 957;
  static const fdcKcalAtwaterSpecificId = 958;
  static const fdcTotalCarbsId = 1005;
  static const fdcTotalFatId = 1004;
  static const fdcTotalProteinsId = 1003;
  static const fdcTotalSugarId = 1063;
  static const fdcTotalSaturatedFatId = 1258;
  static const fdcTotalDietaryFiberId = 1079;

  // Measure unit codes
  static const fdcPortionServingId = 1049;
  static const fdcPortionUnknownId = 9999;
}
