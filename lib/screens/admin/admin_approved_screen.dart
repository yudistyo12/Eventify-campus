import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/admin_state.dart';
import '../../theme/app_theme.dart';
import 'admin_event_detail_screen.dart';

class AdminApprovedScreen extends StatelessWidget {
  const AdminApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminState>(
      builder: (context, adminState, _) {
        final events = adminState.approvedEvents;
        if (events.isEmpty) {
          return const Center(child: Text('Belum ada event yang disetujui.'));
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _ApprovedEventCard(event: events[index]),
        );
      },
    );
  }
}

class _ApprovedEventCard extends StatelessWidget {
  const _ApprovedEventCard({required this.event});

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
            '${event.location}\n'
            'Penyelenggara: ${event.pic}',
            style: TextStyle(color: secondaryColor, height: 1.5),
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              event.isPublished
                  ? Icons.public_rounded
                  : Icons.visibility_off_outlined,
              color: event.isPublished
                  ? AppTheme.successGreen
                  : AppTheme.warningOrange,
            ),
            Text(
              event.isPublished ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: event.isPublished
                    ? AppTheme.successGreen
                    : AppTheme.warningOrange,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
