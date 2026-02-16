import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../domain/activity_model.dart';
import 'activity_provider.dart'; // IMPORT PROVIDER UTAMA

// Import tambahan untuk fitur Chat Otomatis
import 'package:silver_guide/features/family_chat/domain/chat_model.dart';
import 'package:silver_guide/features/family_chat/presentation/chat_actions.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';

class ActivityActions {
  final Ref ref;
  ActivityActions(this.ref);

  // 1. Upload Image Helper (Original)
  Future<String?> _uploadActivityImage(File imageFile, String userId) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_act.jpg";
      final ref = FirebaseStorage.instance.ref().child(
        'users/$userId/activities/$fileName',
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  // 2. Add Activity (Gabungan: Upload Image + Chat Log)
  Future<void> addActivityWithImage({
    required ActivityItem item,
    File? imageFile, // Jika user upload foto custom
  }) async {
    final repo = ref.read(activityRepositoryProvider);

    // A. Logic Upload Gambar (Original)
    String? finalImageUrl = item.customImage;
    if (imageFile != null) {
      finalImageUrl = await _uploadActivityImage(imageFile, item.userId);
    }

    // B. Buat Objek Baru
    final newItem = ActivityItem(
      id: item.id,
      userId: item.userId,
      title: item.title,
      iconKey: item.iconKey,
      colorValue: item.colorValue,
      motivationalMessage: item.motivationalMessage,
      customImage: finalImageUrl, // URL Firestore atau Path Asset
      isAssetImage:
          imageFile == null &&
          (item.isAssetImage), // Tetap true jika asset, false jika upload baru
    );

    // C. Simpan ke Database
    await repo.addActivity(newItem);
    
    // D. Refresh UI
    ref.invalidate(activityProvider(item.userId));

    // E. --- LOGIC CHAT (BARU) ---
    // Kirim notifikasi ke chat keluarga
    await _sendActivityLog(item.userId, "🌱 Menambahkan aktivitas baru: ${newItem.title}");
  }

  // 3. Toggle Activity (Gabungan: Toggle Status + Chat Log)
  Future<String> toggleActivity(
    String userId,
    String id,
    bool status,
    String message,
  ) async {
    await ref.read(activityRepositoryProvider).toggleActivity(id, status);

    // A. Refresh UI
    ref.invalidate(activityProvider(userId));
    ref.invalidate(activityProgressProvider(userId)); // Refresh juga pohonnya

    // B. --- LOGIC CHAT (BARU) ---
    // Jika status == false (artinya tadi belum selesai, sekarang jadi selesai), kirim log
    if (!status) {
       await _sendActivityLog(userId, "🌟 Telah menyelesaikan aktivitas.");
    }

    return !status ? message : "";
  }

  // 4. Delete Activity (Original)
  Future<void> deleteActivity(String userId, String id) async {
    await ref.read(activityRepositoryProvider).deleteActivity(id);
    ref.invalidate(activityProvider(userId));
  }

  // 5. Helper Private untuk Kirim Chat (BARU)
  Future<void> _sendActivityLog(String userId, String text) async {
    try {
      // Ambil data user untuk dapat familyId
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) return;
      
      final user = UserProfile.fromMap(userDoc.data()!);

      if (user.familyId != null && user.familyId!.isNotEmpty) {
        await ref.read(chatActionsProvider).sendSystemMessage(
          familyId: user.familyId!,
          senderId: user.id,
          senderName: user.name,
          text: text,
          contextType: ChatContextType.general, // Atau bisa dibuat tipe khusus Activity
          contextData: "Aktivitas Harian",
        );
      }
    } catch (e) {
      print("Gagal kirim log aktivitas: $e");
    }
  }
}

final activityActionsProvider = Provider((ref) => ActivityActions(ref));