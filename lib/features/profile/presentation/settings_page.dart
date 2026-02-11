import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Copy Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/authentication/presentation/auth_controller.dart';
import 'package:silver_guide/features/profile/domain/user_model.dart';
import 'package:silver_guide/features/profile/presentation/profile_controller.dart';
import 'package:silver_guide/widgets/edit_profile_sheet.dart';

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
              _ProfileHeaderCard(user: user),
              const SizedBox(height: 24),

              // Bagian Keluarga
              const _SectionTitle(title: "KELUARGA"),
              _FamilyConnectionCard(user: user, ref: ref),

              const SizedBox(height: 24),

              // Pengaturan Umum
              const _SectionTitle(title: "UMUM"),
              _GeneralSettingsCard(user: user, ref: ref),

              const SizedBox(height: 40),

              // Tombol Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context, ref);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.red.withValues(alpha: 0.02),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    "Keluar Akun",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar Akun?"),
        content: const Text(
          "Anda harus login kembali untuk mengakses aplikasi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider).logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
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
          color: AppColors.textSecondary,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              backgroundColor: AppColors.surface,
              child: ClipOval(
                child: Image.network(
                  user.photoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user.role == UserRole.guardian
                        ? "Pendamping (Anak)"
                        : "Pengguna Utama",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => EditProfileSheet(user: user),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
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
    bool hasFamily = user.familyId != null && user.familyId!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasFamily)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.vpn_key_outlined,
                color: AppColors.textSecondary,
              ),
              title: const Text("Kode Keluarga"),
              subtitle: Text(
                user.familyId!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: user.familyId!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kode disalin!")),
                  );
                },
              ),
            ),
          if (!hasFamily)
            Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.group_add_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text("Gabung Keluarga"),
                  subtitle: const Text("Masukkan kode undangan"),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black26,
                  ),
                  onTap: () => _showJoinDialog(context, ref),
                ),
                if (user.role == UserRole.guardian) ...[
                  const Divider(height: 2, color: AppColors.surface),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(
                      Icons.add_home_work_outlined,
                      color: AppColors.accent,
                    ),
                    title: const Text("Buat Keluarga Baru"),
                    subtitle: const Text("Dapatkan kode untuk dibagikan"),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.black26,
                    ),
                    onTap: () async {
                      try {
                        await ref
                            .read(profileControllerProvider.notifier)
                            .createFamily();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Keluarga berhasil dibuat!"),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Gagal: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),

          const Divider(height: 2, color: AppColors.surface),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: const Icon(
              Icons.people_outline,
              color: AppColors.textSecondary,
            ),
            title: const Text("Anggota Keluarga"),
            subtitle: Text(
              hasFamily ? "Terhubung" : "Belum ada",
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // --- TOMBOL KELUAR KELUARGA ---
          if (hasFamily) ...[
            const Divider(height: 2, color: AppColors.surface),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 4,
              ),
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                "Keluar dari keluarga",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _showLeaveFamilyDialog(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _showLeaveFamilyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Keluar dari Keluarga?"),
        content: const Text(
          "Anda tidak akan lagi terhubung dengan anggota keluarga saat ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(profileControllerProvider.notifier)
                    .leaveFamily();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Berhasil keluar dari keluarga"),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
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
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: "Contoh: ABC1234",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref
                    .read(profileControllerProvider.notifier)
                    .joinFamily(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Berhasil bergabung!")),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Gabung"),
          ),
        ],
      ),
    );
  }
}

class _GeneralSettingsCard extends StatelessWidget {
  final UserProfile user;
  final WidgetRef ref;
  const _GeneralSettingsCard({required this.user, required this.ref});

  String _getTextSizeLabel(double value) {
    if (value <= 0.8) return "Kecil";
    if (value >= 1.2) return "Besar";
    return "Normal";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            leading: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text("Notifikasi"),
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeTrackColor: AppColors.primary,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
          const Divider(height: 2, color: AppColors.surface),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.text_fields,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    const Text("Ukuran Teks", style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text(
                      _getTextSizeLabel(user.textSize),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surface,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.1),
                    valueIndicatorColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: user.textSize,
                    min: 0.8,
                    max: 1.2,
                    divisions: 2,
                    label: _getTextSizeLabel(user.textSize),
                    onChanged: (double value) {
                      ref
                          .read(profileControllerProvider.notifier)
                          .updateTextSize(value);
                    },
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
