import 'package:flutter/material.dart';

/// Design Tokens: C2 - Colors
/// Strictly adhering to the 3-4 primary color palette + functional tokens.
class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFF234735); // Forest Green (#234735)
  static const Color secondary = Color(0xFF35624A); // Secondary Green (#35624A)

  // Background & Surface
  static const Color background = Color(0xFFF8F8F3); // Off-white (#F8F8F3)
  static const Color surface = Color(0xFFFFFFFF); // White (#FFFFFF)
  static const Color surfaceMuted = Color(0xFFEFF0EA); // Subtle container fill

  // Typography Colors
  static const Color textCharcoal = Color(0xFF292D2A); // Charcoal main text (#292D2A)
  static const Color textMuted = Color(0xFF5F6B63); // Muted secondary text (#5F6B63)
  static const Color textInverse = Color(0xFFFFFFFF); // White text for primary buttons

  // Structural & Border
  static const Color border = Color(0xFFDCE0D9); // Subtle border
  static const Color borderSubtle = Color(0xFFE9ECE5);

  // Functional / Destructive (Only for errors & delete actions)
  static const Color error = Color(0xFFBA1A1A); // Functional Red
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // Chip neutral container & text
  static const Color chipBackground = Color(0xFFEDF0E8);
  static const Color chipBorder = Color(0xFFCFD5C9);
}
