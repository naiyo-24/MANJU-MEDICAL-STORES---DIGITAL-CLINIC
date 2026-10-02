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
    required String indexText,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark 
            ? Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5) 
            : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (title == 'Lab Test' || title == 'CRM') {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch_rounded, size: 48, color: primaryColor),
                        const SizedBox(height: 24),
                        Text('Coming Soon', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        Text('The $title module is under development.', textAlign: TextAlign.center, style: TextStyle(color: descColor)),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Got it'),
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
          child: Stack(
            children: [
              // Watermark number
              Positioned(
                top: 24,
                right: 24,
                child: Text(
                  indexText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 24, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(fontSize: 12, color: descColor, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 14),
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
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), // Clean light slate background instead of green
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 800;
              
              return Stack(
                children: [
                  if (!isDark) // Beautiful blurred background for light mode
                    Positioned.fill(
                      child: Image.asset(
                        'assets/blur_bg.png',
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.4),
                        errorBuilder: (context, error, stackTrace) => const SizedBox(), // Fails gracefully if missing
                      ),
                    ),
                  Column(
                    children: [
                      // Top App Bar Area (Toggle button right)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWeb ? 48.0 : 24.0, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                             IconButton(
                               onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                               icon: Icon(
                                 isDark ? Icons.light_mode : Icons.dark_mode,
                                 color: isDark ? Colors.white : const Color(0xFF1E293B),
                                 size: 24,
                               ),
                             ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isWeb ? 64.0 : 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Left aligned text
                              children: [
                                Center(
                                  child: Image.asset(
                                    isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                                    height: 90,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, color: Color(0xFF166534), size: 40),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                Text(
                                  'WELCOME BACK!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    children: const [
                                      TextSpan(text: 'Select a '),
                                      TextSpan(
                                        text: 'Module',
                                        style: TextStyle(color: Color(0xFF166534)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose a module to continue and manage your services',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Cards
                                _buildDashboardCard(
                                  context: context,
                                  title: 'Counter',
                                  description: 'Manage sales, billing, inventory.',
                                  icon: Icons.point_of_sale_rounded,
                                  primaryColor: const Color(0xFF22C55E), // Green
                                  nextRoute: '/counter/billing',
                                  isDark: isDark,
                                  indexText: '01',
                                ),
                                _buildDashboardCard(
                                  context: context,
                                  title: 'Lab Test',
                                  description: 'Manage lab test bookings, reports.',
                                  icon: Icons.science_rounded, // or biotech
                                  primaryColor: const Color(0xFFF97316), // Orange
                                  nextRoute: '/lab/dashboard',
                                  isDark: isDark,
                                  indexText: '02',
                                ),
                                _buildDashboardCard(
                                  context: context,
                                  title: 'CRM',
                                  description: 'Manage patients, follow-ups.',
                                  icon: Icons.people_alt_rounded,
                                  primaryColor: const Color(0xFF8B5CF6), // Purple
                                  nextRoute: '/crm/dashboard',
                                  isDark: isDark,
                                  indexText: '03',
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Together for a Healthier Tomorrow',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.eco, size: 14, color: Color(0xFF22C55E)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2026 SirfBill Bill Karo, Befikar Raho.',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
