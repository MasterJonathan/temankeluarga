import 'package:flutter/material.dart';

class ActivityItem {
  final String id;
  final String userId;
  final String title;
  
  // Icon tetap ada sebagai fallback
  final String iconKey; 
  final int colorValue;
  final String motivationalMessage;
  final bool isCompleted;

  // --- FITUR BARU: GAMBAR ---
  final String? customImage; // Bisa URL (https://...) atau Asset Path (assets/...)
  final bool isAssetImage;   // True jika pakai gambar rekomendasi bawaan app

  ActivityItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    required this.motivationalMessage,
    this.isCompleted = false,
    this.customImage,
    this.isAssetImage = false,
  });

  Color get color => Color(colorValue);

  static IconData getIconData(String key) {
    switch (key) {
      case 'flower': return Icons.local_florist;
      case 'book': return Icons.menu_book;
      case 'walk': return Icons.directions_walk;
      case 'tea': return Icons.emoji_food_beverage;
      case 'music': return Icons.music_note;
      case 'pet': return Icons.pets;
      default: return Icons.star;
    }
  }
  
  IconData get icon => getIconData(iconKey);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'motivationalMessage': motivationalMessage,
      'customImage': customImage,
      'isAssetImage': isAssetImage,
    };
  }

  factory ActivityItem.fromMap(String docId, Map<String, dynamic> map, bool isCompleted) {
    return ActivityItem(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      iconKey: map['iconKey'] ?? 'star',
      colorValue: map['colorValue'] ?? 0xFF4B5320,
      motivationalMessage: map['motivationalMessage'] ?? 'Semangat!',
      isCompleted: isCompleted,
      customImage: map['customImage'],
      isAssetImage: map['isAssetImage'] ?? false,
    );
  }
}