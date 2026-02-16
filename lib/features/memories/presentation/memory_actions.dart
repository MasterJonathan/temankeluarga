import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/features/memories/presentation/memory_provider.dart';
import '../data/memory_repository.dart';
import '../domain/memory_model.dart';

// Import tambahan untuk fitur Chat Otomatis
import 'package:silver_guide/features/family_chat/domain/chat_model.dart';
import 'package:silver_guide/features/family_chat/presentation/chat_actions.dart';

class MemoryActions {
  final Ref ref;
  MemoryActions(this.ref);

  // 1. Post Memory (Upload Image + Save to DB + Send Chat Log)
  Future<void> postMemory({
    required String familyId,
    required String authorId,
    required String authorName,
    required String content,
    File? imageFile,
  }) async {
    final repo = ref.read(memoryRepositoryProvider);
    
    String? imageUrl;
    
    // A. Upload foto jika ada
    if (imageFile != null) {
      imageUrl = await repo.uploadImage(imageFile, familyId);
    }

    // B. Buat Object Memory
    final newPost = MemoryPost(
      id: '', // Auto Generate di Repo nanti
      familyId: familyId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      imageUrl: imageUrl,
      date: DateTime.now(),
    );

    // C. Simpan ke Repository
    await repo.addMemory(newPost);
    
    // D. Invalidate UI
    // Tidak perlu invalidate manual karena kita listen ke Query Stream yang sama
    // Tapi untuk keamanan, boleh di-invalidate agar memaksa fetch ulang
    ref.invalidate(memoryProvider(familyId));

    // E. --- LOGIC CHAT (BARU) ---
    // Kirim notifikasi ke chat keluarga bahwa ada memori baru
    try {
      await ref.read(chatActionsProvider).sendSystemMessage(
        familyId: familyId,
        senderId: authorId,
        senderName: authorName,
        text: "📸 Membagikan kenangan baru.",
        contextType: ChatContextType.memory, // Icon konteks galeri/memori
        contextData: "Galeri Keluarga",
      );
    } catch (e) {
      print("Gagal kirim log memori ke chat: $e");
    }
  }

  // 2. React to Post (Original)
  Future<void> reactToPost(String familyId, String postId, String userId, String emoji) async {
    final repo = ref.read(memoryRepositoryProvider);
    await repo.reactToPost(postId, userId, emoji);
    // UI otomatis update via Stream, tapi kita invalidate biar responsif
    ref.invalidate(memoryProvider(familyId)); 
  }

  Future<void> deleteMemory(String familyId, String postId, String? imageUrl) async {
    final repo = ref.read(memoryRepositoryProvider);
    
    // 1. Panggil Repo
    await repo.deleteMemory(postId, imageUrl);
    
    // 2. Refresh UI
    ref.invalidate(memoryProvider(familyId));

  }

  Future<void> generateDailyArt({
    required String familyId,
    required String userId,
    required String userName,
    required DateTime date,
  }) async {
    try {
      final dateString = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
      
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast2');
      
      final result = await functions
          .httpsCallable('generateDailyMemoryArt')
          .call({
            'dateString': dateString,
            'familyId': familyId,
            'userId': userId,
            'userName': userName,
          });
      
      // Sukses! Data sudah masuk Firestore, UI akan update otomatis via Stream.
      print("Generate Success: ${result.data}");
      
    } catch (e) {
      throw Exception("Gagal generate: $e");
    }
  }
}

final memoryActionsProvider = Provider((ref) => MemoryActions(ref));