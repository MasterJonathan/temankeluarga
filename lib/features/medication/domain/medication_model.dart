class MedicationTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String time;
  final String? imageUrl;
  final bool isTaken;
  final DateTime? takenAt;

  MedicationTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.time,
    this.imageUrl,
    this.isTaken = false,
    this.takenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      // 'id' tidak perlu disimpan di field, karena sudah jadi ID dokumen
      'userId': userId,
      'title': title,
      'description': description,
      'time': time,
      'imageUrl': imageUrl,
    };
  }

  factory MedicationTask.fromMap(
    String docId,
    Map<String, dynamic> map,
    bool isTaskTaken,
    DateTime? taskTakenAt,
  ) {
    return MedicationTask(
      id: docId, // Ambil ID dari dokumen, bukan field
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      time: map['time'] ?? '00:00',
      imageUrl: map['imageUrl'],
      isTaken: isTaskTaken,
      takenAt: taskTakenAt,
    );
  }

  // --- PERBAIKAN DI SINI ---
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
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}
