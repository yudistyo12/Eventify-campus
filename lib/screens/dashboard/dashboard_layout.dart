import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../event/add_edit_event_screen.dart';
import 'home_tab.dart';
import 'events_tab.dart';
import 'profile_tab.dart';
import 'statistics_tab.dart';

class DashboardLayout extends StatefulWidget {
  final int initialTab;
  const DashboardLayout({super.key, this.initialTab = 0});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    if (index == 2 && !context.read<AppState>().isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(openAddEventAfterLogin: true),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Define tabs list
    final List<Widget> tabs = [
      const HomeTab(),
      const EventsTab(),
      const AddEditEventScreen(), // Direct form tab
      const StatisticsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.07),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.36)
                      : AppTheme.primaryNavy.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavigationItem(
                  index: 0,
                  label: 'Home',
                  selectedIcon: Icons.grid_view_rounded,
                  icon: Icons.grid_view_outlined,
                ),
                _buildNavigationItem(
                  index: 1,
                  label: 'Daftar Event',
                  selectedIcon: Icons.event_note_rounded,
                  icon: Icons.event_note_outlined,
                ),
                _buildAddEventItem(),
                _buildNavigationItem(
                  index: 3,
                  label: 'Statistik',
                  selectedIcon: Icons.bar_chart_rounded,
                  icon: Icons.bar_chart_outlined,
                ),
                _buildNavigationItem(
                  index: 4,
                  label: 'Profile',
                  selectedIcon: Icons.account_circle_rounded,
                  icon: Icons.account_circle_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required int index,
    required String label,
    required IconData selectedIcon,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = isSelected
        ? AppTheme.primaryIndigo
        : colorScheme.onSurface.withValues(alpha: 0.56);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _onTabTapped(index),
          child: SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryIndigo.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    size: 20,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foregroundColor,
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddEventItem() {
    return Expanded(
      child: Semantics(
        button: true,
        selected: _currentIndex == 2,
        label: 'Tambah Event',
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _onTabTapped(2),
          child: SizedBox(
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: 0.38),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: Text(
                    'Tambah Event',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _currentIndex == 2
                          ? AppTheme.primaryIndigo
                          : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.56),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
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
