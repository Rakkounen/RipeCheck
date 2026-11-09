import 'package:flutter/material.dart';

/// Design Tokens: C2 & C3 - Corner Radii
/// Reasonable, purposeful border radii. Avoids excessive decorative rounding.
class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 16.0;
  static const double pill = 999.0;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
}
