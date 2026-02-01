import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/memory_model.dart';

class MemoryRepository {
  final List<MemoryPost> _memories = [
    MemoryPost(
      id: '1',
      content: 'Alhamdulillah, hari ini rasanya badan lebih segar. Tadi pagi sempat jalan kaki sedikit di depan rumah sama Ibu.',
      imageUrl: null, // Hanya teks
      date: DateTime.now(), // Hari ini
      reactionCounts: {'❤️': 3, '👍': 1},
      selectedReaction: '❤️',
    ),
    MemoryPost(
      id: '2',
      content: 'Cucu kesayangan mampir bawakan martabak. Senang sekali rumah jadi ramai.',
      imageUrl: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=500&q=80',
      date: DateTime.now().subtract(const Duration(days: 1)), // Kemarin
      reactionCounts: {'🥰': 5},
    ),
    MemoryPost(
      id: '3',
      content: 'Hujan deras dari sore. Jadi teringat masa dulu waktu anak-anak masih kecil sering main hujan.',
      imageUrl: null,
      date: DateTime.now().subtract(const Duration(days: 1)),
      reactionCounts: {'🙏': 2},
    ),
  ];

  Future<List<MemoryPost>> getMemories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _memories;
  }

  // Input sekarang menerima Teks + Opsional Image Path
  Future<MemoryPost> addDiaryEntry(String text, String? imagePath) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final newPost = MemoryPost(
      id: DateTime.now().toIso8601String(),
      content: text,
      imageUrl: imagePath, // Bisa null
      date: DateTime.now(),
      reactionCounts: {},
    );
    
    _memories.insert(0, newPost);
    return newPost;
  }

  // Update Reaksi
  Future<void> reactToPost(String id, String emoji) async {
    // Logic update backend dummy
    final index = _memories.indexWhere((e) => e.id == id);
    if (index != -1) {
      final old = _memories[index];
      // Simple toggle logic for demo
      final newCounts = Map<String, int>.from(old.reactionCounts);
      
      // Jika sudah pilih ini, remove (unlike). Jika belum, add.
      if (old.selectedReaction == emoji) {
        newCounts[emoji] = (newCounts[emoji] ?? 1) - 1;
        if (newCounts[emoji] == 0) newCounts.remove(emoji);
        _memories[index] = old.copyWith(selectedReaction: null, reactionCounts: newCounts);
      } else {
        // Remove old reaction if exists
        if (old.selectedReaction != null) {
           final oldEmoji = old.selectedReaction!;
           newCounts[oldEmoji] = (newCounts[oldEmoji] ?? 1) - 1;
           if (newCounts[oldEmoji] == 0) newCounts.remove(oldEmoji);
        }
        // Add new
        newCounts[emoji] = (newCounts[emoji] ?? 0) + 1;
        _memories[index] = old.copyWith(selectedReaction: emoji, reactionCounts: newCounts);
      }
    }
  }
}

final memoryRepositoryProvider = Provider((ref) => MemoryRepository());