import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/medication_model.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore;
  MedicationRepository(this._firestore);

  // Helper untuk mendapatkan tanggal hari ini dalam format YYYY-MM-DD
  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

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
  Stream<List<MedicationTask>> watchTasksByDate(String userId, DateTime date) {
    final query = _firestore.collection('medications').where('userId', isEqualTo: userId);
    
    return query.snapshots().asyncMap((snapshot) async {
      final tasksWithStatus = <MedicationTask>[];
      final dateId = _getDateId(date); // Gunakan tanggal yang dipilih

      for (final doc in snapshot.docs) {
        // Cek logs untuk tanggal tersebut
        final logDoc = await doc.reference.collection('logs').doc(dateId).get();
        
        final bool isTaken = logDoc.exists && logDoc.data()?['isTaken'] == true;
        final DateTime? takenAt = logDoc.exists ? (logDoc.data()?['takenAt'] as Timestamp?)?.toDate() : null;

        tasksWithStatus.add(MedicationTask.fromMap(doc.id, doc.data(), isTaken, takenAt));
      }

      tasksWithStatus.sort((a, b) => a.time.compareTo(b.time));
      return tasksWithStatus;
    });
  }

  // 3. UPDATE: Tandai Sudah/Belum Diminum (Lansia & Guardian)
  Future<void> toggleTaskStatus(String medId, bool currentStatus) async {
    final dateId = _getDateId(DateTime.now()); // Default Hari Ini
    final logRef = _firestore.collection('medications').doc(medId).collection('logs').doc(dateId);

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
    await _firestore.collection('medications').doc(task.id).update(task.toMap());
  }

  // 5. DELETE: Hapus Obat (Guardian)
  Future<void> deleteMedication(String medId) async {
    await _firestore.collection('medications').doc(medId).delete();
    // Note: Subcollection 'logs' akan otomatis terhapus (orphan)
    // Untuk production app, perlu Cloud Function untuk membersihkannya.
  }
}

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(FirebaseFirestore.instance);
});