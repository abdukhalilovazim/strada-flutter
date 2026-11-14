import 'package:flutter/material.dart';

/// 🎨 Central Design Tokens for Pizza Strada
/// Built strictly following the ui-ux-design guidelines:
/// 60-30-10 color rule, high contrast WCAG ratios, soft multi-stop shadows.
class AppColors {
  // Brand Primary (pizzastrada.uz saytidagi olovrang-qizil #FF3E1D)
  static const primary          = Color(0xFFFF3E1D);
  static const primaryDark      = Color(0xFFE6381A);
  static const primaryLight     = Color(0xFFFFF2EF);
  static const primaryGradient  = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF3E1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode Primary
  static const darkPrimary      = Color(0xFFFF4824);
  static const darkPrimaryDark  = Color(0xFFE6381A);
  static const darkPrimaryLight = Color(0xFF38120A);

  // Secondary (Fresh Basil Green / Savings)
  static const secondary        = Color(0xFF16A34A);
  static const secondaryLight   = Color(0xFFF0FDF4);
  static const darkSecondary    = Color(0xFF22C55E);
  static const darkSecondaryLight = Color(0xFF052E16);

  // Semantic
  static const error            = Color(0xFFE11D48);
  static const darkError        = Color(0xFFFB7185);
  static const success          = Color(0xFF16A34A);
  static const darkSuccess      = Color(0xFF22C55E);
  static const warning          = Color(0xFFF59E0B);
  static const darkWarning      = Color(0xFFFBBF24);
  static const info             = Color(0xFF2563EB);
  static const darkInfo         = Color(0xFF60A5FA);

  // Neutral (Warm Slate)
  static const neutral900       = Color(0xFF0F172A); // Main headings
  static const neutral800       = Color(0xFF1E293B); // Secondary headings
  static const neutral700       = Color(0xFF334155); // Body text
  static const neutral600       = Color(0xFF475569); // Muted body text
  static const neutral500       = Color(0xFF64748B); // Captions, descriptions
  static const neutral400       = Color(0xFF94A3B8); // Placeholders, borders
  static const neutral300       = Color(0xFFCBD5E1); // Disabled borders
  static const neutral200       = Color(0xFFE2E8F0); // Light divider lines
  static const neutral100       = Color(0xFFF1F5F9); // Component backgrounds
  static const neutral50        = Color(0xFFF8FAFC); // Screen background canvas

  // Surfaces (Light Mode)
  static const background       = Color(0xFFF8FAFC);
  static const surface          = Color(0xFFF8FAFC);
  static const card             = Color(0xFFFFFFFF);

  // Surfaces (Dark Mode)
  static const darkBackground   = Color(0xFF0B0F19);
  static const darkSurface      = Color(0xFF151C2C);
  static const darkCard         = Color(0xFF151C2C);
  static const darkBorder       = Color(0xFF232E42);

  // Elevation & Shadows
  static List<BoxShadow> softShadow([bool isDark = false]) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryGlow() => [
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
