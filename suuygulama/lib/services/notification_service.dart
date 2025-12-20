import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Şirin bildirim mesajları
  final List<String> _notificationMessages = [
    '💧 Su içme zamanı geldi!',
    '🌊 Hidrasyon için bir bardak su iç!',
    '💙 Su içmeyi unutma!',
    '💧 Vücudun suya ihtiyacı var!',
    '🌊 Bir bardak su iç ve kendini iyi hisset!',
    '💙 Su içme vakti!',
    '💧 Hidrasyon önemli!',
    '🌊 Su içmeyi hatırla!',
  ];

  // Bildirim başlıkları
  final List<String> _notificationTitles = [
    'Su İçme Zamanı! 💧',
    'Hidrasyon Hatırlatıcısı 🌊',
    'Su Hatırlatıcısı 💙',
    'Su İçme Vakti 💧',
    'Hidrasyon Önemli 🌊',
    'Su Hatırlatıcısı 💙',
    'Su İçme Zamanı 💧',
    'Hidrasyon Hatırlatıcısı 🌊',
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

  // Periyodik bildirimleri ayarla (uyku düzenine göre)
  Future<void> scheduleDailyNotifications({
    String? wakeUpTime,
    String? sleepTime,
  }) async {
    // Önce mevcut bildirimleri iptal et
    await cancelAllNotifications();

    // Varsayılan saatler (eğer kullanıcı ayarlamadıysa)
    int wakeHour = 7;
    int wakeMinute = 0;
    int sleepHour = 23;
    int sleepMinute = 0;

    // Kullanıcının uyku düzenini parse et
    if (wakeUpTime != null) {
      final wakeParts = wakeUpTime.split(':');
      if (wakeParts.length == 2) {
        wakeHour = int.tryParse(wakeParts[0]) ?? 7;
        wakeMinute = int.tryParse(wakeParts[1]) ?? 0;
      }
    }

    if (sleepTime != null) {
      final sleepParts = sleepTime.split(':');
      if (sleepParts.length == 2) {
        sleepHour = int.tryParse(sleepParts[0]) ?? 23;
        sleepMinute = int.tryParse(sleepParts[1]) ?? 0;
      }
    }

    // Uyanık saat aralığını hesapla
    final now = tz.TZDateTime.now(tz.local);
    var firstNotificationTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      wakeHour,
      wakeMinute,
    );

    // Eğer şu anki saat uyanma saatinden geçtiyse, yarın başlat
    if (now.isAfter(firstNotificationTime)) {
      firstNotificationTime = firstNotificationTime.add(const Duration(days: 1));
    }

    // Uyanık saat aralığı (dakika cinsinden)
    int wakeMinutes = wakeHour * 60 + wakeMinute;
    int sleepMinutes = sleepHour * 60 + sleepMinute;
    
    // Eğer uyuma saati uyanma saatinden önceyse (gece yarısını geçiyorsa)
    if (sleepMinutes < wakeMinutes) {
      sleepMinutes += 24 * 60; // 24 saat ekle
    }
    
    int awakeDuration = sleepMinutes - wakeMinutes; // Dakika cinsinden uyanık süre
    
    // Her 2 saatte bir bildirim gönder (maksimum 8 bildirim)
    int notificationCount = (awakeDuration / 120).ceil().clamp(1, 8);
    int intervalMinutes = (awakeDuration / notificationCount).round();

    // Bildirimleri zamanla
    for (int i = 0; i < notificationCount; i++) {
      final notificationTime = firstNotificationTime.add(Duration(minutes: i * intervalMinutes));
      
      // Uyuma saatinden sonra bildirim gönderme
      final notificationMinutes = notificationTime.hour * 60 + notificationTime.minute;
      final sleepMinutesToday = sleepHour * 60 + sleepMinute;
      
      // Eğer bildirim uyuma saatinden sonraysa, atla
      if (sleepMinutes < wakeMinutes) {
        // Gece yarısını geçen durum
        if (notificationMinutes >= sleepMinutesToday && notificationMinutes < wakeMinutes) {
          continue;
        }
      } else {
        // Normal durum
        if (notificationMinutes >= sleepMinutesToday) {
          continue;
        }
      }
      
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

