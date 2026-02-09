import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/memory_model.dart';

class MemoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MemoryRepository(this._firestore, this._storage);

  // 1. Upload Gambar ke Firebase Storage
  Future<String?> uploadImage(File imageFile, String familyId) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child(
        'families/$familyId/memories/$fileName.jpg',
      );

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  // 2. Simpan Postingan
  Future<void> addMemory(MemoryPost post) async {
    await _firestore.collection('memories').add(post.toMap());
  }

  // 3. Ambil Postingan (Berdasarkan Family ID)
  Stream<List<MemoryPost>> watchMemories(String familyId) {
    return _firestore
        .collection('memories')
        .where('familyId', isEqualTo: familyId)
        .orderBy('date', descending: true) // Terbaru di atas
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MemoryPost.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // 4. Toggle Reaksi
  Future<void> reactToPost(String postId, String userId, String emoji) async {
    final docRef = _firestore.collection('memories').doc(postId);
    final doc = await docRef.get();

    if (doc.exists) {
      final currentReactions = Map<String, String>.from(
        doc.data()?['reactions'] ?? {},
      );

      // Jika user sudah bereaksi dengan emoji yg sama -> Hapus (Unlike)
      if (currentReactions[userId] == emoji) {
        currentReactions.remove(userId);
      } else {
        // Jika belum atau ganti emoji -> Update
        currentReactions[userId] = emoji;
      }

      await docRef.update({'reactions': currentReactions});
    }
  }
}

final memoryRepositoryProvider = Provider((ref) {
  return MemoryRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});
