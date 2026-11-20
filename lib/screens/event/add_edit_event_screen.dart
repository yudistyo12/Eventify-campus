import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_layout.dart';
import '../login_screen.dart';

class AddEditEventScreen extends StatefulWidget {
  final EventModel? event; // Null if Adding, non-null if Editing

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isEditMode;

  final _nameController = TextEditingController();
  final _picController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedStatus = 'Aktif';
  String _selectedCategory = 'Organisasi';
  final Set<int> _selectedReminderDays = {1};

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.event != null;

    if (_isEditMode) {
      final e = widget.event!;
      _nameController.text = e.name;
      _picController.text = e.pic;
      _locationController.text = e.location;
      _descriptionController.text = e.description;
      _selectedDate = e.date;
      _selectedStatus = e.status;
      _selectedCategory = e.category;
      _selectedReminderDays
        ..clear()
        ..addAll(e.reminderDaysBefore);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _picController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryIndigo,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimeOfDayPicker();

    if (pickedTime == null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<TimeOfDay?> showTimeOfDayPicker() {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryIndigo,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppTheme.accentPink : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      late final bool notificationFailed;
      if (_isEditMode) {
        // UPDATE CRUD
        notificationFailed = await appState.updateEvent(
          id: widget.event!.id,
          name: _nameController.text.trim(),
          pic: _picController.text.trim(),
          date: _selectedDate,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          category: _selectedCategory,
          createdAt: widget.event!.createdAt,
          reminderDaysBefore: _selectedReminderDays.toList(),
        );
      } else {
        // CREATE CRUD
        notificationFailed = await appState.addEvent(
          name: _nameController.text.trim(),
          pic: _picController.text.trim(),
          date: _selectedDate,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          category: _selectedCategory,
          reminderDaysBefore: _selectedReminderDays.toList(),
        );
      }

      if (!mounted) return;
      _showSnackbar(
        notificationFailed
            ? 'Event berhasil disimpan, tetapi sebagian notifikasi gagal dijadwalkan.'
            : _isEditMode
            ? 'Event berhasil diperbarui!'
            : 'Event baru berhasil ditambahkan!',
        isError: notificationFailed,
      );

      // Handle redirect depending on how this screen was opened
      if (Navigator.canPop(context)) {
        // If it was pushed on navigation stack (e.g. editing via Edit button)
        Navigator.pop(context);
      } else {
        // If opened as a bottom navigation tab (Adding new event)
        // Reset form inputs
        _nameController.clear();
        _picController.clear();
        _locationController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDate = DateTime.now().add(const Duration(days: 1));
          _selectedStatus = 'Aktif';
          _selectedCategory = 'Organisasi';
          _selectedReminderDays
            ..clear()
            ..add(1);
        });

        // Switch bottom tab index to Daftar Event (index 1)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardLayout(initialTab: 1),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is FirebaseException
          ? 'Firebase (${e.code}): ${e.message ?? 'Tidak dapat menyimpan data.'}'
          : e.toString();
      _showSnackbar('Gagal menyimpan event: $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.isAuthenticated) {
      return _buildLoginRequired(context);
    }
    if (_isEditMode && !appState.canManageEvent(widget.event!)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Hanya pemilik event yang dapat mengedit kegiatan ini.',
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatted = DateFormat(
      'EEEE, dd MMMM yyyy - HH:mm',
    ).format(_selectedDate);
    final categories = ['Akademik', 'Organisasi', 'Lomba', 'Seminar'];
    final statuses = ['Aktif', 'Selesai'];

    final body = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions/Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEditMode
                    ? AppTheme.primaryIndigo.withOpacity(0.08)
                    : AppTheme.successGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isEditMode
                      ? AppTheme.primaryIndigo.withOpacity(0.2)
                      : AppTheme.successGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode
                        ? Icons.edit_note_rounded
                        : Icons.add_circle_outline_rounded,
                    color: _isEditMode
                        ? AppTheme.primaryIndigo
                        : AppTheme.successGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditMode
                          ? 'Perbarui formulir di bawah ini untuk mengubah data kegiatan kampus.'
                          : 'Lengkapi formulir untuk mempublikasikan event atau kegiatan baru.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isEditMode
                            ? AppTheme.primaryIndigo
                            : AppTheme.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Event Name
            CustomTextField(
              controller: _nameController,
              labelText: 'Nama Event / Kegiatan',
              hintText: 'Masukkan nama kegiatan',
              prefixIcon: Icons.title_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama event tidak boleh kosong';
                }
                return null;
              },
            ),

            // 2. PIC / Penanggung Jawab
            CustomTextField(
              controller: _picController,
              labelText: 'Penanggung Jawab (PIC)',
              hintText: 'Nama lengkap PIC event',
              prefixIcon: Icons.person_pin_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama penanggung jawab wajib diisi';
                }
                return null;
              },
            ),

            // 3. Date Selection Row (Date Picker field)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard.withOpacity(0.4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.indigo.withOpacity(0.03),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal & Waktu Event',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dateFormatted,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(
                          Icons.date_range_rounded,
                          color: AppTheme.primaryIndigo,
                        ),
                        tooltip: 'Pilih Tanggal',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Deadline reminders
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard.withValues(alpha: 0.4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.indigo.withValues(alpha: 0.03),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: AppTheme.primaryIndigo,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pengingat Deadline',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih satu atau beberapa waktu pengingat.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final reminder in const [
                        (days: 7, label: '7 hari sebelumnya'),
                        (days: 3, label: '3 hari sebelumnya'),
                        (days: 1, label: '1 hari sebelumnya'),
                        (days: 0, label: 'Hari deadline'),
                      ])
                        FilterChip(
                          label: Text(reminder.label),
                          selected: _selectedReminderDays.contains(
                            reminder.days,
                          ),
                          selectedColor: AppTheme.primaryIndigo.withValues(
                            alpha: 0.15,
                          ),
                          checkmarkColor: AppTheme.primaryIndigo,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedReminderDays.add(reminder.days);
                              } else {
                                _selectedReminderDays.remove(reminder.days);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (_selectedReminderDays.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pengingat dikirim pada pukul ${DateFormat('HH:mm').format(_selectedDate)}.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Location input
            CustomTextField(
              controller: _locationController,
              labelText: 'Lokasi Event',
              hintText: 'Nama gedung, ruangan, zoom link...',
              prefixIcon: Icons.map_rounded,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Lokasi event tidak boleh kosong';
                }
                return null;
              },
            ),

            // 5. Category Dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard.withOpacity(0.4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.indigo.withOpacity(0.03),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori Event',
                    labelStyle: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.category_rounded,
                      color: AppTheme.primaryIndigo,
                      size: 22,
                    ),
                  ),
                  dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat, style: const TextStyle(fontSize: 15)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),

            // 6. Status Dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard.withOpacity(0.4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.indigo.withOpacity(0.03),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status Event',
                    labelStyle: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryIndigo,
                      size: 22,
                    ),
                  ),
                  dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                  items: statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: const TextStyle(fontSize: 15)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
              ),
            ),

            // 7. Description TextField
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Deskripsi Event',
              hintText: 'Tuliskan deskripsi detail event...',
              prefixIcon: Icons.description_rounded,
              maxLines: 4,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Deskripsi event wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Submit Button
            Consumer<AppState>(
              builder: (context, appState, _) {
                return CustomButton(
                  text: _isEditMode ? 'Simpan Perubahan' : 'Publikasikan Event',
                  onPressed: _handleSave,
                  isLoading: appState.isLoading,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (Navigator.canPop(context)) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_isEditMode ? 'Edit Data Event' : 'Tambah Event Baru'),
          centerTitle: true,
        ),
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Event Baru'), centerTitle: true),
      body: body,
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    final isEditing = _isEditMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Akses Event' : 'Login Diperlukan'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 52,
                color: AppTheme.primaryIndigo,
              ),
              const SizedBox(height: 16),
              Text(
                isEditing
                    ? 'Login dan menjadi pemilik event untuk mengeditnya.'
                    : 'Login terlebih dahulu untuk menambahkan dan mempublikasikan event.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Login',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
