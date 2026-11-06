import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';

/// 🔤 Typographic System for Strada Pizza
/// Uses Google Fonts Inter with tuned optical tracking, weights, and line-heights.
class AppTextStyles {
  // Displays & Hero Headlines
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.2,
        color: AppColors.neutral900,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
        color: AppColors.neutral900,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
        color: AppColors.neutral900,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.33,
        color: AppColors.neutral900,
      );

  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: AppColors.neutral900,
      );

  // Body Texts
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
        color: AppColors.neutral800,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: AppColors.neutral700,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.35,
        color: AppColors.neutral500,
      );

  static TextStyle get bodyExtraSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
        color: AppColors.neutral500,
      );

  // Action Labels & Buttons
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.28,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
      );

  // Price Display
  static TextStyle get priceLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: AppColors.primary,
      );

  static TextStyle get priceMedium => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
        color: AppColors.primary,
      );

  static TextStyle get priceSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: AppColors.primary,
      );
}
