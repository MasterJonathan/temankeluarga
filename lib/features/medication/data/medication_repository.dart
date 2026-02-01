import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/medication_model.dart';

// 1. Interface (Kontrak)
abstract class MedicationRepository {
  Future<List<MedicationTask>> getDailyTasks();
  Future<void> markAsTaken(String id);
}

// 2. Mock Implementation (Data Palsu untuk UI Dev)
class MockMedicationRepository implements MedicationRepository {
  // Simulasi database lokal memori
  final List<MedicationTask> _mockData = [
    MedicationTask(
      id: '1',
      title: 'Obat Jantung (Amlodipine)',
      description: '1 Tablet - Sesudah Makan',
      time: '08:00',
      imageUrl: 'https://via.placeholder.com/150/4B5320/FFFFFF?text=Obat', // Placeholder
    ),
    MedicationTask(
      id: '2',
      title: 'Vitamin D',
      description: '1 Kapsul Lunak',
      time: '08:00',
      imageUrl: 'https://via.placeholder.com/150/F0C05A/4A3B32?text=Vit',
    ),
    MedicationTask(
      id: '3',
      title: 'Cek Tensi Darah',
      description: 'Target: < 140/90',
      time: '16:00',
      imageUrl: 'https://via.placeholder.com/150/E07A5F/FFFFFF?text=Tensi',
    ),
  ];

  @override
  Future<List<MedicationTask>> getDailyTasks() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulasi loading
    return _mockData;
  }

  @override
  Future<void> markAsTaken(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Di real app, ini update ke Firebase
    final index = _mockData.indexWhere((e) => e.id == id);
    if (index != -1) {
      _mockData[index] = _mockData[index].copyWith(
        isTaken: true,
        takenAt: DateTime.now(),
      );
    }
  }
}

// 3. Provider Repository
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MockMedicationRepository();
});