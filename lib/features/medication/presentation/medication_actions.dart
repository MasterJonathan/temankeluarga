import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Untuk TimeOfDay
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medication_repository.dart';
import '../domain/medication_model.dart';
import 'medication_provider.dart'; // IMPORT PROVIDER UTAMA

// Import tambahan untuk fitur Chat Otomatis
import 'package:silver_guide/features/family_chat/domain/chat_model.dart';
import 'package:silver_guide/features/family_chat/presentation/chat_actions.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';

// Import Service Notifikasi
import 'package:silver_guide/services/notification_service.dart';

class MedicationActions {
  final Ref ref;
  MedicationActions(this.ref);

  // 1. Toggle Status & Kirim Log ke Chat (LOGIC LAMA + CHAT)
  Future<void> toggleTaskStatus(String userId, String medId, bool currentStatus) async {
    final repo = ref.read(medicationRepositoryProvider);
    
    // A. Update Database (Core)
    await repo.toggleTaskStatus(medId, currentStatus);
    
    // B. FORCE REFRESH UI
    ref.invalidate(medicationProvider(userId));

    // C. --- LOGIC CHAT ---
    // Kirim notif jika status berubah jadi "Sudah Diminum"
    if (!currentStatus) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (!userDoc.exists || userDoc.data() == null) return;
        
        final user = UserProfile.fromMap(userDoc.data()!);

        if (user.familyId != null && user.familyId!.isNotEmpty) {
          await ref.read(chatActionsProvider).sendSystemMessage(
            familyId: user.familyId!,
            senderId: user.id,
            senderName: user.name,
            text: "✅ Telah meminum obat.",
            contextType: ChatContextType.health,
            contextData: "Cek Kesehatan", 
          );
        }
      } catch (e) {
        debugPrint("Gagal kirim log obat ke chat: $e");
      }
    }
  }

  // 2. Tambah Obat & Jadwalkan Notifikasi (LOGIC BARU)
  Future<void> addMedication(MedicationTask task) async {
    final repo = ref.read(medicationRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    // A. Simpan ke Database
    await repo.addMedication(task);
    ref.invalidate(medicationProvider(task.userId));

    // B. --- LOGIC NOTIFIKASI ---
    try {
      // 1. Parse jam string "HH:mm" ke TimeOfDay
      final timeParts = task.time.split(":");
      final timeOfDay = TimeOfDay(
        hour: int.parse(timeParts[0]), 
        minute: int.parse(timeParts[1])
      );

      // 2. Generate ID Unik untuk Notifikasi (Int)
      // Menggunakan hashCode dari kombinasi userId + title + time agar unik
      final uniqueNotifId = "${task.userId}_${task.title}_${task.time}".hashCode;

      // 3. Jadwalkan Notifikasi Harian
      await notifService.scheduleMedication(
        id: uniqueNotifId,
        title: "Waktunya Minum Obat 💊",
        body: "Jangan lupa minum ${task.title} sekarang ya.",
        time: timeOfDay,
      );
    } catch (e) {
      debugPrint("Gagal menjadwalkan notifikasi: $e");
    }
  }

  // 3. Hapus Obat & Batalkan Notifikasi (LOGIC BARU)
  Future<void> deleteMedication(String userId, String medId) async {
    final repo = ref.read(medicationRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    // A. --- LOGIC CANCEL NOTIFIKASI ---
    // Kita perlu fetch data dulu sebelum hapus untuk recreate ID notifikasi
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('medications')
          .doc(medId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final title = data['title'] as String;
        final time = data['time'] as String;
        
        // Recreate ID yang sama seperti saat Add
        final uniqueNotifId = "${userId}_${title}_$time".hashCode;
        
        // Batalkan Notifikasi
        await notifService.cancelNotification(uniqueNotifId);
      }
    } catch (e) {
      debugPrint("Gagal membatalkan notifikasi: $e");
    }

    // B. Hapus dari Database
    await repo.deleteMedication(medId);
    
    // C. Refresh UI
    ref.invalidate(medicationProvider(userId));
  }
}

final medicationActionsProvider = Provider((ref) => MedicationActions(ref));