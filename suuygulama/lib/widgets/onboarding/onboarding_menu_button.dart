import 'package:flutter/material.dart';

/// Modular menu button widget for onboarding screen
class OnboardingMenuButton extends StatelessWidget {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: hasSelection
              ? const LinearGradient(
                  colors: [
                    Color(0xFF64B5F6), // Medium blue
                    Color(0xFF42A5F5), // Slightly darker blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFBBDEFB), // Light pastel blue
                    Color(0xFFE3F2FD), // Very light blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: hasSelection
                  ? const Color(0xFF1976D2).withValues(alpha: 0.2)
                  : const Color(0xFF90CAF9).withValues(alpha: 0.15),
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
                style: TextStyle(
                  color: hasSelection 
                      ? Colors.white 
                      : const Color(0xFF1976D2),
                  fontSize: 15,
                  fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(width: 6),
            
            // Icon on right (selected or default)
            Icon(
              hasSelection ? selectedIcon! : icon,
              color: hasSelection 
                  ? Colors.white 
                  : const Color(0xFF1976D2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
