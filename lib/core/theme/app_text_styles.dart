import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get display => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);
  static TextStyle get h1      => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get h2      => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35);
  static TextStyle get h3      => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get bodyLarge  => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.57);
  static TextStyle get bodySmall  => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get labelLarge => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static TextStyle get labelMedium=> GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3);
}
