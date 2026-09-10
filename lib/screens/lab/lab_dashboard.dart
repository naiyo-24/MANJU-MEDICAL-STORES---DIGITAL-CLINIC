import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LabDashboard extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const LabDashboard({super.key, required this.navigationShell});

  @override
  State<LabDashboard> createState() => _LabDashboardState();
}

class _LabDashboardState extends State<LabDashboard> {
  void _onNavigationItemSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(), // Global Top App Bar
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: ClipRRect(
                    // Ensure content doesn't bleed out
                    child: widget.navigationShell,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.science_outlined, 'Lab Tests'),
                _buildNavItem(2, Icons.description_outlined, 'Templates'),
                _buildNavItem(3, Icons.inventory_2_outlined, 'Packages'),
                _buildNavItem(4, Icons.calendar_today_outlined, 'Bookings'),
                _buildNavItem(5, Icons.track_changes_outlined, 'Sample Tracking'),
                _buildNavItem(6, Icons.analytics_outlined, 'Reports'),
                _buildNavItem(7, Icons.send_outlined, 'Send Reports'),
                _buildNavItem(8, Icons.history_outlined, 'History'),
                _buildNavItem(9, Icons.account_balance_wallet_outlined, 'Accounts'),
                _buildNavItem(10, Icons.settings_outlined, 'Settings'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: InkWell(
              onTap: () => context.go('/dashboard'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, size: 18, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text('Back to App', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = widget.navigationShell.currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _onNavigationItemSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          // Logo & Brand
          Row(
            children: [
              Image.asset('assets/LOGO.png', height: 40, cacheHeight: 120),
              const SizedBox(width: 12),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manju Medical Stores',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '& Digital Clinic',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          Expanded(
            child: Center(
              child: Container(
                width: 600,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search patients, tests, packages...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Notifications
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_none, color: Color(0xFF64748B)),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Profile Pill
          PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Text('Profile', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontSize: 14, color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person, color: Color(0xFF64748B), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lab Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                      Text('Diagnostic Lab', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
