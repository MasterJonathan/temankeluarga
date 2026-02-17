import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';

// === SHEET 1: PILIH LANSIA ===
class ElderlySelectorSheet extends ConsumerWidget {
  const ElderlySelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kita ambil data keluarga dari provider yang sudah ada di profile_controller.dart
    final familyAsync = ref.watch(familyMembersProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Pilih Anggota Lansia", 
              style: AppTheme.lightTheme.textTheme.titleLarge
            ),
          ),
          const SizedBox(height: 16),
          
          familyAsync.when(
            data: (members) {
              final elderlyList = members.where((m) => m.role == UserRole.elderly).toList();
              
              if (elderlyList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text("Belum ada anggota lansia di keluarga ini.")),
                );
              }

              return Column(
                children: elderlyList.map((elderly) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(elderly.photoUrl),
                  ),
                  title: Text(elderly.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Ketuk untuk atur fitur"),
                  trailing: const Icon(Icons.settings, color: AppColors.primary),
                  onTap: () {
                    // Tutup sheet ini dulu
                    Navigator.pop(context);
                    // Buka sheet konfigurasi fitur
                    showModalBottomSheet(
                      context: context, 
                      isScrollControlled: true,
                      builder: (ctx) => FeatureConfigSheet(user: elderly)
                    );
                  },
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// === SHEET 2: KONFIGURASI FITUR ===
class FeatureConfigSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  const FeatureConfigSheet({super.key, required this.user});

  @override
  ConsumerState<FeatureConfigSheet> createState() => _FeatureConfigSheetState();
}

class _FeatureConfigSheetState extends ConsumerState<FeatureConfigSheet> {
  // State lokal untuk checklist
  late List<String> _enabledFeatures;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Copy list dari user saat ini
    _enabledFeatures = List.from(widget.user.enabledFeatures);
  }

  void _toggleFeature(String key, bool value) {
    setState(() {
      if (value) {
        _enabledFeatures.add(key);
      } else {
        // Validasi: Minimal 1 fitur harus aktif agar aplikasi tidak blank
        if (_enabledFeatures.length > 1) {
          _enabledFeatures.remove(key);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Minimal satu fitur harus aktif."))
          );
        }
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      // Panggil Controller untuk update Firestore
      await ref.read(profileControllerProvider.notifier).updateFeatures(
        widget.user.id, 
        _enabledFeatures
      );
      if (mounted) Navigator.pop(context);
      
      // Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fitur untuk ${widget.user.name} berhasil diperbarui."))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundImage: NetworkImage(widget.user.photoUrl)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Atur Fitur", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text(widget.user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // --- LIST SWITCH FITUR ---
            _buildSwitchTile(
              key: 'health', 
              label: "Kesehatan (Obat)", 
              icon: Icons.medication,
              color: AppColors.primary
            ),
            _buildSwitchTile(
              key: 'activity', 
              label: "Aktivitas & Hobi", 
              icon: Icons.local_florist,
              color: Colors.green
            ),
            _buildSwitchTile(
              key: 'memory', 
              label: "Kenangan (Galeri)", 
              icon: Icons.photo_library,
              color: Colors.orange
            ),
            _buildSwitchTile(
              key: 'chat', 
              label: "Obrolan Keluarga", 
              icon: Icons.forum,
              color: Colors.blue
            ),
      
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2))
                  : const Text("Simpan Konfigurasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String key, required String label, required IconData icon, required Color color}) {
    final bool isActive = _enabledFeatures.contains(key);
    
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: isActive,
      activeThumbColor: color,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      onChanged: (val) => _toggleFeature(key, val),
    );
  }
}