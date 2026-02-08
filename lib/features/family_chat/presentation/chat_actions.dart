import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../domain/chat_model.dart';

class ChatActions {
  final Ref ref;
  ChatActions(this.ref);

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
}

final chatActionsProvider = Provider((ref) => ChatActions(ref));