import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CounterDashboard extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CounterDashboard({super.key, required this.navigationShell});

  @override
  State<CounterDashboard> createState() => _CounterDashboardState();
}

class _CounterDashboardState extends State<CounterDashboard> {
  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    return InkWell(
      onTap: () {
        widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF166534) : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF166534) : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Global Top App Bar
          Container(
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
                                hintText: 'Search medicines, customers, invoices...',
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
                

                
                // Profile Pill
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          Text('Logout', style: TextStyle(fontSize: 14, color: Colors.red)),
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
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Counter Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                            Text('Counter', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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
          ),
          
          // Main Body
          Expanded(
            child: Row(
              children: [
                // Custom Sidebar
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [

                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Counter Module', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                Text('Manage your pharmacy operations', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      _buildSidebarItem(index: 0, icon: Icons.inventory_2, label: 'Inventory'),
                      _buildSidebarItem(index: 1, icon: Icons.receipt_long, label: 'Billing'),
                      _buildSidebarItem(index: 2, icon: Icons.storefront, label: 'Shops'),
                      _buildSidebarItem(index: 3, icon: Icons.people, label: 'Customers'),
                      _buildSidebarItem(index: 4, icon: Icons.account_balance_wallet, label: 'Accounts'),
                      _buildSidebarItem(index: 5, icon: Icons.history, label: 'History'),
                      
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE2E8F0), thickness: 1, indent: 16, endIndent: 16),
                      const SizedBox(height: 8),
                      
                      InkWell(
                        onTap: () {
                          // Go back to the module selection screen
                          context.go('/dashboard');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Bottom Sidebar Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.eco, color: Color(0xFF22C55E)),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Better Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('Brighter Tomorrow', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('Version 1.0.0', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Screen Content
                Expanded(
                  child: Container(
                    color: Colors.white,
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
}
