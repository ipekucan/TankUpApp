import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Centralized text styles for the application.
/// Eliminates hardcoded TextStyle definitions across screens.
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  // ============================================
  // HEADINGS
  // ============================================

  /// Large heading style (e.g., "Günlük Hedef", "Cinsiyet Seçiniz")
  /// fontSize: 32, fontWeight: w300, letterSpacing: 1.2
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    color: Color(0xFF4A5568),
    letterSpacing: 1.2,
  );

  /// Medium heading style (e.g., "Sıvı Tüketim Grafiği", section titles)
  /// fontSize: 22, fontWeight: bold
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Color(0xFF4A5568),
  );

  /// Small heading style (e.g., section headers in profile)
  /// fontSize: 18, fontWeight: w600
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4A5568),
  );

  /// AppBar title style
  /// fontSize: 24, fontWeight: w300, letterSpacing: 1.2
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  // ============================================
  // BODY TEXT
  // ============================================

  /// Large body text (e.g., button labels, important text)
  /// fontSize: 16, fontWeight: w600
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4A5568),
  );

  /// Medium body text (e.g., regular content, descriptions)
  /// fontSize: 14-16, fontWeight: w500-w600
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4A5568),
  );

  /// Small body text (e.g., secondary information, captions)
  /// fontSize: 12-14, color: grey
  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  );

  /// Body text with grey color (for secondary information)
  static TextStyle bodyGrey = TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
  );

  /// Body text with light grey color (for placeholders)
  static TextStyle bodyLightGrey = TextStyle(
    fontSize: 14,
    color: Colors.grey[400],
  );

  // ============================================
  // LABELS & BUTTONS
  // ============================================

  /// Button text style
  /// fontSize: 16-18, fontWeight: w600-w700
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Large button text style
  static const TextStyle buttonTextLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Tab label style (selected)
  static const TextStyle tabLabelSelected = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Tab label style (unselected)
  static const TextStyle tabLabelUnselected = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // ============================================
  // SPECIAL CASES
  // ============================================

  /// Subtitle/description text (e.g., under headings)
  /// fontSize: 16, color: grey with alpha
  static TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: const Color(0xFF4A5568).withValues(alpha: 0.7),
  );

  /// Placeholder text style (italic, light grey)
  static TextStyle placeholder = TextStyle(
    fontSize: 14,
    color: Colors.grey[400],
    fontStyle: FontStyle.italic,
  );

  /// Value text style (for displaying values, e.g., amounts)
  static TextStyle valueText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.grey[900],
  );

  /// Date/time display style
  static const TextStyle dateText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Color(0xFF4A5568),
    letterSpacing: 0.5,
  );
}

