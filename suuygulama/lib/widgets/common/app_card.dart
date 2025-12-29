import 'package:flutter/material.dart';

/// Reusable card widget with standardized styling.
/// 
/// Provides a consistent white card with shadow and rounded corners
/// used throughout the application. Eliminates code duplication
/// of the common "white container with shadow" pattern.
/// 
/// Example:
/// ```dart
/// AppCard(
///   padding: EdgeInsets.all(20),
///   child: Text('Card content'),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// The widget to display inside the card
  final Widget child;

  /// Padding for the card content
  /// Defaults to EdgeInsets.all(20) if not specified
  final EdgeInsets? padding;

  /// Optional elevation override (default: 4)
  final double? elevation;

  /// Optional border radius override (default: 20)
  final double? borderRadius;

  /// Optional background color override (default: Colors.white)
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
      ),
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }
}

/// Alternative AppCard implementation using Container (for cases where Card doesn't fit)
/// 
/// Use this when you need more control over the shadow or styling.
class AppCardContainer extends StatelessWidget {
  /// The widget to display inside the card
  final Widget child;

  /// Padding for the card content
  /// Defaults to EdgeInsets.all(20) if not specified
  final EdgeInsets? padding;

  /// Optional border radius override (default: 20)
  final double? borderRadius;

  /// Optional background color override (default: Colors.white)
  final Color? backgroundColor;

  /// Optional shadow color override (default: Colors.black with alpha 0.05)
  final Color? shadowColor;

  /// Optional blur radius override (default: 10)
  final double? blurRadius;

  const AppCardContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.shadowColor,
    this.blurRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withValues(alpha: 0.05),
            blurRadius: blurRadius ?? 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(20.0),
      child: child,
    );
  }
}

