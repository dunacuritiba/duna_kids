import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Azure Blue Core Palette
  static const Color primaryAzure = Color(0xFF007FFF);      // Pure Azure
  static const Color primaryHover = Color(0xFF0066CC);      // Hover / Pressed
  static const Color azureLight = Color(0xFFE8F3FF);        // Soft Tint
  static const Color azureSubtle = Color(0xFFF0F7FF);       // Surface Accent
  static const Color azureGlow = Color(0x33007FFF);         // Glow / Shadow

  // Angular Modern Slate & Neutrals
  static const Color background = Color(0xFFF8FAFC);       // Slate 50
  static const Color surface = Color(0xFFFFFFFF);          // White
  static const Color surfaceSubtle = Color(0xFFF1F5F9);    // Slate 100
  static const Color border = Color(0xFFE2E8F0);           // Slate 200
  static const Color borderFocused = Color(0xFF007FFF);    // Azure Active
  
  // Typography Hierarchy
  static const Color textPrimary = Color(0xFF0F172A);      // Slate 900
  static const Color textSecondary = Color(0xFF475569);    // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);        // Slate 400

  // Semantic Feedback
  static const Color success = Color(0xFF10B981);          // Emerald 500
  static const Color successSubtle = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);          // Amber 500
  static const Color error = Color(0xFFEF4444);            // Rose 500
  static const Color errorSubtle = Color(0xFFFEF2F2);

  // Angular Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF007FFF),
      Color(0xFF005CE6),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF0F7FF),
      Color(0xFFF8FAFC),
    ],
  );
}
