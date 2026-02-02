import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// State Provider: Apakah user sudah login?
// Default: false (Belum login)
final authStateProvider = StateProvider<bool>((ref) => false);

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<void> loginWithGoogle() async {
    // Simulasi loading network
    await Future.delayed(const Duration(seconds: 2)); 
    // Set status jadi login
    ref.read(authStateProvider.notifier).state = true; 
  }

  Future<void> loginWithPhone(String phone) async {
    await Future.delayed(const Duration(seconds: 2));
    ref.read(authStateProvider.notifier).state = true;
  }

  void logout() {
    ref.read(authStateProvider.notifier).state = false;
  }
}

final authControllerProvider = Provider((ref) => AuthController(ref));