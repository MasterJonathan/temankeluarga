import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/activity_repository.dart';
import '../domain/activity_model.dart';
import 'activity_provider.dart'; // IMPORT PROVIDER UTAMA

class ActivityActions {
  final Ref ref;
  ActivityActions(this.ref);

  Future<void> addActivity(ActivityItem item) async {
    await ref.read(activityRepositoryProvider).addActivity(item);
    // Refresh UI
    ref.invalidate(activityProvider(item.userId));
  }

  Future<String> toggleActivity(String userId, String id, bool status, String message) async {
    await ref.read(activityRepositoryProvider).toggleActivity(id, status);
    
    // Refresh UI (SOLUSI)
    ref.invalidate(activityProvider(userId));
    ref.invalidate(activityProgressProvider(userId)); // Refresh juga pohonnya
    
    return !status ? message : "";
  }

  Future<void> deleteActivity(String userId, String id) async {
    await ref.read(activityRepositoryProvider).deleteActivity(id);
    ref.invalidate(activityProvider(userId));
  }
}

final activityActionsProvider = Provider((ref) => ActivityActions(ref));