import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified theme configuration for chart styling.
/// Ensures visual consistency across Day, Week, and Month views.
class ChartTheme {
  ChartTheme._(); // Private constructor to prevent instantiation

  // ============================================
  // Typography Constants
  // ============================================

  /// Unified text style for X-axis (bottom) labels.
  /// Used consistently across all timeframes (Day, Week, Month).
  static TextStyle get axisLabelStyle => GoogleFonts.nunito(
    color: const Color(0xFF757575), // Colors.grey[600]
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
  );

  /// Padding for axis labels.
  static const EdgeInsets axisLabelPadding = EdgeInsets.only(top: 4.0);

  // ============================================
  // Bar Styling Constants
  // ============================================

  /// Consistent bar width for all timeframes.
  /// Previously: Month=12.0, Day/Week=20.0
  static const double barWidth = 16.0;

  /// Consistent border radius for all bars (Premium rounded top).
  static const BorderRadius barBorderRadius = BorderRadius.vertical(
    top: Radius.circular(8.0),
  );

  // ============================================
  // Axis Configuration Constants
  // ============================================

  /// Reserved size for bottom axis titles.
  /// Ensures consistent vertical spacing and prevents graph "jumping".
  static const double bottomAxisReservedSize = 40.0;

  /// Reserved size for left axis titles (for consistency, even if not shown).
  static const double leftAxisReservedSize = 0.0;

  /// Groups space between bars.
  static const double groupsSpace = 8.0;

  // ============================================
  // Color Constants
  // ============================================

  /// Axis label color (grey[600]).
  static const Color axisLabelColor = Color(0xFF757575);

  /// Tooltip background color.
  static const Color tooltipBackgroundColor = Color(0xFF424242); // black87

  /// Tooltip text color.
  static const Color tooltipTextColor = Colors.white;

  /// Tooltip text style.
  static const TextStyle tooltipTextStyle = TextStyle(
    color: tooltipTextColor,
    fontWeight: FontWeight.bold,
    fontSize: 16.0,
  );

  /// Tooltip border radius.
  static const double tooltipBorderRadius = 8.0;
}

