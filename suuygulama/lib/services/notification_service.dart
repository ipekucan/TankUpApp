import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Şirin bildirim mesajları (aksolotun ağzından)
  final List<String> _notificationMessages = [
    '💧 Susadım! Bana bir bardak su getirir misin?',
    '🌊 Su içme zamanı geldi! Ben de içeyim mi?',
    '💙 Aksolotun susadı! Hadi birlikte su içelim!',
    '💧 Tankımda su azaldı, beni besler misin?',
    '🌊 Su içmeyi unutma! Ben de seninle içmek istiyorum!',
    '💙 Biraz susadım, bir bardak su içer misin?',
    '💧 Su içme vakti! Aksolotun seni bekliyor!',
    '🌊 Hadi su içelim! Ben de çok susadım!',
  ];

  // Bildirim başlıkları
  final List<String> _notificationTitles = [
    'Aksolotun Susadı! 💧',
    'Su İçme Zamanı! 🌊',
    'Aksolotun Mesajı 💙',
    'Su Hatırlatıcısı 💧',
    'Birlikte Su İçelim! 🌊',
    'Aksolotun İsteği 💙',
    'Su Vakti! 💧',
    'Susadım! 🌊',
  ];

  // Bildirim servisini başlat
  Future<void> initialize() async {
    // Timezone verilerini yükle
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android ayarları
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Başlangıç ayarları
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Bildirimleri başlat
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için kanal oluştur
    await _createNotificationChannel();
  }

  // Android bildirim kanalı oluştur
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'water_reminder_channel',
      'Su İçme Hatırlatıcısı',
      description: 'Aksolotun su içme hatırlatıcı bildirimleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Bildirim tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    // Bildirim tıklandığında yapılacak işlemler
    // (örneğin uygulamayı açmak)
  }

  // Periyodik bildirimleri ayarla (günde 8 kez, 2 saatte bir)
  Future<void> scheduleDailyNotifications() async {
    // Önce mevcut bildirimleri iptal et
    await cancelAllNotifications();

    // İlk bildirim saati (sabah 8:00)
    final now = tz.TZDateTime.now(tz.local);
    var firstNotificationTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8, // Saat 8
      0, // Dakika 0
    );

    // Eğer şu anki saat 8:00'dan geçtiyse, yarın 8:00'dan başlat
    if (now.isAfter(firstNotificationTime)) {
      firstNotificationTime = firstNotificationTime.add(const Duration(days: 1));
    }

    // Günde 8 bildirim (2 saatte bir: 8:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00)
    for (int i = 0; i < 8; i++) {
      final notificationTime = firstNotificationTime.add(Duration(hours: i * 2));
      
      // Mesaj ve başlık seç (döngüsel olarak)
      final messageIndex = i % _notificationMessages.length;
      final title = _notificationTitles[messageIndex];
      final body = _notificationMessages[messageIndex];

      await _scheduleNotification(
        id: i,
        title: title,
        body: body,
        scheduledDate: notificationTime,
      );
    }
  }

  // Bildirim zamanla
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Su İçme Hatırlatıcısı',
      channelDescription: 'Aksolotun su içme hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarla
    );
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Anlık bildirim gönder (test için)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Su İçme Hatırlatıcısı',
      channelDescription: 'Aksolotun su içme hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Test bildirimi için özel ID
      title,
      body,
      notificationDetails,
    );
  }
}

