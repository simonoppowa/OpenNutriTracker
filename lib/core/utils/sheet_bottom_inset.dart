import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The space a bottom sheet keeps clear at its foot: the keyboard while it
/// is up, else the system navigation bar. With edge-to-edge (target SDK 35
/// and up) the bar is drawn over the sheet, so a sheet padded only by the
/// keyboard puts its last button under the bar.
double sheetBottomInset(BuildContext context) => math.max(
  MediaQuery.viewInsetsOf(context).bottom,
  MediaQuery.viewPaddingOf(context).bottom,
);
