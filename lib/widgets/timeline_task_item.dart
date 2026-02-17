import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
import 'package:teman_keluarga/features/medication/domain/medication_model.dart';
import 'package:teman_keluarga/features/medication/presentation/medication_actions.dart';
import 'package:teman_keluarga/features/profile/domain/user_model.dart';
import 'package:teman_keluarga/features/profile/presentation/profile_controller.dart'; // Butuh untuk cek role

class TimelineTaskItem extends ConsumerWidget {
  final MedicationTask task;
  final DateTime selectedDate;

  const TimelineTaskItem({
    super.key,
    required this.task,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileControllerProvider);
    final isGuardian = userAsync.valueOrNull?.role == UserRole.guardian;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday = taskDate.isAtSameMomentAs(today);

    String buttonText;
    if (taskDate.isAtSameMomentAs(today)) {
      buttonText = task.isTaken ? "Batalkan" : "Konfirmasi Selesai";
    } else if (taskDate.isAfter(today)) {
      buttonText = "Akan Datang";
    } else {
      buttonText = "Terlewati";
    }

    final cardColor = task.isTaken ? AppColors.secondary : AppColors.surface;
    final textColor = AppColors.textPrimary;
    final subTextColor = AppColors.textSecondary;
    final btnBgColor = task.isTaken ? AppColors.surface : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line
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
                      color: task.isTaken
                          ? AppColors.primary
                          : AppColors.secondarySurface,
                    ),
                  ),
                ],
              ),
            ),

            // Kartu Obat
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    task.imageUrl ??
                                        "https://cdn-icons-png.flaticon.com/256/883/883407.png",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
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
                                                decorationColor: AppColors.surface,
                                              ),
                                        ),
                                      ),
                                      // TOMBOL DELETE (Khusus Guardian)
                                      if (isGuardian)
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: task.isTaken
                                                ? AppColors.surface
                                                : AppColors.danger,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () =>
                                              _confirmDelete(context, ref),
                                        ),
                                    ],
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

                      // Tombol Konfirmasi (Inset Floating)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity, // Agar tombol memenuhi lebar
                          child: ElevatedButton(
                            // LOGIC UTAMA: Jika bukan hari ini, onPressed = null (Disabled)
                            onPressed: isToday
                                ? () {
                                    ref
                                        .read(medicationActionsProvider)
                                        .toggleTaskStatus(
                                          task.userId,
                                          task.id,
                                          task.isTaken,
                                        );
                                  }
                                : null, // Ini membuat tombol otomatis disabled

                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                // Opsional: Tambahkan border abu-abu tipis jika tombol disabled (putih) agar terlihat
                                side: isToday
                                    ? BorderSide.none
                                    : const BorderSide(color: Colors.grey),
                              ),

                              // WARNA KETIKA AKTIF (HARI INI)
                              backgroundColor: btnBgColor, // Warna Primary
                              foregroundColor: task.isTaken
                                  ? AppColors.textPrimary
                                  : AppColors.surface, // Teks Putih
                              // WARNA KETIKA DISABLED (BUKAN HARI INI)
                              disabledBackgroundColor:
                                  AppColors.surface, // Button Putih
                              disabledForegroundColor:
                                  AppColors.textPrimary, // Teks Hitam

                              elevation: (isToday && !task.isTaken)
                                  ? 4
                                  : 0, // Shadow hanya jika belum diminum hari ini
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon juga logicnya disesuaikan
                                if (isToday) ...[
                                  Icon(
                                    task.isTaken
                                        ? Icons.undo
                                        : Icons.check_circle_outline,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  buttonText,
                                  style: const TextStyle(
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

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Obat?"),
        content: const Text(
          "Jadwal ini akan dihapus permanen untuk semua tanggal.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(medicationActionsProvider)
                  .deleteMedication(task.userId, task.id);
              Navigator.pop(ctx);
            },
            child: const Text("Hapus", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
