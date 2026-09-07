import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';

class AppTextStyles {
  static TextStyle get display => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.25, color: AppColors.neutral900);
  static TextStyle get h1      => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.33, color: AppColors.neutral900);
  static TextStyle get h2      => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.4, color: AppColors.neutral900);
  static TextStyle get h3      => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.33, color: AppColors.neutral900);
  static TextStyle get h4      => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.33, color: AppColors.neutral900);
  
  static TextStyle get bodyLarge  => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.5, color: AppColors.neutral800);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.43, color: AppColors.neutral700);
  static TextStyle get bodySmall  => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2, height: 1.33, color: AppColors.neutral600);
  static TextStyle get bodyExtraSmall => GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 0.3, height: 1.4, color: AppColors.neutral600);
  
  static TextStyle get labelLarge => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.25);
  static TextStyle get labelMedium=> GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.28);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3);
}
