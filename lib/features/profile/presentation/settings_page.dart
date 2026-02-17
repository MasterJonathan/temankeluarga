import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Copy Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
import 'package:teman_keluarga/features/authentication/presentation/auth_controller.dart';
import 'package:teman_keluarga/features/profile/domain/user_model.dart';
import 'package:teman_keluarga/features/profile/presentation/profile_controller.dart';
import 'package:teman_keluarga/widgets/edit_profile_sheet.dart';
import 'package:teman_keluarga/widgets/feature_management_sheet.dart';

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
      body: SafeArea(
        child: asyncUser.when(
          data: (user) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              children: [
                _ProfileHeaderCard(user: user),
                const SizedBox(height: 24),
        
                // Bagian Keluarga
                const _SectionTitle(title: "KELUARGA"),
                _FamilyConnectionCard(user: user),
        
                const SizedBox(height: 24),
                
                // Bagian Fitur (Khusus Guardian)
                if (user.role == UserRole.guardian && user.familyId != null) ...[
                  const _SectionTitle(title: "KONFIGURASI"),
                  _FeatureSettingsCard(user: user),
                  const SizedBox(height: 24),
                ],
        
                // Pengaturan Umum
                const _SectionTitle(title: "UMUM"),
                _GeneralSettingsCard(user: user, ref: ref),
        
                const SizedBox(height: 40),
        
                // Tombol Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text("Error: $err")),
        ),
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
            child: const Text("Keluar", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// === WIDGET KELUARGA (UPDATED) ===
class _FamilyConnectionCard extends ConsumerWidget {
  final UserProfile user;
  const _FamilyConnectionCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasFamily = user.familyId != null && user.familyId!.isNotEmpty;
    final bool isGuardian = user.role == UserRole.guardian;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          if (hasFamily) ...[
            // 1. Header Kode Keluarga
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
            ),
            const Divider(height: 2, color: AppColors.surface),

            // 2. Request List (Hanya Guardian)
            if (isGuardian) _buildRequestList(context, ref, user.familyId!),

            // 3. Member List (Real Data)
            _buildMemberList(context, ref, user),

            // 4. Tombol Keluar (HANYA GUARDIAN, Lansia tidak boleh leave sendiri)
            if (isGuardian) ...[
              const Divider(height: 2, color: AppColors.surface),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                title: const Text("Keluar dari keluarga", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500)),
                onTap: () => _showLeaveDialog(context, ref),
              ),
            ],
          ] else ...[
            // State Belum Punya Keluarga
            _buildNoFamilyView(context, ref, isGuardian),
          ],
        ],
      ),
    );
  }

  // Widget List Anggota
  Widget _buildMemberList(BuildContext context, WidgetRef ref, UserProfile currentUser) {
    final membersAsync = ref.watch(familyMembersProvider); // Ini dari profile_controller.dart

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) return const SizedBox();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text("Anggota", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
            ...members.map((member) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              leading: CircleAvatar(backgroundImage: NetworkImage(member.photoUrl), radius: 16),
              title: Text(member.name + (member.id == currentUser.id ? " (Anda)" : ""), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(member.role == UserRole.guardian ? "Pendamping" : "Pengguna Utama", style: const TextStyle(fontSize: 12)),
              trailing: (currentUser.role == UserRole.guardian && member.id != currentUser.id)
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                      onPressed: () => _showKickDialog(context, ref, member),
                    )
                  : null,
            )),
          ],
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox(),
    );
  }

  // Widget List Request (Pending Approval)
  Widget _buildRequestList(BuildContext context, WidgetRef ref, String familyId) {
    final requestsAsync = ref.watch(joinRequestsProvider(familyId));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox();
        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: const Text("Menunggu Persetujuan", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            ...requests.map((req) => ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(req.photoUrl), radius: 16),
              title: Text(req.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Ingin bergabung"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => ref.read(profileControllerProvider.notifier).acceptMember(req.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.danger),
                    onPressed: () => ref.read(profileControllerProvider.notifier).removeMember(req.id),
                  ),
                ],
              ),
            )),
            const Divider(height: 2, color: AppColors.surface),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildNoFamilyView(BuildContext context, WidgetRef ref, bool isGuardian) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.group_add_outlined, color: AppColors.primary),
          title: const Text("Gabung Keluarga"),
          subtitle: const Text("Masukkan kode undangan"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => _showJoinDialog(context, ref),
        ),
        if (isGuardian) ...[
          const Divider(height: 2, color: AppColors.surface),
          ListTile(
            leading: const Icon(Icons.add_home_work_outlined, color: AppColors.accent),
            title: const Text("Buat Keluarga Baru"),
            subtitle: const Text("Dapatkan kode unik"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () async {
              try {
                await ref.read(profileControllerProvider.notifier).createFamily();
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Keluarga berhasil dibuat!")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: AppColors.danger));
                }
              }
            },
          ),
        ]
      ],
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Gabung Keluarga"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: "Contoh: ABC1234", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            const Text("Setelah memasukkan kode, tunggu Guardian menyetujui permintaan Anda.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              ref.read(profileControllerProvider.notifier).requestJoinFamily(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permintaan dikirim. Tunggu persetujuan.")));
            },
            child: const Text("Kirim Request"),
          ),
        ],
      ),
    );
  }

  void _showKickDialog(BuildContext context, WidgetRef ref, UserProfile member) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Keluarkan ${member.name}?"),
      content: const Text("Mereka tidak akan bisa lagi mengakses data keluarga."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
        TextButton(onPressed: () {
          ref.read(profileControllerProvider.notifier).removeMember(member.id);
          Navigator.pop(ctx);
        }, child: const Text("Keluarkan", style: TextStyle(color: AppColors.danger))),
      ],
    ));
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
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
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text("Keluar", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// === CARD FITUR (BARU) ===
class _FeatureSettingsCard extends StatelessWidget {
  final UserProfile user;
  const _FeatureSettingsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: const Icon(Icons.tune, color: AppColors.primary),
        title: const Text("Atur Fitur Lansia"),
        subtitle: const Text("Aktifkan/Nonaktifkan menu"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          _showFeatureDialog(context);
        },
      ),
    );
  }

  void _showFeatureDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => const ElderlySelectorSheet(), // <--- PANGGIL SHEET BARU DI SINI
    );
  }
}

// === KOMPONEN UI LAMA ===

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
              border: Border.all(color: AppColors.surface, width: 2),
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
                          color: AppColors.surface,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
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
                    color: AppColors.surface.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.role == UserRole.guardian
                        ? "Pendamping (Anak)"
                        : "Pengguna Utama",
                    style: const TextStyle(
                      color: AppColors.surface,
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
            icon: const Icon(Icons.edit, color: AppColors.surface),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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