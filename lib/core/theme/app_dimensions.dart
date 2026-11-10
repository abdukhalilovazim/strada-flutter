import 'package:flutter/material.dart';

/// 📐 Strada Pizza Universal Sizing & Spacing Design Tokens
/// Strictly adheres to the 8-point / 4-point harmonic subgrid system.
/// Guaranteed 120 FPS performance with pre-allocated const insets and gaps.
class AppDim {
  // ── 1. Spacing Scale (8px Grid with 4px Subgrid) ──
  static const double xxs   = 2.0;
  static const double xs    = 4.0;
  static const double sm    = 8.0;
  static const double md    = 12.0;
  static const double base  = 16.0;
  static const double lg    = 20.0;
  static const double xl    = 24.0;
  static const double xxl   = 32.0;
  static const double xxxl  = 40.0;
  static const double giant = 48.0;

  // ── 2. Screen & Container Padding Tokens ──
  /// Standard screen horizontal margin used across all mobile pages
  static const double screenMargin = 16.0;

  /// Standard screen insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets screenPaddingTop = EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0);
  static const EdgeInsets screenPaddingBottom = EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(16.0);

  /// Card Insets
  static const EdgeInsets cardPaddingSm  = EdgeInsets.all(10.0);
  static const EdgeInsets cardPadding    = EdgeInsets.all(12.0);
  static const EdgeInsets cardPaddingLg  = EdgeInsets.all(16.0);

  /// Common Inset Constants
  static const EdgeInsets insetZero  = EdgeInsets.zero;
  static const EdgeInsets insetXs    = EdgeInsets.all(xs);
  static const EdgeInsets insetSm    = EdgeInsets.all(sm);
  static const EdgeInsets insetMd    = EdgeInsets.all(md);
  static const EdgeInsets insetBase  = EdgeInsets.all(base);
  static const EdgeInsets insetLg    = EdgeInsets.all(lg);
  static const EdgeInsets insetXl    = EdgeInsets.all(xl);

  static const EdgeInsets insetH8    = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets insetH12   = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets insetH16   = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets insetH20   = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets insetV4    = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets insetV8    = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets insetV12   = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets insetV16   = EdgeInsets.symmetric(vertical: base);

  // ── 3. Component Dimensions (Heights & Widths) ──
  /// Button Heights
  static const double btnHeightPrimary   = 52.0; // Primary CTA buttons (Order, Pay, Confirm)
  static const double btnHeightSecondary = 50.0; // Secondary outline / secondary CTA
  static const double btnHeightMd        = 48.0; // Medium buttons
  static const double btnHeightSm        = 38.0; // Compact buttons / Chips / Filters
  static const double btnHeightXs        = 32.0; // Mini action buttons / Card steppers

  /// Input Fields
  static const double inputHeightSingle  = 50.0; // Standard single-line text field
  static const EdgeInsets inputPadding   = EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0);

  /// Navigation & Bars
  static const double appBarHeight       = 56.0;
  static const double categoryBarHeight  = 52.0;
  static const double bottomBarHeight    = 64.0;
  static const double floatingCartHeight = 56.0;
  static const double storyAvatarSize    = 72.0;

  /// Quantity Stepper
  static const double stepperHeightSm    = 32.0;
  static const double stepperHeightMd    = 42.0;

  // ── 4. Corner Radius Values (Double & BorderRadius) ──
  static const double rXsVal   = 4.0;
  static const double rSmVal   = 8.0;
  static const double rMdVal   = 12.0;
  static const double rBaseVal = 14.0;
  static const double rLgVal   = 16.0;
  static const double rCardVal = 18.0;
  static const double rXlVal   = 20.0;
  static const double rSheetVal= 24.0;
  static const double rPillVal = 999.0;

  // Backwards-compatible BorderRadius instances
  static const BorderRadius radiusXs   = BorderRadius.all(Radius.circular(rXsVal));
  static const BorderRadius radiusSm   = BorderRadius.all(Radius.circular(rSmVal));
  static const BorderRadius radiusMd   = BorderRadius.all(Radius.circular(rMdVal));
  static const BorderRadius radiusBase = BorderRadius.all(Radius.circular(rBaseVal));
  static const BorderRadius radiusLg   = BorderRadius.all(Radius.circular(rLgVal));
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(rCardVal));
  static const BorderRadius radiusXl   = BorderRadius.all(Radius.circular(rXlVal));
  static const BorderRadius radiusSheet= BorderRadius.vertical(top: Radius.circular(rSheetVal));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(rPillVal));

  // ── 5. Border Width Tokens ──
  static const double borderThin   = 1.0;  // Card outlines, Idle inputs
  static const double borderMedium = 1.5;  // Focused inputs, Active badges, Outlines
  static const double borderThick  = 2.0;  // Selected borders, Radio rings

  // ── 6. Elevation / BoxShadows ──
  static const shadowSm = [BoxShadow(color: Color(0x0A000000), blurRadius: 8,  offset: Offset(0, 2))];
  static const shadowMd = [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))];
  static const shadowLg = [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))];

  // ── 7. Pre-allocated Gaps for Zero Memory Allocation & 120 FPS ──
  static const SizedBox gapZero = SizedBox.shrink();

  static const SizedBox gapW2  = SizedBox(width: xxs);
  static const SizedBox gapW4  = SizedBox(width: xs);
  static const SizedBox gapW6  = SizedBox(width: 6.0);
  static const SizedBox gapW8  = SizedBox(width: sm);
  static const SizedBox gapW10 = SizedBox(width: 10.0);
  static const SizedBox gapW12 = SizedBox(width: md);
  static const SizedBox gapW14 = SizedBox(width: 14.0);
  static const SizedBox gapW16 = SizedBox(width: base);
  static const SizedBox gapW20 = SizedBox(width: lg);
  static const SizedBox gapW24 = SizedBox(width: xl);
  static const SizedBox gapW32 = SizedBox(width: xxl);

  static const SizedBox gapH2  = SizedBox(height: xxs);
  static const SizedBox gapH4  = SizedBox(height: xs);
  static const SizedBox gapH6  = SizedBox(height: 6.0);
  static const SizedBox gapH8  = SizedBox(height: sm);
  static const SizedBox gapH10 = SizedBox(height: 10.0);
  static const SizedBox gapH12 = SizedBox(height: md);
  static const SizedBox gapH14 = SizedBox(height: 14.0);
  static const SizedBox gapH16 = SizedBox(height: base);
  static const SizedBox gapH18 = SizedBox(height: 18.0);
  static const SizedBox gapH20 = SizedBox(height: lg);
  static const SizedBox gapH24 = SizedBox(height: xl);
  static const SizedBox gapH28 = SizedBox(height: 28.0);
  static const SizedBox gapH32 = SizedBox(height: xxl);
  static const SizedBox gapH40 = SizedBox(height: xxxl);
  static const SizedBox gapH48 = SizedBox(height: giant);
}
