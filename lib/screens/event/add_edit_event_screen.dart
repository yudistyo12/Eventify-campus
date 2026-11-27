import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/event_image.dart';
import '../dashboard/dashboard_layout.dart';
import '../login_screen.dart';

class AddEditEventScreen extends StatefulWidget {
  final EventModel? event; // Null if Adding, non-null if Editing

  const AddEditEventScreen({super.key, this.event});

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final Radius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          radius,
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + 7 < metric.length ? distance + 7 : metric.length;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isEditMode;

  final _nameController = TextEditingController();
  final _picController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _removeExistingImage = false;
  bool _isPickingImage = false;
  bool _isSaving = false;
  String? _saveStatus;

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

  Future<void> _pickEventImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 60,
      );
      if (image == null || !mounted) return;

      final sourceBytes = await image.readAsBytes();
      final bytes = await compressEventImage(sourceBytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
        _removeExistingImage = false;
      });
    } catch (error) {
      if (mounted) _showSnackbar('Gagal memilih foto: $error');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  String _formatImageSize(int bytes) {
    final sizeInKilobytes = bytes / 1024;
    if (sizeInKilobytes < 1024) return '${sizeInKilobytes.ceil()} KB';
    return '${(sizeInKilobytes / 1024).toStringAsFixed(1)} MB';
  }

  Widget _buildEventImagePicker(bool isDark) {
    final existingImageUrl = widget.event?.imageUrl;
    final hasExistingImage = existingImageUrl?.isNotEmpty == true;
    final hasImage =
        _imageBytes != null || (hasExistingImage && !_removeExistingImage);
    final preview = _imageBytes != null
        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
        : hasExistingImage && !_removeExistingImage
        ? EventImage(
            imageUrl: existingImageUrl,
            fallback: _buildImagePlaceholder(isDark),
          )
        : _buildImagePlaceholder(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppTheme.primaryIndigo.withValues(alpha: 0.55),
          radius: const Radius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isPickingImage ? null : _pickEventImage,
              child: SizedBox(
                height: 156,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    preview,
                    if (hasImage)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Text(
                            _imageName == null
                                ? 'Ketuk foto untuk mengganti'
                                : 'Ketuk untuk mengganti · $_imageName · '
                                      '${_formatImageSize(_imageBytes!.length)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (hasImage)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          tooltip: 'Hapus foto event',
                          onPressed: () {
                            setState(() {
                              _imageBytes = null;
                              _imageName = null;
                              _removeExistingImage = hasExistingImage;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accentPink,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    if (_isPickingImage)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark
          ? AppTheme.darkCard
          : AppTheme.primaryIndigo.withValues(alpha: 0.04),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: isDark ? AppTheme.secondaryIndigo : AppTheme.primaryIndigo,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            _isPickingImage
                ? 'Membuka galeri...'
                : 'Unggah Poster / Foto Event',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryNavy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Foto dikompresi otomatis · maksimal 200 KB',
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.07 : 0.055),
        ),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: isDark
                      ? AppTheme.secondaryIndigo
                      : AppTheme.primaryIndigo,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
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
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveStatus = 'Menyimpan data event...';
    });

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
          imageBytes: _imageBytes,
          removeImage: _removeExistingImage,
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
          imageBytes: _imageBytes,
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
          _imageBytes = null;
          _imageName = null;
          _removeExistingImage = false;
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveStatus = null;
        });
      }
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions/Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isEditMode
                        ? AppTheme.primaryIndigo.withValues(alpha: 0.08)
                        : AppTheme.successGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isEditMode
                          ? AppTheme.primaryIndigo.withValues(alpha: 0.2)
                          : AppTheme.successGreen.withValues(alpha: 0.2),
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
                              ? 'Perbarui data event dan kirim kembali untuk ditinjau admin.'
                              : 'Lengkapi data event untuk diajukan dan ditinjau admin.',
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

                _buildFormSection(
                  context,
                  title: 'Informasi Dasar',
                  icon: Icons.subject_rounded,
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),

                _buildFormSection(
                  context,
                  title: 'Jadwal & Pengingat',
                  icon: Icons.calendar_month_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 3. Date Selection Row (Date Picker field)
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                                  icon: Icon(
                                    Icons.date_range_rounded,
                                    color: isDark
                                        ? AppTheme.secondaryIndigo
                                        : AppTheme.primaryIndigo,
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
                                Icon(
                                  Icons.notifications_active_rounded,
                                  color: isDark
                                      ? AppTheme.secondaryIndigo
                                      : AppTheme.primaryIndigo,
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
                                    selectedColor: AppTheme.primaryIndigo
                                        .withValues(alpha: 0.15),
                                    checkmarkColor: AppTheme.primaryIndigo,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedReminderDays.add(
                                            reminder.days,
                                          );
                                        } else {
                                          _selectedReminderDays.remove(
                                            reminder.days,
                                          );
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
                    ],
                  ),
                ),

                _buildFormSection(
                  context,
                  title: 'Lokasi & Kategori',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
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
                              prefixIcon: Icon(
                                Icons.category_rounded,
                                color: isDark
                                    ? AppTheme.secondaryIndigo
                                    : AppTheme.primaryIndigo,
                                size: 22,
                              ),
                            ),
                            dropdownColor: isDark
                                ? AppTheme.darkCard
                                : Colors.white,
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: const TextStyle(fontSize: 15),
                                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
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
                              prefixIcon: Icon(
                                Icons.check_circle_rounded,
                                color: isDark
                                    ? AppTheme.secondaryIndigo
                                    : AppTheme.primaryIndigo,
                                size: 22,
                              ),
                            ),
                            dropdownColor: isDark
                                ? AppTheme.darkCard
                                : Colors.white,
                            items: statuses.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                  style: const TextStyle(fontSize: 15),
                                ),
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
                    ],
                  ),
                ),

                _buildFormSection(
                  context,
                  title: 'Deskripsi & Poster',
                  icon: Icons.image_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 8),
                      _buildEventImagePicker(isDark),
                    ],
                  ),
                ),

                if (_isSaving) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _saveStatus ?? 'Menyimpan data event...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ],

                // Submit Button
                Consumer<AppState>(
                  builder: (context, appState, _) {
                    return CustomButton(
                      text: _isEditMode ? 'Kirim Perubahan' : 'Kirim Pengajuan',
                      onPressed: _handleSave,
                      isLoading: appState.isLoading || _isSaving,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
              Icon(
                Icons.lock_outline_rounded,
                size: 52,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.secondaryIndigo
                    : AppTheme.primaryIndigo,
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
                      builder: (context) =>
                          LoginScreen(openAddEventAfterLogin: !isEditing),
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
