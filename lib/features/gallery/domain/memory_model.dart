class MemoryPost {
  final String id;
  final String content;     // Teks Jurnal (Wajib)
  final String? imageUrl;   // Foto (Opsional)
  final DateTime date;
  final String? selectedReaction; // Emoji yang dipilih user (misal: '❤️', '🙏')
  final Map<String, int> reactionCounts; // Total reaksi: {'❤️': 2, '👍': 1}

  MemoryPost({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.date,
    this.selectedReaction,
    this.reactionCounts = const {},
  });

  MemoryPost copyWith({
    String? selectedReaction,
    Map<String, int>? reactionCounts,
  }) {
    return MemoryPost(
      id: id,
      content: content,
      imageUrl: imageUrl,
      date: date,
      selectedReaction: selectedReaction ?? this.selectedReaction,
      reactionCounts: reactionCounts ?? this.reactionCounts,
    );
  }
}