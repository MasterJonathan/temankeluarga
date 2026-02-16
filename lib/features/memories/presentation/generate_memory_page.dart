import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/memories/presentation/memory_actions.dart';

class GenerateMemoryPage extends ConsumerStatefulWidget {
  final String familyId;
  final String userId;
  final String userName;

  const GenerateMemoryPage({
    super.key,
    required this.familyId,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<GenerateMemoryPage> createState() => _GenerateMemoryPageState();
}

class _GenerateMemoryPageState extends ConsumerState<GenerateMemoryPage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _generate() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(memoryActionsProvider)
          .generateDailyArt(
            familyId: widget.familyId,
            userId: widget.userId,
            userName: widget.userName,
            date: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context); // Kembali ke feed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sedang melukis kenangan... Tunggu sebentar ya!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("Lukis Kenangan"),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 80,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 24),
              const Text(
                "Buat Halaman Buku Kenangan", // Ganti Judul
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Pilih tanggal. AI akan mengumpulkan foto dan cerita di tanggal tersebut, lalu menyusunnya menjadi satu halaman scrapbook yang cantik.", // Deskripsi baru
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary, // Warna Emas/Magic
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.brush),
                            SizedBox(width: 8),
                            Text(
                              "Lukis Sekarang",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
