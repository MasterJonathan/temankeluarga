import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_model.dart';
import '../data/chat_repository.dart';

final chatProvider = 
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, familyId) {
  
  if (familyId.isEmpty) return Stream.value([]);

  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(familyId);
});