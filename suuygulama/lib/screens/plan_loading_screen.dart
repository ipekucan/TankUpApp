import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';

class PlanLoadingScreen extends StatefulWidget {
  final String? wakeUpTime;
  final String? sleepTime;
  final double? customGoal;

  const PlanLoadingScreen({
    super.key,
    this.wakeUpTime,
    this.sleepTime,
    this.customGoal,
  });

  @override
  State<PlanLoadingScreen> createState() => _PlanLoadingScreenState();
}

class _PlanLoadingScreenState extends State<PlanLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _calculateAndSavePlan();
  }

  Future<void> _calculateAndSavePlan() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final waterProvider = Provider.of<WaterProvider>(context, listen: false);
    
    // Kısa bir gecikme (animasyon için)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Bilimsel hesaplama: VKE ve su hedefi
    // VKE = Kilo / (Boy/100)² (UserProvider'da zaten var)
    // Su hedefi = Kilo × 35ml + Aktivite bonusu (UserProvider'da zaten var)
    // Eğer özel hedef varsa onu kullan, yoksa hesaplanan hedefi kullan
    final idealGoal = widget.customGoal ?? userProvider.calculateIdealWaterGoal();
    
    // Su hedefini ayarla
    await waterProvider.updateDailyGoal(idealGoal);
    
    // Coin'i sıfırla
    await waterProvider.resetCoins();
    
    // Onboarding tamamlandı flag'ini kaydet
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
    
    if (!mounted) return;
    
    // Bildirimleri uyku düzenine göre güncelle
    final notificationService = NotificationService();
    notificationService.scheduleDailyNotifications(
      wakeUpTime: widget.wakeUpTime,
      sleepTime: widget.sleepTime,
    ).catchError((e) {
      // Hata durumunda sessizce devam et
    });
    
    if (!mounted) return;
    
    // Ana sayfaya yönlendir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Boş alan (ileride animasyon için)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Kişisel planınız oluşturuluyor...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF4A5568),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.softPinkButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

