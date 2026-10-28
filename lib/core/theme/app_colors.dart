import 'package:flutter/material.dart';

/// Design tokens and semantic color definitions for HabitFlow
class AppColors {
  // Brand Colors (from requirements doc)
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF0FDF4);
  static const Color darkBackground = Color(0xFF111827);

  // Light Theme Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF9FAFB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // Dark Theme Surfaces
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceVariantDark = Color(0xFF374151);
  static const Color borderDark = Color(0xFF374151);
  static const Color dividerDark = Color(0xFF1F2937);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);

  // Category Colors
  static const Color categoryHealth = Color(0xFFEF4444);
  static const Color categoryFitness = Color(0xFFF97316);
  static const Color categoryLearning = Color(0xFF3B82F6);
  static const Color categoryMindfulness = Color(0xFF8B5CF6);
  static const Color categoryProductivity = Color(0xFFEAB308);
  static const Color categoryPersonal = Color(0xFF06B6D4);
  static const Color categoryOther = Color(0xFF64748B);

  // Status & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
