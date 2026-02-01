import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart'; // Pastikan import ini benar
import '../domain/activity_model.dart';

class ActivityRepository {
  // Mock Data
  final List<ActivityItem> _activities = [
    ActivityItem(
      id: '1',
      title: 'Menyiram Tanaman',
      icon: Icons.local_florist,
      themeColor: AppColors.primary, // Hijau Olive
      motivationalMessage: 'Terima kasih sudah merawat kehidupan!',
    ),
    ActivityItem(
      id: '2',
      title: 'Jalan Pagi',
      icon: Icons.directions_walk,
      themeColor: AppColors.accent, // Terra Cotta
      motivationalMessage: 'Hebat! Jantung jadi lebih sehat.',
    ),
    ActivityItem(
      id: '3',
      title: 'Membaca / Mengaji',
      icon: Icons.menu_book,
      themeColor: AppColors.secondary, // Gold
      motivationalMessage: 'Ilmu dan ketenangan bertambah.',
    ),
    ActivityItem(
      id: '4',
      title: 'Minum Teh',
      icon: Icons.emoji_food_beverage,
      themeColor: const Color(0xFF8D6E63), // Coklat Teh
      motivationalMessage: 'Nikmati waktu santainya ya.',
    ),
  ];

  Future<List<ActivityItem>> getActivities() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _activities;
  }

  Future<void> toggleActivity(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _activities.indexWhere((e) => e.id == id);
    if (index != -1) {
      _activities[index] = _activities[index].copyWith(
        isCompleted: !_activities[index].isCompleted
      );
    }
  }
}

final activityRepositoryProvider = Provider((ref) => ActivityRepository());