import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final PageController _pageController = PageController();

  // Controllers untuk Input Text
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  int _currentStep = 0; // 0, 1, 2
  String? _selectedRole; // 'elderly' atau 'guardian'
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- Logic Navigasi Wizard ---
  void _nextStep() {
    // Validasi Sederhana sebelum lanjut
    if (_currentStep == 0) {
      if (_emailController.text.isEmpty || _passController.text.isEmpty) {
        _showError("Email dan Kata Sandi wajib diisi.");
        return;
      }
      if (_passController.text != _confirmPassController.text) {
        _showError("Konfirmasi kata sandi tidak cocok.");
        return;
      }
    } else if (_currentStep == 1) {
      if (_nameController.text.isEmpty) {
        _showError("Nama Lengkap wajib diisi.");
        return;
      }
    }

    // Pindah Halaman
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // Step Terakhir: Submit
      _submitRegistration();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context); // Kembali ke Login
    }
  }

  void _submitRegistration() async {
    if (_selectedRole == null) {
      _showError("Silakan pilih peran Anda terlebih dahulu.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil Controller dengan Data Lengkap
      await ref
          .read(authControllerProvider)
          .register(
            email: _emailController.text,
            password: _passController.text,
            name: _nameController.text,
            phone: _phoneController.text,
            roleStr: _selectedRole!, // 'elderly' atau 'guardian'
          );

      // Jika sukses, Auth State akan berubah jadi 'LoggedIn'
      // Main.dart akan otomatis merubah halaman ke MainNavigationScaffold
      // Kita perlu memastikan navigasi stack bersih
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError("Registrasi Gagal: ${e.toString()}");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
        title: const Text(
          "Buat Akun Baru",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2,
            colors: [Color(0xFFffebe5), Color(0xFFfbf3ff)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Image.asset('images/2.png', height: 300),
              // 1. Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _buildProgressDot(0),
                    _buildProgressLine(0),
                    _buildProgressDot(1),
                    _buildProgressLine(1),
                    _buildProgressDot(2),
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe manual
                  children: [
                    _buildStep1Account(),
                    _buildStep2Personal(),
                    _buildStep3Role(),
                  ],
                ),
              ),

              // Tombol Lanjut (Hanya muncul di Step 1 & 2)
              // Di Step 3 tombolnya menyatu dengan pilihan kartu agar lebih intuitif
              if (_currentStep < 2)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Lanjut",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS STEPS ---

  Widget _buildStep1Account() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mulai dari akun.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.beVietnamPro().fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Daftarkan email dan kata sandi untuk keamanan akun Anda.",
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            controller: _emailController,
            label: "Email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passController,
            label: "Kata sandi",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPassController,
            label: "Ulangi kata sandi",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Personal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Isi data diri.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.beVietnamPro().fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Siapa nama panggilan akrab Anda?",
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            controller: _nameController,
            label: "Nama Lengkap",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: "Nomor WhatsApp (Opsional)",
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          const Text(
            "*Nomor HP berguna untuk pemulihan akun jika lupa password.",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Role() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pilih peran.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.beVietnamPro().fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Bagaimana Anda akan menggunakan aplikasi ini?",
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 32),

          // Pilihan 1: Senior
          _RoleSelectionCard(
            title: "Pengguna Utama",
            subtitle: "Saya ingin mencatat kesehatan & kenangan saya sendiri.",
            icon: Icons.person,
            color: AppColors.primary,
            isSelected: _selectedRole == 'elderly',
            onTap: () => setState(() => _selectedRole = 'elderly'),
          ),

          const SizedBox(height: 16),

          // Pilihan 2: Guardian
          _RoleSelectionCard(
            title: "Pendamping (Keluarga)",
            subtitle: "Saya ingin membantu memantau orang tua saya.",
            icon: Icons.supervised_user_circle,
            color: AppColors.accent, // Warna Terra Cotta
            isSelected: _selectedRole == 'guardian',
            onTap: () => setState(() => _selectedRole = 'guardian'),
          ),

          const Spacer(),

          // Tombol Finish
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Selesai & Masuk",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildProgressDot(int index) {
    bool isActive = index <= _currentStep;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "${index + 1}",
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(int index) {
    bool isActive = index < _currentStep;
    return Expanded(
      child: Container(
        height: 4,
        color: isActive ? AppColors.primary : Colors.grey[300],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.getFont('Open Sans', color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.openSans(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
