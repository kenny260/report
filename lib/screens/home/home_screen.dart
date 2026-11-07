import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'tabs/feed_tab.dart';
import 'tabs/my_reports_tab.dart';
import 'tabs/staff_dashboard_tab.dart';
import 'tabs/profile_tab.dart';
import '../incident/create_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isStaff = authProvider.isStaff;

    final tabs = [
      const FeedTab(),
      const MyReportsTab(),
      const StaffDashboardTab(),
      const ProfileTab(),
    ];

    final titles = [
      'Campus Incidents',
      'My Submissions',
      isStaff ? 'Staff Command Center' : 'Campus Health',
      'Account Profile',
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Role pill indicator
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isStaff ? Colors.purple[700] : Colors.blue[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isStaff ? Icons.shield_outlined : Icons.school_outlined,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isStaff ? 'Staff' : 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      floatingActionButton: _currentIndex <= 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateIncidentScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text(
                'Report Issue',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.16),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed, color: AppTheme.primaryDark),
            label: 'Incidents',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppTheme.primaryDark),
            label: 'My Reports',
          ),
          NavigationDestination(
            icon: Icon(
              isStaff
                  ? Icons.admin_panel_settings_outlined
                  : Icons.bar_chart_outlined,
            ),
            selectedIcon: Icon(
              isStaff ? Icons.admin_panel_settings : Icons.bar_chart,
              color: AppTheme.primaryDark,
            ),
            label: isStaff ? 'Staff Panel' : 'Overview',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryDark),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
