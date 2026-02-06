import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/features/authentication/presentation/auth_controller.dart'; // Import Auth Controller
import '../domain/user_model.dart';
import '../data/profile_repository.dart';


class ProfileController extends StreamNotifier<UserProfile> {
  
  @override
  Stream<UserProfile> build() {
    // 1. LISTEN KE AUTH STATE
    // Ini kuncinya! Jika user logout (jadi null) atau login user baru,
    // baris ini akan memicu ProfileController untuk dijalankan ulang (Rebuild).
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Jika tidak ada user login, return stream kosong atau error
          return const Stream.empty();
        }
        // Jika ada user, panggil repository dengan UID yang baru
        final repo = ref.read(profileRepositoryProvider);
        return repo.watchUser(user.uid);
      },
      error: (e, st) => Stream.error(e, st),
      loading: () => const Stream.empty(),
    );
  }

  // Fungsi Action tetap sama
  Future<void> joinFamily(String code) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.joinFamily(code.toUpperCase().trim());
  }

  Future<void> createFamily() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.createFamilyGroup();
  }

  
}

final profileControllerProvider = 
    StreamNotifierProvider<ProfileController, UserProfile>(() => ProfileController());