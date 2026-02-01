import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/medication_model.dart';
import '../data/medication_repository.dart';

// 1. Definisikan Controller secara Manual
class MedicationController extends AsyncNotifier<List<MedicationTask>> {
  
  // Method build() adalah tempat inisialisasi awal
  @override
  FutureOr<List<MedicationTask>> build() async {
    // Di class AsyncNotifier, 'ref' sudah tersedia otomatis (this.ref)
    final repository = ref.read(medicationRepositoryProvider);
    return repository.getDailyTasks();
  }

  // Fungsi Logika: Tandai Selesai
  Future<void> toggleTaskStatus(String id) async {
    final repository = ref.read(medicationRepositoryProvider);
    
    // Set state ke loading agar UI tahu ada proses
    state = const AsyncValue.loading();
    
    // Lakukan update dengan perlindungan error (guard)
    state = await AsyncValue.guard(() async {
      await repository.markAsTaken(id);
      return repository.getDailyTasks(); // Refresh data terbaru
    });
  }
}

// 2. Daftarkan Provider secara Manual
final medicationControllerProvider = 
    AsyncNotifierProvider<MedicationController, List<MedicationTask>>(
  () => MedicationController(),
);