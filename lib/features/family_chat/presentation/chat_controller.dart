import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_model.dart';
import '../data/chat_repository.dart';

class ChatController extends AsyncNotifier<List<ChatMessage>> {
  @override
  FutureOr<List<ChatMessage>> build() async {
    final repo = ref.read(chatRepositoryProvider);
    return repo.getMessages();
  }

  Future<void> sendMessage(String text, {ChatContextType type = ChatContextType.general, String? extraData}) async {
    final repo = ref.read(chatRepositoryProvider);
    
    // 1. Kirim Pesan Kita
    final myMsg = await repo.sendMessage(text, type, extraData);
    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, myMsg]);

    // 2. Simulasi Anak Membalas (setelah delay)
    final replyMsg = await repo.simulateReply(type);
    final updatedList = state.value ?? [];
    state = AsyncValue.data([...updatedList, replyMsg]);
  }
}

final chatControllerProvider = 
    AsyncNotifierProvider<ChatController, List<ChatMessage>>(() => ChatController());