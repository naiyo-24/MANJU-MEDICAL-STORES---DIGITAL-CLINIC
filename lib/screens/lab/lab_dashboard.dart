import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';

class LabDashboard extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const LabDashboard({super.key, required this.navigationShell});

  @override
  State<LabDashboard> createState() => _LabDashboardState();
}

class _LabDashboardState extends State<LabDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onNavigationItemSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (!Responsive.isDesktop(context)) {
      Navigator.pop(context); // Close drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Column(
        children: [
          _buildHeader(isDesktop), // Global Top App Bar
          Expanded(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(),
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
                _buildNavItem(
                  5,
                  Icons.track_changes_outlined,
                  'Sample Tracking',
                ),
                _buildNavItem(6, Icons.analytics_outlined, 'Reports'),
                _buildNavItem(7, Icons.send_outlined, 'Send Reports'),
                _buildNavItem(8, Icons.history_outlined, 'History'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => context.go('/dashboard'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: const [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
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

  Widget _buildHeader(bool isDesktop) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 16),
          ],
          // Logo & Brand
          Row(
            children: [
              Image.asset('assets/LOGO.png', height: 40, cacheHeight: 120),
            ],
          ),

          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
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
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Pill
          PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                context.go('/dashboard');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lab Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Diagnostic Lab',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
