import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget _buildDashboardCard({
    required BuildContext context,
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color primaryColor,
    required String nextRoute,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
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
          onTap: () {
            context.push(
              '/role_login',
              extra: {
                'roleName': title,
                'themeColor': primaryColor,
                'nextRoute': nextRoute,
              },
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background faded shape
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 150,
                  color: primaryColor.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 40, color: primaryColor),
                        ),
                        Text(
                          number,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
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

  Widget _buildFeatureBadge(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/back.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFFF8FAFC)),
            ),
          ),
          // Very light overlay to ensure text remains readable without washing out the image
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWeb = constraints.maxWidth > 800;

                return Column(
                  children: [
                    // Top App Bar Area
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 48.0 : 24.0,
                        vertical: 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/LOGO.png',
                                height: 80,
                                cacheHeight: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.local_hospital,
                                      color: Color(0xFF166534),
                                      size: 40,
                                    ),
                              ),
                            ],
                          ),
                          if (isWeb)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
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
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFFF1F5F9),
                                    child: Icon(
                                      Icons.person,
                                      color: Color(0xFF475569),
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome Back,',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isWeb ? 40 : 20),
                              // Header Text
                              const Text(
                                'WELCOME BACK!',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -1,
                                  ),
                                  children: [
                                    TextSpan(text: 'Select a '),
                                    TextSpan(
                                      text: 'Module',
                                      style: TextStyle(
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Choose a module to continue and manage your services',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: isWeb ? 64 : 32),

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
                                                number: '01',
                                                title: 'Counter',
                                                description:
                                                    'Manage sales, billing, inventory and pharmacy counter operations.',
                                                icon:
                                                    Icons.point_of_sale_rounded,
                                                primaryColor: const Color(
                                                  0xFF22C55E,
                                                ),
                                                nextRoute: '/counter/inventory',
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                            Expanded(
                                              child: _buildDashboardCard(
                                                context: context,
                                                number: '02',
                                                title: 'Lab Test',
                                                description:
                                                    'Manage lab test bookings, reports and patient records.',
                                                icon: Icons.science_rounded,
                                                primaryColor: const Color(
                                                  0xFFF97316,
                                                ),
                                                nextRoute: '/lab/dashboard',
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                            Expanded(
                                              child: _buildDashboardCard(
                                                context: context,
                                                number: '03',
                                                title: 'CRM',
                                                description:
                                                    'Manage patients, follow-ups and customer relationships.',
                                                icon: Icons.people_alt_rounded,
                                                primaryColor: const Color(
                                                  0xFF8B5CF6,
                                                ),
                                                nextRoute: '/crm/dashboard',
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
                                          number: '01',
                                          title: 'Counter',
                                          description:
                                              'Manage sales, billing, inventory.',
                                          icon: Icons.point_of_sale_rounded,
                                          primaryColor: const Color(0xFF22C55E),
                                          nextRoute: '/counter/inventory',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDashboardCard(
                                          context: context,
                                          number: '02',
                                          title: 'Lab Test',
                                          description:
                                              'Manage lab test bookings, reports.',
                                          icon: Icons.science_rounded,
                                          primaryColor: const Color(0xFFF97316),
                                          nextRoute: '/lab/dashboard',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDashboardCard(
                                          context: context,
                                          number: '03',
                                          title: 'CRM',
                                          description:
                                              'Manage patients, follow-ups.',
                                          icon: Icons.people_alt_rounded,
                                          primaryColor: const Color(0xFF8B5CF6),
                                          nextRoute: '/crm/dashboard',
                                        ),
                                      ],
                                    ),
                              SizedBox(height: isWeb ? 40 : 20),

                              // Bottom Features Bar
                              if (isWeb)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildFeatureBadge(
                                        Icons.security,
                                        const Color(0xFF166534),
                                        'Secure & Reliable',
                                        'Your data is safe with us',
                                      ),
                                      const SizedBox(width: 48),
                                      _buildFeatureBadge(
                                        Icons.bolt,
                                        const Color(0xFFF59E0B),
                                        'Fast & Efficient',
                                        'Save time, do more',
                                      ),
                                      const SizedBox(width: 48),
                                      _buildFeatureBadge(
                                        Icons.favorite,
                                        const Color(0xFFEF4444),
                                        'Better Healthcare',
                                        'For a healthier community',
                                      ),
                                    ],
                                  ),
                                ),
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
                          vertical: 16,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '© 2026 SirfBill Bill Karo, Befikar Raho. All rights reserved.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Together for a Healthier Tomorrow',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
