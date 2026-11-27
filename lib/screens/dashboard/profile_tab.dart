import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../event/add_edit_event_screen.dart';
import '../login_screen.dart';
import 'dashboard_layout.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(3);
    final initials = parts.map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? 'M' : initials;
  }

  Future<void> _toggleDarkMode(BuildContext context, bool enabled) async {
    try {
      await Provider.of<AppState>(
        context,
        listen: false,
      ).toggleDarkMode(enabled);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan preferensi mode gelap: $error'),
          backgroundColor: AppTheme.accentPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    Object? cleanupError;

    try {
      await appState.logout();
    } catch (error) {
      if (appState.isAuthenticated) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal keluar dari akun: $error'),
            backgroundColor: AppTheme.accentPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      cleanupError = error;
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardLayout()),
      (route) => false,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          cleanupError == null
              ? 'Berhasil keluar dari akun'
              : 'Anda sudah keluar, tetapi pembersihan lokal gagal: $cleanupError',
        ),
        backgroundColor: cleanupError == null
            ? AppTheme.primaryNavy
            : AppTheme.accentPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final user = appState.currentUser;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 238,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryNavy, Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 20,
                  20,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Profile Avatar Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : AppTheme.primaryNavy.withValues(alpha: 0.055),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.15)
                                : Colors.indigo.withValues(alpha: 0.03),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryIndigo.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _initials(user?.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            user?.name ?? 'Pengunjung',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          // NIM & Major
                          Text(
                            user == null
                                ? 'Jelajahi event publik sebagai pengunjung'
                                : 'NIM: ${user.nim}  |  Prodi: ${user.major}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Email chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.indigo.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              user?.email ?? 'Belum login',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    user == null
                        ? _buildVisitorCard()
                        : _UserSubmissionsSection(uid: user.uid),

                    const SizedBox(height: 24),

                    // 3. Settings Toggle
                    Text(
                      'Pengaturan Aplikasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : AppTheme.primaryNavy.withValues(alpha: 0.055),
                        ),
                        boxShadow: AppTheme.softShadow(context),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryIndigo.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                appState.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: appState.isDarkMode
                                    ? AppTheme.secondaryIndigo
                                    : AppTheme.primaryIndigo,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Mode Gelap',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Aktifkan tampilan gelap di seluruh aplikasi',
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: Switch(
                              value: appState.isDarkMode,
                              onChanged: (enabled) =>
                                  _toggleDarkMode(context, enabled),
                              activeThumbColor: AppTheme.primaryIndigo,
                            ),
                          ),
                          const Divider(height: 1, indent: 60),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryIndigo.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: appState.isDarkMode
                                    ? AppTheme.secondaryIndigo
                                    : AppTheme.primaryIndigo,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Notifikasi Event',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              appState.notificationsEnabled
                                  ? 'Aktif (Menerima pengingat event)'
                                  : 'Tidak Aktif (Notifikasi dimatikan)',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Switch(
                              value: appState.notificationsEnabled,
                              onChanged: (val) {
                                appState.toggleNotifications(val);
                                _showNotificationSwitchMessage(context, val);
                              },
                              activeThumbColor: AppTheme.primaryIndigo,
                            ),
                          ),
                          const Divider(height: 1, indent: 60),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_done_rounded,
                                color: AppTheme.successGreen,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Status Koneksi Firebase',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Terhubung secara real-time ke Firestore',
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.successGreen,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (user == null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Login untuk mengelola event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryIndigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _handleLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: AppTheme.accentPink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(
                              color: AppTheme.accentPink,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Keluar Akun (Log Out)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotificationSwitchMessage(BuildContext context, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Notifikasi berhasil diaktifkan.'
              : 'Notifikasi berhasil dimatikan.',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: enabled
            ? AppTheme.successGreen
            : AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildVisitorCard() {
    const benefits = [
      (
        icon: Icons.add_circle_outline_rounded,
        label: 'Ajukan & publikasikan event kampusmu',
      ),
      (
        icon: Icons.notifications_active_outlined,
        label: 'Dapatkan pengingat deadline otomatis',
      ),
      (
        icon: Icons.track_changes_rounded,
        label: 'Pantau status persetujuan admin secara real-time',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gabung di Eventify Campus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (final benefit in benefits) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(benefit.icon, size: 19, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefit.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (benefit != benefits.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _UserSubmissionsSection extends StatefulWidget {
  const _UserSubmissionsSection({required this.uid});

  final String uid;

  @override
  State<_UserSubmissionsSection> createState() =>
      _UserSubmissionsSectionState();
}

class _UserSubmissionsSectionState extends State<_UserSubmissionsSection> {
  final EventService _eventService = EventService();
  late Stream<List<EventModel>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _eventService.getUserEventsStream(widget.uid);
  }

  @override
  void didUpdateWidget(covariant _UserSubmissionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _eventsStream = _eventService.getUserEventsStream(widget.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pengajuan Event Saya',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<EventModel>>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Gagal memuat pengajuan: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.accentPink),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final events = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (events.isEmpty)
                  Text(
                    'Anda belum mengajukan event.',
                    style: TextStyle(color: secondaryColor),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _UserSubmissionCard(
                      event: events[index],
                      secondaryColor: secondaryColor,
                    ),
                  ),
                const SizedBox(height: 20),
                _SubmissionSummaryCard(events: events),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SubmissionSummaryCard extends StatelessWidget {
  const _SubmissionSummaryCard({required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    final approvedCount = events.where((event) => event.isApproved).length;
    final pendingCount = events.where((event) => event.isPending).length;
    final statistics = [
      (label: 'Total Pengajuan', value: events.length),
      (label: 'Disetujui', value: approvedCount),
      (label: 'Menunggu', value: pendingCount),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pengajuan Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var index = 0; index < statistics.length; index++) ...[
                if (index > 0)
                  Container(
                    width: 1,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${statistics[index].value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statistics[index].label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UserSubmissionCard extends StatelessWidget {
  const _UserSubmissionCard({
    required this.event,
    required this.secondaryColor,
  });

  final EventModel event;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final statusColor = event.isPending
        ? AppTheme.warningOrange
        : event.isRejected
        ? AppTheme.accentPink
        : event.isPublished
        ? AppTheme.successGreen
        : AppTheme.warningOrange;
    final statusLabel = event.isPending
        ? 'Menunggu'
        : event.isRejected
        ? 'Ditolak'
        : event.isPublished
        ? 'Disetujui'
        : 'Disetujui · Nonaktif';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: secondaryColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${event.date.day.toString().padLeft(2, '0')}/'
            '${event.date.month.toString().padLeft(2, '0')}/'
            '${event.date.year} · ${event.location}',
            style: TextStyle(color: secondaryColor, fontSize: 12),
          ),
          if (event.isRejected &&
              event.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Alasan: ${event.rejectionReason}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondaryColor,
                height: 1.4,
              ),
            ),
          ],
          if (event.isPending || event.isRejected) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: statusColor,
                  backgroundColor: statusColor.withValues(alpha: 0.09),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditEventScreen(event: event),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  event.isRejected
                      ? 'Perbaiki & ajukan ulang'
                      : 'Edit pengajuan',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
