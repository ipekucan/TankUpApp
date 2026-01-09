import 'package:flutter/material.dart';

/// Modular menu button widget for onboarding screen
class OnboardingMenuButton extends StatelessWidget {
  // Clean & Bold color palette
  static const Color _primaryMutedBlue = Color(0xFF85B7D2);
  static const Color _buttonPaleBlue = Color(0xFFD2ECF9);
  
  final String label;
  final IconData icon;
  final String? selectedValue;
  final IconData? selectedIcon;
  final VoidCallback onTap;
  
  const OnboardingMenuButton({
    super.key,
    required this.label,
    required this.icon,
    this.selectedValue,
    this.selectedIcon,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedValue != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _buttonPaleBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryMutedBlue.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Text on left (title or selected value)
            Flexible(
              child: Text(
                hasSelection ? selectedValue! : label,
                style: const TextStyle(
                  color: _primaryMutedBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Icon on right (selected or default)
            Icon(
              hasSelection ? selectedIcon! : icon,
              color: _primaryMutedBlue,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
