import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/water_provider.dart';
import 'providers/aquarium_provider.dart';
import 'providers/user_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/drink_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // HAFIZA RESET (Geçici - bir kez çalıştırılacak, sonra silinebilir)
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (e) {
    if (kDebugMode) {
      print('Hafıza temizleme hatası: $e');
    }
  }
  
  // Bildirim servisini arka planda başlat - uygulama başlatmayı engellemesin
  Future.microtask(() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Günlük bildirimleri ayarla (varsayılan saatlerle)
      // Profil tamamlandığında güncellenecek
      await notificationService.scheduleDailyNotifications();
    } catch (e) {
      // Bildirim hatası uygulama başlatmayı engellemesin
      if (kDebugMode) {
        print('Bildirim servisi başlatma hatası: $e');
      }
    }
  });
  
  runApp(const TankUpApp());
}

class TankUpApp extends StatelessWidget {
  const TankUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WaterProvider(),
          lazy: true, // İhtiyaç duyulduğunda yükle
        ),
        ChangeNotifierProvider(
          create: (_) => AquariumProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => DrinkProvider(),
          lazy: true,
        ),
      ],
      child: MaterialApp(
        title: 'TankUp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA8D5E2),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.nunitoTextTheme(),
          scaffoldBackgroundColor: AppColors.softBlue,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.2,
              color: const Color(0xFF4A5568),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            color: Colors.white,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
