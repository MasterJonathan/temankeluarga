import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';

// Import Provider & Actions yang baru dibuat
import 'memory_provider.dart';
import 'memory_actions.dart';
import '../domain/memory_model.dart';

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileControllerProvider);
    final user = userAsync.valueOrNull; // Gunakan valueOrNull agar aman

    final familyId = user?.familyId ?? "";
    final currentUserId = user?.id ?? "";

    // Watch Data
    final asyncMemories = ref.watch(memoryProvider(familyId));

    return Scaffold(
      backgroundColor: AppColors.surface,

      // Floating Action Button
      // Pastikan tombol ini selalu dirender, logic validasi ada di onPressed
      body: asyncMemories.when(
        data: (memories) {
          if (familyId.isEmpty) {
            return const Center(
              child: Text(
                "Bergabunglah dengan keluarga untuk melihat kenangan.",
              ),
            );
          }

          if (memories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_album_outlined,
                    size: 60,
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada kenangan.\nTulis cerita pertamamu!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          // Grouping logic (Sama)
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
                    return _DailyGroupItem(
                      dateKey: dateKey,
                      posts: dailyPosts,
                      currentUserId: currentUserId,
                    );
                  }, childCount: grouped.keys.length),
                ),
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

  // --- LOGIC DIALOG INPUT JURNAL (Updated with Firebase Logic) ---

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
  final String currentUserId; // Tambahan

  const _DailyGroupItem({
    required this.dateKey,
    required this.posts,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split(' ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIMELINE KIRI
          SizedBox(
            width: 75,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  parts[0],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  parts[1].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // 2. KONTEN KANAN
          Expanded(
            child: Column(
              children: posts
                  .map(
                    (post) => _DiaryPostItem(
                      post: post,
                      currentUserId: currentUserId,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ITEM JURNAL ---
class _DiaryPostItem extends ConsumerWidget {
  final MemoryPost post;
  final String currentUserId;

  const _DiaryPostItem({required this.post, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String timeString =
        "${post.date.hour.toString().padLeft(2, '0')}:${post.date.minute.toString().padLeft(2, '0')}";

    // Logic Reaksi
    // Cari apakah currentUserId sudah ada di map reactions
    final myReactionEmoji = post.reactions[currentUserId];

    return Container(
      margin: const EdgeInsets.only(bottom: 24, right: 16, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JAM & AUTHOR
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  "$timeString • ${post.authorName}", // Tampilkan nama penulis
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontFamily: 'Lora',
                  ),
                ),
              ],
            ),
          ),

          // KONTEN
          if (post.content.isNotEmpty)
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
                errorBuilder: (ctx, error, stackTrace) => Container(
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

          // REAKSI
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    _showReactionPicker(context, ref, post.id, post.familyId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: myReactionEmoji != null
                        ? AppColors.secondary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: myReactionEmoji != null
                          ? AppColors.secondary
                          : AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        myReactionEmoji != null
                            ? Icons.emoji_emotions
                            : Icons.add_reaction_outlined,
                        size: 18,
                        color: myReactionEmoji != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        myReactionEmoji ?? "Reaksi",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: myReactionEmoji != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // TAMPILKAN JUMLAH REAKSI
              if (post.reactions.isNotEmpty)
                ..._buildReactionCounts(post.reactions),
            ],
          ),
        ],
      ),
    );
  }

  // Helper untuk menampilkan summary reaksi (misal: ❤️ 2, 👍 1)
  List<Widget> _buildReactionCounts(Map<String, String> reactions) {
    // Hitung frekuensi tiap emoji
    final counts = <String, int>{};
    for (var emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    return counts.entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        )
        .toList();
  }

  void _showReactionPicker(
    BuildContext context,
    WidgetRef ref,
    String postId,
    String familyId,
  ) {
    final emojis = ["❤️", "😂", "🙏", "😢", "👍", "🔥"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
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
                      // Panggil Action Provider
                      ref
                          .read(memoryActionsProvider)
                          .reactToPost(familyId, postId, currentUserId, emoji);
                      Navigator.pop(ctx);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
