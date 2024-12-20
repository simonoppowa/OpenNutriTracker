class UnitCalc {
  static double cmToInches(double cm) {
    return cm / 2.54;
  }

  static double inchesToCm(double inches) {
    return inches * 2.54;
  }

  static double cmToFeet(double cm) {
    return cm / 30.48;
  }

  /// Converts feet to centimeters and rounds the result
  static double feetToCm(double feet) {
    return (feet * 30.48).roundToDouble();
  }

  /// Converts feet to inches and rounds the result
  static double kgToLbs(double kg) {
    return (kg * 2.20462).roundToDouble();
  }

  /// Converts pounds to kilograms and rounds the result
  static double lbsToKg(double lbs) {
    return (lbs / 2.20462).roundToDouble();
  }
}
