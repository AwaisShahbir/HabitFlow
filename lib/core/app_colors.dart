import 'package:flutter/material.dart';

/// Design tokens and semantic color definitions for HabitFlow
/// Crafted following HCI principles: high contrast (WCAG AAA), clear visual affordance,
/// and harmonious natural emerald accents.
class AppColors {
  // Brand Emerald Colors
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color primaryGreenDark = Color(0xFF15803D);
  static const Color primaryGreenLight = Color(0xFFDCFCE7);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentGreenGlow = Color(0x4022C55E);

  // Light Theme Surfaces (Soft, clean, non-glaring off-white)
  static const Color lightBackground = Color(0xFFF8FAF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F4F1);
  static const Color borderLight = Color(0xFFE5E9E5);
  static const Color dividerLight = Color(0xFFEDF2ED);

  // Dark Theme Surfaces (Deep obsidian & slate for high OLED contrast)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF2D3B4E);
  static const Color dividerDark = Color(0xFF1E293B);

  // Typography Colors (Light Mode)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Typography Colors (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Category Colors & Pastel Background Tints
  static const Color categoryHealth = Color(0xFF2563EB); // Water / Blue
  static const Color categoryHealthBg = Color(0xFFEFF6FF);

  static const Color categoryFitness = Color(0xFFEA580C); // Gym / Orange
  static const Color categoryFitnessBg = Color(0xFFFFF7ED);

  static const Color categoryLearning = Color(0xFF7C3AED); // Reading / Purple
  static const Color categoryLearningBg = Color(0xFFF5F3FF);

  static const Color categoryMindfulness = Color(0xFFD97706); // Meditate / Amber
  static const Color categoryMindfulnessBg = Color(0xFFFFFBEB);

  static const Color categoryProductivity = Color(0xFF059669); // Productivity / Emerald
  static const Color categoryProductivityBg = Color(0xFFECFDF5);

  static const Color categoryPersonal = Color(0xFF0284C7); // Sky
  static const Color categoryPersonalBg = Color(0xFFF0F9FF);

  static const Color categoryOther = Color(0xFF64748B); // Slate
  static const Color categoryOtherBg = Color(0xFFF8FAFC);

  // Status & Semantic Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
