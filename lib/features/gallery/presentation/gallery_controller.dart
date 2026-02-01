import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/memory_model.dart';
import '../data/memory_repository.dart';

class GalleryController extends AsyncNotifier<List<MemoryPost>> {
  
  @override
  FutureOr<List<MemoryPost>> build() async {
    final repo = ref.read(memoryRepositoryProvider);
    return repo.getMemories();
  }

  // Fungsi Tambah Jurnal Baru
  Future<void> postDiary(String content, String? imagePath) async {
    final repo = ref.read(memoryRepositoryProvider);
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await repo.addDiaryEntry(content, imagePath);
      return repo.getMemories(); // Refresh list
    });
  }

  // Fungsi React
  Future<void> reactToPost(String id, String emoji) async {
    final repo = ref.read(memoryRepositoryProvider);
    // Optimistic Update bisa ditambahkan di sini agar UI instan
    await repo.reactToPost(id, emoji);
    ref.invalidateSelf(); // Refresh data
  }
}

final galleryControllerProvider = 
    AsyncNotifierProvider<GalleryController, List<MemoryPost>>(() => GalleryController());