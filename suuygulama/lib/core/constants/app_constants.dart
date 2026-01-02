import 'package:flutter/material.dart';

/// Centralized constants for the application.
/// Contains magic numbers, durations, sizes, and other hardcoded values.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  
  /// Default animation duration for quick transitions
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  /// Long animation duration for smooth transitions
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  /// Very long animation duration for complex animations
  static const Duration veryLongAnimationDuration = Duration(milliseconds: 1500);
  
  /// Wave animation duration
  static const Duration waveAnimationDuration = Duration(seconds: 3);
  
  /// Bubble animation duration
  static const Duration bubbleAnimationDuration = Duration(seconds: 4);
  
  /// Toggle timer duration for status button
  static const Duration statusToggleDuration = Duration(milliseconds: 3500);
  
  /// Animated switcher transition duration
  static const Duration animatedSwitcherDuration = Duration(milliseconds: 400);

  // ============================================
  // PADDING & SPACING
  // ============================================
  
  /// Default padding used throughout the app
  static const double defaultPadding = 20.0;
  
  /// Small padding for tight spaces
  static const double smallPadding = 12.0;
  
  /// Medium padding
  static const double mediumPadding = 16.0;
  
  /// Large padding
  static const double largePadding = 24.0;
  
  /// Extra large padding
  static const double extraLargePadding = 32.0;
  
  /// Default horizontal padding
  static const double defaultHorizontalPadding = 16.0;
  
  /// Default vertical padding
  static const double defaultVerticalPadding = 12.0;
  
  /// Small spacing between elements
  static const double smallSpacing = 4.0;
  
  /// Medium spacing between elements
  static const double mediumSpacing = 8.0;
  
  /// Default spacing between elements
  static const double defaultSpacing = 12.0;
  
  /// Large spacing between elements
  static const double largeSpacing = 16.0;
  
  /// Extra large spacing between elements
  static const double extraLargeSpacing = 20.0;
  
  /// Button spacing in control groups
  static const double buttonSpacing = 24.0;

  // ============================================
  // BORDER RADIUS
  // ============================================
  
  /// Default border radius for cards and containers
  static const double defaultBorderRadius = 20.0;
  
  /// Small border radius
  static const double smallBorderRadius = 12.0;
  
  /// Medium border radius
  static const double mediumBorderRadius = 25.0;
  
  /// Large border radius
  static const double largeBorderRadius = 30.0;
  
  /// Circular border radius (for circles)
  static const double circularBorderRadius = 999.0;

  // ============================================
  // BUTTON SIZES
  // ============================================
  
  /// Small button radius
  static const double smallButtonRadius = 30.0;
  
  /// Default button radius
  static const double defaultButtonRadius = 36.0;
  
  /// Coin button size
  static const double coinButtonSize = 60.0;
  
  /// Coin button icon size
  static const double coinButtonIconSize = 24.0;
  
  /// Coin button text size
  static const double coinButtonTextSize = 12.0;
  
  /// Status button size
  static const double statusButtonSize = 60.0;
  
  /// Status button inner size
  static const double statusButtonInnerSize = 50.0;
  
  /// Status button icon size
  static const double statusButtonIconSize = 20.0;
  
  /// Status button text size
  static const double statusButtonTextSize = 12.0;
  
  /// Control button radius
  static const double controlButtonRadius = 30.0;
  
  /// Main control button radius (water button)
  static const double mainControlButtonRadius = 36.0;
  
  /// Control button icon size
  static const double controlButtonIconSize = 30.0;
  
  /// Main control button icon size
  static const double mainControlButtonIconSize = 36.0;
  
  /// Small control button icon size
  static const double smallControlButtonIconSize = 24.0;
  
  /// Add button badge size
  static const double addButtonBadgeSize = 16.0;
  
  /// Add button badge icon size
  static const double addButtonBadgeIconSize = 12.0;

  /// Menu button width for D-shaped button
  static const double menuButtonWidth = 110.0;

  /// Standard button gap (equivalent to one standard button spacing)
  static const double standardButtonGap = 24.0;

  /// Menu button to water button gap (reduced for closer proximity)
  static const double menuToWaterButtonGap = 16.0;

  // ============================================
  // TANK VISUALIZATION
  // ============================================
  
  /// Tank size (width and height)
  static const double tankSize = 300.0;
  
  /// Number of bubbles in the tank
  static const int bubbleCount = 8;
  
  /// Minimum bubble size
  static const double minBubbleSize = 4.0;
  
  /// Maximum bubble size
  static const double maxBubbleSize = 12.0;
  
  /// Minimum bubble speed
  static const double minBubbleSpeed = 0.1;
  
  /// Maximum bubble speed
  static const double maxBubbleSpeed = 0.4;
  
  /// Maximum bubble delay
  static const double maxBubbleDelay = 2.0;
  
  /// Bubble X position range start
  static const double bubbleXRangeStart = 0.1;
  
  /// Bubble X position range end
  static const double bubbleXRangeEnd = 0.9;
  
  /// Wave amplitude
  static const double waveAmplitude = 5.0;
  
  /// Wave frequency
  static const double waveFrequency = 1.5;
  
  /// Wave height
  static const double waveHeight = 40.0;
  
  /// Minimum fill percentage for wave display
  static const double minFillForWave = 0.05;
  
  /// Minimum water height for wave display
  static const double minWaterHeightForWave = 15.0;
  
  /// Minimum water height for bubbles
  static const double minWaterHeightForBubbles = 10.0;

  // ============================================
  // SHEET SIZES (DraggableScrollableSheet)
  // ============================================
  
  /// Initial challenge sheet size (peek height)
  static const double challengeSheetInitialSize = 0.12;
  
  /// Minimum challenge sheet size
  static const double challengeSheetMinSize = 0.12;
  
  /// Maximum challenge sheet size
  static const double challengeSheetMaxSize = 0.85;
  
  /// Challenge sheet open size
  static const double challengeSheetOpenSize = 0.85;
  
  /// Control panel bottom position (as percentage of screen height)
  static const double controlPanelBottomPosition = 0.22;

  // ============================================
  // FONT SIZES
  // ============================================
  
  /// Small font size
  static const double smallFontSize = 12.0;
  
  /// Medium font size
  static const double mediumFontSize = 14.0;
  
  /// Default font size
  static const double defaultFontSize = 16.0;
  
  /// Large font size
  static const double largeFontSize = 18.0;
  
  /// Extra large font size
  static const double extraLargeFontSize = 20.0;
  
  /// Heading font size
  static const double headingFontSize = 22.0;
  
  /// Large heading font size
  static const double largeHeadingFontSize = 28.0;
  
  /// Achievement badge emoji size
  static const double achievementBadgeEmojiSize = 80.0;
  
  /// Achievement title font size
  static const double achievementTitleFontSize = 28.0;
  
  /// Achievement name font size
  static const double achievementNameFontSize = 22.0;
  
  /// Achievement reward font size
  static const double achievementRewardFontSize = 18.0;
  
  /// Achievement button font size
  static const double achievementButtonFontSize = 18.0;
  
  /// Daily goal font size
  static const double dailyGoalFontSize = 20.0;
  
  /// Challenge title font size
  static const double challengeTitleFontSize = 22.0;
  
  /// Challenge section title font size
  static const double challengeSectionTitleFontSize = 18.0;
  
  /// Challenge completed section title font size
  static const double challengeCompletedSectionTitleFontSize = 16.0;

  // ============================================
  // ACHIEVEMENT DIALOG
  // ============================================
  
  /// Achievement dialog padding
  static const double achievementDialogPadding = 30.0;
  
  /// Achievement dialog border width
  static const double achievementDialogBorderWidth = 3.0;
  
  /// Achievement dialog shadow blur radius
  static const double achievementDialogShadowBlur = 30.0;
  
  /// Achievement dialog shadow spread radius
  static const double achievementDialogShadowSpread = 5.0;
  
  /// Achievement dialog secondary shadow blur radius
  static const double achievementDialogSecondaryShadowBlur = 25.0;
  
  /// Achievement dialog secondary shadow offset
  static const Offset achievementDialogSecondaryShadowOffset = Offset(0, 10);
  
  /// Achievement reward icon size
  static const double achievementRewardIconSize = 24.0;
  
  /// Achievement button horizontal padding
  static const double achievementButtonHorizontalPadding = 40.0;
  
  /// Achievement button vertical padding
  static const double achievementButtonVerticalPadding = 16.0;
  
  /// Achievement button elevation
  static const double achievementButtonElevation = 8.0;

  // ============================================
  // ONBOARDING CONSTANTS
  // ============================================
  
  /// Default daily goal in milliliters
  static const double defaultGoalMl = 2500.0;
  
  /// Default daily goal in ounces
  static const double defaultGoalOz = 85.0;
  
  /// Base water requirement per kg (ml/kg)
  static const double baseWaterPerKg = 35.0;
  
  /// High activity bonus (ml)
  static const double highActivityBonus = 500.0;
  
  /// Medium activity bonus (ml)
  static const double mediumActivityBonus = 250.0;
  
  /// Very hot climate bonus (ml)
  static const double veryHotClimateBonus = 400.0;
  
  /// Hot climate bonus (ml)
  static const double hotClimateBonus = 300.0;
  
  /// Warm climate bonus (ml)
  static const double warmClimateBonus = 150.0;
  
  /// Minimum daily goal (ml)
  static const double minDailyGoal = 1500.0;
  
  /// Maximum daily goal (ml)
  static const double maxDailyGoal = 5000.0;

  // ============================================
  // HYDRATION / COIN / HISTORY LOGIC CONSTANTS
  // ============================================

  /// Daily hydration hard limit (ml). Used to prevent consuming beyond a safe cap.
  static const double dailyHydrationLimitMl = 5000.0;

  /// Daily coin reward granted on day reset.
  static const int dailyResetCoinReward = 10;

  /// Lucky drink chance configuration.
  /// Current implementation uses `now.millisecondsSinceEpoch % luckyDrinkModuloBase < luckyDrinkChanceThreshold`.
  static const int luckyDrinkModuloBase = 100;
  static const int luckyDrinkChanceThreshold = 5; // 5% chance
  static const int luckyDrinkRewardCoins = 10;

  /// Early bird bonus configuration.
  static const int earlyBirdCutoffHour = 9;
  static const double earlyBirdMaxConsumedMl = 500.0;
  static const int earlyBirdRewardCoins = 5;

  /// Night owl bonus configuration.
  static const int nightOwlStartHour = 20;
  static const int nightOwlRewardCoins = 5;

  /// Daily goal completion bonus configuration.
  static const int dailyGoalBonusCoins = 15;

  /// Challenge tracking: minimum ml for a "big cup" water drink.
  static const double challengeBigCupMinMl = 330.0;

  /// History retention window (days) for local storage.
  static const int historyRetentionDays = 30;
  
  /// Default weight for calculations (kg)
  static const double defaultWeightKg = 70.0;
  
  /// Pounds to kilograms conversion factor
  static const double lbsToKgFactor = 0.453592;

  // ============================================
  // SHADOW & ELEVATION
  // ============================================
  
  /// Default shadow blur radius
  static const double defaultShadowBlur = 10.0;
  
  /// Default shadow offset
  static const Offset defaultShadowOffset = Offset(0, 3);
  
  /// Small shadow blur radius
  static const double smallShadowBlur = 8.0;
  
  /// Small shadow offset
  static const Offset smallShadowOffset = Offset(0, 2);
  
  /// Large shadow blur radius
  static const double largeShadowBlur = 20.0;
  
  /// Large shadow offset
  static const Offset largeShadowOffset = Offset(0, -5);
  
  /// Default shadow alpha
  static const double defaultShadowAlpha = 0.1;

  // ============================================
  // CHALLENGE PANEL
  // ============================================
  
  /// Challenge panel handle width
  static const double challengePanelHandleWidth = 40.0;
  
  /// Challenge panel handle height
  static const double challengePanelHandleHeight = 4.0;
  
  /// Challenge panel handle border radius
  static const double challengePanelHandleBorderRadius = 2.0;
  
  /// Challenge panel handle top margin
  static const double challengePanelHandleTopMargin = 12.0;
  
  /// Challenge panel handle bottom margin
  static const double challengePanelHandleBottomMargin = 8.0;
  
  /// Challenge panel content padding
  static const EdgeInsets challengePanelContentPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 8.0,
  );
  
  /// Challenge card bottom padding
  static const double challengeCardBottomPadding = 16.0;
  
  /// Challenge section divider height
  static const double challengeSectionDividerHeight = 20.0;
  
  /// Challenge completed opacity
  static const double challengeCompletedOpacity = 0.5;
  
  /// Challenge title top padding
  static const double challengeTitleTopPadding = 12.0;
  
  /// Challenge title bottom padding
  static const double challengeTitleBottomPadding = 24.0;
  
  /// Challenge section title bottom padding
  static const double challengeSectionTitleBottomPadding = 12.0;

  /// Challenge map node radius (for gamified map)
  static const double challengeMapNodeRadius = 32.0;

  // ============================================
  // PROGRESS INDICATOR
  // ============================================
  
  /// Progress indicator stroke width
  static const double progressIndicatorStrokeWidth = 4.0;
  
  /// Progress indicator size
  static const double progressIndicatorSize = 60.0;

  // ============================================
  // ANIMATION VALUES
  // ============================================
  
  /// Coin scale animation begin value
  static const double coinScaleBegin = 1.0;
  
  /// Coin scale animation end value
  static const double coinScaleEnd = 1.3;
  
  /// Fill animation begin value
  static const double fillAnimationBegin = 0.0;
  
  /// Fill animation end value
  static const double fillAnimationEnd = 1.0;
  
  /// Minimum fill difference for animation
  static const double minFillDifference = 0.01;
  
  /// Minimum animation value difference
  static const double minAnimationValueDifference = 0.001;
  
  /// Bubble progress multiplier
  static const double bubbleProgressMultiplier = 0.8;
  
  /// Bubble opacity fade multiplier
  static const double bubbleOpacityFadeMultiplier = 1.5;

  // ============================================
  // WAVE CONFIGURATION
  // ============================================
  
  /// Wave gradient duration 1 (ms)
  static const int waveGradientDuration1 = 4000;
  
  /// Wave gradient duration 2 (ms)
  static const int waveGradientDuration2 = 5000;
  
  /// Wave height percentage 1
  static const double waveHeightPercentage1 = 0.20;
  
  /// Wave height percentage 2
  static const double waveHeightPercentage2 = 0.25;
  
  /// Wave alpha value 1
  static const double waveAlpha1 = 0.7;
  
  /// Wave alpha value 2
  static const double waveAlpha2 = 0.5;
  
  /// Wave alpha value 3
  static const double waveAlpha3 = 0.6;
  
  /// Wave alpha value 4
  static const double waveAlpha4 = 0.4;

  // ============================================
  // WATER COLORS
  // ============================================
  
  /// Primary water color
  static const Color waterColorPrimary = Color(0xFF4FC3F7);
  
  /// Secondary water color
  static const Color waterColorSecondary = Color(0xFF0288D1);
  
  /// Background gradient color 1 (Soft mint/aqua top)
  static const Color backgroundGradientColor1 = Color(0xFFE0F5F1);
  
  /// Background gradient color 2 (Light cream middle)
  static const Color backgroundGradientColor2 = Color(0xFFF5F0E8);
  
  /// Background gradient color 3 (Warm cream bottom)
  static const Color backgroundGradientColor3 = Color(0xFFFDF8F3);
  
  /// Background gradient stop 1
  static const double backgroundGradientStop1 = 0.0;
  
  /// Background gradient stop 2
  static const double backgroundGradientStop2 = 0.5;
  
  /// Background gradient stop 3
  static const double backgroundGradientStop3 = 1.0;

  // ============================================
  // ACHIEVEMENT COLORS
  // ============================================
  
  /// First cup achievement color
  static const Color firstCupAchievementColor = Color(0xFF00BCD4);
  
  /// Achievement border alpha
  static const double achievementBorderAlpha = 0.3;
  
  /// Achievement shadow alpha 1
  static const double achievementShadowAlpha1 = 0.6;
  
  /// Achievement shadow alpha 2
  static const double achievementShadowAlpha2 = 0.4;
  
  /// Achievement reward background alpha
  static const double achievementRewardBackgroundAlpha = 0.2;
}

