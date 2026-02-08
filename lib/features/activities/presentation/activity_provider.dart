import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/activity_model.dart';
import '../data/activity_repository.dart';

final activityProvider = 
    StreamProvider.autoDispose.family<List<ActivityItem>, String>((ref, userId) {
  
  if (userId.isEmpty) return Stream.value([]); // Return list kosong, bukan stuck loading

  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchDailyActivities(userId);
});

// Provider hitung progress (0.0 - 1.0) untuk Pohon
final activityProgressProvider = Provider.autoDispose.family<double, String>((ref, userId) {
  final activitiesAsync = ref.watch(activityProvider(userId));
  
  return activitiesAsync.when(
    data: (list) {
      if (list.isEmpty) return 0.0;
      final completed = list.where((e) => e.isCompleted).length;
      return completed / list.length;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});