import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified theme configuration for onboarding screens.
/// 
/// Design Philosophy: Clean, airy, and soft with pastel tones,
/// generous whitespace, and layered soft shadows.
class OnboardingTheme {
  OnboardingTheme._();

  // ============================================
  // Color Palette - Soft Pastel Tones
  // ============================================
  
  /// Primary accent - Soft sky blue
  static const Color primaryAccent = Color(0xFF7EC8E3);
  
  /// Primary accent light - Very light blue for backgrounds
  static const Color primaryAccentLight = Color(0xFFE8F6FB);
  
  /// Primary accent dark - Deeper blue for emphasis
  static const Color primaryAccentDark = Color(0xFF5BA4C9);
  
  /// Secondary accent - Soft lavender
  static const Color secondaryAccent = Color(0xFFB8A9C9);
  
  /// Tertiary accent - Soft mint
  static const Color tertiaryAccent = Color(0xFF98D4BB);
  
  /// Warm accent - Soft peach
  static const Color warmAccent = Color(0xFFF7D4BC);
  
  /// Background - Pure white with slight warmth
  static const Color background = Color(0xFFFCFCFC);
  
  /// Card background - Soft off-white
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Text primary - Soft dark gray
  static const Color textPrimary = Color(0xFF3D4F5F);
  
  /// Text secondary - Medium gray
  static const Color textSecondary = Color(0xFF7A8D9C);
  
  /// Text tertiary - Light gray
  static const Color textTertiary = Color(0xFFB0BEC5);
  
  /// Border color - Very soft gray
  static const Color borderColor = Color(0xFFE8EEF2);
  
  /// Disabled color
  static const Color disabledColor = Color(0xFFE0E5E9);

  // ============================================
  // Typography
  // ============================================
  
  /// Main heading style
  static TextStyle get headingStyle => GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  /// Subtitle style
  static TextStyle get subtitleStyle => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.1,
    height: 1.5,
  );
  
  /// Button text style
  static TextStyle get buttonTextStyle => GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  /// Option label style
  static TextStyle get optionLabelStyle => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.2,
  );
  
  /// Value display style (large numbers)
  static TextStyle get valueDisplayStyle => GoogleFonts.nunito(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  /// Unit text style
  static TextStyle get unitStyle => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // ============================================
  // Dimensions
  // ============================================
  
  static const double pagePadding = 28.0;
  static const double cardRadius = 24.0;
  static const double buttonRadius = 28.0;
  static const double buttonHeight = 58.0;
  static const double iconSize = 32.0;
  static const double selectionCircleSize = 120.0;
  static const double optionCardHeight = 72.0;

  // ============================================
  // Shadows
  // ============================================
  
  /// Soft shadow for cards and buttons
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.08),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Selected item shadow with glow
  static List<BoxShadow> get selectedShadow => [
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.1),
      blurRadius: 40,
      spreadRadius: 8,
      offset: const Offset(0, 0),
    ),
  ];
  
  /// Button shadow
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryAccent.withValues(alpha: 0.35),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  // ============================================
  // Decorations
  // ============================================
  
  /// Card decoration (unselected)
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: borderColor, width: 1.5),
    boxShadow: softShadow,
  );
  
  /// Selected card decoration
  static BoxDecoration get selectedCardDecoration => BoxDecoration(
    color: primaryAccentLight,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: primaryAccent, width: 2),
    boxShadow: selectedShadow,
  );
  
  /// Primary button decoration
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryAccent,
        primaryAccentDark,
      ],
    ),
    borderRadius: BorderRadius.circular(buttonRadius),
    boxShadow: buttonShadow,
  );
  
  /// Disabled button decoration
  static BoxDecoration get disabledButtonDecoration => BoxDecoration(
    color: disabledColor,
    borderRadius: BorderRadius.circular(buttonRadius),
  );

  // ============================================
  // Progress Indicator
  // ============================================
  
  /// Progress bar track color
  static const Color progressTrackColor = Color(0xFFE8EEF2);
  
  /// Progress bar fill gradient
  static LinearGradient get progressGradient => const LinearGradient(
    colors: [primaryAccent, primaryAccentDark],
  );
}

/// Reusable animated selection circle for onboarding
class OnboardingSelectionCircle extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? customColor;

  const OnboardingSelectionCircle({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = customColor ?? OnboardingTheme.primaryAccent;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: OnboardingTheme.selectionCircleSize,
        height: OnboardingTheme.selectionCircleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? accentColor : Colors.white,
          border: Border.all(
            color: isSelected ? accentColor : OnboardingTheme.borderColor,
            width: isSelected ? 0 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : OnboardingTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 44,
                color: isSelected ? Colors.white : accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: OnboardingTheme.optionLabelStyle.copyWith(
                color: isSelected ? Colors.white : OnboardingTheme.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable option card for onboarding
class OnboardingOptionCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? customColor;

  const OnboardingOptionCard({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = customColor ?? OnboardingTheme.primaryAccent;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected 
              ? accentColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : OnboardingTheme.borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : OnboardingTheme.softShadow,
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? accentColor 
                    : accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? Colors.white : accentColor,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: OnboardingTheme.optionLabelStyle.copyWith(
                      color: isSelected 
                          ? accentColor 
                          : OnboardingTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: OnboardingTheme.subtitleStyle.copyWith(
                        fontSize: 13,
                        color: OnboardingTheme.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Checkmark
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary action button for onboarding
class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: OnboardingTheme.buttonHeight,
        decoration: isEnabled
            ? OnboardingTheme.primaryButtonDecoration
            : OnboardingTheme.disabledButtonDecoration,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: OnboardingTheme.buttonTextStyle.copyWith(
                    color: isEnabled ? Colors.white : OnboardingTheme.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Page header for onboarding steps
class OnboardingHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const OnboardingHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: OnboardingTheme.headingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            subtitle,
            style: OnboardingTheme.subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
