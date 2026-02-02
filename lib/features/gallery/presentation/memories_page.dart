import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'gallery_controller.dart';
import '../domain/memory_model.dart';

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMemories = ref.watch(galleryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWriteDiaryDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 4,
        child: const Icon(Icons.edit_note, size: 32),
      ),

      body: asyncMemories.when(
        data: (memories) {
          // Grouping berdasarkan tanggal
          Map<String, List<MemoryPost>> grouped = {};
          for (var post in memories) {
            String dateKey =
                "${post.date.day} ${_getMonthName(post.date.month)} ${post.date.year}";
            if (!grouped.containsKey(dateKey)) {
              grouped[dateKey] = [];
            }
            grouped[dateKey]!.add(post);
          }

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    String dateKey = grouped.keys.elementAt(index);
                    List<MemoryPost> dailyPosts = grouped[dateKey]!;
                    return _DailyGroupItem(dateKey: dateKey, posts: dailyPosts);
                  }, childCount: grouped.keys.length),
                ),
                // Tambahan space di bawah agar item terakhir tidak ketutup FAB/Nav Bar
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  // --- LOGIC DIALOG INPUT JURNAL ---
  void _showWriteDiaryDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Wajib agar bisa full screen/resize saat keyboard muncul
      useSafeArea:
          true, // SOLUSI: Menghindari tertutup tombol Back/Home Android
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          // Padding bawah dinamis: Jarak Keyboard + Jarak aman Navigasi
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan konten
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tulis Cerita",
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 5,
                autofocus: true, // Langsung muncul keyboard
                style: AppTheme.lightTheme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Apa yang berkesan hari ini, Ayah/Ibu?",
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text("Fitur Upload Foto (Placeholder)"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text("Foto"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        ref
                            .read(galleryControllerProvider.notifier)
                            .postDiary(textController.text, null);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Simpan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Ags",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return months[month - 1];
  }
}

// --- WIDGET PENGELOMPOK TANGGAL ---
class _DailyGroupItem extends StatelessWidget {
  final String dateKey;
  final List<MemoryPost> posts;

  const _DailyGroupItem({required this.dateKey, required this.posts});

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split(' ');

    return IntrinsicHeight(
      // Agar tinggi garis mengikuti tinggi konten
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIMELINE KIRI
          SizedBox(
            width: 75,
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ), // Padding agar sejajar dengan jam post pertama
                Text(
                  parts[0], // Tanggal
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  parts[1].toUpperCase(), // Bulan
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: 1.5, // Garis lebih tipis
                    color: AppColors.textSecondary.withOpacity(
                      0.3,
                    ), // Warna lebih samar
                  ),
                ),
              ],
            ),
          ),

          // 2. KONTEN KANAN
          Expanded(
            child: Column(
              children: posts
                  .map((post) => _DiaryPostItem(post: post))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ITEM JURNAL (Updated dengan Jam) ---
class _DiaryPostItem extends ConsumerWidget {
  final MemoryPost post;

  const _DiaryPostItem({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Format Jam Manual (Simple) - Nanti bisa pakai intl DateFormat('HH:mm')
    final String timeString =
        "${post.date.hour.toString().padLeft(2, '0')}:${post.date.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 24, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- UPDATE: Jam diletakkan di atas konten ---
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // Sedikit tebal agar terbaca
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontFamily: 'Lora', // Konsisten dengan font body
                  ),
                ),
              ],
            ),
          ),

          // Konten Utama
          Text(
            post.content,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),

          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Reaksi
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showReactionPicker(context, ref, post.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: post.selectedReaction != null
                        ? AppColors.secondary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: post.selectedReaction != null
                          ? AppColors.secondary
                          : AppColors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.selectedReaction != null
                            ? Icons.emoji_emotions
                            : Icons.add_reaction_outlined,
                        size: 18,
                        color: post.selectedReaction != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.selectedReaction ?? "Reaksi",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: post.selectedReaction != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (post.reactionCounts.isNotEmpty)
                ...post.reactionCounts.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${e.key} ${e.value}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context, WidgetRef ref, String postId) {
    final emojis = ["❤️", "😂", "🙏", "😢", "👍", "🔥"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: emojis
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    ref
                        .read(galleryControllerProvider.notifier)
                        .reactToPost(postId, emoji);
                    Navigator.pop(ctx);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
