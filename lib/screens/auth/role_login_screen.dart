import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleLoginScreen extends StatefulWidget {
  final String roleName;
  final Color themeColor;
  final String nextRoute;

  const RoleLoginScreen({
    super.key,
    required this.roleName,
    required this.themeColor,
    required this.nextRoute,
  });

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  void _login() {
    if (_formKey.currentState!.validate()) {
      if (_userIdController.text == 'admin' && _passwordController.text == 'password') {
        context.go(widget.nextRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid User ID or Password')),
        );
      }
    }
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.themeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.themeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Image (Blurred)
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.2)],
                  stops: const [0.4, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: Image.asset(
                'assets/back.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFE2E8F0)),
              ),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFF8FAFC).withOpacity(0.95),
                    const Color(0xFFF8FAFC).withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Custom Top Bar
              Container(
                height: 50,
                color: widget.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      label: const Text('Back', style: TextStyle(color: Colors.white)),
                    ),
                    Text(
                      '${widget.roleName} Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isWeb)
                      const Text(
                        'Manju Medical Stores & Digital Clinic',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      )
                    else
                      const SizedBox(width: 60), // Balance the row
                  ],
                ),
              ),

              Expanded(
                child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
              ),

              // Footer
              if (isWeb)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '© 2026 Manju Medical Stores & Digital Clinic. All rights reserved.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Together for a Healthier Tomorrow',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.eco, size: 14, color: widget.themeColor),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // Left Content
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Image.asset('assets/LOGO.png', height: 80, cacheHeight: 250),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manju Medical Stores',
                          style: TextStyle(
                            color: widget.themeColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          '& Digital Clinic',
                          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.eco, size: 16, color: Color(0xFF22C55E)),
                            const SizedBox(width: 6),
                            const Text(
                              'Your Health   Our Priority',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const Text('Welcome to', style: TextStyle(fontSize: 24, color: Color(0xFF64748B))),
                Text(
                  '${widget.roleName} Module',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: widget.themeColor),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.roleName == 'Counter'
                      ? 'Manage your pharmacy, billing, inventory\nand daily operations with ease.'
                      : widget.roleName == 'Lab Test'
                          ? 'Manage your lab test bookings, reports\nand patient records effortlessly.'
                          : 'Manage patients, follow-ups and\ncustomer relationships efficiently.',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 48),
                if (widget.roleName == 'Counter') ...[
                  _buildFeatureItem(Icons.medication, 'Faster Billing', 'Serve customers quickly'),
                  _buildFeatureItem(Icons.inventory, 'Inventory Management', 'Keep stock in control'),
                  _buildFeatureItem(Icons.security, 'Reliable & Secure', 'Your data is always safe'),
                ] else if (widget.roleName == 'Lab Test') ...[
                  _buildFeatureItem(Icons.science, 'Easy Booking', 'Schedule lab tests quickly'),
                  _buildFeatureItem(Icons.assignment, 'Report Management', 'Access and manage reports'),
                  _buildFeatureItem(Icons.people, 'Patient Support', 'Keep records organized'),
                ] else ...[
                  _buildFeatureItem(Icons.folder_shared, 'Patient Management', 'Keep patient records organized'),
                  _buildFeatureItem(Icons.notifications_active, 'Smart Follow-ups', 'Never miss an important follow-up'),
                  _buildFeatureItem(Icons.handshake, 'Better Relationships', 'Build stronger customer connections'),
                ],
              ],
            ),
          ),
          
          // Right Login Card
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginCard(),
              ),
            ),
          ),
        ],
      ), // Closes Row
      ), // Closes Padding
      ), // Closes ConstrainedBox
    ); // Closes Center
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildLoginCard(),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.admin_panel_settings, size: 64, color: widget.themeColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Access ${widget.roleName} Module',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to continue',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(
                hintText: 'User ID',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter User ID' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF94A3B8)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text(
                  'Secure Access. Authorized Personnel Only.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
