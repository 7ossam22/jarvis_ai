import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF0D1117);
  static const cardSurface = Color(0xFF111827);

  static const arcReactorCyan = Color(0xFF00D4FF);
  static const arcReactorGlow = Color(0xFF00FFFF);
  static const ironGold = Color(0xFFFFB300);
  static const ironRed = Color(0xFFFF1744);
  static const ironBlue = Color(0xFF1565C0);

  static const textPrimary = Color(0xFFE0F7FA);
  static const textSecondary = Color(0xFF78909C);
  static const textDim = Color(0xFF37474F);

  static const glowCyan = Color(0x4400D4FF);
  static const glowGold = Color(0x44FFB300);
  static const glowRed = Color(0x44FF1744);

  static LinearGradient get hudGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0A0F), Color(0xFF0D1B2A), Color(0xFF0A0A0F)],
      );

  static LinearGradient get arcGradient => const LinearGradient(
        colors: [arcReactorCyan, arcReactorGlow, ironGold],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
