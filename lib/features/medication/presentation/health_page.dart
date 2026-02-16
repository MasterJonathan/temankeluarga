import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal Date Strip
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';
import 'package:silver_guide/features/profile/presentation/guardian_state.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';
import 'package:silver_guide/services/notification_service.dart';
import 'package:silver_guide/widgets/timeline_task_item.dart';
import 'package:silver_guide/features/medication/presentation/medication_provider.dart';

class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(profileControllerProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);

    ref.listen(medicationProvider(activeProfileId ?? ""), (previous, next) {
      if (next.value != null &&
          currentUserAsync.value?.role == UserRole.elderly) {
        final notifService = ref.read(notificationServiceProvider);

        // Loop semua obat dan pastikan terjadwal
        for (var task in next.value!) {
          final timeParts = task.time.split(":");
          final timeOfDay = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
          final uniqueId = "${task.userId}_${task.title}_${task.time}".hashCode;

          notifService.scheduleMedication(
            id: uniqueId,
            title: "Waktunya Minum Obat 💊",
            body: "Jangan lupa minum ${task.title}",
            time: timeOfDay,
          );
        }
      }
    });
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: currentUserAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, error) => const SizedBox(),
        data: (user) {
          // MODE 1: GUARDIAN DASHBOARD (Belum pilih siapa-siapa)
          if (user.role == UserRole.guardian && activeProfileId == null) {
            return const _GuardianHealthDashboard();
          }

          // MODE 2: DETAIL VIEW (Lansia atau Guardian yang sudah pilih)
          return _DetailTimelineView(
            activeProfileId:
                activeProfileId ??
                user.id, // Fallback ke ID sendiri jika Lansia
            isGuardianMode: user.role == UserRole.guardian,
            userName: user.name,
          );
        },
      ),
    );
  }
}

// ==========================================
// VIEW 1: DASHBOARD GUARDIAN (RINGKASAN)
// ==========================================
class _GuardianHealthDashboard extends ConsumerWidget {
  const _GuardianHealthDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);

    return familyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, error) => const Center(child: Text("Gagal memuat keluarga")),
      data: (members) {
        final elderlyMembers = members
            .where((m) => m.role == UserRole.elderly)
            .toList();

        if (elderlyMembers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 60,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Belum ada Orang Tua yang terhubung.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bagikan kode keluarga dari Settings.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              "Pantauan Kesehatan",
              style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pilih anggota keluarga untuk melihat detail obat.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Render Kartu untuk setiap Lansia
            ...elderlyMembers.map(
              (member) => _HealthSummaryCard(member: member),
            ),
          ],
        );
      },
    );
  }
}

class _HealthSummaryCard extends ConsumerWidget {
  final UserProfile member;
  const _HealthSummaryCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kita watch data obat user ini untuk menampilkan progress bar ringkas
    final medicationsAsync = ref.watch(medicationProvider(member.id));

    return medicationsAsync.when(
      loading: () => const Card(
        child: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, error) => const SizedBox(),
      data: (tasks) {
        final total = tasks.length;
        final taken = tasks.where((t) => t.isTaken).length;
        final progress = total == 0 ? 0.0 : taken / total;

        // Status Logic Warna
        Color statusColor = AppColors.primary; // Hijau (Aman)
        String statusText = "Terkendali";

        if (total == 0) {
          statusColor = Colors.grey;
          statusText = "Kosong";
        } else if (taken < total) {
          // Bisa tambah logika jam jika mau lebih canggih (misal: merah jika telat)
          statusColor = AppColors.accent; // Orange (Belum selesai)
          statusText = "Perlu Dicek";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // AKSI: Set Active Profile -> UI otomatis pindah ke Detail View
                ref.read(viewedElderlyIdProvider.notifier).state = member.id;
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Hero(
                      tag: "avatar_${member.id}",
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(member.photoUrl),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Custom Progress Bar
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: total == 0 ? 0.0 : progress,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$taken / $total Obat",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// VIEW 2: DETAIL TIMELINE (DENGAN DATE STRIP)
// ==========================================
class _DetailTimelineView extends ConsumerWidget {
  final String activeProfileId;
  final bool isGuardianMode;
  final String userName;

  const _DetailTimelineView({
    required this.activeProfileId,
    required this.isGuardianMode,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider untuk data obat detail (sudah handle logic tanggal di dalam medication_provider.dart)
    final asyncMedications = ref.watch(medicationProvider(activeProfileId));
    final selectedDate = ref.watch(selectedDateProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGuardianMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(viewedElderlyIdProvider.notifier).state =
                              null,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Kembali ke Ringkasan",
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                _buildDateStrip(context, ref, selectedDate, userName),
              ],
            ),
          ),
        ),

        asyncMedications.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      "Tidak ada catatan obat pada tanggal ini.",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return TimelineTaskItem(
                    selectedDate: selectedDate,
                    task: tasks[index],
                  );
                }, childCount: tasks.length),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              SliverFillRemaining(child: Center(child: Text("Error: $e"))),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 200)),
      ],
    );
  }

  // Widget Date Strip yang Dinamis
  Widget _buildDateStrip(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    String name,
  ) {
    // Generate 5 hari (Hari ini + 4 hari ke belakang)
    final today = DateTime.now();
    final List<DateTime> dates = List.generate(5, (index) {
      return today.add(Duration(days: index - 2));
    });

    // Format Tanggal Header (misal: "Senin, 24 Oktober 2023")
    final String formattedHeaderDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDate);

    final int hour = DateTime.now().hour;
    String greeting;
    if (hour >= 4 && hour < 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Greeting & Tanggal (Outside)
        Text(
          "$greeting, $name",
          style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedHeaderDate,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 24),

        // 2. Banner Quote (Accent Background)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.5), // Subtle accent
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  height: 130, // Tinggi tetap untuk centering quote
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "\"Kesehatan adalah harta paling berharga yang kita miliki.\"",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Gambar mepet bawah (Zero padding bottom)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Image.asset(
                  "assets/images/1_crop.png",
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 2. Tanya AI Section
        Text(
          "Tanya AI",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Mic Button (Besar untuk Lansia)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mulai Bicara...")),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Input & Send
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Tanya sesuatu...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 2. Row Kalender
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dates.map((date) {
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                final isToday = DateUtils.isSameDay(date, today);

                final dayNum = date.day.toString();
                final dayName = DateFormat(
                  'E',
                  'id_ID',
                ).format(date); // Sen, Sel, Rab, Kam

                return GestureDetector(
                  onTap: () {
                    // Update state tanggal -> Provider otomatis refresh data
                    ref.read(selectedDateProvider.notifier).state = date;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayNum,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isToday ? "Hari Ini" : dayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Jadwal Minum Obat",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
