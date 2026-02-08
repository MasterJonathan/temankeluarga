import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medication_repository.dart';
import '../domain/medication_model.dart';
import 'medication_provider.dart'; // IMPORT PROVIDER UTAMA

class MedicationActions {
  final Ref ref;
  MedicationActions(this.ref);

  Future<void> toggleTaskStatus(String userId, String medId, bool currentStatus) async {
    final repo = ref.read(medicationRepositoryProvider);
    
    // 1. Update Database
    await repo.toggleTaskStatus(medId, currentStatus);
    
    // 2. FORCE REFRESH UI (SOLUSI MASALAH ANDA)
    // Kita invalidate provider spesifik milik userId ini
    ref.invalidate(medicationProvider(userId));
  }

  Future<void> addMedication(MedicationTask task) async {
    final repo = ref.read(medicationRepositoryProvider);
    await repo.addMedication(task);
    
    // Force refresh juga saat tambah data
    ref.invalidate(medicationProvider(task.userId));
  }

  Future<void> deleteMedication(String userId, String medId) async {
    final repo = ref.read(medicationRepositoryProvider);
    await repo.deleteMedication(medId);
    
    // Force refresh
    ref.invalidate(medicationProvider(userId));
  }
}

final medicationActionsProvider = Provider((ref) => MedicationActions(ref));