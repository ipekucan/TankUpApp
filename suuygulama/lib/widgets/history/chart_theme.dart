import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified theme configuration for chart styling.
/// Ensures visual consistency across Day, Week, and Month views.
/// 
/// Design Philosophy: Modern, minimalist, premium feel with soft gradients
/// and rounded elements. Inspired by iOS Health app aesthetics.
class ChartTheme {
  ChartTheme._(); // Private constructor to prevent instantiation

  // ============================================
  // Typography Constants
  // ============================================

  /// Unified text style for X-axis (bottom) labels.
  /// Used consistently across all timeframes (Day, Week, Month).
  static TextStyle get axisLabelStyle => GoogleFonts.nunito(
    color: const Color(0xFF6B7280), // Medium gray for better visibility
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Padding for axis labels.
  static const EdgeInsets axisLabelPadding = EdgeInsets.only(top: 8.0);

  // ============================================
  // Bar Styling Constants
  // ============================================

  /// Consistent bar width for all timeframes.
  /// Slightly wider for better visual impact.
  static const double barWidth = 20.0;

  /// Consistent border radius for all bars (Premium rounded top).
  /// More pronounced rounding for modern aesthetic.
  static const BorderRadius barBorderRadius = BorderRadius.vertical(
    top: Radius.circular(10.0),
  );

  // ============================================
  // Axis Configuration Constants
  // ============================================

  /// Reserved size for bottom axis titles.
  /// Ensures consistent vertical spacing and prevents graph "jumping".
  static const double bottomAxisReservedSize = 36.0;

  /// Reserved size for left axis titles (for consistency, even if not shown).
  static const double leftAxisReservedSize = 0.0;

  /// Groups space between bars.
  static const double groupsSpace = 12.0;

  // ============================================
  // Color Constants - Premium Palette
  // ============================================

  /// Primary chart color - Vibrant blue gradient start
  static const Color primaryBarColor = Color(0xFF4F8EF7);
  
  /// Primary chart color - Gradient end (lighter)
  static const Color primaryBarColorLight = Color(0xFF7EB6FF);
  
  /// Secondary chart color for accent/highlight
  static const Color accentBarColor = Color(0xFF5FC3E4);
  
  /// Empty bar color - Subtle gray
  static const Color emptyBarColor = Color(0xFFE5E7EB);

  /// Axis label color - Medium gray for better visibility.
  static const Color axisLabelColor = Color(0xFF6B7280);
  
  /// Grid line color - Very subtle
  static const Color gridLineColor = Color(0xFFF3F4F6);

  /// Tooltip background color - Dark with transparency for depth
  static const Color tooltipBackgroundColor = Color(0xFF1F2937);

  /// Tooltip text color.
  static const Color tooltipTextColor = Colors.white;

  /// Tooltip text style - Refined typography
  static TextStyle get tooltipTextStyle => GoogleFonts.nunito(
    color: tooltipTextColor,
    fontWeight: FontWeight.w700,
    fontSize: 14.0,
    letterSpacing: 0.2,
  );

  /// Tooltip border radius - More rounded for modern feel.
  static const double tooltipBorderRadius = 12.0;
  
  // ============================================
  // Shadow & Depth Constants
  // ============================================
  
  /// Tooltip shadow for floating effect
  static List<BoxShadow> get tooltipShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Chart container background - Subtle gradient base
  static const Color chartBackgroundStart = Color(0xFFFAFAFA);
  static const Color chartBackgroundEnd = Color(0xFFF5F5F5);
}

