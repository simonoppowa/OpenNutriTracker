import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';

import '../calc/unit_calc.dart';

class ValueValidator{

  static String? heightStringValidator(String? value, String wrongHeightLabel, {bool isImperial = false}){
    if(value == null) return wrongHeightLabel;

    if (isImperial) {
      if (value.isEmpty || !Ranges.feetRegExp.hasMatch(value)) {
        return wrongHeightLabel;
      } else {
        return null;
      }
    } else {
      if (value.isEmpty || !Ranges.cmRegExp.hasMatch(value)) {
        return wrongHeightLabel;
      } else {
        return null;
      }
    }
  }

  static String? weightStringValidator(String? value, String wrongWeightLabel, {bool isImperial = false}){
    if(value == null) return wrongWeightLabel;

    if (isImperial) {
      if (value.isEmpty || !Ranges.lbsRegExp.hasMatch(value)) {
        return wrongWeightLabel;
      } else {
        return null;
      }
    } else {
      if (value.isEmpty || !Ranges.kgRegExp.hasMatch(value)) {
        return wrongWeightLabel;
      } else {
        return null;
      }
    }
  }

  static double? parseHeightInCm(double? height, {bool isImperial = false}){
    if(height == null) return null;
    bool isBelowMin = isImperial ? height < Ranges.minHeightInFeet : height < Ranges.minHeight;
    bool isAboveMax = isImperial ? height > Ranges.maxHeightInFeet : height > Ranges.maxHeight;

    if (isBelowMin || isAboveMax) {
      return null;
    }
    return !isImperial ? height : UnitCalc.feetToCm(height);
  }

  static double? parseWeightInKg(double? weight, {bool isImperial = false}){
    if(weight == null) return null;
    bool isBelowMin = isImperial ? weight < Ranges.minWeightInLbs : weight < Ranges.minWeight;
    bool isAboveMax = isImperial ? weight > Ranges.maxWeightInLbs : weight > Ranges.maxWeight;

    if (isBelowMin || isAboveMax) {
      return null;
    }
    return !isImperial ? weight : UnitCalc.lbsToKg(weight);
  }

  static DateTime getFirstDate(){
    return DateTime.now().subtract(Ranges.maxAge);
  }

  static DateTime getLastDate(){
    return DateTime.now().add(Ranges.maxDurationForBirthdayIntoTheFuture);
  }
}