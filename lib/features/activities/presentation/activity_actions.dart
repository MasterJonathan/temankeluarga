import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../domain/activity_model.dart';
import 'activity_provider.dart'; // IMPORT PROVIDER UTAMA

class ActivityActions {
  final Ref ref;
  ActivityActions(this.ref);

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

  Future<void> addActivityWithImage({
    required ActivityItem item,
    File? imageFile, // Jika user upload foto custom
  }) async {
    final repo = ref.read(activityRepositoryProvider);

    // Jika ada file custom, upload dulu
    String? finalImageUrl = item.customImage;
    if (imageFile != null) {
      finalImageUrl = await _uploadActivityImage(imageFile, item.userId);
    }

    // Buat objek baru dengan URL hasil upload (jika ada)
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

    await repo.addActivity(newItem);
    ref.invalidate(activityProvider(item.userId));
  }

  Future<String> toggleActivity(
    String userId,
    String id,
    bool status,
    String message,
  ) async {
    await ref.read(activityRepositoryProvider).toggleActivity(id, status);

    // Refresh UI (SOLUSI)
    ref.invalidate(activityProvider(userId));
    ref.invalidate(activityProgressProvider(userId)); // Refresh juga pohonnya

    return !status ? message : "";
  }

  Future<void> deleteActivity(String userId, String id) async {
    await ref.read(activityRepositoryProvider).deleteActivity(id);
    ref.invalidate(activityProvider(userId));
  }
}

final activityActionsProvider = Provider((ref) => ActivityActions(ref));
