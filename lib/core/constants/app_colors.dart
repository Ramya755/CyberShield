import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0B1020);
  static const Color surface = Color(0xFF121A2F);
  static const Color card = Color(0xFF18223D);

  static const Color primaryBlue = Color(0xFF4FC3F7);
  static const Color primaryPurple = Color(0xFF9B5DE5);
  static const Color primaryPink = Color(0xFFF15BB5);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8C1D1);
  static const Color errorRed = Color(0xFFFF5A5F);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}