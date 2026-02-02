import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Copy Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';
import 'profile_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Pengaturan"),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: asyncUser.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // 1. Profil Card (Header)
              _ProfileHeaderCard(user: user),
              
              const SizedBox(height: 24),

              // 2. Bagian Khusus Guardian (Remote Control)
              // Hanya "Switch Profile", tombol tambah obat dihapus
              if (user.role == UserRole.guardian) ...[
                const _SectionTitle(title: "MODE PENDAMPING"),
                _GuardianControlCard(user: user),
                const SizedBox(height: 24),
              ],

              // 3. Bagian Keluarga
              const _SectionTitle(title: "KELUARGA"),
              _FamilyConnectionCard(user: user, ref: ref),

              const SizedBox(height: 24),

              // 4. Pengaturan Umum
              const _SectionTitle(title: "UMUM"),
              _GeneralSettingsCard(ref: ref),

              const SizedBox(height: 40),
              
              // 5. Tombol Logout (Sekarang terlihat seperti tombol)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Logic Logout nanti
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.red.withOpacity(0.02),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
              Text(
                "Versi 1.0.0 (Beta)", 
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12)
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

// === KOMPONEN UI ===

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.5,
          color: AppColors.textSecondary
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final UserProfile user;
  const _ProfileHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 15, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(user.photoUrl),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Playfair Display'
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.role == UserRole.guardian ? "Pendamping (Anak)" : "Pengguna Utama",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card Khusus Guardian: "Switch Profil" (Tanpa Border Kuning, Tanpa Tombol Tambah)
class _GuardianControlCard extends StatelessWidget {
  final UserProfile user;
  const _GuardianControlCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Tanpa Border Kuning sesuai request
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.supervised_user_circle, color: AppColors.primary, size: 24),
        ),
        title: const Text("Sedang Memantau", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        subtitle: const Text(
          "Bapak Sutomo", // Nanti dinamis
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)
        ), 
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: const Text("Ganti", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Ganti Profil (Simulasi)")));
        },
      ),
    );
  }
}

class _FamilyConnectionCard extends StatelessWidget {
  final UserProfile user;
  final WidgetRef ref;
  
  const _FamilyConnectionCard({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    bool hasFamily = user.familyId != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          if (hasFamily)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.vpn_key_outlined, color: AppColors.textSecondary),
              title: const Text("Kode Keluarga"),
              subtitle: Text(
                user.familyId!, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary, letterSpacing: 1.0)
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                   Clipboard.setData(ClipboardData(text: user.familyId!));
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode disalin!")));
                },
              ),
            )
          else
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.group_add_outlined, color: AppColors.primary),
              title: const Text("Gabung Keluarga"),
              subtitle: const Text("Masukkan kode undangan"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
              onTap: () {
                _showJoinDialog(context, ref);
              },
            ),
          
          // Divider sesuai request (Warna Surface)
          const Divider(height: 2, color: AppColors.surface),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(Icons.people_outline, color: AppColors.textSecondary),
            title: const Text("Anggota Keluarga"),
            subtitle: Text(hasFamily ? "3 Anggota terhubung" : "Belum ada", style: const TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Gabung Keluarga"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Contoh: KEL-8899", 
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal", style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(profileControllerProvider.notifier).joinFamily(controller.text);
              Navigator.pop(ctx);
            }, 
            child: const Text("Gabung")
          )
        ],
      )
    );
  }
}

class _GeneralSettingsCard extends StatelessWidget {
  final WidgetRef ref;
  const _GeneralSettingsCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // DEMO ONLY: Switch Role
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.switch_account, color: Colors.purple, size: 20),
            ),
            title: const Text("Ganti Peran [Demo]"),
            subtitle: const Text("Simulasi switch Lansia <-> Guardian", style: TextStyle(fontSize: 12)),
            onTap: () {
              ref.read(profileControllerProvider.notifier).toggleRoleForDemo();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role Berubah! Cek Header Profil.")));
            },
          ),
          
          const Divider(height: 2, color: AppColors.surface),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            title: const Text("Notifikasi"),
            trailing: Switch(
              value: true, 
              onChanged: (v) {}, 
              activeColor: AppColors.primary,
              trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
            ),
          ),
          
          const Divider(height: 2, color: AppColors.surface),
          
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Icon(Icons.text_fields, color: AppColors.textSecondary),
            title: Text("Ukuran Teks"),
            trailing: Text("Besar", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}