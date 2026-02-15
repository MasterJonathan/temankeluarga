import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/medication_model.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore;
  MedicationRepository(this._firestore);

  // Helper untuk mendapatkan tanggal hari ini dalam format YYYY-MM-DD
  String _getDateId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // 1. CREATE: Tambah Obat Baru (Guardian)
  Future<void> addMedication(MedicationTask task) async {
    final docRef = _firestore.collection('medications').doc();
    // Set ID dari dokumen yang baru dibuat
    final taskWithId = task.copyWith(id: docRef.id);
    await docRef.set(taskWithId.toMap());
  }

  // 2. READ: Dapatkan semua obat untuk user + status hari ini (Realtime)
  // UPDATED: Dengan Logic Filtering (Google Calendar Style)
  Stream<List<MedicationTask>> watchTasksByDate(String userId, DateTime selectedDate) {
    final query = _firestore
        .collection('medications')
        .where('userId', isEqualTo: userId);

    return query.snapshots().asyncMap((snapshot) async {
      final tasksWithStatus = <MedicationTask>[];
      final dateId = _getDateId(selectedDate);

      // Normalisasi selectedDate ke jam 00:00:00 untuk perbandingan tanggal yang akurat
      final normalizedSelected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      for (final doc in snapshot.docs) {
        // 1. Parsing Data Dasar
        final data = doc.data();
        
        // Ambil data filtering
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = data['endDate'] != null 
            ? (data['endDate'] as Timestamp).toDate() 
            : null;
        final frequency = List<int>.from(data['frequency'] ?? []);

        // 2. FILTERING LOGIC
        
        // A. Cek Range Tanggal (Start & End)
        final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
        final normalizedEnd = endDate != null 
            ? DateTime(endDate.year, endDate.month, endDate.day) 
            : null;

        // Skip jika tanggal yang dipilih SEBELUM tanggal mulai
        if (normalizedSelected.isBefore(normalizedStart)) continue;
        
        // Skip jika tanggal yang dipilih SETELAH tanggal selesai (jika ada end date)
        if (normalizedEnd != null && normalizedSelected.isAfter(normalizedEnd)) continue;

        // B. Cek Hari (Frequency)
        // normalizedSelected.weekday mengembalikan 1 (Senin) s/d 7 (Minggu)
        if (!frequency.contains(normalizedSelected.weekday)) continue; // Bukan jadwal hari ini

        // 3. Jika Lolos Filter, Ambil Status Harian (Logs)
        final logDoc = await doc.reference.collection('logs').doc(dateId).get();

        final bool isTaken = logDoc.exists && logDoc.data()?['isTaken'] == true;
        final DateTime? takenAt = logDoc.exists
            ? (logDoc.data()?['takenAt'] as Timestamp?)?.toDate()
            : null;

        tasksWithStatus.add(
          MedicationTask.fromMap(doc.id, doc.data(), isTaken, takenAt),
        );
      }

      tasksWithStatus.sort((a, b) => a.time.compareTo(b.time));
      return tasksWithStatus;
    });
  }

  // 3. UPDATE: Tandai Sudah/Belum Diminum (Lansia & Guardian)
  Future<void> toggleTaskStatus(String medId, bool currentStatus) async {
    final dateId = _getDateId(DateTime.now()); // Default Hari Ini
    final logRef = _firestore
        .collection('medications')
        .doc(medId)
        .collection('logs')
        .doc(dateId);

    if (!currentStatus) {
      await logRef.set({
        'isTaken': true,
        'takenAt': FieldValue.serverTimestamp(),
      });
    } else {
      await logRef.delete();
    }
  }

  // 4. UPDATE: Edit Detail Obat (Guardian)
  Future<void> updateMedication(MedicationTask task) async {
    await _firestore
        .collection('medications')
        .doc(task.id)
        .update(task.toMap());
  }

  // 5. DELETE: Hapus Obat (Guardian)
  Future<void> deleteMedication(String medId) async {
    await _firestore.collection('medications').doc(medId).delete();
    // Note: Subcollection 'logs' akan otomatis terhapus (orphan) di Firestore
  }
}

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(FirebaseFirestore.instance);
});