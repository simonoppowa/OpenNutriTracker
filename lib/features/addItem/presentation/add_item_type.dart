enum AddItemType {
  activityType("Activity"),
  breakfastType("Breakfast"),
  lunchType("Lunch"),
  dinnerType("Dinner"),
  snackType("Snack");

  const AddItemType(this.typeName);

  final String typeName;
}
