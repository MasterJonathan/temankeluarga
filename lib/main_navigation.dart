import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/activities/presentation/activities_page.dart';
import 'package:silver_guide/features/family_chat/presentation/family_chat_page.dart';
import 'package:silver_guide/features/gallery/presentation/memories_page.dart';
import 'package:silver_guide/features/medication/presentation/health_page.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';
import 'package:silver_guide/features/profile/presentation/settings_page.dart';

// State Provider untuk mengontrol Tab yang aktif
final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScaffold extends ConsumerWidget {
  const MainNavigationScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    final asyncUser = ref.watch(profileControllerProvider);

    // List Halaman (Placeholder untuk saat ini)
    final List<Widget> pages = [
      const HealthPage(),
      const ActivitiesPage(), 
      const MemoriesPage(),
      const FamilyChatPage(),
    ];

    // Judul Halaman berdasarkan Index
    final List<String> titles = [
      "Selamat Pagi, Ayah", // Bisa dinamis nanti
      "Aktivitas Hari Ini",
      "Kenangan Kita",
      "Ruang Keluarga",
    ];

    return Scaffold(
      // 1. Header dengan SOS Button
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          _buildSOSButton(context), 
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // Navigasi ke Settings Page
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const SettingsPage())
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: asyncUser != null 
                ? NetworkImage(asyncUser.value!.photoUrl) 
                : null, // Loading or Error
              child: asyncUser.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            ),
          ),
          const SizedBox(width: 16),
          ],
      ),

      // 2. Body dengan IndexedStack (State Preservation)
      body: IndexedStack(index: currentIndex, children: pages),

      // 3. Bottom Navigation (Autumn Style)
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Sehat',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist),
            label: 'Aktivitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Kenangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Obrolan',
          ),
        ],
      ),
    );
  }

  // Widget Tombol SOS (Safety First)
  Widget _buildSOSButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Implementasi Hitung Mundur & Logic SOS
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Fitur SOS ditekan - Logic akan diimplementasikan nanti",
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent, // Warna Terra Cotta/Merah Bata
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
        ),
        icon: const Icon(Icons.sos, size: 20),
        label: const Text(
          "SOS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Helper sementara untuk Placeholder
  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Fitur ini akan segera dibangun.",
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
