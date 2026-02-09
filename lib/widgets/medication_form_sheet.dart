import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:silver_guide/features/medication/domain/medication_model.dart';
import 'package:silver_guide/features/medication/presentation/medication_actions.dart';

class MedicationFormSheet extends ConsumerStatefulWidget {
  final String userId; // Wajib tahu obat ini untuk siapa

  const MedicationFormSheet({super.key, required this.userId});

  @override
  ConsumerState<MedicationFormSheet> createState() =>
      _MedicationFormSheetState();
}

class _MedicationFormSheetState extends ConsumerState<MedicationFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController(); // Akan jadi Time Picker

  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _submitForm() {
    if (_nameController.text.isEmpty || _timeController.text.isEmpty) {
      // Tampilkan error
      return;
    }

    final newTask = MedicationTask(
      id: '', // ID akan digenerate oleh Firestore di Repository
      userId: widget.userId,
      title: _nameController.text,
      description: _descController.text,
      time:
          "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
    );

    // Panggil controller untuk simpan
    ref.read(medicationActionsProvider).addMedication(newTask);

    Navigator.pop(context); // Tutup bottom sheet
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
        children: [
          const Text(
            "Tambah Jadwal Obat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Obat (e.g. Amlodipine)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (e.g. 10mg, sesudah makan)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(
              labelText: 'Waktu Minum',
              suffixIcon: Icon(Icons.access_time),
            ),
            readOnly: true,
            onTap: () => _selectTime(context),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text("Simpan Jadwal"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
