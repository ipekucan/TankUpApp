import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/water_provider.dart';
import 'providers/axolotl_provider.dart';
import 'providers/user_provider.dart';
import 'providers/achievement_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TEST: Tüm eski hatalı verileri temizle (bir kez çalıştırılacak, sonra silinebilir)
  // Bu satırı test sonrası silebilirsiniz
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (e) {
    // Hata durumunda sessizce devam et
  }
  
  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Günlük bildirimleri ayarla
  await notificationService.scheduleDailyNotifications();
  
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
          lazy: false, // Verilerin hemen yüklenmesi için
        ),
        ChangeNotifierProvider(
          create: (_) => AxolotlProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementProvider(),
          lazy: false,
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
        home: MainNavigationScreen(),
      ),
    );
  }
}
