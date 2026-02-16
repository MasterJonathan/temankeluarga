import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/activities/domain/activity_model.dart';
import 'package:silver_guide/features/activities/presentation/activity_actions.dart';

class AddActivityPage extends ConsumerStatefulWidget {
  final String userId;
  const AddActivityPage({super.key, required this.userId});

  @override
  ConsumerState<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends ConsumerState<AddActivityPage> {
  final _titleController = TextEditingController();
  final _msgController = TextEditingController();

  // State Pilihan
  String _selectedIconKey = 'flower';
  final Color _selectedColor = AppColors.primary;

  // State Gambar
  File? _customImageFile; // Jika user ambil dari galeri
  String? _selectedAssetPath; // Jika user pilih dari rekomendasi
  int _selectedRecIndex = -1; // Untuk highlight border rekomendasi

  bool _isLoading = false;

  // DATA REKOMENDASI (Sesuaikan path dengan folder assets Anda)
  final List<Map<String, String>> _recommendations = [
    {
      'title': 'Minum Air',
      'img': 'assets/images/activities/drink_water.png',
      'msg': 'Tetap terhidrasi ya!',
    },
    {
      'title': 'Makan Sehat',
      'img': 'assets/images/activities/eat_food.png',
      'msg': 'Asupan gizi penting.',
    },
    {
      'title': 'Cek Kesehatan',
      'img': 'assets/images/activities/medical_checkup.png',
      'msg': 'Jangan lupa obatnya.',
    }, // Reuse gambar medical
    {
      'title': 'Baca Buku',
      'img': 'assets/images/activities/reading_book.png',
      'msg': 'Asah pikiran.',
    },
    {
      'title': 'Bersepeda',
      'img': 'assets/images/activities/riding_bicycle.png',
      'msg': 'Hati-hati di jalan.',
    },
    {
      'title': 'Menyiram Tanaman',
      'img': 'assets/images/activities/watering_plant.png',
      'msg': 'Segar sekali!',
    },
    {
      'title': 'Menjahit',
      'img': 'assets/images/activities/sewing_clothes.png',
      'msg': 'Kreativitas tanpa batas.',
    },
    {
      'title': 'Main Game',
      'img': 'assets/images/activities/playing_game.png',
      'msg': 'Hiburan sejenak.',
    },
    {
      'title': 'Bersih Rumah',
      'img': 'assets/images/activities/cleaning_house.png',
      'msg': 'Rumah bersih, hati senang.',
    },
  ];

  final Map<String, IconData> _iconOptions = {
    'flower': Icons.local_florist,
    'book': Icons.menu_book,
    'walk': Icons.directions_walk,
    'tea': Icons.emoji_food_beverage,
    'music': Icons.music_note,
    'pet': Icons.pets,
  };

  void _onRecommendationSelected(int index) {
    final item = _recommendations[index];
    setState(() {
      _selectedRecIndex = index;
      _titleController.text = item['title']!;
      _msgController.text = item['msg']!;
      _selectedAssetPath = item['img'];

      // Reset custom image jika user memilih rekomendasi
      _customImageFile = null;
    });
  }

  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _customImageFile = File(picked.path);

        // Reset rekomendasi karena user upload sendiri
        _selectedAssetPath = null;
        _selectedRecIndex = -1;
      });
    }
  }

  void _submit() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul aktivitas wajib diisi")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Tentukan Gambar Akhir (Custom > Asset > Null)
    String? finalImage = _customImageFile != null ? null : _selectedAssetPath;
    bool isAsset = _customImageFile == null && _selectedAssetPath != null;

    final newItem = ActivityItem(
      id: '',
      userId: widget.userId,
      title: _titleController.text,
      iconKey: _selectedIconKey, // Tetap simpan ikon sebagai fallback
      colorValue: _selectedColor.value,
      motivationalMessage: _msgController.text.isEmpty
          ? "Hebat!"
          : _msgController.text,
      customImage: finalImage,
      isAssetImage: isAsset,
    );

    try {
      await ref
          .read(activityActionsProvider)
          .addActivityWithImage(
            item: newItem,
            imageFile: _customImageFile, // Kirim file jika ada untuk diupload
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Tambah Aktivitas"),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BAGIAN REKOMENDASI
                    const Text(
                      "Rekomendasi Kegiatan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final item = _recommendations[index];
                          final isSelected = _selectedRecIndex == index;

                          return GestureDetector(
                            onTap: () => _onRecommendationSelected(index),
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 3,
                                      )
                                    : Border.all(color: Colors.transparent),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Gambar Aset
                                  Image.asset(
                                    item['img']!,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      item['title']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. BAGIAN FORM CUSTOM
                    const Text(
                      "Detail Aktivitas",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preview Gambar Custom / Terpilih
                    Center(
                      child: GestureDetector(
                        onTap: _pickCustomImage,
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                            image: _customImageFile != null
                                ? DecorationImage(
                                    image: FileImage(_customImageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (_selectedAssetPath != null
                                      ? DecorationImage(
                                          image: AssetImage(
                                            _selectedAssetPath!,
                                          ),
                                          fit: BoxFit.cover,
                                        ) // Tampilkan aset jika dipilih
                                      : null),
                          ),
                          child:
                              (_customImageFile == null &&
                                  _selectedAssetPath == null)
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                      Text(
                                        "Upload Foto Sendiri (Opsional)",
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: const CircleAvatar(
                                      backgroundColor: AppColors.surface,
                                      radius: 14,
                                      child: Icon(Icons.edit, size: 16),
                                    ),
                                    onPressed: _pickCustomImage,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Nama Aktivitas",
                        hintText: "Contoh: Jalan Pagi",
                        prefixIcon: const Icon(Icons.assignment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        labelText: "Pesan Semangat",
                        hintText: "Contoh: Sehat selalu!",
                        prefixIcon: const Icon(Icons.auto_awesome_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "atau gunakan Ikon Dafault",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconOptions.entries.map((e) {
                        final isSelected = _selectedIconKey == e.key;
                        return ChoiceChip(
                          label: Icon(
                            e.value,
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.primary,
                            size: 24,
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          onSelected: (val) =>
                              setState(() => _selectedIconKey = e.key),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Simpan Aktivitas",
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
