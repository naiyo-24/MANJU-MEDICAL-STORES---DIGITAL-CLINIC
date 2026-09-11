import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CrmDashboard extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const CrmDashboard({super.key, required this.navigationShell});

  @override
  State<CrmDashboard> createState() => _CrmDashboardState();
}

class _CrmDashboardState extends State<CrmDashboard> {
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
                _buildNavItem(1, Icons.people_outline, 'Patient Management'),
                _buildNavItem(2, Icons.calendar_month_outlined, 'Appointment Management'),
                _buildNavItem(3, Icons.edit_document, 'Prescription Generation'),
                _buildNavItem(4, Icons.medical_services_outlined, 'Doctor Inventory'),
                _buildNavItem(5, Icons.receipt_long, 'Payment Receipt'),
                _buildNavItem(6, Icons.history, 'Payment History'),
                _buildNavItem(7, Icons.science_outlined, 'Lab Test Billing'),
                _buildNavItem(8, Icons.send, 'Send to Lab'),
                _buildNavItem(9, Icons.shopping_cart_outlined, 'Order Management'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1, indent: 16, endIndent: 16),
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
                  Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
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
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
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
          const Spacer(),
          // Search Bar
          Container(
            width: 400,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search patients, appointments, doctors...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 12), // Align center
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right Actions
          Row(
            children: [

              // User Profile Outline Button
              PopupMenuButton<String>(
                offset: const Offset(0, 40),
                onSelected: (value) {
                  if (value == 'logout') {
                    context.go('/dashboard');
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                        child: Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('CRM Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                          Text('CRM', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
