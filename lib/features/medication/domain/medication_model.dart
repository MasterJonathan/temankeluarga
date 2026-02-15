import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String time; // "HH:mm"
  final String? imageUrl;
  final bool isTaken;
  final DateTime? takenAt;
  
  // --- FITUR BARU ---
  final DateTime startDate;
  final DateTime? endDate; // Null = Selamanya
  final List<int> frequency; // [1, 2, ... 7] (1 = Senin, 7 = Minggu)

  MedicationTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.time,
    this.imageUrl,
    this.isTaken = false,
    this.takenAt,
    required this.startDate,
    this.endDate,
    required this.frequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'time': time,
      'imageUrl': imageUrl,
      // Simpan field baru
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'frequency': frequency,
    };
  }

  factory MedicationTask.fromMap(String docId, Map<String, dynamic> map, bool isTaskTaken, DateTime? taskTakenAt) {
    return MedicationTask(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      time: map['time'] ?? '00:00',
      imageUrl: map['imageUrl'],
      isTaken: isTaskTaken,
      takenAt: taskTakenAt,
      // Load field baru
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      frequency: List<int>.from(map['frequency'] ?? [1,2,3,4,5,6,7]),
    );
  }

  MedicationTask copyWith({
    String? id,
    String? userId,
    bool? isTaken,
    DateTime? takenAt,
  }) {
    return MedicationTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title,
      description: description,
      time: time,
      imageUrl: imageUrl,
      startDate: startDate,
      endDate: endDate,
      frequency: frequency,
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}