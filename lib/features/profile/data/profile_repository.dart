import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math'; // Untuk generate kode acak
import 'dart:typed_data'; // Import for Uint8List
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

  // 2. Request Join Keluarga (GANTI joinFamily)
  Future<void> requestJoinFamily(String familyCode) async {
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

    final familyDocId = familyQuery.docs.first.id;

    // Masukkan ke array 'requests' (Bukan memberIds)
    await _firestore.collection('families').doc(familyDocId).update({
      'requests': FieldValue.arrayUnion([uid])
    });

    // User status update (optional, biar UI tau dia lagi pending)
    await _firestore.collection('users').doc(uid).update({
      'joinStatus': 'pending', // pending, approved
    });
  }

  // 3. Buat Keluarga Baru (Khusus Guardian) - UPDATE: Tambah field requests
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
      'requests': [], // Field baru ditambahkan sesuai instruksi
    });

    await _firestore.collection('users').doc(uid).update({'familyId': code});

    return code;
  }

  // 4. TERIMA REQUEST (Khusus Guardian) - BARU
  Future<void> acceptJoinRequest(String familyId, String targetUserId) async {
    // Pindahkan dari requests ke memberIds
    await _firestore.collection('families').doc(familyId).update({
      'requests': FieldValue.arrayRemove([targetUserId]),
      'memberIds': FieldValue.arrayUnion([targetUserId])
    });

    // Update User Profile
    await _firestore.collection('users').doc(targetUserId).update({
      'familyId': familyId, // Resmi punya familyId
      'joinStatus': 'approved',
    });
  }

  // 5. TOLAK / KICK MEMBER - BARU
  Future<void> removeMember(String familyId, String targetUserId) async {
    // Hapus dari family
    await _firestore.collection('families').doc(familyId).update({
      'memberIds': FieldValue.arrayRemove([targetUserId]),
      'requests': FieldValue.arrayRemove([targetUserId]), // Jaga-jaga kalau masih di request
    });

    // Reset User Profile
    await _firestore.collection('users').doc(targetUserId).update({
      'familyId': FieldValue.delete(),
      'joinStatus': FieldValue.delete(),
    });
  }

  // 6. UPDATE FITUR LANSIA - BARU
  Future<void> updateElderlyFeatures(String elderlyId, List<String> features) async {
    await _firestore.collection('users').doc(elderlyId).update({
      'enabledFeatures': features,
    });
  }

  // 7. AMBIL REQUESTS (Stream) - BARU
  Stream<List<UserProfile>> watchJoinRequests(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = List<String>.from(snapshot.data()?['requests'] ?? []);
          if (requests.isEmpty) return [];

          // Fetch user profiles dari ID yang ada di request
          // (Di production sebaiknya limit max 10 query 'in')
          final usersQuery = await _firestore.collection('users').where(FieldPath.documentId, whereIn: requests).get();
          return usersQuery.docs.map((d) => UserProfile.fromMap(d.data())).toList();
        });
  }

  // --- Method Lama Lainnya ---

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

  // Update Data Profil (Nama & HP)
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }

  // Update Foto Profil
  // Gunakan Uint8List agar support Flutter Web
  Future<String> updateProfilePicture(String uid, Uint8List imageBytes) async {
    final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');

    // Metadata agar browser tahu ini adalah image
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putData(imageBytes, metadata);
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(uid).update({'photoUrl': url});

    return url;
  }

  // Update Text Size
  Future<void> updateTextSize(String uid, double size) async {
    await _firestore.collection('users').doc(uid).update({'textSize': size});
  }

  // Keluar dari Keluarga
  Future<void> leaveFamily() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final familyId = userDoc.data()?['familyId'];

    if (familyId != null && familyId.isNotEmpty) {
      // 1. Update User: Hapus familyId
      await _firestore.collection('users').doc(uid).update({
        'familyId': FieldValue.delete(),
      });

      // 2. Update Family: Hapus member dari list
      await _firestore.collection('families').doc(familyId).update({
        'memberIds': FieldValue.arrayRemove([uid]),
      });
    }
  }
}

// Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});