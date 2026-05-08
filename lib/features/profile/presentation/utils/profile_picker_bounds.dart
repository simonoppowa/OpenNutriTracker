import 'dart:math';

const _heightRangeCm = 100.0;
const _heightRangeFt = 10.0;
const _weightRangeKg = 50.0;
const _weightRangeLbs = 100.0;
const _minHeight = 1.0;
const _minWeight = 1.0;
const _maxHeightCm = 457.0; // ~15 ft, well above any recorded human height
const _maxHeightFt = 15.0;

double absoluteMaxHeight(bool usesImperialUnits) =>
    usesImperialUnits ? _maxHeightFt : _maxHeightCm;

double minSelectableHeight(double userHeight, bool usesImperialUnits) {
  final range = usesImperialUnits ? _heightRangeFt : _heightRangeCm;
  return max(_minHeight, userHeight - range);
}

double maxSelectableHeight(double userHeight, bool usesImperialUnits) {
  final range = usesImperialUnits ? _heightRangeFt : _heightRangeCm;
  final clampedMin = minSelectableHeight(userHeight, usesImperialUnits);
  final rawMax = userHeight + range;
  return max(clampedMin + range, rawMax);
}

double clampHeightSelection(double selectedHeight, double minHeight) {
  return max(minHeight, selectedHeight);
}

double minSelectableWeight(double userWeight, bool usesImperialUnits) {
  final range = usesImperialUnits ? _weightRangeLbs : _weightRangeKg;
  return max(_minWeight, userWeight - range);
}

double maxSelectableWeight(double userWeight, bool usesImperialUnits) {
  final range = usesImperialUnits ? _weightRangeLbs : _weightRangeKg;
  final minWeight = minSelectableWeight(userWeight, usesImperialUnits);
  final candidateMaxWeight = userWeight + range;
  return max(minWeight + range, candidateMaxWeight);
}

double clampWeightSelection(double selectedWeight, double minWeight) {
  return max(minWeight, selectedWeight);
}
