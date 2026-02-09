import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/app/theme/app_theme.dart';
import 'package:silver_guide/features/activities/domain/activity_model.dart';
import 'package:silver_guide/features/activities/presentation/activity_actions.dart';

class ActivityFormSheet extends ConsumerStatefulWidget {
  final String userId;
  const ActivityFormSheet({super.key, required this.userId});

  @override
  ConsumerState<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends ConsumerState<ActivityFormSheet> {
  final _titleController = TextEditingController();
  final _msgController = TextEditingController();

  String _selectedIconKey = 'flower';
  final Color _selectedColor = AppColors.primary;

  final Map<String, IconData> _iconOptions = {
    'flower': Icons.local_florist,
    'book': Icons.menu_book,
    'walk': Icons.directions_walk,
    'tea': Icons.emoji_food_beverage,
    'music': Icons.music_note,
    'pet': Icons.pets,
  };

  void _submit() {
    if (_titleController.text.isEmpty) return;

    final newItem = ActivityItem(
      id: '',
      userId: widget.userId,
      title: _titleController.text,
      iconKey: _selectedIconKey,
      colorValue: _selectedColor.toARGB32(),
      motivationalMessage: _msgController.text.isEmpty
          ? "Hebat!"
          : _msgController.text,
    );

    ref.read(activityActionsProvider).addActivity(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tambah Aktivitas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: "Nama Aktivitas (Contoh: Jalan Pagi)",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgController,
            decoration: const InputDecoration(
              labelText: "Pesan Semangat (Contoh: Sehat selalu!)",
            ),
          ),
          const SizedBox(height: 16),
          const Text("Pilih Ikon:"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _iconOptions.entries.map((e) {
              final isSelected = _selectedIconKey == e.key;
              return ChoiceChip(
                label: Icon(
                  e.value,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                onSelected: (bool selected) {
                  setState(() => _selectedIconKey = e.key);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text("Simpan Aktivitas"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
