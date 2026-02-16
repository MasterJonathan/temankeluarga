import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io'; // Untuk Platform check

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // HARDCODE KE WIB (ASIA/JAKARTA) UNTUK TESTING
    // Pastikan ini sesuai lokasi Anda
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (e) {
      print("Timezone Error: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Tambahkan pengaturan Linux/iOS jika perlu (kosongkan dulu)
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Notifikasi diklik: ${details.payload}");
      },
    );

    // --- REQUEST PERMISSION EXPLICITLY ---
    await _requestPermissions();
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

    print("--- DEBUG JADWAL NOTIFIKASI ---");
    print("ID: $id");
    print("Waktu Sekarang: $now");
    print("Jadwal: $scheduledDate");
    print("-------------------------------");

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_channel_v2', // <--- GANTI ID INI (Misal tambah _v2)
            'Jadwal Obat Penting',   // <--- GANTI NAMA JUGA
            channelDescription: 'Alarm bunyi untuk jadwal minum obat',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // Pastikan icon ini benar. Jika ragu, pakai mipmap/ic_launcher
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
      print("SUKSES MENJADWALKAN ke System Android");
    } catch (e) {
      print("GAGAL MENJADWALKAN: $e");
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