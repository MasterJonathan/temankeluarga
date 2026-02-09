import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';
import 'package:silver_guide/features/profile/presentation/guardian_state.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';
import 'package:silver_guide/features/activities/domain/activity_model.dart';
import 'package:silver_guide/widgets/activity_form_sheet.dart';
import 'activity_provider.dart';
import 'activity_actions.dart';

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileId = ref.watch(activeProfileIdProvider);
    final currentUserAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: currentUserAsync.when(
        data: (user) {
          // LOGIC STRICT: Hanya Guardian yang sedang memantau profil spesifik
          if (user.role == UserRole.guardian && activeProfileId != null) {
            return FloatingActionButton.extended(
              heroTag: "fab_add_activity",
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => ActivityFormSheet(userId: activeProfileId),
                );
              },
              label: const Text("Tambah Hobi"),
              icon: const Icon(Icons.local_florist),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white, // Pastikan teks putih agar kontras
            );
          }
          // Lansia atau Guardian di Dashboard tidak melihat tombol ini
          return null;
        },
        loading: () => null,
        error: (_, _) => null,
      ),

      body: currentUserAsync.when(
        data: (user) {
          if (user.role == UserRole.guardian && activeProfileId == null) {
            return const _GuardianActivityDashboard();
          }
          return _DetailActivityView(
            activeProfileId: activeProfileId ?? user.id,
            isGuardianMode: user.role == UserRole.guardian,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox(),
      ),
    );
  }
}

// === DASHBOARD ===
class _GuardianActivityDashboard extends ConsumerWidget {
  const _GuardianActivityDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);

    return familyAsync.when(
      data: (members) {
        final elderlyMembers = members
            .where((m) => m.role == UserRole.elderly)
            .toList();
        if (elderlyMembers.isEmpty) {
          return const Center(child: Text("Belum ada lansia."));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "Kebun Keluarga",
              style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Lihat perkembangan kebahagiaan mereka.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ...elderlyMembers.map((m) => _ActivitySummaryCard(member: m)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox(),
    );
  }
}

class _ActivitySummaryCard extends ConsumerWidget {
  final UserProfile member;
  const _ActivitySummaryCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(activityProgressProvider(member.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () =>
            ref.read(viewedElderlyIdProvider.notifier).state = member.id,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedScale(
                scale: 0.8 + (progress * 0.2),
                duration: const Duration(seconds: 1),
                child: Icon(
                  progress == 1.0 ? Icons.park : Icons.forest_outlined,
                  size: 50,
                  color: progress > 0.5 ? AppColors.primary : Colors.grey,
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(progress * 100).toInt()}% Energi",
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: AppColors.secondary,
                        backgroundColor: Colors.grey[200],
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// === DETAIL VIEW ===
class _DetailActivityView extends ConsumerWidget {
  final String activeProfileId;
  final bool isGuardianMode;

  const _DetailActivityView({
    required this.activeProfileId,
    required this.isGuardianMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActivities = ref.watch(activityProvider(activeProfileId));
    final progress = ref.watch(activityProgressProvider(activeProfileId));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (isGuardianMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(viewedElderlyIdProvider.notifier).state = null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Kembali ke Kebun",
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
              _FamilyTreeHeader(progress: progress),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ... (Kode Grid Activity Card tetap sama seperti file sebelumnya)
        asyncActivities.when(
          data: (activities) {
            if (activities.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text("Belum ada hobi.")),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ActivityCard(item: activities[index]),
                  childCount: activities.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              SliverFillRemaining(child: Center(child: Text("Error: $e"))),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// === WIDGETS ===

class _ActivityCard extends ConsumerWidget {
  final ActivityItem item;
  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = item.isCompleted;

    return GestureDetector(
      onTap: () async {
        // Panggil Action Provider
        final msg = await ref
            .read(activityActionsProvider)
            .toggleActivity(
              item.userId, // <--- Tambahkan parameter ini
              item.id,
              isDone,
              item.motivationalMessage,
            );

        if (msg.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: item.color,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: isDone ? item.color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDone
                  ? item.color.withValues(alpha: 0.4)
                  : Colors.black12,
              blurRadius: isDone ? 16 : 8,
              offset: Offset(0, isDone ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.white.withValues(alpha: 0.2)
                    : item.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 48,
                color: isDone ? Colors.white : item.color,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: isDone ? Colors.white : AppColors.textPrimary,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyTreeHeader extends StatelessWidget {
  final double progress;
  const _FamilyTreeHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    String statusMsg = "Pohon butuh air...";
    if (progress > 0.3) statusMsg = "Pohon mulai segar!";
    if (progress > 0.6) statusMsg = "Daunnya makin lebat!";
    if (progress == 1.0) statusMsg = "Luar biasa! Pohon berbuah!";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AnimatedScale(
              scale: 0.8 + (progress * 0.4),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              child: Icon(
                progress == 1.0 ? Icons.park : Icons.forest_outlined,
                size: 80,
                color: progress == 1.0
                    ? AppColors.primary
                    : AppColors.textSecondary,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.white,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
