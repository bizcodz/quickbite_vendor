import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return; 

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // 🔥 Web-safe check for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }

  static Future<void> showOtpNotification(String otp) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'otp_channel_v2',
      'OTP Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(0, 'StreetSync Verification', 'Your code is: $otp', platformChannelSpecifics);
  }
}
