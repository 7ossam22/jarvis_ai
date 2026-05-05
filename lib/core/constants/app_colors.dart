import 'package:flutter/material.dart';

class AppColors {
  // Base & Surfaces
  static const background = Color(0xFFF8FAFC); // Slate 50
  static const surface = Color(0xFFFFFFFF); // White
  static const surfaceHover = Color(0xFFF1F5F9); // Slate 100
  static const cardSurface = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const borderLight = Color(0xFFE2E8F0); // Slate 200
  static const borderMedium = Color(0xFFCBD5E1); // Slate 300

  // Typography & Icons
  static const textPrimary = Color(0xFF0F172A); // Slate 900
  static const textSecondary = Color(0xFF334155); // Slate 700
  static const textMuted = Color(0xFF64748B); // Slate 500
  static const textDisabled = Color(0xFF94A3B8); // Slate 400
  static const textDim = Color(0xFF94A3B8);

  // Brand & Semantic
  static const primary = Color(0xFF1B757A);
  static const primaryLight = Color(0xFF26A69A);
  static const sky500 = Color(0xFF0EA5E9);
  
  static const success = Color(0xFF10B981); // Emerald 500
  static const error = Color(0xFFEF4444); // Rose 500
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const info = Color(0xFF0EA5E9); // Sky 500
  static const indigo = Color(0xFF6366F1); // Indigo 500

  // Legacy/Compatibility (to be refactored)
  static const arcReactorCyan = primary;
  static const arcReactorGlow = primaryLight;
  static const ironGold = warning;
  static const ironRed = error;

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryLight],
      );

  static LinearGradient get surfaceGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surface, background],
      );
}
