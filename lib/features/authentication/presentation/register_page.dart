import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final PageController _pageController = PageController();

  // Controllers
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  int _currentStep = 0; // 0, 1, 2, 3
  String? _selectedRole;
  String? _selectedAgeRange;

  // Default semua fitur aktif
  // Key: 'health', 'activity', 'memory', 'chat'
  final List<String> _selectedFeatures = [
    'health',
    'activity',
    'memory',
    'chat',
  ];

  bool _isLoading = false;

  // Getter untuk menentukan total step dinamis
  // Jika Elderly: 3 Step (0,1,2). Jika Guardian: 4 Step (0,1,2,3).
  int get _totalSteps => _selectedRole == 'elderly' ? 3 : 4;

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

  // --- LOGIC NAVIGASI ---
  void _nextStep() {
    // Validasi Step 0 (Akun)
    if (_currentStep == 0) {
      if (_emailController.text.isEmpty || _passController.text.isEmpty) {
        _showError("Email dan Kata Sandi wajib diisi.");
        return;
      }
      if (_passController.text != _confirmPassController.text) {
        _showError("Konfirmasi kata sandi tidak cocok.");
        return;
      }
    }
    // Validasi Step 1 (Data Diri)
    else if (_currentStep == 1) {
      if (_nameController.text.isEmpty) {
        _showError("Nama Lengkap wajib diisi.");
        return;
      }
      if (_selectedAgeRange == null) {
        _showError("Silakan pilih rentang usia Anda.");
        return;
      }
    }
    // Validasi Step 2 (Peran) -> Disini Percabangan terjadi
    else if (_currentStep == 2) {
      if (_selectedRole == null) {
        _showError("Silakan pilih peran Anda terlebih dahulu.");
        return;
      }

      // JIKA LANSIA: Selesai di sini (Skip Step 4)
      if (_selectedRole == 'elderly') {
        _submitRegistration();
        return;
      }
      // JIKA GUARDIAN: Lanjut ke Step 4 (Fitur)
    }
    // Validasi Step 3 (Fitur - Khusus Guardian)
    else if (_currentStep == 3) {
      if (_selectedFeatures.isEmpty) {
        _showError("Pilih minimal 1 fitur utama.");
        return;
      }
      _submitRegistration();
      return;
    }

    // Pindah Halaman jika belum finish
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
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
      Navigator.pop(context);
    }
  }

  void _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      // Logic: Jika Elderly, paksa enable semua fitur (atau default family)
      // Jika Guardian, gunakan pilihan dia.
      final featuresToSend = _selectedRole == 'elderly'
          ? ['health', 'activity', 'memory', 'chat']
          : _selectedFeatures;

      await ref
          .read(authControllerProvider)
          .register(
            email: _emailController.text,
            password: _passController.text,
            name: _nameController.text,
            phone: _phoneController.text,
            roleStr: _selectedRole!,
            ageRange: _selectedAgeRange,
            enabledFeatures: featuresToSend, // Kirim fitur terpilih
          );

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
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  // --- LOGIC TOGGLE FITUR ---
  void _toggleFeature(String featureKey) {
    setState(() {
      if (_selectedFeatures.contains(featureKey)) {
        // Cegah hapus semua (Minimal 1)
        if (_selectedFeatures.length > 1) {
          _selectedFeatures.remove(featureKey);
        } else {
          _showError("Minimal 1 fitur harus aktif.");
        }
      } else {
        _selectedFeatures.add(featureKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Total dots ditampilkan max 4 biar tidak goyang layoutnya
    // Tapi logic active-nya mengikuti _currentStep

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
              // Gambar dinamis? Atau statis saja
              // 1. Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(0),
                    _buildProgressLine(0),
                    _buildProgressDot(1),
                    _buildProgressLine(1),
                    _buildProgressDot(2),
                    // Garis & Dot ke-4 hanya muncul visualnya jika Guardian atau belum pilih role
                    if (_selectedRole != 'elderly') ...[
                      _buildProgressLine(2),
                      _buildProgressDot(3),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Account(),
                    _buildStep2Personal(),
                    _buildStep3Role(),
                    _buildStep4Features(), // Halaman Baru
                  ],
                ),
              ),

              // Tombol Lanjut (Hanya untuk Step 0 dan 1)
              // Step 2 & 3 punya tombol khusus di dalam widgetnya
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
                          color: AppColors.surface,
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

  // ... (WIDGET Step 1 & 2 SAMA SEPERTI SEBELUMNYA - COPY PASTE KODE ANDA DI SINI) ...
  Widget _buildStep1Account() {
    // ... Copy from your previous code ...
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset('assets/images/2.png', height: 200)),
          const SizedBox(height: 16),

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
          const SizedBox(height: 24),
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
          Center(child: Image.asset('assets/images/2.png', height: 200)),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),
          _buildDropdownField(
            value: _selectedAgeRange,
            label: "Rentang Usia",
            icon: Icons.calendar_today_outlined,
            items: [
              "Dewasa muda (18–35 tahun)",
              "Dewasa mapan (36–59 tahun)",
              "Lansia (60+ tahun)",
            ],
            onChanged: (val) => setState(() => _selectedAgeRange = val),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: PILIH PERAN ---
  Widget _buildStep3Role() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset('assets/images/2.png', height: 200)),
          const SizedBox(height: 16),

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

          _roleSelectionCard(
            title: "Pengguna Utama",
            subtitle: "Saya ingin mencatat kesehatan & kenangan saya sendiri.",
            icon: Icons.person,
            color: AppColors.primary,
            isSelected: _selectedRole == 'elderly',
            onTap: () => setState(() => _selectedRole = 'elderly'),
          ),
          const SizedBox(height: 16),
          _roleSelectionCard(
            title: "Pendamping (Keluarga)",
            subtitle: "Saya ingin membantu memantau orang tua saya.",
            icon: Icons.supervised_user_circle,
            color: AppColors.accent,
            isSelected: _selectedRole == 'guardian',
            onTap: () => setState(() => _selectedRole = 'guardian'),
          ),

          const SizedBox(height:24),


          // TOMBOL Lanjut / Selesai (Tergantung Role)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _nextStep, // Logic Submit/Next ada di _nextStep
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColors.surface)
                  : Text(
                      _selectedRole == 'elderly'
                          ? "Selesai & Masuk"
                          : "Lanjut Atur Fitur",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 4: PILIH FITUR (BARU) ---
  Widget _buildStep4Features() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset('assets/images/2.png', height: 200)),
          const SizedBox(height: 16),

          Text(
            "Sesuaikan Fitur.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.beVietnamPro().fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Fitur apa yang dibutuhkan orang tua saat ini?",
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),

          // LIST FITUR
          _featureSelectionCard(
            keyName: 'health',
            title: "Kesehatan",
            subtitle: "Jadwal obat & pantauan medis.",
            icon: Icons.medication,
            color: AppColors.primary,
            isSelected: _selectedFeatures.contains('health'),
            onTap: () => _toggleFeature('health'),
          ),
          const SizedBox(height: 8),
          _featureSelectionCard(
            keyName: 'activity',
            title: "Aktivitas",
            subtitle: "Hobi & kebun kebahagiaan.",
            icon: Icons.local_florist,
            color: Colors.green,
            isSelected: _selectedFeatures.contains('activity'),
            onTap: () => _toggleFeature('activity'),
          ),
          const SizedBox(height: 8),
          _featureSelectionCard(
            keyName: 'memory',
            title: "Kenangan",
            subtitle: "Album foto & jurnal harian.",
            icon: Icons.photo_library,
            color: Colors.orange,
            isSelected: _selectedFeatures.contains('memory'),
            onTap: () => _toggleFeature('memory'),
          ),
          const SizedBox(height: 8),
          _featureSelectionCard(
            keyName: 'chat',
            title: "Obrolan",
            subtitle: "Grup chat keluarga simpel.",
            icon: Icons.forum,
            color: Colors.blue,
            isSelected: _selectedFeatures.contains('chat'),
            onTap: () => _toggleFeature('chat'),
          ),

          const SizedBox(height: 32),

          // TOMBOL FINAL
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
                  ? const CircularProgressIndicator(color: AppColors.surface)
                  : const Text(
                      "Simpan & Selesai",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.surface,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ... (Widget Helper Lain: _buildProgressDot, _buildTextField, _buildDropdownField, _RoleSelectionCard - SAMA SEPERTI KODE ANDA) ...
  // Copy paste saja helper widget Anda yang lama di bawah sini agar kode lengkap.

  Widget _buildProgressDot(int index) {
    bool isActive = index <= _currentStep;
    // Trik Visual: Jika Elderly, Step 2 (Role) adalah step terakhir.
    // Jadi dot ke-3 (index 2) harus terlihat "selesai" jika di step itu.
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
            color: isActive ? AppColors.surface : Colors.grey[600],
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

  // Helper Card untuk Fitur
  Widget _featureSelectionCard({
    required String keyName,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 24,
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
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isSelected,
              onChanged: (val) => onTap(),
              activeThumbColor: color,
            ),
          ],
        ),
      ),
    );
  }

  // Paste juga _buildTextField, _buildDropdownField, dan _RoleSelectionCard dari kode Anda sebelumnya di sini.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
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

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
      child: DropdownButtonFormField<String>(
        initialValue: value,
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
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.openSans(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: AppColors.surface,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _roleSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.surface : Colors.grey[500],
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
