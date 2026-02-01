import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/activity_model.dart';
import '../data/activity_repository.dart';

class ActivityController extends AsyncNotifier<List<ActivityItem>> {
  @override
  FutureOr<List<ActivityItem>> build() async {
    final repo = ref.read(activityRepositoryProvider);
    return repo.getActivities();
  }

  Future<String?> toggleActivity(String id) async {
    final repo = ref.read(activityRepositoryProvider);
    
    // Optimistic Update
    final currentList = state.value;
    if (currentList == null) return null;

    final index = currentList.indexWhere((e) => e.id == id);
    if (index == -1) return null;

    final targetItem = currentList[index];
    final newItem = targetItem.copyWith(isCompleted: !targetItem.isCompleted);

    // Update UI List
    List<ActivityItem> newList = List.from(currentList);
    newList[index] = newItem;
    state = AsyncValue.data(newList);

    // Call Repo
    await repo.toggleActivity(id);

    // Return pesan motivasi jika jadi "completed"
    if (newItem.isCompleted) {
      return newItem.motivationalMessage;
    }
    return null;
  }
}

// Provider Controller
final activityControllerProvider = 
    AsyncNotifierProvider<ActivityController, List<ActivityItem>>(() => ActivityController());

// Provider Khusus: Menghitung Persentase Selesai (0.0 - 1.0) untuk Pohon
final activityProgressProvider = Provider.autoDispose<double>((ref) {
  final activitiesState = ref.watch(activityControllerProvider);
  return activitiesState.when(
    data: (list) {
      if (list.isEmpty) return 0.0;
      final completed = list.where((e) => e.isCompleted).length;
      return completed / list.length;
    },
    error: (_, __) => 0.0,
    loading: () => 0.0,
  );
});