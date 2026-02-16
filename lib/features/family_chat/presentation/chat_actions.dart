import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../domain/chat_model.dart';

class ChatActions {
  final Ref ref;
  ChatActions(this.ref);

  // 1. Kirim Pesan Teks (Original)
  Future<void> sendTextMessage({
    required String familyId,
    required String senderId,
    required String senderName,
    required String text,
    ChatContextType contextType = ChatContextType.general,
    String? contextData,
  }) async {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      content: text,
      type: ChatType.text,
      timestamp: DateTime.now(),
      contextType: contextType,
      contextData: contextData,
    );
    
    await ref.read(chatRepositoryProvider).sendMessage(familyId, message);
  }

  // 2. Kirim Pesan Gambar (Original)
  Future<void> sendImageMessage({
    required String familyId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    final imageUrl = await repo.uploadChatImage(imageFile, familyId);

    if (imageUrl != null) {
      final message = ChatMessage(
        id: '',
        senderId: senderId,
        senderName: senderName,
        content: imageUrl,
        type: ChatType.image,
        timestamp: DateTime.now(),
      );
      await repo.sendMessage(familyId, message);
    }
  }

  // 3. Kirim Pesan Sistem / Otomatis (BARU)
  Future<void> sendSystemMessage({
    required String familyId,
    required String senderId,
    required String senderName,
    required String text,
    ChatContextType contextType = ChatContextType.general,
    String? contextData,
  }) async {
    // Kita gunakan format khusus, misal diawali [Info] atau icon
    // Pesan ini tetap bertipe text, namun biasanya senderName/Id yang membedakan di UI
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      senderName: senderName,
      content: text, // Isi pesan otomatis
      type: ChatType.text,
      timestamp: DateTime.now(),
      contextType: contextType,
      contextData: contextData,
    );
    
    // Kirim ke repository
    await ref.read(chatRepositoryProvider).sendMessage(familyId, message);
  }
}

final chatActionsProvider = Provider((ref) => ChatActions(ref));