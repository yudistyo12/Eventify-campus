import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = context.select<AppState, bool>(
      (appState) => appState.isAuthenticated,
    );

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.indigo.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
          indicatorColor: AppTheme.primaryIndigo.withValues(alpha: 0.12),
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                _currentIndex == 0
                    ? Icons.grid_view_rounded
                    : Icons.grid_view_outlined,
                color: _currentIndex == 0
                    ? AppTheme.primaryIndigo
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                _currentIndex == 1
                    ? Icons.event_note_rounded
                    : Icons.event_note_outlined,
                color: _currentIndex == 1
                    ? AppTheme.primaryIndigo
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              label: 'Daftar Event',
            ),
            NavigationDestination(
              icon: Icon(
                _currentIndex == 2
                    ? Icons.add_box_rounded
                    : Icons.add_box_outlined,
                color: _currentIndex == 2
                    ? AppTheme.primaryIndigo
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              label: 'Tambah Event',
            ),
            NavigationDestination(
              icon: Icon(
                _currentIndex == 3
                    ? Icons.bar_chart_rounded
                    : Icons.bar_chart_outlined,
                color: _currentIndex == 3
                    ? AppTheme.primaryIndigo
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              label: 'Statistik',
            ),
            NavigationDestination(
              icon: Icon(
                _currentIndex == 4
                    ? Icons.account_circle_rounded
                    : Icons.account_circle_outlined,
                color: _currentIndex == 4
                    ? AppTheme.primaryIndigo
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
      // Floating action button on home page is only visible when not on add/profile tab
      floatingActionButton:
          isAuthenticated && (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              onPressed: () {
                // Route to index 2 (Tambah Event tab)
                setState(() {
                  _currentIndex = 2;
                });
              },
              tooltip: 'Tambah Event Baru',
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
