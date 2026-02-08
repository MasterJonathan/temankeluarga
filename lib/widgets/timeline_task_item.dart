import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/medication/domain/medication_model.dart';
import 'package:silver_guide/features/medication/presentation/medication_actions.dart';
import 'package:silver_guide/features/medication/presentation/medication_provider.dart';

class TimelineTaskItem extends ConsumerWidget {
  final MedicationTask task;

  const TimelineTaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic Warna: Invert jika sudah diminum
    // Jika Done: Card Hijau, Teks Putih
    // Jika Belum: Card Putih, Teks Coklat
    final cardColor = task.isTaken ? AppColors.primary : Colors.white;
    final textColor = task.isTaken ? Colors.white : AppColors.textPrimary;
    final subTextColor = task.isTaken
        ? Colors.white70
        : AppColors.textSecondary;

    // Logic Tombol:
    // Jika Done: Tombol Putih, Teks Hijau
    // Jika Belum: Tombol Hijau, Teks Putih
    final btnBgColor = task.isTaken ? Colors.white : AppColors.primary;
    final btnTextColor = task.isTaken ? AppColors.primary : Colors.white;

    final bool hasImage = task.imageUrl != null && task.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Garis Waktu (Timeline Line)
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(
                    task.time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: 2,
                      // Garis tetap Emas jika sukses, atau abu samar jika belum
                      color: task.isTaken
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 2. Kartu Obat
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ROW ATAS: Gambar & Teks
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto Obat
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    hasImage 
                                      ? task.imageUrl! 
                                      : "https://cdn-icons-png.flaticon.com/256/883/883407.png", // Ikon obat default
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Teks Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: AppTheme
                                        .lightTheme
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          decoration: task.isTaken
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    task.description,
                                    style: AppTheme
                                        .lightTheme
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: subTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ROW BAWAH: Tombol Inset (Di dalam padding)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: InkWell(
                          onTap: () {
                            // PERBAIKAN: Kirim task.userId sebagai parameter pertama
                            ref
                                .read(medicationActionsProvider)
                                .toggleTaskStatus(
                                  task.userId, // <--- User ID
                                  task.id, // <--- Med ID
                                  task.isTaken, // <--- Status Lama
                                );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: btnBgColor,
                              borderRadius: BorderRadius.circular(16),
                              // Opsional: Shadow halus untuk tombol agar lebih "pop"
                              boxShadow: task.isTaken
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  task.isTaken
                                      ? Icons.undo
                                      : Icons.check_circle_outline,
                                  color: btnTextColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  task.isTaken
                                      ? "Batalkan"
                                      : "Konfirmasi Minum",
                                  style: TextStyle(
                                    color: btnTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
