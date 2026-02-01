enum ChatContextType { general, health, memory }

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;        // True = Lansia, False = Anak/Keluarga
  final DateTime time;
  final ChatContextType contextType; 
  final String? contextData; // Misal: "Sudah minum obat Amlodipine"

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.contextType = ChatContextType.general,
    this.contextData,
  });
}