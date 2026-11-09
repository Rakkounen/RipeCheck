import 'package:flutter/material.dart';

/// Design Tokens: C2 - Spacing Scale
/// Consistent spacing scale for padding, margins, and gaps.
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Minimum Interactive Touch Target (C4 UX Principle: >= 48px)
  static const double minTouchTarget = 48.0;

  // Edge insets presets
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: lg, vertical: sm);
}
