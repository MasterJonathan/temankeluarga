import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';

// Import Feature Pages
import 'package:silver_guide/features/activities/presentation/activities_page.dart';
import 'package:silver_guide/features/activities/presentation/add_activity_page.dart';
import 'package:silver_guide/features/family_chat/domain/chat_model.dart';
import 'package:silver_guide/features/family_chat/presentation/chat_actions.dart';
import 'package:silver_guide/features/family_chat/presentation/family_chat_page.dart';
import 'package:silver_guide/features/memories/presentation/memories_page.dart';
import 'package:silver_guide/features/medication/presentation/health_page.dart';

// Import Profile & State
import 'package:silver_guide/features/profile/domain/user_model.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';
import 'package:silver_guide/features/profile/presentation/settings_page.dart';
import 'package:silver_guide/features/profile/presentation/guardian_state.dart';

// Import Sheets
import 'package:silver_guide/widgets/medication_form_sheet.dart';
import 'package:silver_guide/widgets/write_diary_sheet.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScaffold extends ConsumerWidget {
  const MainNavigationScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final asyncUser = ref.watch(profileControllerProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);


    
    // Kita cek nanti di logic build

    return asyncUser.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (user) {
        // 1. DEFINISI FITUR
        final allFeatures = [
          _NavItem(id: 'health', title: "Jadwal Kesehatan", icon: Icons.medication_outlined, selectedIcon: Icons.medication, label: 'Sehat', page: const HealthPage()),
          _NavItem(id: 'activity', title: "Aktivitas Hari Ini", icon: Icons.local_florist_outlined, selectedIcon: Icons.local_florist, label: 'Aktivitas', page: const ActivitiesPage()),
          _NavItem(id: 'memory', title: "Kenangan Kita", icon: Icons.photo_library_outlined, selectedIcon: Icons.photo_library, label: 'Kenangan', page: const MemoriesPage()),
          _NavItem(id: 'chat', title: "Ruang Keluarga", icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: 'Obrolan', page: const FamilyChatPage()),
        ];

        // 2. FILTER FITUR
        final enabledKeys = user.enabledFeatures.isEmpty 
            ? ['health', 'activity', 'memory', 'chat'] 
            : user.enabledFeatures;

        final visibleItems = allFeatures
            .where((item) => enabledKeys.contains(item.id))
            .toList();

        final safeIndex = currentIndex >= visibleItems.length ? 0 : currentIndex;
        final activeItem = visibleItems.isNotEmpty ? visibleItems[safeIndex] : null;

        // LOGIC KHUSUS CHAT PAGE
        // Jika sedang di halaman Chat, kita sembunyikan FAB SOS & BottomBar
        // agar input text tidak tertutup keyboard/FAB.
        final bool isChatPage = activeItem?.id == 'chat';

        return Scaffold(
          extendBody: true,
          // ResizeToAvoidBottomInset: true penting agar keyboard mendorong body ke atas
          resizeToAvoidBottomInset: true, 
          
          appBar: AppBar(
            title: Text(activeItem?.title ?? "Silver Guide"),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl)
                        : const NetworkImage("https://cdn-icons-png.flaticon.com/256/149/149071.png"),
                  ),
                ),
              ),
            ],
          ),

          // BODY
          body: Stack(
            children: [
              visibleItems.isEmpty 
                  ? const Center(child: Text("Tidak ada fitur yang aktif."))
                  : IndexedStack(
                      index: safeIndex,
                      children: visibleItems.map((e) => e.page).toList(),
                    ),

              // Tombol Tambah Guardian
              // Sembunyikan jika di Chat Page (karena chat punya input sendiri)
              if (!isChatPage)
                Positioned(
                  bottom: 136, 
                  right: 16,
                  child: _buildPageActionFab(context, user, activeItem?.id, activeProfileId),
                ),
            ],
          ),

          // TOMBOL SOS (Hanya muncul jika BUKAN Chat Page)
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: isChatPage ? null : SizedBox(
            width: 64, height: 64,
            child: FloatingActionButton(
              heroTag: "fab_sos_main",
              elevation: 4,
              backgroundColor: Colors.red,
              shape: const CircleBorder(),
              onPressed: () => _showSosCountdown(context, ref, user),
              child: const Icon(Icons.sos, size: 28, color: Colors.white),
            ),
          ),


          
          // Solusi Praktis: Di Halaman Chat, SOS hilang. Lubang tetap ada (estetika).
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: AppColors.surface,
            surfaceTintColor: AppColors.primary,
            elevation: 8,
            height: 80,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFixedSlot(context, ref, allFeatures, visibleItems, 'health', safeIndex),
                      _buildFixedSlot(context, ref, allFeatures, visibleItems, 'activity', safeIndex),
                    ],
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFixedSlot(context, ref, allFeatures, visibleItems, 'memory', safeIndex),
                      _buildFixedSlot(context, ref, allFeatures, visibleItems, 'chat', safeIndex),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPER UNTUK MEMBUAT SLOT STATIS ---
  Widget _buildFixedSlot(
    BuildContext context,
    WidgetRef ref,
    List<_NavItem> allFeatures, // Referensi data asli
    List<_NavItem> visibleItems, // List yang sedang aktif di IndexedStack
    String featureId, // ID fitur yang ingin ditampilkan di slot ini
    int currentIndex, // Index halaman yang sedang aktif
  ) {
    // 1. Cari Index Asli di IndexedStack (Visible Items)
    //    Kita butuh ini untuk men-trigger navigasi (ref.read...state = index)
    final int targetIndex = visibleItems.indexWhere(
      (item) => item.id == featureId,
    );

    // 2. Jika Fitur ini TIDAK AKTIF (Index -1), tampilkan Widget Kosong (Invisible)
    //    tapi ukurannya tetap sama agar layout tidak geser.
    if (targetIndex == -1) {
      return const SizedBox(width: 72); // Lebar sama dengan tombol aktif
    }

    // 3. Jika Aktif, Render Tombol Normal
    //    Kita ambil data ikon/label dari allFeatures
    final item = allFeatures.firstWhere((e) => e.id == featureId);
    final isSelected = currentIndex == targetIndex;

    return InkWell(
      onTap: () => ref.read(navIndexProvider.notifier).state = targetIndex,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 8 : 0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC TOMBOL TAMBAH (Guardian) ---
  Widget _buildPageActionFab(
    BuildContext context,
    UserProfile user,
    String? featureId,
    String? activeProfileId,
  ) {
    if (featureId == 'memory') {
      if (user.familyId == null || user.familyId!.isEmpty)
        return const SizedBox.shrink();
      return FloatingActionButton(
        heroTag: "fab_add_memory",
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => WriteDiarySheet(
            familyId: user.familyId!,
            userId: user.id,
            userName: user.name,
          ),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_note, color: Colors.white),
      );
    }

    if (user.role == UserRole.guardian && activeProfileId != null) {
      if (featureId == 'health') {
        return FloatingActionButton(
          heroTag: "fab_add_health",
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => MedicationFormSheet(userId: activeProfileId),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        );
      } else if (featureId == 'activity') {
        return FloatingActionButton(
          heroTag: "fab_add_activity",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddActivityPage(userId: activeProfileId!),
            ),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _showSosCountdown(BuildContext context, WidgetRef ref, UserProfile user) { 
    // Note: Tambahkan parameter ref dan user
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sinyal Darurat Terkirim!"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    // --- LOGIC CHAT SOS ---
    if (user.familyId != null && user.familyId!.isNotEmpty) {
      ref.read(chatActionsProvider).sendSystemMessage(
        familyId: user.familyId!,
        senderId: user.id,
        senderName: user.name,
        text: "🚨 MENEKAN TOMBOL SOS! BUTUH BANTUAN!",
        contextType: ChatContextType.general,
      );
    }
  }
}

class _NavItem {
  final String id;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  _NavItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}
