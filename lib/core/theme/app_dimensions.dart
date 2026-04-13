import 'package:flutter/material.dart';

class AppDim {
  // Spacing (8px grid)
  static const xs   = 4.0;
  static const sm   = 8.0;
  static const md   = 16.0;
  static const lg   = 24.0;
  static const xl   = 32.0;
  static const xxl  = 48.0;

  // Border radius
  static const radiusXs   = BorderRadius.all(Radius.circular(4));
  static const radiusSm   = BorderRadius.all(Radius.circular(8));
  static const radiusMd   = BorderRadius.all(Radius.circular(12));
  static const radiusLg   = BorderRadius.all(Radius.circular(16));
  static const radiusXl   = BorderRadius.all(Radius.circular(24));
  static const radiusFull = BorderRadius.all(Radius.circular(100)); // pill

  // Border width
  static const borderThin   = 1.0;   // card, input idle
  static const borderMedium = 1.5;   // input focused
  static const borderThick  = 2.0;   // aktiv element

  // Elevation (box shadow)
  static const shadowSm = [BoxShadow(color: Color(0x0A000000), blurRadius: 8,  offset: Offset(0, 2))];
  static const shadowMd = [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))];
  static const shadowLg = [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))];
}
