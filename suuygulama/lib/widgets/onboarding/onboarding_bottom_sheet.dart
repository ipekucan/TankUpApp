import 'package:flutter/material.dart';

/// Modular bottom sheet container for onboarding selections
class OnboardingBottomSheet extends StatelessWidget {
  final Widget child;
  
  const OnboardingBottomSheet({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.5,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Content
          Expanded(child: child),
          
          // Privacy text at bottom
          const SizedBox(height: 16),
          Text(
            'Bilgileriniz sadece hesaplama içindir, kaydedilmez.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
