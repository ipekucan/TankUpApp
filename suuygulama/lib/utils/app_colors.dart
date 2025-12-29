import 'package:flutter/material.dart';

// Modern Su/Hidrasyon Temalı Renk Paleti
// Tasarım Felsefesi: Temiz, ferah, enerjik ve modern
class AppColors {
  // ============================================
  // ANA RENKLER (Primary Colors)
  // ============================================
  
  // Ana Mavi (Deep Ocean) - Butonlar, vurgular
  static const Color primaryBlue = Color(0xFF2B5876); // Koyu okyanus mavisi
  static const Color primaryBlueLight = Color(0xFF3E6B8A); // Açık versiyonu
  static const Color primaryBlueDark = Color(0xFF1E4054); // Koyu versiyonu
  
  // İkincil Mavi (Fresh Aqua) - Aksiyon butonları, linkler
  static const Color secondaryAqua = Color(0xFF00BCD4); // Canlı turkuaz
  static const Color secondaryAquaLight = Color(0xFF26C6DA); // Açık turkuaz
  static const Color secondaryAquaDark = Color(0xFF0097A7); // Koyu turkuaz
  
  // Vurgu Rengi (Energetic Coral) - Önemli aksiyonlar
  static const Color accentCoral = Color(0xFFFF6B6B); // Canlı koral
  static const Color accentCoralLight = Color(0xFFFF8E8E); // Açık koral
  static const Color accentCoralDark = Color(0xFFFF4757); // Koyu koral

  // ============================================
  // GRADYAN RENKLER (Gradients)
  // ============================================
  
  // Ana Gradyan (Zen Mode arka planı)
  static const List<Color> zenGradient = [
    Color(0xFF2B5876), // Üst: Koyu mavi
    Color(0xFF4E4376), // Alt: Mor-mavi
  ];
  
  // Su Gradyanı (Fresh Water)
  static const List<Color> waterGradient = [
    Color(0xFFA8D5E2), // Açık su mavisi
    Color(0xFF7EC8E3), // Daha canlı mavi
  ];
  
  // Başarı Gradyanı (Success)
  static const List<Color> successGradient = [
    Color(0xFF4CAF50), // Yeşil
    Color(0xFF66BB6A), // Açık yeşil
  ];

  // ============================================
  // ARKA PLAN RENKLERİ (Backgrounds)
  // ============================================
  
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Temiz beyaz
  static const Color backgroundLight = Color(0xFFF5F9FC); // Çok açık mavi-beyaz
  static const Color backgroundSoft = Color(0xFFE8F4F8); // Yumuşak açık mavi
  static const Color backgroundSubtle = Color(0xFFF0F8FF); // Çok hafif mavi

  // ============================================
  // METİN RENKLERİ (Text Colors)
  // ============================================
  
  static const Color textPrimary = Color(0xFF2D3748); // Ana metin (koyu gri)
  static const Color textSecondary = Color(0xFF4A5568); // İkincil metin (orta gri)
  static const Color textTertiary = Color(0xFF718096); // Üçüncül metin (açık gri)
  static const Color textWhite = Color(0xFFFFFFFF); // Beyaz metin
  static const Color textOnDark = Color(0xFFE2E8F0); // Koyu arka plan üzerinde

  // ============================================
  // DURUM RENKLERİ (Status Colors)
  // ============================================
  
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenLight = Color(0xFF66BB6A);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningOrangeLight = Color(0xFFFFB74D);
  static const Color errorRed = Color(0xFFE53E3E);
  static const Color errorRedLight = Color(0xFFFC8181);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color infoBlueLight = Color(0xFF64B5F6);

  // ============================================
  // BUTON RENKLERİ (Button Colors)
  // ============================================
  
  // Ana Buton (Primary)
  static const Color buttonPrimary = primaryBlue;
  static const Color buttonPrimaryLight = primaryBlueLight;
  
  // İkincil Buton (Secondary)
  static const Color buttonSecondary = secondaryAqua;
  static const Color buttonSecondaryLight = secondaryAquaLight;
  
  // Vurgu Butonu (Accent)
  static const Color buttonAccent = accentCoral;
  static const Color buttonAccentLight = accentCoralLight;
  
  // Yumuşak Pembe Buton (Eski uyumluluk için)
  static const Color softPinkButton = accentCoralLight;

  // ============================================
  // KART VE YÜZEY RENKLERİ (Card & Surface)
  // ============================================
  
  static const Color cardBackground = Color(0xFFFFFFFF); // Beyaz kartlar
  static const Color cardBorder = Color(0xFFE2E8F0); // Kart kenarlıkları
  static const Color surfaceElevated = Color(0xFFFAFBFC); // Yükseltilmiş yüzeyler

  // ============================================
  // SU VE TANK RENKLERİ (Water & Tank)
  // ============================================
  
  static const Color waterColor = Color(0xFFA8D5E2); // Su rengi
  static const Color waterColorLight = Color(0xFFB8DDE8); // Açık su
  static const Color tankBackground = Color(0xFFE8F4F8); // Tank arka planı
  static const Color tankBorder = Color(0xFFB8D4E3); // Tank kenarlığı

  // ============================================
  // AKSOLOTL RENKLERİ (Axolotl Colors)
  // ============================================
  
  static const Color pinkSkin = Color(0xFFFFB6C1); // Pembe ten
  static const Color blueSkin = Color(0xFFB0E0E6); // Mavi ten
  static const Color yellowSkin = Color(0xFFFFF8DC); // Sarı ten
  static const Color greenSkin = Color(0xFFD4EDDA); // Yeşil ten
  
  static const Color blackEye = Color(0xFF2C3E50);
  static const Color brownEye = Color(0xFF8B4513);
  static const Color blueEye = Color(0xFF4169E1);
  
  static const Color hatColor = Color(0xFFFFD700); // Altın
  static const Color glassesColor = Color(0xFF708090); // Gri
  static const Color scarfColor = accentCoral; // Koral

  // ============================================
  // ÖZEL RENKLER (Special Colors)
  // ============================================
  
  static const Color goldCoin = Color(0xFFFFD700); // Altın coin
  static const Color goldCoinLight = Color(0xFFFFC107); // Açık altın
  
  // Eski uyumluluk için (deprecated - yavaşça kaldırılacak)
  @Deprecated('Use backgroundLight instead')
  static const Color softBlue = backgroundSoft;
  
  @Deprecated('Use backgroundSubtle instead')
  static const Color verySoftBlue = backgroundSubtle;
  
  @Deprecated('Use softPinkButton instead')
  static const Color softPink = accentCoralLight;
  
  @Deprecated('Use buttonAccent instead')
  static const Color softYellow = warningOrangeLight;
  
  @Deprecated('Use successGreen instead')
  static const Color softGreen = successGreenLight;
  
  @Deprecated('Use zenGradient[1] instead')
  static const Color softPurple = Color(0xFF4E4376);

  // ============================================
  // SHADOW RENKLERİ (Shadows)
  // ============================================
  
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.1);
  static Color shadowDark = Colors.black.withValues(alpha: 0.2);
}
