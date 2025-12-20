import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/water_provider.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';

class PersonalHydrationPlanScreen extends StatelessWidget {
  final String? wakeUpTime;
  final String? sleepTime;

  const PersonalHydrationPlanScreen({
    super.key,
    this.wakeUpTime,
    this.sleepTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verySoftBlue,
      body: SafeArea(
        child: Consumer2<UserProvider, WaterProvider>(
          builder: (context, userProvider, waterProvider, child) {
            // Bilimsel hesaplamalar
            final bmi = userProvider.bmi;
            final idealGoal = userProvider.calculateIdealWaterGoal();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  const Text(
                    'Kişisel Hidrasyon Planınız',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF4A5568),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bilimsel analiz sonuçlarınız',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF4A5568).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // VKE (BMI) Kartı
                  _buildBMICard(bmi),
                  const SizedBox(height: 20),
                  
                  // Günlük Su Hedefi Kartı
                  _buildDailyGoalCard(idealGoal),
                  const SizedBox(height: 40),
                  
                  // Detaylı Bilgiler
                  _buildDetailsSection(userProvider),
                  const SizedBox(height: 40),
                  
                  // Onay Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmPlan(context, userProvider, waterProvider, idealGoal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softPinkButton,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Planı Onayla ve Başla',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBMICard(double? bmi) {
    if (bmi == null) {
      return const SizedBox.shrink();
    }

    String bmiCategory;
    Color bmiColor;
    
    if (bmi < 18.5) {
      bmiCategory = 'Zayıf';
      bmiColor = Colors.blue;
    } else if (bmi < 25.0) {
      bmiCategory = 'Normal';
      bmiColor = Colors.green;
    } else if (bmi < 30.0) {
      bmiCategory = 'Fazla Kilolu';
      bmiColor = Colors.orange;
    } else {
      bmiCategory = 'Obez';
      bmiColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics,
                  color: bmiColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vücut Kitle Endeksi (VKE)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    Text(
                      bmiCategory,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: bmiColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  Text(
                    'VKE Değeri',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4A5568).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: bmiColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(double idealGoal) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.softPinkButton.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.water_drop,
                  color: AppColors.softPinkButton,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Su Hedefi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    Text(
                      'Önerilen Miktar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(idealGoal / 1000).toStringAsFixed(1)}L',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  Text(
                    'Günlük Hedef',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4A5568).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.softPinkButton.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${idealGoal.toStringAsFixed(0)}ml',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.softPinkButton,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hesaplama Detayları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 20),
          if (userProvider.userData.weight != null)
            _buildDetailRow(
              'Kilo',
              '${userProvider.userData.weight!.toStringAsFixed(1)} kg',
            ),
          if (userProvider.userData.height != null)
            _buildDetailRow(
              'Boy',
              '${userProvider.userData.height!.toStringAsFixed(0)} cm',
            ),
          if (userProvider.userData.age != null)
            _buildDetailRow(
              'Yaş',
              '${userProvider.userData.age} yaş',
            ),
          if (userProvider.userData.activityLevel != null)
            _buildDetailRow(
              'Aktivite Seviyesi',
              _getActivityLevelText(userProvider.userData.activityLevel!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF4A5568).withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityLevelText(String level) {
    switch (level) {
      case 'low':
        return 'Düşük';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Yüksek';
      default:
        return level;
    }
  }

  Future<void> _confirmPlan(
    BuildContext context,
    UserProvider userProvider,
    WaterProvider waterProvider,
    double idealGoal,
  ) async {
    if (!context.mounted) return;

    try {
      // Onboarding tamamlandı flag'ini kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      // Coin'i 0 yap
      await waterProvider.resetCoins();
      
      // İdeal su hedefini ayarla
      await waterProvider.updateDailyGoal(idealGoal);
      
      if (!context.mounted) return;
      
      // Bildirimleri uyku düzenine göre güncelle
      final notificationService = NotificationService();
      notificationService.scheduleDailyNotifications(
        wakeUpTime: wakeUpTime,
        sleepTime: sleepTime,
      ).catchError((e) {
        if (kDebugMode) {
          print('Bildirim zamanlama hatası: $e');
        }
      });
      
      if (!context.mounted) return;
      
      // Ana sayfaya yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Plan onaylama hatası: $e');
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir hata oluştu. Lütfen tekrar deneyin.'),
        ),
      );
    }
  }
}

