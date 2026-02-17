import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:teman_keluarga/features/profile/domain/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthController {
  final Ref ref;

  // 1. Singleton Instance (Sesuai Dokumen v7)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool _isInitialized = false;

  AuthController(this.ref);

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      // 2. Explicit Initialize (Sesuai Dokumen v7)
      await _googleSignIn.initialize();
      _isInitialized = true;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      await _ensureInitialized();

      // 3. Sign In (v7 uses authenticate())
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Note: If cancelled, it throws GoogleSignInException (handled below).
      // So no null check needed for googleUser if return type is non-nullable.

      // ---------------------------------------------------------
      // PERUBAHAN UTAMA V7 DI SINI
      // ---------------------------------------------------------

      // 4. Ambil ID Token dari 'authentication'
      // Objek ini di v7 HANYA punya idToken, TIDAK ADA accessToken.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 5. Ambil Access Token dari 'authorizationClient'
      // Kita harus request authorization untuk scope dasar ('email') agar dapat accessToken.
      // Sesuai dokumentasi: "authorizationForScopes returns an access token..."
      final GoogleSignInClientAuthorization? googleAuthZ = await googleUser
          .authorizationClient
          .authorizationForScopes(['email', 'profile']);

      if (googleAuthZ == null) {
        throw Exception("Gagal mendapatkan otorisasi token Google.");
      }

      // 6. Gabungkan Keduanya untuk Firebase Credential
      // Firebase butuh idToken (Identity) dan accessToken (Authorization)
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthZ.accessToken, // Dari AuthorizationClient
        idToken: googleAuth.idToken, // Dari Authentication
      );

      // ---------------------------------------------------------

      // 7. Sign In ke Firebase Auth
      final userCred = await ref
          .read(firebaseAuthProvider)
          .signInWithCredential(credential);
      final user = userCred.user;

      // 8. Logic Firestore (Buat Profil Jika Baru)
      if (user != null) {
        await _createProfileIfNew(user);
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw Exception("Google Sign In Error (${e.code}): ${e.details}");
    } catch (e) {
      throw Exception("Gagal Login: $e");
    }
  }

  // Helper: Logic Buat Profil Firestore
  Future<void> _createProfileIfNew(User user) async {
    final docRef = ref
        .read(firestoreProvider)
        .collection('users')
        .doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final newUser = UserProfile(
        id: user.uid,
        name: user.displayName ?? "User Baru",
        email: user.email ?? "",
        photoUrl: user.photoURL ?? "https://ui-avatars.com/api/?name=User",
        role: UserRole.elderly,
        createdAt: DateTime.now(),
      );
      await docRef.set(newUser.toMap());
    }
  }

  // --- REGISTER EMAIL ---
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String roleStr,
    String? ageRange,
    List<String> enabledFeatures = const [
      'health',
      'activity',
      'memory',
      'chat',
    ],
  }) async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firestoreProvider);

    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user == null) throw Exception("Gagal membuat user auth");
    final uid = credential.user!.uid;

    final newUser = UserProfile(
      id: uid,
      name: name,
      email: email,
      photoUrl:
          "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random",
      role: roleStr == 'guardian' ? UserRole.guardian : UserRole.elderly,
      phone: phone,
      ageRange: ageRange,
      enabledFeatures: enabledFeatures,
      createdAt: DateTime.now(),
    );

    await firestore.collection('users').doc(uid).set(newUser.toMap());
  }

  // --- LOGIN EMAIL ---
  Future<void> login(String email, String password) async {
    await ref
        .read(firebaseAuthProvider)
        .signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  // --- PERBAIKAN LOGOUT ---
  Future<void> logout() async {
    try {
      // Pastikan Google Sign In sudah init sebelum sign out
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Abaikan error jika user tidak login via google
    }

    // Logout Firebase
    await ref.read(firebaseAuthProvider).signOut();
  }

  // --- PASSWORD RESET ---
  Future<void> sendPasswordResetEmail(String email) async {
    await ref
        .read(firebaseAuthProvider)
        .sendPasswordResetEmail(email: email.trim());
  }
}

final authControllerProvider = Provider((ref) => AuthController(ref));
