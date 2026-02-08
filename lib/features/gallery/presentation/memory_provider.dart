import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/memory_model.dart';
import '../data/memory_repository.dart';

// Provider untuk membaca data (Butuh familyId)
final memoryProvider = 
    StreamProvider.autoDispose.family<List<MemoryPost>, String>((ref, familyId) {
  
  if (familyId.isEmpty) return Stream.value([]);

  final repo = ref.watch(memoryRepositoryProvider);
  return repo.watchMemories(familyId);
});