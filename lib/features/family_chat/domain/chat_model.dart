import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { text, image, audio }
enum ChatContextType { general, health, memory }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content; // Teks atau URL Gambar
  final ChatType type; 
  final ChatContextType contextType;
  final String? contextData; // Misal: "Obat Amlodipine"
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.contextType = ChatContextType.general,
    this.contextData,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name, // 'text', 'image'
      'contextType': contextType.name,
      'contextData': contextData,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(String docId, Map<String, dynamic> map) {
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Keluarga',
      content: map['content'] ?? '',
      type: ChatType.values.firstWhere((e) => e.name == map['type'], orElse: () => ChatType.text),
      contextType: ChatContextType.values.firstWhere((e) => e.name == map['contextType'], orElse: () => ChatContextType.general),
      contextData: map['contextData'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}