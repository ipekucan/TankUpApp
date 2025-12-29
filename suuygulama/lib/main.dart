import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'providers/water_provider.dart';
import 'providers/aquarium_provider.dart';
import 'providers/user_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/drink_provider.dart';
import 'providers/challenge_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Release modda tüm print mesajlarını sustur
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
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
      // Bildirim hatası uygulama başlatmayı engellemesin - sessizce devam et
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
        ChangeNotifierProvider(
          create: (_) => ChallengeProvider(),
          lazy: true,
        ),
      ],
      child: ShowCaseWidget(
        builder: (context) => MaterialApp(
          title: 'TankUp',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              secondary: AppColors.secondaryAqua,
              tertiary: AppColors.accentCoral,
              surface: AppColors.cardBackground,
              error: AppColors.errorRed,
              onPrimary: AppColors.textWhite,
              onSecondary: AppColors.textWhite,
              onSurface: AppColors.textPrimary,
              onError: AppColors.textWhite,
            ),
            textTheme: GoogleFonts.nunitoTextTheme().copyWith(
              bodyLarge: GoogleFonts.nunito(color: AppColors.textPrimary),
              bodyMedium: GoogleFonts.nunito(color: AppColors.textSecondary),
              bodySmall: GoogleFonts.nunito(color: AppColors.textTertiary),
            ),
            scaffoldBackgroundColor: AppColors.backgroundLight,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.cardBorder,
                  width: 1,
                ),
              ),
              color: AppColors.cardBackground,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.textWhite,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppColors.buttonSecondary,
              foregroundColor: AppColors.textWhite,
              elevation: 4,
            ),
          ),
        home: const SplashScreen(),
        ),
      ),
    );
  }
}
