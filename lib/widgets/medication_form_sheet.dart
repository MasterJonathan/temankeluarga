import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teman_keluarga/app/theme/app_theme.dart';
import 'package:teman_keluarga/features/medication/domain/medication_model.dart';
import 'package:teman_keluarga/features/medication/presentation/medication_actions.dart';

class MedicationFormSheet extends ConsumerStatefulWidget {
  final String userId;
  const MedicationFormSheet({super.key, required this.userId});

  @override
  ConsumerState<MedicationFormSheet> createState() => _MedicationFormSheetState();
}

class _MedicationFormSheetState extends ConsumerState<MedicationFormSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  // Controller untuk field read-only agar bisa pakai TextField biasa
  final _timeDisplayController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30)); 
  bool _isForever = true; 
  
  final List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    // Set nilai awal controller tanggal/waktu
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Panggil di sini karena 'context' sudah siap digunakan
    _updateTimeDisplay();
    _updateDateDisplays();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _timeDisplayController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _updateTimeDisplay() {
    _timeDisplayController.text = _selectedTime.format(context);
  }

  void _updateDateDisplays() {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    _startDateController.text = dateFormat.format(_startDate);
    _endDateController.text = dateFormat.format(_endDate);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _updateTimeDisplay();
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), 
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
        _updateDateDisplays();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, 
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _updateDateDisplays();
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;

    final newTask = MedicationTask(
      id: '',
      userId: widget.userId,
      title: _nameController.text,
      description: _descController.text,
      time: "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
      startDate: _startDate,
      endDate: _isForever ? null : _endDate, 
      frequency: _selectedDays,
    );

    ref.read(medicationActionsProvider).addMedication(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, 
          right: 24, 
          top: 24
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Judul (Sesuai patokan: Center, Bold, Size 24)
              const Center(
                child: Text(
                  "Tambah Jadwal Obat",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              
              // Nama Obat
              TextField(
                controller: _nameController, 
                decoration: InputDecoration(
                  labelText: 'Nama Obat', 
                  hintText: 'Contoh: Paracetamol',
                  prefixIcon: const Icon(Icons.medication),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
              const SizedBox(height: 16),

              // Dosis / Aturan
              TextField(
                controller: _descController, 
                decoration: InputDecoration(
                  labelText: 'Deskripsi / Dosis / Aturan', 
                  hintText: 'Contoh: Sesudah makan',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
              const SizedBox(height: 16),

              // Waktu Minum (Menggunakan TextField ReadOnly)
              TextField(
                controller: _timeDisplayController,
                readOnly: true,
                onTap: _selectTime,
                decoration: InputDecoration(
                  labelText: 'Jam Minum',
                  prefixIcon: const Icon(Icons.access_time_filled),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text("Durasi Pengobatan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              // Tanggal Mulai
              TextField(
                controller: _startDateController,
                readOnly: true,
                onTap: _pickStartDate,
                decoration: InputDecoration(
                  labelText: 'Mulai Tanggal',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 8),

              // Switch Selamanya
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Berulang Selamanya", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Tidak ada tanggal berakhir"),
                value: _isForever,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _isForever = val);
                },
              ),

              // Tanggal Selesai (Conditional)
              if (!_isForever) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _endDateController,
                  readOnly: true,
                  onTap: _pickEndDate,
                  decoration: InputDecoration(
                    labelText: 'Sampai Tanggal',
                    prefixIcon: const Icon(Icons.event_available),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              
              const Text("Ulangi Setiap Hari:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              // Day Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = index + 1; // 1 = Senin
                  final isSelected = _selectedDays.contains(day);
                  final dayName = ['S', 'S', 'R', 'K', 'J', 'S', 'M'][index]; 
                  
                  return GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40, // Sedikit diperbesar agar lebih mudah ditap
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected ? AppColors.surface : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),
              
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Simpan Jadwal", 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: AppColors.surface,
                    )
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