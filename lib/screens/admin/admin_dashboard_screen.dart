import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../providers/admin_state.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_layout.dart';
import 'admin_event_detail_screen.dart';
import 'admin_pending_screen.dart';
import 'admin_approved_screen.dart';
import 'admin_rejected_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedMenuIndex = 0;

  Future<void> _handleLogout() async {
    final adminState = Provider.of<AdminState>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await adminState.adminLogout();
      await appState.refreshCurrentUser();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal keluar dari panel admin: $error'),
          backgroundColor: AppTheme.accentPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardLayout()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Berhasil keluar dari panel admin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openEventDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminEventDetailScreen(event: event)),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardContent(context),
      const AdminPendingScreen(),
      const AdminApprovedScreen(),
      const AdminRejectedScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryNavy,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADMIN PANEL',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successGreen.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Aktif • Sesi Admin',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Logout Admin',
              onPressed: _handleLogout,
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.white24),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildNavigationTabs(context),
          Expanded(child: pages[_selectedMenuIndex]),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
        ),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildMenuTab(0, Icons.grid_view_rounded, 'Ringkasan'),
            _buildMenuTab(1, Icons.pending_actions_rounded, 'Pengajuan'),
            _buildMenuTab(2, Icons.check_circle_outline_rounded, 'Disetujui'),
            _buildMenuTab(3, Icons.highlight_off_rounded, 'Ditolak'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(int index, IconData icon, String label) {
    final isSelected = _selectedMenuIndex == index;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primaryIndigo, Color(0xFF8B5CF6)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _selectedMenuIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : scheme.onSurface.withValues(alpha: 0.64),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return Consumer<AdminState>(
      builder: (context, adminState, _) {
        final pending = adminState.pendingEvents;
        final approved = adminState.approvedEvents;
        final reviewEvents = <EventModel>[
          if (pending.isNotEmpty) pending.first,
          if (approved.isNotEmpty) approved.first,
        ];

        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWelcomeCard(adminState),
                    const SizedBox(height: 28),
                    _buildMetricsSection(
                      context,
                      adminState,
                      availableWidth: constraints.maxWidth,
                    ),
                    const SizedBox(height: 28),
                    _buildIncomingReviews(context, reviewEvents),
                    const SizedBox(height: 24),
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => setState(() => _selectedMenuIndex = 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_double_arrow_up_rounded,
                              size: 17,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lihat seluruh aktivitas pengajuan',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55),
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(AdminState adminState) {
    final name = adminState.adminUser?.name.trim() ?? '';
    final displayName = name.isEmpty
        ? 'admin'
        : name.split(RegExp(r'\s+')).last.toLowerCase();
    final initial = displayName.isEmpty ? 'K' : displayName[0].toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryIndigo.withValues(alpha: 0.17),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -64,
              child: _WelcomeOrb(size: 190, opacity: 0.07),
            ),
            Positioned(
              right: 68,
              bottom: -96,
              child: _WelcomeOrb(size: 160, opacity: 0.055),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), AppTheme.primaryIndigo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryIndigo.withValues(alpha: 0.5),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $displayName 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Kelola dan verifikasi seluruh event kampus dalam satu dasbor dinamis.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(
    BuildContext context,
    AdminState adminState, {
    required double availableWidth,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final secondaryColor = textColor.withValues(alpha: 0.58);
    final total = adminState.totalEventsCount;
    final chartSize = availableWidth < 430 ? 116.0 : 136.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metrik & Tren Kegiatan',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: chartSize,
                height: chartSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(chartSize),
                      painter: _AdminEventDonutPainter(
                        pending: adminState.pendingEventsCount,
                        approved: adminState.approvedEventsCount,
                        rejected: adminState.rejectedEventsCount,
                        total: total,
                        trackColor: textColor.withValues(alpha: 0.08),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Total Event',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: secondaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: availableWidth < 430 ? 12 : 24),
              Expanded(
                child: Column(
                  children: [
                    _buildMetricRow(
                      context,
                      icon: Icons.schedule_rounded,
                      label: 'Menunggu Tinjauan',
                      count: adminState.pendingEventsCount,
                      total: total,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(height: 14),
                    _buildMetricRow(
                      context,
                      icon: Icons.check_rounded,
                      label: 'Telah Disetujui',
                      count: adminState.approvedEventsCount,
                      total: total,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(height: 14),
                    _buildMetricRow(
                      context,
                      icon: Icons.close_rounded,
                      label: 'Tolak / Revisi',
                      count: adminState.rejectedEventsCount,
                      total: total,
                      color: AppTheme.accentPink,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final progress = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingReviews(BuildContext context, List<EventModel> events) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingExists = events.any((event) => event.isPending);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tinjau Pengajuan Masuk',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (pendingExists)
              TextButton(
                onPressed: () => setState(() => _selectedMenuIndex = 1),
                child: const Text('Semua'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.62
                    : 0.8,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: textColor.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: isDark
                      ? AppTheme.secondaryIndigo
                      : AppTheme.primaryIndigo,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada pengajuan untuk ditinjau.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildReviewEventCard(context, event),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewEventCard(BuildContext context, EventModel event) {
    final isPending = event.isPending;
    final statusColor = isPending
        ? AppTheme.warningOrange
        : AppTheme.successGreen;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openEventDetail(event),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isDark ? 0.78 : 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryIndigo.withValues(alpha: 0.17),
                      AppTheme.primaryIndigo.withValues(alpha: 0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: isDark
                      ? AppTheme.secondaryIndigo
                      : AppTheme.primaryIndigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengirim: ${event.pic}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                    Text(
                      _formatDate(event.date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? 'Menunggu' : 'Disetujui',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: 104,
                    height: 34,
                    child: FilledButton(
                      onPressed: () => _openEventDetail(event),
                      style: FilledButton.styleFrom(
                        backgroundColor: isPending
                            ? AppTheme.primaryIndigo
                            : AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        textStyle: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(isPending ? 'Verifikasi' : 'Detail'),
                          ),
                          if (isPending) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.north_east_rounded, size: 13),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeOrb extends StatelessWidget {
  const _WelcomeOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 20,
        ),
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity * 0.9),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _AdminEventDonutPainter extends CustomPainter {
  const _AdminEventDonutPainter({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.total,
    required this.trackColor,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int total;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.105;
    final rect = Offset.zero & size;
    final center = rect.center;
    final arcRect = Rect.fromCircle(
      center: center,
      radius: (size.width - strokeWidth) / 2,
    );
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, arcRect.width / 2, trackPaint);

    if (total <= 0) return;

    final segments = [
      (value: pending, color: AppTheme.warningOrange),
      (value: approved, color: AppTheme.successGreen),
      (value: rejected, color: AppTheme.accentPink),
    ];
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = 2 * math.pi * segment.value / total;
      final gap = math.min(0.045, sweep * 0.15);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(arcRect, startAngle + gap / 2, sweep - gap, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AdminEventDonutPainter oldDelegate) {
    return oldDelegate.pending != pending ||
        oldDelegate.approved != approved ||
        oldDelegate.rejected != rejected ||
        oldDelegate.total != total ||
        oldDelegate.trackColor != trackColor;
  }
}
