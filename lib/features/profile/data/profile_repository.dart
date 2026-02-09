import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math'; // Untuk generate kode acak
import '../domain/user_model.dart';

class ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileRepository(this._auth, this._firestore);

  // 1. Stream User Profil (Realtime)
  Stream<UserProfile> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Return user kosong atau throw error, tergantung preferensi
        throw Exception("Profil tidak ditemukan");
      }
      return UserProfile.fromMap(snapshot.data()!);
    });
  }

  // 2. Gabung Keluarga (Update field familyId)
  Future<void> joinFamily(String familyCode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final familyQuery = await _firestore
        .collection('families')
        .where('inviteCode', isEqualTo: familyCode)
        .limit(1)
        .get();

    if (familyQuery.docs.isEmpty) {
      throw Exception("Kode Keluarga tidak ditemukan.");
    }

    await _firestore.collection('users').doc(uid).update({
      'familyId': familyCode,
    });

    final familyDocId = familyQuery.docs.first.id;
    await _firestore.collection('families').doc(familyDocId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
    });
  }

  // 3. Buat Keluarga Baru (Khusus Guardian)
  Future<String> createFamilyGroup() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("No User");

    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final String code = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    await _firestore.collection('families').doc(code).set({
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'memberIds': [uid],
    });

    await _firestore.collection('users').doc(uid).update({'familyId': code});

    return code;
  }


   Future<List<UserProfile>> getFamilyMembers(String familyId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .get();
        
    if (querySnapshot.docs.isEmpty) return [];

    return querySnapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data()))
        .toList();
  }

  // 4. Update Data Profil (Nama & HP)
  Future<void> updateProfile({required String uid, required String name, required String phone}) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }

  // 5. Update Foto Profil
  // (Pastikan package firebase_storage sudah diimport)
  Future<String> updateProfilePicture(String uid, File imageFile) async {
    final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();
    
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': url,
    });
    
    return url;
  }
}

// Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});
