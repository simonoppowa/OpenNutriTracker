class FDCConst {

  static const _pageSize = "10";

  // URL
  static const _fdcWebsiteUrl = "https://api.nal.usda.gov/fdc";
  static const _fdcBaseUrl = "api.nal.usda.gov";
  static const _fdcFoodSearchTag = "/fdc/v1/foods/search";

  static const _fdcQueryTag = "query";
  static const _fdcPageSizeTag = "pageSize";
  static const _fdcDataTypeTag = "dataType";
  static const _fdcDataTypeBrandedValue = "Branded";
  static const _fdcDataTypeFoundationValue = "Foundation";
  static const _fdcDataTypeSRLegacyValue = "SR Legacy";
  static const _fdcSortOrderTag = "sortOrder";
  static const _fdcSortOrderAscValue = "asc";
  static const _fdcApiKeyTag = "api_key";

  static const _dataTypeParams = [
    _fdcDataTypeBrandedValue,
    _fdcDataTypeFoundationValue,
    _fdcDataTypeSRLegacyValue
  ];

  static String _getDataTypeParams() => _dataTypeParams.join(",");

  static Uri getFDCWordSearchUrl(String searchString, String apiKey) {
    final queryParameters = {
      _fdcQueryTag: searchString,
      _fdcPageSizeTag: _pageSize,
      _fdcDataTypeTag: _getDataTypeParams(),
      _fdcSortOrderTag: _fdcSortOrderAscValue,
      _fdcApiKeyTag: apiKey
    };

    return Uri.https(_fdcBaseUrl, _fdcFoodSearchTag, queryParameters);
  }

  // Nutriment codes
  static const fdcTotalKcalId = 1008;
  static const fdcTotalCarbsId = 1005;
  static const fdcTotalFatId = 1004;
  static const fdcTotalProteinsId = 1003;
  static const fdcTotalSugarId = 1063;
  static const fdcTotalSaturatedFatId = 1258;
  static const fdcTotalDietaryFiberId = 1079;
}
