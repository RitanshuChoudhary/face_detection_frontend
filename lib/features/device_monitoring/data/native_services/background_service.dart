import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:telephony/telephony.dart';
import '../local_db/database_helper.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // For Android, we need a notification channel for the foreground service
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'monitoring_channel', 
    'FaceTrack Monitoring',
    description: 'Running background data monitoring',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'monitoring_channel',
      initialNotificationTitle: 'FaceTrack Service',
      initialNotificationContent: 'Monitoring active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final db = DatabaseHelper();

  // 1. Listen for Notifications (WhatsApp, etc.)
  NotificationListenerService.notificationsStream.listen((event) {
    if (event.packageName != null) {
      db.insertLog({
        'type': 'NOTIFICATION',
        'sender': event.title ?? 'Unknown',
        'content': event.content ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'package_name': event.packageName,
      });
    }
  });

  // 2. Listen for SMS
  final Telephony telephony = Telephony.instance;
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) {
      db.insertLog({
        'type': 'SMS',
        'sender': message.address ?? 'Unknown',
        'content': message.body ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'package_name': 'com.android.sms',
      });
    },
    listenInBackground: true,
  );

  // Periodic Timer for Sync or Status Update
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "FaceTrack Monitoring",
          content: "Last active: ${DateTime.now().hour}:${DateTime.now().minute}",
        );
      }
    }
    
    // Placeholder for background sync
    // final unsynced = await db.getUnsyncedLogs();
    // if (unsynced.isNotEmpty) {
    //   // Attempt to send to your backend
    // }
  });
}
