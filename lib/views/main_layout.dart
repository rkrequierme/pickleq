import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

import 'dashboard_view.dart';
import 'queue_view.dart';
import 'court_view.dart';
import 'match_view.dart';
import 'reports_view.dart';
import 'session_view.dart';
import 'public_display_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _showPublicDisplay = false;

  final List<Widget> _views = [
    const DashboardView(),
    const QueueView(),
    const CourtView(),
    const MatchView(),
    const ReportsView(),
    const SessionView(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    // If public display is active, show it full-screen
    if (_showPublicDisplay) {
      return Scaffold(
        body: PublicDisplayView(
          onClose: () {
            setState(() {
              _showPublicDisplay = false;
            });
          },
        ),
      );
    }

    // App Bar
    final appBar = AppBar(
      backgroundColor: AppTheme.slateCard,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const Icon(Icons.sports_tennis, color: AppTheme.neonLime, size: 24),
          const SizedBox(width: 8),
          const Text(
            "PickleQ",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 24),
          // Session Indicator Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: appState.activeSession != null
                  ? AppTheme.neonLime.withOpacity(0.08)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: appState.activeSession != null
                    ? AppTheme.neonLime.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appState.activeSession != null ? AppTheme.neonLime : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  appState.activeSession != null
                      ? "SESSION ACTIVE: ${appState.activeSession!.date}"
                      : "NO ACTIVE SESSION",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: appState.activeSession != null
                        ? AppTheme.neonLime
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Public Screen Toggle
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showPublicDisplay = true;
            });
          },
          icon: const Icon(Icons.tv, size: 18),
          label: const Text("PUBLIC DISPLAY"),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.electricTeal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(width: 8),
        // Logout Button
        IconButton(
          icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
          tooltip: 'Sign Out',
          onPressed: () {
            _showLogoutConfirm(context, appState);
          },
        ),
        const SizedBox(width: 16),
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          // Sidebar Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: Text('Queue'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: Text('Courts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sports_esports_outlined),
                selectedIcon: Icon(Icons.sports_esports),
                label: Text('Match Control'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('EOD / Session'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderMuted),
          // View Content Area
          Expanded(
            child: _views[_selectedIndex],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to end your administrative session and log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
              child: const Text("LOG OUT", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
