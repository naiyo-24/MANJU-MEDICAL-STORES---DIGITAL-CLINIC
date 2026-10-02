import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../providers/counter_providers.dart';
import '../../providers/distributor_provider.dart';
import '../../providers/theme_provider.dart';

class CounterDashboard extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CounterDashboard({super.key, required this.navigationShell});

  @override
  ConsumerState<CounterDashboard> createState() => _CounterDashboardState();
}

class _CounterDashboardState extends ConsumerState<CounterDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarExpanded = true;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
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

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    String? shortcut,
    required bool isExpanded,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final itemBgSelected = isDark ? const Color(0xFF166534).withValues(alpha: 0.2) : const Color(0xFFE8F5E9);
    final itemBorderSelected = isDark ? const Color(0xFF22C55E).withValues(alpha: 0.5) : const Color(0xFF22C55E).withValues(alpha: 0.3);
    final iconColorSelected = isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
    final iconColorUnselected = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textColorSelected = isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
    final textColorUnselected = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
    final shortcutColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final shortcutColorSelected = isDark ? const Color(0xFF4ADE80).withValues(alpha: 0.7) : const Color(0xFF166534).withValues(alpha: 0.7);
    
    Widget content = Container(
      width: isExpanded ? 228 : 48, // Fix width to prevent flex overflow during animation
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 0, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? itemBgSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: itemBorderSelected,
                width: 1,
              )
            : null,
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.centerLeft,
        firstChild: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? iconColorSelected : iconColorUnselected,
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
                        color: isSelected ? textColorSelected : textColorUnselected,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shortcut != null)
                      Text(
                        shortcut,
                        style: TextStyle(
                          color: isSelected ? shortcutColorSelected : shortcutColor,
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
            color: isSelected ? iconColorSelected : iconColorUnselected,
            size: 20,
          ),
        ),
      ),
    );

    if (!isExpanded) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: scaffoldBg,
        drawer: isDesktop ? null : Drawer(child: _buildSidebar(isDesktop)),
      body: Column(
        children: [
          _buildHeader(isDesktop),
          // Main Body
          Expanded(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(isDesktop),
                // Screen Content
                Expanded(
                  child: Container(
                    color: scaffoldBg,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(key, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                  icon: Icon(Icons.menu, color: iconColor),
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
              Image.asset(
                isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png', 
                height: isDesktop ? 75 : 45, 
                fit: BoxFit.contain, 
                cacheHeight: 225
              ),
            ],
          ),

          if (isDesktop)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(Icons.keyboard, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F1', 'Billing'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F2', 'Inventory'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F3', 'Shops'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F4', 'Customers'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F5', 'Accounts'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F6', 'History'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F7', 'Settings'),
                      const SizedBox(width: 12),
                      _buildShortcutChip('F8', 'Distributors'),
                    ],
                  ),
                ),
              ),
            ),
          
          if (!isDesktop) const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Date & Time Pill
                  const _LiveClockWidget(),
                  const SizedBox(width: 16),

                  // Profile Pill
                  PopupMenuButton<String>(
                    offset: const Offset(0, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await AuthService.logout();
                        if (context.mounted) {
                          context.go('/dashboard');
                          ref.invalidate(categoryProvider);
                          ref.invalidate(rackProvider);
                          ref.invalidate(inventoryProvider);
                          ref.invalidate(billingInventoryProvider);
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
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Counter Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Counter',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            size: 16,
                          ),
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

  Widget _buildSidebar(bool isDesktop) {
    // On mobile (Drawer), always force the sidebar to be fully expanded
    final bool isExpanded = isDesktop ? _isSidebarExpanded : true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 260 : 80,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(isExpanded ? 24.0 : 16.0),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                alignment: Alignment.centerLeft,
                firstChild: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
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
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Manage your pharmacy operations',
                          style: TextStyle(fontSize: 10, color: subtitleColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                secondChild: Center(
                  child: Icon(Icons.local_pharmacy, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534), size: 28),
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
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.inventory_2,
                    label: 'Inventory',
                    shortcut: 'F2',
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.storefront,
                    label: 'Shops',
                    shortcut: 'F3',
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.people,
                    label: 'Customers',
                    shortcut: 'F4',
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 4,
                    icon: Icons.account_balance_wallet,
                    label: 'Accounts',
                    shortcut: 'F5',
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 5,
                    icon: Icons.history,
                    label: 'History',
                    shortcut: 'F6',
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 6,
                    icon: Icons.settings,
                    label: 'Settings',
                    shortcut: 'F7',
                    isExpanded: isExpanded,
                  ),
                  _buildSidebarItem(
                    index: 7,
                    icon: Icons.local_shipping,
                    label: 'Distributors',
                    shortcut: 'F8',
                    isExpanded: isExpanded,
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: borderColor,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),

                  Tooltip(
                    message: isExpanded ? '' : 'Logout',
                    child: InkWell(
                      onTap: () async {
                        await AuthService.logout();
                        if (context.mounted) {
                          // Go back to the module selection screen FIRST
                          context.go('/dashboard');
                          // Then invalidate providers so they don't refetch with a missing token
                          ref.invalidate(categoryProvider);
                          ref.invalidate(rackProvider);
                          ref.invalidate(inventoryProvider);
                          ref.invalidate(billingInventoryProvider);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 16 : 0,
                          vertical: 12,
                        ),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF22C55E)),
                      const SizedBox(width: 12),
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
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Brighter Tomorrow',
                              style: TextStyle(
                                fontSize: 10,
                                color: subtitleColor,
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
            padding: EdgeInsets.all(isExpanded ? 24.0 : 16.0),
            child: Center(
              child: Text(
                isExpanded ? 'Version 1.0.0' : 'v1',
                style: TextStyle(fontSize: 10, color: subtitleColor),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _LiveClockWidget extends StatefulWidget {
  const _LiveClockWidget();

  @override
  State<_LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<_LiveClockWidget> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
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
        width: 155, // FIXED WIDTH to prevent layout jitter every second
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F8F5),
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
                  style: TextStyle(
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTime(_currentTime),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
