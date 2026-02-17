import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http; // Wajib tambah ini di pubspec.yaml
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart'; // Butuh UserRole
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';

import 'memory_provider.dart';
import 'memory_actions.dart';
import '../domain/memory_model.dart';
import 'package:silver_guide/features/memories/presentation/generate_memory_page.dart';

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileControllerProvider);
    final user = userAsync.valueOrNull;

    final familyId = user?.familyId ?? "";
    final currentUserId = user?.id ?? "";
    final isGuardian = user?.role == UserRole.guardian; // Cek Role

    final asyncMemories = ref.watch(memoryProvider(familyId));

    return Scaffold(
      backgroundColor: AppColors.surface,
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
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada kenangan.\nTulis cerita pertamamu!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                    child: InkWell(
                      onTap: () {
                        if (familyId.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateMemoryPage(
                              familyId: familyId,
                              userId: user!.id,
                              userName: user.name,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0.8),
                              AppColors.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.textPrimary,
                              size: 28,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Lukis Kenangan",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Ubah cerita hari ini jadi gambar lucu",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    String dateKey = grouped.keys.elementAt(index);
                    List<MemoryPost> dailyPosts = grouped[dateKey]!;
                    return _DailyGroupItem(
                      dateKey: dateKey,
                      posts: dailyPosts,
                      currentUserId: currentUserId,
                      isGuardian: isGuardian, // Pass Role ke Item
                    );
                  }, childCount: grouped.keys.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 160)),
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
  final String currentUserId;
  final bool isGuardian; // Tambahan

  const _DailyGroupItem({
    required this.dateKey,
    required this.posts,
    required this.currentUserId,
    required this.isGuardian,
  });

  @override
  Widget build(BuildContext context) {
    final parts = dateKey.split(' ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: Column(
              children: posts
                  .map(
                    (post) => _DiaryPostItem(
                      post: post,
                      currentUserId: currentUserId,
                      isGuardian: isGuardian,
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
  final bool isGuardian; // Tambahan

  const _DiaryPostItem({
    required this.post,
    required this.currentUserId,
    required this.isGuardian,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String timeString =
        "${post.date.hour.toString().padLeft(2, '0')}:${post.date.minute.toString().padLeft(2, '0')}";
    final myReactionEmoji = post.reactions[currentUserId];

    return Container(
      margin: const EdgeInsets.only(bottom: 24, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: JAM & AUTHOR & DELETE BUTTON
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Agar tombol delete di kanan
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$timeString • ${post.authorName}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontFamily: 'Lora',
                      ),
                    ),
                  ],
                ),

                // TOMBOL DELETE (Hanya Guardian)
                if (isGuardian)
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),

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
            const SizedBox(height: 16),
            GestureDetector(
              // INTERAKSI ZOOM GAMBAR
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        _FullScreenImageViewer(imageUrl: post.imageUrl!),
                  ),
                );
              },
              child: Hero(
                tag: post.imageUrl!, // Tag Hero harus sama dengan viewer
                child: ClipRRect(
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
              ),
            ),
          ],

          const SizedBox(height: 16),

          // REAKSI
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () =>
                    _showReactionPicker(context, ref, post.id, post.familyId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
              const SizedBox(width: 16),
              if (post.reactions.isNotEmpty)
                ..._buildReactionCounts(post.reactions),
            ],
          ),
        ],
      ),
    );
  }

  // --- LOGIC DELETE ---
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Kenangan?"),
        content: const Text(
          "Postingan ini akan dihapus permanen dari keluarga.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup Dialog dulu

              try {
                // PANGGIL ACTION DELETE
                await ref
                    .read(memoryActionsProvider)
                    .deleteMemory(post.familyId, post.id, post.imageUrl);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kenangan berhasil dihapus")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal: $e"),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Hapus",
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReactionCounts(Map<String, String> reactions) {
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: emojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
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

// === NEW WIDGET: FULL SCREEN IMAGE VIEWER ===
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImageViewer({required this.imageUrl});

  Future<void> _downloadImage(BuildContext context) async {
    try {
      var response = await http.get(Uri.parse(imageUrl));
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: "memory_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['isSuccess']
                  ? "Gambar tersimpan di Galeri"
                  : "Gagal menyimpan gambar",
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          // Fitur Zoom & Pan bawaan Flutter
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl, // Tag harus sama dgn di list
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
