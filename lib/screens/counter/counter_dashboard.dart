import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../providers/counter_providers.dart';
import '../../providers/distributor_provider.dart';

class CounterDashboard extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CounterDashboard({super.key, required this.navigationShell});

  @override
  ConsumerState<CounterDashboard> createState() => _CounterDashboardState();
}

class _CounterDashboardState extends ConsumerState<CounterDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  bool _isSidebarExpanded = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Real-time synchronization polling every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        ref.invalidate(inventoryProvider);
        ref.invalidate(rackProvider);
        ref.invalidate(categoryProvider);
        ref.invalidate(distributorsProvider);
      } catch (_) {
        // Ignore errors if context is deactivated during hot restarts
      }
    });

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        _switchTab(0);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        _switchTab(1);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        _switchTab(2);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f4) {
        _switchTab(3);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        _switchTab(4);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f6) {
        _switchTab(5);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f7) {
        _switchTab(6);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f8) {
        _switchTab(7);
        return true;
      }
    }
    return false;
  }

  void _switchTab(int index) {
    if (widget.navigationShell.currentIndex != index) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $period';
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    String? shortcut,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    
    Widget content = Container(
      width: _isSidebarExpanded ? 228 : 48, // Fix width to prevent flex overflow during animation
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 16 : 0, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _isSidebarExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.centerLeft,
        firstChild: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF166534) : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140, // Fixed width instead of Expanded
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF166534) : const Color(0xFF64748B),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shortcut != null)
                      Text(
                        shortcut,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF166534).withValues(alpha: 0.7) : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        secondChild: Center(
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF166534) : const Color(0xFF64748B),
            size: 20,
          ),
        ),
      ),
    );

    if (!_isSidebarExpanded) {
      content = Tooltip(message: label, child: content);
    }

    return InkWell(
      onTap: () {
        widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        );
        if (Responsive.isDesktop(context)) {
          setState(() {
            _isSidebarExpanded = false;
          });
        } else {
          Navigator.pop(context); // Close drawer on mobile
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Column(
        children: [
          _buildHeader(isDesktop),
          // Main Body
          Expanded(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(),
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
      ),
    );
  }

  Widget _buildShortcutChip(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    if (isDesktop) {
                      setState(() {
                        _isSidebarExpanded = !_isSidebarExpanded;
                      });
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),
                SizedBox(width: isDesktop ? 16 : 8),
                Flexible(
                  child: Image.asset(
                    'assets/LOGO.png', 
                    height: isDesktop ? 75 : 45, 
                    fit: BoxFit.contain, 
                    cacheHeight: 225
                  ),
                ),
              ],
            ),
          ),

          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.keyboard, size: 16, color: Color(0xFF64748B)),
                  _buildShortcutChip('F1', 'Billing'),
                  _buildShortcutChip('F2', 'Inventory'),
                  _buildShortcutChip('F3', 'Shops'),
                  _buildShortcutChip('F4', 'Customers'),
                  _buildShortcutChip('F5', 'Accounts'),
                  _buildShortcutChip('F6', 'History'),
                  _buildShortcutChip('F7', 'Settings'),
                  _buildShortcutChip('F8', 'Distributors'),
                ],
              ),
            ),
          
          if (!isDesktop) const Spacer(),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Allow scrolling to the left if space is tight, keeping right alignment
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Date & Time Pill
                  InkWell(
                    onTap: () async {
                      await showDatePicker(
                        context: context,
                        initialDate: _currentTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF166534), // Header background color
                                onPrimary: Colors.white, // Header text color
                                onSurface: Color(0xFF1E293B), // Body text color
                                surface: Colors.white, // Dialog background color
                              ),
                              dialogBackgroundColor: Colors.white,
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534), // Button text color
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF166534),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDate(_currentTime),
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(_currentTime),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Profile Pill
                  PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        ref.invalidate(categoryProvider);
                        ref.invalidate(rackProvider);
                        ref.invalidate(inventoryProvider);
                        ref.invalidate(billingInventoryProvider);
                        await AuthService.logout();
                        if (context.mounted) {
                          context.go('/dashboard');
                        }
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
                                'Counter Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Counter',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 260 : 80,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: _isSidebarExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(_isSidebarExpanded ? 24.0 : 16.0),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _isSidebarExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                alignment: Alignment.centerLeft,
                firstChild: const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: 212,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Counter Module',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Manage your pharmacy operations',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                secondChild: const Center(
                  child: Icon(Icons.local_pharmacy, color: Color(0xFF166534), size: 28),
                ),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.receipt_long,
                    label: 'Billing',
                    shortcut: 'F1',
                  ),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.inventory_2,
                    label: 'Inventory',
                    shortcut: 'F2',
                  ),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.storefront,
                    label: 'Shops',
                    shortcut: 'F3',
                  ),
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.people,
                    label: 'Customers',
                    shortcut: 'F4',
                  ),
                  _buildSidebarItem(
                    index: 4,
                    icon: Icons.account_balance_wallet,
                    label: 'Accounts',
                    shortcut: 'F5',
                  ),
                  _buildSidebarItem(
                    index: 5,
                    icon: Icons.history,
                    label: 'History',
                    shortcut: 'F6',
                  ),
                  _buildSidebarItem(
                    index: 6,
                    icon: Icons.settings,
                    label: 'Settings',
                    shortcut: 'F7',
                  ),
                  _buildSidebarItem(
                    index: 7,
                    icon: Icons.local_shipping,
                    label: 'Distributors',
                    shortcut: 'F8',
                  ),

                  const SizedBox(height: 16),
                  const Divider(
                    color: Color(0xFFE2E8F0),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),

                  Tooltip(
                    message: _isSidebarExpanded ? '' : 'Logout',
                    child: InkWell(
                      onTap: () async {
                        ref.invalidate(categoryProvider);
                        ref.invalidate(rackProvider);
                        ref.invalidate(inventoryProvider);
                        ref.invalidate(billingInventoryProvider);
                        await AuthService.logout();
                        if (context.mounted) {
                          // Go back to the module selection screen
                          context.go('/dashboard');
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: _isSidebarExpanded ? 16 : 0,
                          vertical: 12,
                        ),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: _isSidebarExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          alignment: Alignment.centerLeft,
                          firstChild: const SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
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
                          secondChild: const Center(
                            child: Icon(Icons.logout, color: Colors.red, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sidebar Card
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isSidebarExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            alignment: Alignment.bottomCenter,
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: 228,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.eco, color: Color(0xFF22C55E)),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Better Care',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Brighter Tomorrow',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            secondChild: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Icon(Icons.eco, color: Color(0xFF22C55E), size: 24),
              ),
            ),
          ),
            
          Padding(
            padding: EdgeInsets.all(_isSidebarExpanded ? 24.0 : 16.0),
            child: Center(
              child: Text(
                _isSidebarExpanded ? 'Version 1.0.0' : 'v1',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
