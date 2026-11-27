import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/admin_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/event_image.dart';

class AdminEventDetailScreen extends StatelessWidget {
  const AdminEventDetailScreen({super.key, required this.event});

  final EventModel event;

  Future<void> _approve(BuildContext context) async {
    try {
      await context.read<AdminState>().approveEvent(event.id);
      if (!context.mounted) return;
      _showResult(context, 'Event berhasil disetujui.', isError: false);
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      _showResult(context, 'Gagal menyetujui event: $error');
    }
  }

  Future<void> _reject(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tolak pengajuan'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Alasan penolakan wajib diisi'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan',
                hintText: 'Jelaskan hal yang perlu diperbaiki',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: const Text('Tolak event'),
            ),
          ],
        ),
      );

      if (reason == null || !context.mounted) return;
      await context.read<AdminState>().rejectEvent(event.id, reason);
      if (!context.mounted) return;
      _showResult(context, 'Event ditolak.', isError: false);
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      _showResult(context, 'Gagal menolak event: $error');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _togglePublication(BuildContext context) async {
    try {
      final adminState = context.read<AdminState>();
      if (event.isPublished) {
        await adminState.deactivateEvent(event.id);
      } else {
        await adminState.reactivateEvent(event.id);
      }

      if (!context.mounted) return;
      _showResult(
        context,
        event.isPublished
            ? 'Event berhasil dinonaktifkan.'
            : 'Event berhasil dipublikasikan kembali.',
        isError: false,
      );
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      _showResult(context, 'Gagal mengubah publikasi event: $error');
    }
  }

  void _showResult(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.accentPink : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final isLoading = context.watch<AdminState>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (event.imageUrl?.isNotEmpty == true) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: EventImage(
                    imageUrl: event.imageUrl,
                    fallback: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.person_outline_rounded,
                    'Penyelenggara / PIC',
                    event.pic,
                    Colors.white,
                  ),
                  _detailRow(
                    Icons.calendar_month_rounded,
                    'Tanggal dan waktu',
                    DateFormat('EEEE, dd MMM yyyy • HH:mm').format(event.date),
                    Colors.white,
                  ),
                  _detailRow(
                    Icons.location_on_outlined,
                    'Lokasi',
                    event.location,
                    Colors.white,
                  ),
                  _detailRow(
                    Icons.category_outlined,
                    'Kategori',
                    event.category,
                    Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Deskripsi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(color: secondaryColor, height: 1.5),
            ),
            if (event.rejectionReason?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              Text(
                'Alasan penolakan sebelumnya',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                event.rejectionReason!,
                style: TextStyle(color: secondaryColor, height: 1.5),
              ),
            ],
            const SizedBox(height: 32),
            if (event.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : () => _reject(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPink,
                        side: const BorderSide(color: AppTheme.accentPink),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : () => _approve(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Setujui'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            if (event.isApproved)
              FilledButton.icon(
                onPressed: isLoading ? null : () => _togglePublication(context),
                icon: Icon(
                  event.isPublished
                      ? Icons.visibility_off_outlined
                      : Icons.public_rounded,
                ),
                label: Text(
                  event.isPublished
                      ? 'Nonaktifkan event'
                      : 'Publikasikan kembali',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: event.isPublished
                      ? AppTheme.warningOrange
                      : AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                color: color.withValues(alpha: 0.95),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
