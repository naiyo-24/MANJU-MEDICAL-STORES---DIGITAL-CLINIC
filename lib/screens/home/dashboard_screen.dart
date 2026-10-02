import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color primaryColor,
    required String nextRoute,
    required bool isDark,
  }) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark 
            ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5) 
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Lab Test' || title == 'CRM') {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: isDark ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5) : null,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rocket_launch_rounded,
                            size: 48,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The $title module is currently under development. We are crafting a seamless experience and will launch this soon!',
                          style: TextStyle(
                            fontSize: 15,
                            color: descColor,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              context.push(
                '/role_login',
                extra: {
                  'roleName': title,
                  'themeColor': primaryColor,
                  'nextRoute': nextRoute,
                },
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(isWeb ? 32.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: primaryColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: descColor,
                        fontWeight: FontWeight.w500,                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 24 : 16,
                          vertical: isWeb ? 12 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isWeb ? 16 : 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: isWeb ? 18 : 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 800;
              return Column(
                children: [
                  // Top App Bar Area (Toggle button right)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 48.0 : 24.0,
                      vertical: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                         IconButton(
                           onPressed: () {
                             ref.read(themeProvider.notifier).toggleTheme();
                           },
                           icon: Icon(
                             isDark ? Icons.light_mode : Icons.dark_mode,
                             color: isDark ? Colors.white : const Color(0xFF1E293B),
                             size: 28,
                           ),
                         ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 64.0 : 24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: isWeb ? 20 : 10),
                            // Centered Logo
                            Image.asset(
                              isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.local_hospital,
                                    color: Color(0xFF166534),
                                    size: 60,
                                  ),
                            ),
                            const SizedBox(height: 48),

                            // Cards
                            isWeb
                                ? IntrinsicHeight(
                                    child: Center(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: _buildDashboardCard(
                                              context: context,
                                              title: 'Counter',
                                              description:
                                                  'Manage sales, billing, inventory and pharmacy counter operations.',
                                              icon:
                                                  Icons.point_of_sale_rounded,
                                              primaryColor: const Color(0xFF22C55E), // Green
                                              nextRoute: '/counter/billing',
                                              isDark: isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 32),
                                          Expanded(
                                            child: _buildDashboardCard(
                                              context: context,
                                              title: 'Lab Test',
                                              description:
                                                  'Manage lab test bookings, reports and patient records.',
                                              icon: Icons.science_rounded,
                                              primaryColor: const Color(0xFF3B82F6), // Blue
                                              nextRoute: '/lab/dashboard',
                                              isDark: isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 32),
                                          Expanded(
                                            child: _buildDashboardCard(
                                              context: context,
                                              title: 'CRM',
                                              description:
                                                  'Manage patients, follow-ups and customer relationships.',
                                              icon: Icons.people_alt_rounded,
                                              primaryColor: const Color(0xFFF97316), // Orange
                                              nextRoute: '/crm/dashboard',
                                              isDark: isDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildDashboardCard(
                                        context: context,
                                        title: 'Counter',
                                        description:
                                            'Manage sales, billing, inventory.',
                                        icon: Icons.point_of_sale_rounded,
                                        primaryColor: const Color(0xFF22C55E), // Green
                                        nextRoute: '/counter/billing',
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDashboardCard(
                                        context: context,
                                        title: 'Lab Test',
                                        description:
                                            'Manage lab test bookings, reports.',
                                        icon: Icons.science_rounded,
                                        primaryColor: const Color(0xFF3B82F6), // Blue
                                        nextRoute: '/lab/dashboard',
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDashboardCard(
                                        context: context,
                                        title: 'CRM',
                                        description:
                                            'Manage patients, follow-ups.',
                                        icon: Icons.people_alt_rounded,
                                        primaryColor: const Color(0xFFF97316), // Orange
                                        nextRoute: '/crm/dashboard',
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                            SizedBox(height: isWeb ? 40 : 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  if (isWeb)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,                      ),
                      child: Row(
                        mainAxisAlignment: isWeb
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.center,
                        children: [
                          Text(
                            '© 2026 SirfBill Bill Karo, Befikar Raho. All rights reserved.',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Together for a Healthier Tomorrow',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.eco,
                                size: 14,
                                color: Color(0xFF22C55E),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },          ),
        ),
      ),
    );
  }
}
