import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io'; // Untuk Platform check

// Import Tambahan
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Instance FCM
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. Init Timezone & Local Settings (Kode Lama)
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (e) {
      debugPrint("Timezone Error: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notifikasi diklik: ${details.payload}");
      },
    );

    // 2. Request Permissions (Local + FCM)
    await _requestPermissions();

    // 3. Init Firebase Messaging (Kode Baru)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Izin Notifikasi FCM Diberikan');
      
      // A. Upload Token ke Firestore
      await _saveDeviceToken();
      
      // B. Listen Pesan saat App di Depan (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Pesan masuk saat app dibuka: ${message.notification?.title}");
        
        // Tampilkan sebagai Notifikasi Lokal (Pop-up)
        // Agar user tau ada chat meski sedang buka app
        if (message.notification != null) {
          showLocalNotification(
            title: message.notification!.title ?? "Pesan Baru",
            body: message.notification!.body ?? "",
          );
        }
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Minta izin Notifikasi (Android 13+)
      await androidImplementation?.requestNotificationsPermission();
      
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // --- FCM METHODS (BARU) ---

  // Simpan Token HP ke Database User
  Future<void> _saveDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      User? user = FirebaseAuth.instance.currentUser;

      if (token != null && user != null) {
        // Simpan di field array agar 1 user bisa punya banyak HP (multi-device)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmTokens': FieldValue.arrayUnion([token]), 
            });
        debugPrint("Device Token Saved: $token");
      }
    } catch (e) {
      debugPrint("Gagal simpan token FCM: $e");
    }
  }

  // Fungsi helper untuk menampilkan notif dari FCM ke UI (Chat)
  Future<void> showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_channel', // Channel ID Khusus Chat
      'Obrolan Keluarga',
      channelDescription: 'Notifikasi pesan baru',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID Random
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // --- LOCAL NOTIFICATION METHODS (LAMA) ---

  Future<void> scheduleMedication({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {

    final location = tz.local;
    
    final now = tz.TZDateTime.now(location);
    
    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Jika waktu sudah lewat hari ini, jadwalkan besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint("--- DEBUG JADWAL NOTIFIKASI ---");
    debugPrint("ID: $id");
    debugPrint("Waktu Sekarang: $now");
    debugPrint("Jadwal: $scheduledDate");
    debugPrint("-------------------------------");

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel_v2', // Channel ID Obat
            'Jadwal Obat Penting',   
            channelDescription: 'Alarm bunyi untuk jadwal minum obat',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher', 
            
            // TAMBAHAN AGAR LEBIH AGRESIF:
            fullScreenIntent: true, // Mencoba muncul di lockscreen
            category: AndroidNotificationCategory.alarm, // Memberi tahu OS ini ALARM
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Wajib izin Exact Alarm
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("SUKSES MENJADWALKAN ke System Android");
    } catch (e) {
      debugPrint("GAGAL MENJADWALKAN: $e");
      // Biasanya error karena permission 'SCHEDULE_EXACT_ALARM' belum allow
    }
  }
  
  // Fungsi Test Instant
  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      0, 
      "Test Notifikasi", 
      "Ini adalah tes notifikasi instan.", 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel', 
          'Test Channel',
          importance: Importance.max,
          priority: Priority.high,
        )
      )
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});