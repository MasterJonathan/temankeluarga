import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/medication_model.dart';
import '../data/medication_repository.dart';

// 1. State Tanggal yang Dipilih (Default Hari Ini)
final selectedDateProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime.now(),
);

// 2. Provider Data Obat
final medicationProvider = StreamProvider.autoDispose
    .family<List<MedicationTask>, String>((ref, userId) {
      if (userId.isEmpty) return Stream.value([]);

      final repo = ref.watch(medicationRepositoryProvider);

      // Ambil tanggal yang sedang dipilih user
      final selectedDate = ref.watch(selectedDateProvider);

      // Panggil Repo dengan tanggal tersebut
      return repo.watchTasksByDate(userId, selectedDate);
    });
