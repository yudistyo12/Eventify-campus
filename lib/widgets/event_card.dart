import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.showActions,
  });

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
        return const Color(0xFFF59E0B); // Amber/Yellow
      case 'seminar':
        return const Color(0xFF8B5CF6); // Purple
      case 'organisasi':
      default:
        return AppTheme.primaryIndigo; // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(event.category);
    final catIcon = _getCategoryIcon(event.category);
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(event.date);

    final isCompleted = event.status == 'Selesai';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.indigo.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.indigo.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                // Category Side Highlight Indicator
                Container(width: 6, height: 110, color: catColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with Category and Status pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(catIcon, size: 14, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  event.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? (isDark
                                          ? Colors.white10
                                          : Colors.black.withOpacity(0.05))
                                    : (isDark
                                          ? AppTheme.successGreen.withOpacity(
                                              0.15,
                                            )
                                          : AppTheme.successGreen.withOpacity(
                                              0.1,
                                            )),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                event.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? (isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary)
                                      : AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Event Name
                        Text(
                          event.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Date Info
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 13,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Location Info
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (showActions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: AppTheme.primaryIndigo,
                          ),
                          onPressed: onEdit,
                          tooltip: 'Edit Event',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: AppTheme.accentPink,
                          ),
                          onPressed: onDelete,
                          tooltip: 'Hapus Event',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
