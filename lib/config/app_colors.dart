import 'package:flutter/material.dart';

class AppColors {
  // Dark theme backgrounds
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color darkBg2 = Color(0xFF242424);
  static const Color darkBg3 = Color(0xFF2E2E2E);
  
  // Cyan/Turquoise accents
  static const Color cyan = Color(0xFF00BCD4);
  static const Color cyanLight = Color(0xFF4DD0E1);
  static const Color cyanDark = Color(0xFF0097A7);
  
  // Yellow/Gold accents
  static const Color gold = Color(0xFFFFD54F);
  static const Color goldLight = Color(0xFFFFF59D);
  static const Color goldDark = Color(0xFFFBC02D);
  
  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);
  
  // Border colors
  static const Color borderLight = Color(0xFF404040);
  static const Color borderMedium = Color(0xFF505050);
  static const Color borderColor = Color(0xFF404040);
  
  // Additional semantic colors
  static const Color darkSecondaryBg = Color(0xFF242424);
  static const Color errorBg = Color(0xFF5F2C2C);
  
  // Gradients
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF242424),
    ],
  );
}
