import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/interactive_cup_modal.dart';
import 'tank_screen.dart';
import 'tank_room_screen.dart';
import '../features/challenge/screens/challenge_screen.dart';
import 'profile_screen.dart';

/// Modern Animated Navigation Screen
/// Design: Bottom-anchored nav bar with center water button
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  
  // Animation controllers
  late AnimationController _morphController;
  late AnimationController _iconController;

  // Screens mapped to nav indices (excluding center button)
  final List<Widget> _screens = [
    const TankScreen(),
    const TankRoomScreen(),
    const ChallengeScreen(),
    const ProfileScreen(),
  ];
  
  // Map nav bar index to screen index (skip center button)
  int _getScreenIndex(int navIndex) {
    if (navIndex < 2) return navIndex;
    if (navIndex > 2) return navIndex - 1;
    return 0; // Center button doesn't have a screen
  }

  @override
  void initState() {
    super.initState();
    // Morphing bubble animation - smooth and fluid
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    
    // Icon bounce animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    _iconController.dispose();
    super.dispose();
  }
  
  void _onItemTapped(int navIndex) {
    // Center button (index 2) opens water modal
    if (navIndex == 2) {
      _showWaterModal();
      return;
    }
    
    if (_currentIndex != navIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = navIndex;
      });
      
      // Trigger morphing animation
      _morphController.forward(from: 0);
      _iconController.forward(from: 0);
    }
  }
  
  void _showWaterModal() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isScrollControlled: true,
      builder: (context) => const InteractiveCupModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenIndex = _getScreenIndex(_currentIndex);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true,
      body: IndexedStack(
        index: screenIndex,
        sizing: StackFit.expand,
        children: _screens,
      ),
      bottomNavigationBar: _MorphingBubbleNavBar(
        currentIndex: _currentIndex,
        previousIndex: _previousIndex,
        morphController: _morphController,
        iconController: _iconController,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// ============================================================================
// CONFIGURATION & DATA MODELS
// ============================================================================

/// Navigation bar configuration - Bottom-anchored with oval corners
class _NavBarConfig {
  // Dimensions - Taller and anchored to bottom
  static const double navBarHeight = 80.0;
  static const double navBarRadiusTop = 28.0;        // Oval top corners
  static const double iconSize = 24.0;
  static const double bubbleHeight = 46.0;
  static const double bubbleRadius = 23.0;           // Fully rounded
  
  // Color Palette - Mint/Aqua theme
  static const Color primaryMint = Color(0xFFC4F5F4);       // Requested mint color
  static const Color primaryMintDark = Color(0xFF9DE8E7);   // Slightly darker
  static const Color inactiveColor = Color(0xFFB0C4C3);     // Soft gray-green
  static const Color backgroundColor = Color(0xFFFFFFFE);   // Pure warm white
  static const Color iconActiveColor = Color(0xFF5A9E9D);   // Teal icon on bubble
}

/// Navigation item data
class _NavItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isCenter;

  const _NavItemData({
    required this.activeIcon,
    required this.inactiveIcon,
    this.isCenter = false,
  });
}

/// Navigation items - Clean minimal icons (with center placeholder)
const List<_NavItemData> _navItems = [
  _NavItemData(
    activeIcon: Icons.home_rounded,
    inactiveIcon: Icons.home_outlined,
  ),
  _NavItemData(
    activeIcon: Icons.grid_view_rounded,
    inactiveIcon: Icons.grid_view_outlined,
  ),
  // Center is reserved for water button
  _NavItemData(
    activeIcon: Icons.local_drink_rounded,
    inactiveIcon: Icons.local_drink_outlined,
    isCenter: true,
  ),
  _NavItemData(
    activeIcon: Icons.pie_chart_rounded,
    inactiveIcon: Icons.pie_chart_outline_rounded,
  ),
  _NavItemData(
    activeIcon: Icons.favorite_rounded,
    inactiveIcon: Icons.favorite_outline_rounded,
  ),
];

// ============================================================================
// MAIN NAVIGATION BAR WIDGET
// ============================================================================

/// Navigation bar with morphing bubble indicator
class _MorphingBubbleNavBar extends StatelessWidget {
  final int currentIndex;
  final int previousIndex;
  final AnimationController morphController;
  final AnimationController iconController;
  final ValueChanged<int> onItemTapped;

  const _MorphingBubbleNavBar({
    required this.currentIndex,
    required this.previousIndex,
    required this.morphController,
    required this.iconController,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero, // Anchored to screen edges
      height: _NavBarConfig.navBarHeight,
      decoration: BoxDecoration(
        color: _NavBarConfig.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_NavBarConfig.navBarRadiusTop),
          topRight: Radius.circular(_NavBarConfig.navBarRadiusTop),
        ),
        boxShadow: [
          // Soft top shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_NavBarConfig.navBarRadiusTop),
          topRight: Radius.circular(_NavBarConfig.navBarRadiusTop),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / _navItems.length;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Morphing bubble indicator (behind icons) - skip center
                if (currentIndex != 2)
                  _MorphingBubble(
                    currentIndex: currentIndex,
                    previousIndex: previousIndex,
                    morphController: morphController,
                    itemWidth: itemWidth,
                  ),
                // Navigation items row (on top)
                Row(
                  children: List.generate(
                    _navItems.length,
                    (index) {
                      // Center button is special
                      if (index == 2) {
                        return SizedBox(
                          width: itemWidth,
                          height: _NavBarConfig.navBarHeight,
                          child: Center(
                            child: _CenterWaterButton(
                              onTap: () => onItemTapped(index),
                            ),
                          ),
                        );
                      }
                      return _NavBarItem(
                        index: index,
                        isSelected: currentIndex == index,
                        iconController: iconController,
                        itemWidth: itemWidth,
                        onTap: () => onItemTapped(index),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// MORPHING BUBBLE INDICATOR
// ============================================================================

/// Animated morphing bubble that slides between tabs
class _MorphingBubble extends StatelessWidget {
  final int currentIndex;
  final int previousIndex;
  final AnimationController morphController;
  final double itemWidth;

  const _MorphingBubble({
    required this.currentIndex,
    required this.previousIndex,
    required this.morphController,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: morphController,
      builder: (context, child) {
        // Calculate positions
        final startCenter = previousIndex * itemWidth + itemWidth / 2;
        final endCenter = currentIndex * itemWidth + itemWidth / 2;
        final distance = (endCenter - startCenter).abs();
        
        // Custom easing for fluid motion
        final progress = _fluidEasing(morphController.value);
        final currentCenter = startCenter + (endCenter - startCenter) * progress;
        
        // Morphing effect: stretch horizontally during movement
        // More stretch for longer distances
        final stretchFactor = distance / itemWidth;
        final morphProgress = _morphCurve(morphController.value);
        final extraWidth = morphProgress * stretchFactor * 30; // Max 30px extra stretch
        
        // Calculate bubble width with morphing
        final bubbleWidth = _NavBarConfig.bubbleHeight + extraWidth;
        
        // Slight vertical squash during stretch
        final scaleY = 1.0 - (morphProgress * 0.08 * stretchFactor);
        
        return Positioned(
          left: currentCenter - bubbleWidth / 2,
          top: (_NavBarConfig.navBarHeight - _NavBarConfig.bubbleHeight * scaleY) / 2,
          child: Transform.scale(
            scaleY: scaleY,
            child: Container(
              width: bubbleWidth,
              height: _NavBarConfig.bubbleHeight,
              decoration: BoxDecoration(
                // Mint/aqua gradient
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _NavBarConfig.primaryMint,
                    _NavBarConfig.primaryMintDark,
                  ],
                  stops: [0.3, 1.0],
                ),
                borderRadius: BorderRadius.circular(_NavBarConfig.bubbleRadius),
                boxShadow: [
                  // Soft glow effect
                  BoxShadow(
                    color: _NavBarConfig.primaryMint.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Custom fluid easing curve for natural movement
  double _fluidEasing(double t) {
    // Smooth ease-out with slight overshoot
    return 1 - (1 - t) * (1 - t) * (1 - t);
  }
  
  /// Curve for morphing effect (peak at middle of animation)
  double _morphCurve(double t) {
    // Bell curve: peaks at 0.5
    return 4 * t * (1 - t);
  }
}

// ============================================================================
// NAVIGATION BAR ITEM
// ============================================================================

/// Individual navigation item with animated icon
class _NavBarItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final AnimationController iconController;
  final double itemWidth;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.index,
    required this.isSelected,
    required this.iconController,
    required this.itemWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = _navItems[index];
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        height: _NavBarConfig.navBarHeight,
        child: Center(
          child: AnimatedBuilder(
            animation: iconController,
            builder: (context, child) {
              // Bounce effect for selected icon
              double scale = 1.0;
              if (isSelected) {
                final bounceProgress = Curves.elasticOut.transform(
                  iconController.value.clamp(0.0, 1.0),
                );
                scale = 0.8 + (0.2 * bounceProgress);
              }
              
              return Transform.scale(
                scale: scale,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isSelected ? item.activeIcon : item.inactiveIcon,
                    key: ValueKey('nav_${isSelected}_$index'),
                    color: isSelected
                        ? _NavBarConfig.iconActiveColor
                        : _NavBarConfig.inactiveColor,
                    size: _NavBarConfig.iconSize,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CENTER WATER BUTTON
// ============================================================================

/// Floating center water button
class _CenterWaterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterWaterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB2EBF2), // Light cyan
              Color(0xFF80DEEA), // Cyan
              Color(0xFF4DD0E1), // Deeper cyan
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DD0E1).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.water_drop_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
