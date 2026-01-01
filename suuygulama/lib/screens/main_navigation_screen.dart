import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'tank_screen.dart';
import 'tank_room_screen.dart';
import '../features/challenge/screens/challenge_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // 0: Ana Sayfa, 1: Zen Odası, 2: Mücadele, 3: Profil

  final List<Widget> _screens = [
    const TankScreen(), // Ana Sayfa
    const TankRoomScreen(), // Zen Odası
    const ChallengeScreen(), // Mücadele
    const ProfileScreen(), // Profil
  ];

  // Navigation items data with filled/outlined icon pairs
  final List<_NavItemData> _navItems = const [
    _NavItemData(
      label: 'Ana Sayfa',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Zen Odası',
      activeIcon: Icons.spa_rounded,
      inactiveIcon: Icons.spa_outlined,
    ),
    _NavItemData(
      label: 'Mücadele',
      activeIcon: Icons.emoji_events_rounded,
      inactiveIcon: Icons.emoji_events_outlined,
    ),
    _NavItemData(
      label: 'Profil',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBody: true, // Critical for floating effect
      body: IndexedStack(
        index: _currentIndex,
        sizing: StackFit.expand,
        children: _screens,
      ),
      bottomNavigationBar: _buildIconFillNavBar(),
    );
  }

  /// Builds the icon fill animation navigation bar
  Widget _buildIconFillNavBar() {
    return Container(
      margin: EdgeInsets.zero,
      height: 90.0,
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _navItems.length,
          (index) => _buildNavItem(
            index,
            _navItems[index].label,
            _navItems[index].activeIcon,
            _navItems[index].inactiveIcon,
          ),
        ),
      ),
    );
  }

  /// Builds a navigation item with animated icon fill
  Widget _buildNavItem(
    int index,
    String label,
    IconData activeIcon,
    IconData inactiveIcon,
  ) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 70,
        height: 90.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The Animated Icon (Outline -> Filled transition)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                key: ValueKey('${isSelected}_$index'),
                color: isSelected ? AppColors.primaryBlue : Colors.grey,
                size: isSelected ? 34.0 : 30.0,
              ),
            ),
            
            // The Label (Static & Clean)
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryBlue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for navigation items with icon pairs
class _NavItemData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
