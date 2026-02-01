class MedicationTask {
  final String id;
  final String title;      // Nama Obat: "Amlodipine", "Vitamin D"
  final String description;// Dosis/Instruksi: "1 Tablet - Setelah Makan"
  final String time;       // "08:00", "13:00"
  final String imageUrl;   // Foto obat (Penting untuk visual)
  final bool isTaken;      // Status sudah diminum?
  final DateTime? takenAt; // Kapan diminum

  MedicationTask({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.imageUrl,
    this.isTaken = false,
    this.takenAt,
  });

  // Untuk update state (Immutability)
  MedicationTask copyWith({bool? isTaken, DateTime? takenAt}) {
    return MedicationTask(
      id: id,
      title: title,
      description: description,
      time: time,
      imageUrl: imageUrl,
      isTaken: isTaken ?? this.isTaken,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}