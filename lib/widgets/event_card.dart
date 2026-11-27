import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
import 'event_image.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;
  final bool isFeatured;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.showActions,
    this.isFeatured = false,
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
        return AppTheme.primaryIndigo;
      case 'lomba':
        return AppTheme.warningOrange;
      case 'seminar':
        return AppTheme.accentPink;
      case 'organisasi':
      default:
        return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(event.category);
    final catIcon = _getCategoryIcon(event.category);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final card = isFeatured
        ? _buildMagazineCard(context, catColor, catIcon, scheme)
        : _buildHorizontalCard(context, catColor, catIcon, scheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(isFeatured ? 24 : 20),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.07 : 0.055),
        ),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isFeatured ? 24 : 20),
        child: Material(color: Colors.transparent, child: card),
      ),
    );
  }

  Widget _buildMagazineCard(
    BuildContext context,
    Color categoryColor,
    IconData categoryIcon,
    ColorScheme scheme,
  ) {
    final secondaryColor = scheme.onSurface.withValues(alpha: 0.58);
    final isCompleted = event.status == 'Selesai';

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(
                  imageUrl: event.imageUrl,
                  fallback: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor.withValues(alpha: 0.82),
                          AppTheme.primaryNavy,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      categoryIcon,
                      size: 54,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x44000000),
                        Colors.transparent,
                        Color(0x99000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _imagePill(
                    icon: categoryIcon,
                    label: event.category,
                    color: categoryColor,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _imagePill(
                    icon: Icons.circle,
                    label: event.status,
                    color: isCompleted
                        ? AppTheme.warningOrange
                        : AppTheme.successGreen,
                    dotOnly: true,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _imagePill(
                    icon: Icons.calendar_month_rounded,
                    label: DateFormat('dd MMM yyyy').format(event.date),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                      ),
                    ),
                    if (showActions) ...[
                      IconButton(
                        tooltip: 'Edit Event',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 19,
                          color: scheme.brightness == Brightness.dark
                              ? AppTheme.secondaryIndigo
                              : AppTheme.primaryIndigo,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus Event',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppTheme.accentPink,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: scheme.brightness == Brightness.dark
                          ? AppTheme.secondaryIndigo
                          : AppTheme.primaryIndigo.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy · HH:mm').format(event.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: secondaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    Color categoryColor,
    IconData categoryIcon,
    ColorScheme scheme,
  ) {
    final secondaryColor = scheme.onSurface.withValues(alpha: 0.58);
    final statusColor = event.status == 'Selesai'
        ? AppTheme.warningOrange
        : AppTheme.successGreen;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 126,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventImage(
                  imageUrl: event.imageUrl,
                  fallback: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor.withValues(alpha: 0.82),
                          AppTheme.primaryNavy,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 34,
                    ),
                  ),
                ),
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      DateFormat('dd MMM').format(event.date),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.status,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yyyy · HH:mm').format(event.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: secondaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: secondaryColor),
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
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: scheme.brightness == Brightness.dark
                          ? AppTheme.secondaryIndigo
                          : AppTheme.primaryIndigo,
                    ),
                    onPressed: onEdit,
                    tooltip: 'Edit Event',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: AppTheme.accentPink,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Hapus Event',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePill({
    required IconData icon,
    required String label,
    required Color color,
    bool dotOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotOnly)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          else
            Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
