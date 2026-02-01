import 'package:flutter/material.dart';

class ActivityItem {
  final String id;
  final String title;
  final IconData icon;
  final Color themeColor; // Warna khusus aktivitas ini (misal: Hijau untuk Tanaman)
  final bool isCompleted;
  final String motivationalMessage; // Pesan saat selesai: "Wah, segar sekali tanamannya!"

  ActivityItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.themeColor,
    this.isCompleted = false,
    required this.motivationalMessage,
  });

  ActivityItem copyWith({bool? isCompleted}) {
    return ActivityItem(
      id: id,
      title: title,
      icon: icon,
      themeColor: themeColor,
      isCompleted: isCompleted ?? this.isCompleted,
      motivationalMessage: motivationalMessage,
    );
  }
}