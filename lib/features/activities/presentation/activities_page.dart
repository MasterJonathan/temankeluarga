import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'activity_controller.dart';
import '../domain/activity_model.dart';

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActivities = ref.watch(activityControllerProvider);
    final progress = ref.watch(activityProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // 1. Header Gamifikasi (Pohon Keluarga)
          SliverToBoxAdapter(
            child: _FamilyTreeHeader(progress: progress),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 2. Judul Bagian
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Kebun Aktivitas",
                style: AppTheme.lightTheme.textTheme.displayMedium,
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Lakukan hobi untuk menyuburkan pohon keluarga kita.",
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 3. Grid Aktivitas
          asyncActivities.when(
            data: (activities) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 Kolom (Besar)
                  childAspectRatio: 0.85, // Sedikit memanjang ke bawah
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _ActivityCard(item: activities[index]);
                  },
                  childCount: activities.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (err, _) => SliverToBoxAdapter(child: Text("Error: $err")),
          ),

          // Spacer Bawah
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// === WIDGET 1: HEADER POHON (GAMIFIKASI) ===
class _FamilyTreeHeader extends StatelessWidget {
  final double progress; // 0.0 sampai 1.0

  const _FamilyTreeHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    // Tentukan pesan berdasarkan progress
    String statusMsg = "Pohon butuh air...";
    if (progress > 0.3) statusMsg = "Pohon mulai segar!";
    if (progress > 0.6) statusMsg = "Daunnya makin lebat!";
    if (progress == 1.0) statusMsg = "Luar biasa! Pohon berbuah!";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Ikon Pohon Animasi (Simpel Scale)
            AnimatedScale(
              scale: 0.8 + (progress * 0.4), // Membesar saat progress naik
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              child: Icon(
                progress == 1.0 ? Icons.park : Icons.forest_outlined, // Berubah ikon kalau full
                size: 80,
                color: progress == 1.0 ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusMsg,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Progress Bar Custom
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.white,
                color: AppColors.secondary, // Warna Emas
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${(progress * 100).toInt()}% Energi Terkumpul",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// === WIDGET 2: KARTU AKTIVITAS (INTERAKTIF) ===
class _ActivityCard extends ConsumerWidget {
  final ActivityItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = item.isCompleted;

    return GestureDetector(
      onTap: () async {
        final message = await ref.read(activityControllerProvider.notifier).toggleActivity(item.id);
        
        // Tampilkan feedback positif jika selesai
        if (message != null && context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: item.themeColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          // Logic Warna: Jika done pakai warna tema, jika tidak pakai Putih
          color: isDone ? item.themeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDone ? item.themeColor.withOpacity(0.4) : Colors.black12,
              blurRadius: isDone ? 16 : 8,
              offset: Offset(0, isDone ? 8 : 4),
            )
          ],
          border: isDone ? null : Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon yang berubah warna
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDone ? Colors.white.withOpacity(0.2) : item.themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 48,
                // Jika done warna Putih, jika belum warna Tema
                color: isDone ? Colors.white : item.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            // Text Judul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  // Jika done warna Putih, jika belum Hitam
                  color: isDone ? Colors.white : AppColors.textPrimary,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Indikator Status Teks
            AnimatedOpacity(
              opacity: isDone ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Selesai",
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}