import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/medication/presentation/medication_controller.dart';
import 'package:silver_guide/features/medication/domain/medication_model.dart';
import 'package:silver_guide/widget/timeline_task_item.dart';

class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMedications = ref.watch(medicationControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // 1. Header Kalender (Date Strip)
          SliverToBoxAdapter(
            child: _buildDateStrip(),
          ),

          // 2. Daftar Obat / Timeline
          asyncMedications.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const SliverToBoxAdapter(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text("Tidak ada jadwal obat hari ini.")),
                ));
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return TimelineTaskItem(task: task);
                  },
                  childCount: tasks.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Terjadi kesalahan: $err"),
            )),
          ),

          // Spacer bawah agar tidak tertutup nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Jadwal Hari Ini",
            style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Minggu, 24 Oktober", // Nanti gunakan DateFormat
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          // Simulasi Date Selector (Sederhana dulu untuk MVP)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) {
                final isToday = index == 0;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${24 + index}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppColors.surface : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        ["M", "S", "S", "R", "K"][index],
                        style: TextStyle(
                          fontSize: 14,
                          color: isToday ? AppColors.surface : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }
}