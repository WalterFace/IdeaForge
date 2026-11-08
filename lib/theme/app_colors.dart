import 'package:flutter/material.dart';

/// Altitude brand palette.
class AppColors {
  AppColors._();

  static const Color espresso = Color(0xFF241913);
  static const Color oatCream = Color(0xFFFAF5EB);
  static const Color caramel = Color(0xFFD99A52);
  static const Color softGreen = Color(0xFF597661);

  static const Color warmGray = Color(0xFFF2EEE7);
  static const Color warmGrayDark = Color(0xFFE4DDD2);
  static const Color mocha = Color(0xFF5C4033);
  static const Color latte = Color(0xFFC9A77C);
  static const Color cream = Color(0xFFFFFCF6);
  static const Color danger = Color(0xFFB4473A);
  static const Color success = Color(0xFF3F8F5A);
  static const Color info = Color(0xFF3D6B8E);

  static const Color textPrimary = espresso;
  static const Color textSecondary = Color(0xFF6F6259);
  static const Color textMuted = Color(0xFF9C8F84);

  static const LinearGradient espressoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2A20), espresso],
  );

  static const LinearGradient caramelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8B472), caramel],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6E8E78), softGreen],
  );
}
