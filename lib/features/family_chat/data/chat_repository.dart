import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_model.dart';

class ChatRepository {
  // Database Chat Sementara
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'Bapak, nanti sore aku mampir ya bawakan buah.',
      isMe: false, // Dari Anak
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  Future<List<ChatMessage>> getMessages() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messages;
  }

  Future<ChatMessage> sendMessage(String text, ChatContextType type, String? contextData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newMessage = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isMe: true,
      time: DateTime.now(),
      contextType: type,
      contextData: contextData,
    );
    
    _messages.add(newMessage);
    return newMessage;
  }

  // Simulasi Balasan Otomatis dari Anak
  Future<ChatMessage> simulateReply(ChatContextType type) async {
    await Future.delayed(const Duration(seconds: 2)); // Nunggu 2 detik seolah ngetik
    
    String replyText = "Oke pak, sehat selalu ya!";
    if (type == ChatContextType.health) {
      replyText = "Wah bagus pak! Dijaga terus ya minum obatnya.";
    } else if (type == ChatContextType.memory) {
      replyText = "Lucu banget fotonya pak! Itu kapan?";
    }

    final reply = ChatMessage(
      id: DateTime.now().toString(),
      text: replyText,
      isMe: false,
      time: DateTime.now(),
    );
    _messages.add(reply);
    return reply;
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository());