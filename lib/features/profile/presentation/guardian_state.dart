import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:teman_keluarga/features/profile/domain/user_model.dart';
import 'package:teman_keluarga/features/profile/presentation/profile_controller.dart';

// --- State Pilihan Manual ---
class ViewedElderlyNotifier extends StateNotifier<String?> {
  ViewedElderlyNotifier() : super(null);

  @override
  set state(String? value) => super.state = value;

  void clear() => state = null; // Fungsi Reset
}

final viewedElderlyIdProvider = StateProvider<String?>((ref) => null);

// --- PROVIDER BARU: THE BRAIN (VERSI NOTIFIER) ---
class ActiveProfileIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    // 1. Dengarkan kedua sumber data
    final userAsync = ref.watch(profileControllerProvider);
    final selectedId = ref.watch(viewedElderlyIdProvider);

    // 2. Tentukan state awal
    final user = userAsync.value;
    if (user == null) return null;
    if (user.role == UserRole.elderly) return user.id;
    if (user.role == UserRole.guardian) return selectedId;
    return null;
  }
}

final activeProfileIdProvider =
    NotifierProvider<ActiveProfileIdNotifier, String?>(() {
      return ActiveProfileIdNotifier();
    });
