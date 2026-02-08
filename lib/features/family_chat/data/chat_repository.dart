import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRepository(this._firestore, this._storage);

  // 1. Kirim Pesan
  Future<void> sendMessage(String familyId, ChatMessage message) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('messages')
        .add(message.toMap());
  }

  // 2. Upload Gambar Chat
  Future<String?> uploadChatImage(File imageFile, String familyId) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = _storage.ref().child('families/$familyId/chat/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Chat Upload Error: $e");
      return null;
    }
  }

  // 3. Stream Pesan Realtime
  Stream<List<ChatMessage>> watchMessages(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Pesan baru di bawah (logic UI nanti di-reverse)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});