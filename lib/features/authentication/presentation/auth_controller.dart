import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// 1. Service: Access to Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 2. State: Listen to real authentication state changes (Login/Logout)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// 3. Controller: Handle User Actions
class AuthController {
  final Ref ref;

  AuthController(this.ref);

  // Login with Email & Password
  Future<void> login(String email, String password) async {
    await ref
        .read(firebaseAuthProvider)
        .signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  // Login with Google
  Future<void> loginWithGoogle() async {
    // 1. Trigger Google Sign In flow
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // 2. Get auth details from request
    final googleAuth = await googleUser?.authentication;

    if (googleAuth != null) {
      // 3. Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
    }
  }

  // Register new account
  Future<void> register(String email, String password) async {
    await ref
        .read(firebaseAuthProvider)
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
  }

  // Logout
  Future<void> logout() async {
    await ref.read(firebaseAuthProvider).signOut();
  }
}

final authControllerProvider = Provider((ref) => AuthController(ref));
