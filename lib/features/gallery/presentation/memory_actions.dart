import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/features/gallery/presentation/memory_provider.dart';
import '../data/memory_repository.dart';
import '../domain/memory_model.dart';

class MemoryActions {
  final Ref ref;
  MemoryActions(this.ref);

  Future<void> postMemory({
    required String familyId,
    required String authorId,
    required String authorName,
    required String content,
    File? imageFile,
  }) async {
    final repo = ref.read(memoryRepositoryProvider);
    
    String? imageUrl;
    
    // Upload foto jika ada
    if (imageFile != null) {
      imageUrl = await repo.uploadImage(imageFile, familyId);
    }

    final newPost = MemoryPost(
      id: '', // Auto Generate
      familyId: familyId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      imageUrl: imageUrl,
      date: DateTime.now(),
    );

    await repo.addMemory(newPost);
    // Tidak perlu invalidate manual karena kita listen ke Query Stream yang sama
    // Tapi untuk keamanan, boleh di-invalidate
    ref.invalidate(memoryProvider(familyId));
  }

  Future<void> reactToPost(String familyId, String postId, String userId, String emoji) async {
    final repo = ref.read(memoryRepositoryProvider);
    await repo.reactToPost(postId, userId, emoji);
    // UI otomatis update via Stream, tapi kita invalidate biar responsif
    ref.invalidate(memoryProvider(familyId)); 
  }
}

final memoryActionsProvider = Provider((ref) => MemoryActions(ref));