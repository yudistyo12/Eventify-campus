import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'add_edit_event_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'akademik':
        return Icons.school_rounded;
      case 'lomba':
        return Icons.emoji_events_rounded;
      case 'seminar':
        return Icons.co_present_rounded;
      case 'organisasi':
      default:
        return Icons.groups_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'akademik':
        return const Color(0xFF3B82F6); // Blue
      case 'lomba':
        return const Color(0xFFF59E0B); // Amber
      case 'seminar':
        return const Color(0xFF8B5CF6); // Purple
      case 'organisasi':
      default:
        return AppTheme.primaryIndigo; // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManageEvent = context.select<AppState, bool>(
      (appState) => appState.canManageEvent(event),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(event.category);
    final catIcon = _getCategoryIcon(event.category);

    final dayFormatted = DateFormat('EEEE').format(event.date);
    final dateFormatted = DateFormat('dd MMMM yyyy').format(event.date);
    final timeFormatted = DateFormat('HH:mm').format(event.date);

    final isCompleted = event.status == 'Selesai';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header SilverAppBar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.4),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (canManageEvent)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditEventScreen(event: event),
                      ),
                    );
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor.withOpacity(0.8), catColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        catIcon,
                        size: 220,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Icon(catIcon, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            event.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Detail list view contents
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Pill & Date Created
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05))
                                : AppTheme.successGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCompleted
                                  ? Colors.transparent
                                  : AppTheme.successGreen.withValues(
                                      alpha: 0.2,
                                    ),
                            ),
                          ),
                          child: Text(
                            event.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? (isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary)
                                  : AppTheme.successGreen,
                            ),
                          ),
                        ),
                        Text(
                          'Dibuat: ${DateFormat('dd MMM yy').format(event.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Event Title
                    Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Information Rows
                    _buildDetailRow(
                      context: context,
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.blue,
                      title: 'Tanggal & Waktu',
                      subtitle: '$dayFormatted, $dateFormatted',
                      trailing: timeFormatted,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      context: context,
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.red,
                      title: 'Lokasi Pelaksanaan',
                      subtitle: event.location,
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      context: context,
                      icon: Icons.person_pin_rounded,
                      iconColor: Colors.orange,
                      title: 'Penanggung Jawab (PIC)',
                      subtitle: event.pic,
                    ),

                    const SizedBox(height: 28),
                    const Divider(height: 1),
                    const SizedBox(height: 28),

                    // Description Section
                    Text(
                      'Deskripsi Kegiatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkCard
                            : Colors.indigo.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.indigo.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
