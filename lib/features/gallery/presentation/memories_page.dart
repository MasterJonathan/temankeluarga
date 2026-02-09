import 'dart:io'; // Tambahan untuk File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Tambahan untuk ambil foto
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
    // 1. Ambil Data User (FamilyID & UserID)
    final userAsync = ref.watch(profileControllerProvider);
    final familyId = userAsync.value?.familyId ?? "";
    final currentUserId = userAsync.value?.id ?? "";

    // 2. Watch Data Memories (Realtime Firestore)
    // Jika belum punya familyId, stream akan kosong
    final asyncMemories = ref.watch(memoryProvider(familyId));

    return Scaffold(
      backgroundColor: AppColors.surface,

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (familyId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Silakan gabung keluarga di Settings dulu."),
              ),
            );
            return;
          }
          _showWriteDiaryDialog(context, ref, familyId, userAsync.value!);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 4,
        child: const Icon(Icons.edit_note, size: 32),
      ),

      body: asyncMemories.when(
        data: (memories) {
          if (memories.isEmpty) {
            return Center(
              child: Text(
                "Belum ada kenangan.\nTulis cerita pertamamu!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            );
          }

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
                    return _DailyGroupItem(
                      dateKey: dateKey,
                      posts: dailyPosts,
                      currentUserId:
                          currentUserId, // Kirim ID untuk cek status like
                    );
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

  // --- LOGIC DIALOG INPUT JURNAL (Updated with Firebase Logic) ---
  void _showWriteDiaryDialog(
    BuildContext context,
    WidgetRef ref,
    String familyId,
    dynamic userProfile,
  ) {
    final textController = TextEditingController();
    File? selectedImage; // State Lokal untuk gambar
    bool isUploading = false; // State Loading

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Gunakan StatefulBuilder agar bisa update UI di dalam BottomSheet (untuk preview gambar)
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tulis Cerita",
                        style: AppTheme.lightTheme.textTheme.titleLarge,
                      ),
                      if (isUploading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
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
                    autofocus: true,
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

                  // PREVIEW GAMBAR JIKA ADA
                  if (selectedImage != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => selectedImage = null),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // TOMBOL AMBIL FOTO
                      TextButton.icon(
                        onPressed: isUploading
                            ? null
                            : () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 70,
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedImage = File(picked.path);
                                  });
                                }
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text("Foto"),
                      ),
                      const Spacer(),
                      // TOMBOL SIMPAN KE FIREBASE
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (textController.text.isNotEmpty ||
                                    selectedImage != null) {
                                  setState(() => isUploading = true);

                                  try {
                                    // Panggil Action Provider
                                    await ref
                                        .read(memoryActionsProvider)
                                        .postMemory(
                                          familyId: familyId,
                                          authorId: userProfile.id,
                                          authorName: userProfile.name,
                                          content: textController.text,
                                          imageFile: selectedImage,
                                        );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    setState(() => isUploading = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text("Gagal: $e")),
                                      );
                                    }
                                  }
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
          );
        },
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
    );
  }
}
