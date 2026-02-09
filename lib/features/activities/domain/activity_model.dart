import 'package:flutter/material.dart';

class ActivityItem {
  final String id;
  final String userId; // Pemilik
  final String title;
  final String iconKey; // Key untuk mapping icon: 'flower', 'book', 'walk'
  final int colorValue; // Int warna: 0xFF4B5320
  final String motivationalMessage;
  final bool isCompleted;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    required this.motivationalMessage,
    this.isCompleted = false,
  });

  // Helper untuk mendapatkan Warna Asli
  Color get color => Color(colorValue);

  // Helper untuk mapping String ke IconData (Hardcode di Model/UI)
  static IconData getIconData(String key) {
    switch (key) {
      case 'flower':
        return Icons.local_florist;
      case 'book':
        return Icons.menu_book;
      case 'walk':
        return Icons.directions_walk;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'music':
        return Icons.music_note;
      case 'pet':
        return Icons.pets;
      default:
        return Icons.star;
    }
  }

  IconData get icon => getIconData(iconKey);

  // --- SERIALIZATION ---
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'motivationalMessage': motivationalMessage,
    };
  }

  factory ActivityItem.fromMap(
    String docId,
    Map<String, dynamic> map,
    bool isCompleted,
  ) {
    return ActivityItem(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      iconKey: map['iconKey'] ?? 'star',
      colorValue: map['colorValue'] ?? 0xFF4B5320,
      motivationalMessage: map['motivationalMessage'] ?? 'Semangat!',
      isCompleted: isCompleted,
    );
  }
}
