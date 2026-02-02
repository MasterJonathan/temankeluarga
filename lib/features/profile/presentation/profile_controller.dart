import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import '../data/profile_repository.dart';

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  FutureOr<UserProfile> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.getCurrentUser();
  }

  // Fungsi untuk Demo: Ganti Peran (User -> Guardian -> User)
  Future<void> toggleRoleForDemo() async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.switchRoleDemo());
  }

  // Fungsi Gabung Keluarga
  Future<void> joinFamily(String code) async {
    final repo = ref.read(profileRepositoryProvider);
    // Kita tidak set loading full screen, tapi biarkan UI menangani loading state tombol
    await repo.joinFamily(code);
    ref.invalidateSelf(); // Refresh data user
  }
}

final profileControllerProvider = 
    AsyncNotifierProvider<ProfileController, UserProfile>(() => ProfileController());