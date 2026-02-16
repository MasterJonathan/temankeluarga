import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/memories/presentation/memory_actions.dart';

class WriteDiarySheet extends ConsumerStatefulWidget {
  final String familyId;
  final String userId;
  final String userName;

  const WriteDiarySheet({
    super.key,
    required this.familyId,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<WriteDiarySheet> createState() => _WriteDiarySheetState();
}

class _WriteDiarySheetState extends ConsumerState<WriteDiarySheet> {
  final _textController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    ); // Kompres sedikit

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (_textController.text.isEmpty && _selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      await ref
          .read(memoryActionsProvider)
          .postMemory(
            familyId: widget.familyId,
            authorId: widget.userId,
            authorName: widget.userName,
            content: _textController.text,
            imageFile: _selectedImage,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal upload: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tulis Cerita",
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                if (_isUploading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Apa kenangan hari ini?",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Preview Gambar
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const CircleAvatar(
                        backgroundColor: AppColors.surface,
                        radius: 16,
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.photo_camera,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Posting"),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
