import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryPost {
  final String id;
  final String familyId; // Shared per keluarga
  final String authorId; // Siapa yang posting
  final String authorName; // Cache nama author
  final String content;
  final String? imageUrl;
  final DateTime date;
  
  // Map untuk menyimpan reaksi: {'userId_A': '❤️', 'userId_B': '👍'}
  final Map<String, String> reactions; 

  MemoryPost({
    required this.id,
    required this.familyId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageUrl,
    required this.date,
    this.reactions = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'reactions': reactions,
    };
  }

  factory MemoryPost.fromMap(String docId, Map<String, dynamic> map) {
    return MemoryPost(
      id: docId,
      familyId: map['familyId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Keluarga',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      date: (map['date'] as Timestamp).toDate(),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
    );
  }
}