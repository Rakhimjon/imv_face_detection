import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6366F1); // Indigo
  static const secondary = Color(0xFFEC4899); // Pink
  static const background = Color(0xFF0F172A); // Slate 900
  static const surface = Color(0xFF1E293B); // Slate 800
  static const text = Color(0xFFF8FAFC); // Slate 50
  static const textSecondary = Color(0xFF94A3B8); // Slate 400
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  
  // Glassmorphism effects
  static final glass = Colors.white.withOpacity(0.1);
  static final glassBorder = Colors.white.withOpacity(0.2);
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors(); // Interface for consistency
}
