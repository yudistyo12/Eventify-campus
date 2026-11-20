import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/admin_state.dart';
import '../../theme/app_theme.dart';
import 'admin_event_detail_screen.dart';

class AdminRejectedScreen extends StatelessWidget {
  const AdminRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminState>(
      builder: (context, adminState, _) {
        final events = adminState.rejectedEvents;
        if (events.isEmpty) {
          return const Center(child: Text('Belum ada event yang ditolak.'));
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _RejectedEventCard(event: events[index]),
        );
      },
    );
  }
}

class _RejectedEventCard extends StatelessWidget {
  const _RejectedEventCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Card(
      color: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          event.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${DateFormat('dd MMM yyyy, HH:mm').format(event.date)}\n'
            'Alasan: ${event.rejectionReason ?? 'Tidak dicantumkan'}',
            style: TextStyle(color: secondaryColor, height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        isThreeLine: true,
        leading: const Icon(Icons.cancel_outlined, color: AppTheme.accentPink),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminEventDetailScreen(event: event),
            ),
          );
        },
      ),
    );
  }
}
