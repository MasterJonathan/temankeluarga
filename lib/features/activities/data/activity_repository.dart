import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/activity_model.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore;
  ActivityRepository(this._firestore);

  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // CREATE
  Future<void> addActivity(ActivityItem item) async {
    await _firestore.collection('activities').add(item.toMap());
  }

  // READ (Stream Realtime)
  Stream<List<ActivityItem>> watchDailyActivities(String userId) {
    final query = _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId);

    return query.snapshots().asyncMap((snapshot) async {
      final List<ActivityItem> items = [];
      final today = _getTodayDateString();

      for (final doc in snapshot.docs) {
        // Cek log harian
        final logDoc = await doc.reference.collection('logs').doc(today).get();
        final bool isCompleted =
            logDoc.exists && logDoc.data()?['completed'] == true;

        items.add(ActivityItem.fromMap(doc.id, doc.data(), isCompleted));
      }
      return items;
    });
  }

  // UPDATE (Toggle Status)
  Future<void> toggleActivity(String activityId, bool currentStatus) async {
    final today = _getTodayDateString();
    final logRef = _firestore
        .collection('activities')
        .doc(activityId)
        .collection('logs')
        .doc(today);

    if (!currentStatus) {
      await logRef.set({
        'completed': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await logRef.delete();
    }
  }

  // DELETE
  Future<void> deleteActivity(String activityId) async {
    await _firestore.collection('activities').doc(activityId).delete();
  }
}

final activityRepositoryProvider = Provider(
  (ref) => ActivityRepository(FirebaseFirestore.instance),
);
