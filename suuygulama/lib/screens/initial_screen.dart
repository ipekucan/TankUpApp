import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _shouldShowOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      // Eğer onboarding tamamlanmamışsa veya weight verisi yoksa onboarding göster
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final hasWeight = userProvider.userData.weight != null;
      
      if (!mounted) return;
      setState(() {
        _shouldShowOnboarding = !onboardingCompleted || !hasWeight;
        _isLoading = false;
      });
    } catch (e) {
      // Hata durumunda onboarding göster
      if (!mounted) return;
      setState(() {
        _shouldShowOnboarding = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Onboarding gösterilmeli mi kontrol et
        if (_shouldShowOnboarding || !userProvider.isProfileComplete) {
          return const OnboardingScreen();
        }
        // Onboarding tamamlanmışsa MainNavigationScreen'e geç
        return const MainNavigationScreen();
      },
    );
  }
}

