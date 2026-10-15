import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';

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

  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {


      setState(() {
        _isLoading = true;
      });

      final userId = _userIdController.text.trim().toLowerCase();
      
      // Role-based validation
      bool isValidRole = true;
      String errorMsg = '';
      
      if (widget.roleName == 'Billing Counter' && !userId.contains('counter')) {
        isValidRole = false;
        errorMsg = 'Unauthorized: Only Counter admins can access this module.';
      } else if (widget.roleName == 'CRM' && !userId.contains('crm')) {
        isValidRole = false;
        errorMsg = 'Unauthorized: Only CRM admins can access this module.';
      } else if (widget.roleName == 'Lab Test' && !userId.contains('lab')) {
        isValidRole = false;
        errorMsg = 'Unauthorized: Only Lab admins can access this module.';
      }

      if (!isValidRole) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Access Denied', style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      try {
        final success = await AuthService.adminLogin(
          _userIdController.text,
          _passwordController.text,
        );

        if (success && mounted) {
          context.go(widget.nextRoute);
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Login Failed', style: TextStyle(color: Colors.red)),
                ],
              ),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.15),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 850;
    final isTablet = width >= 600 && width < 850;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final shaderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Stack(
      children: [
        // Solid Background
        Positioned.fill(
          child: Container(color: scaffoldBg),
        ),
        // Background Image (Blurred)
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: isWide ? Alignment.centerLeft : Alignment.topCenter,
                end: isWide ? Alignment.centerRight : Alignment.bottomCenter,
                colors: [
                  shaderColor, 
                  shaderColor.withValues(alpha: isWide ? 0.2 : 0.5)
                ],
                stops: const [0.4, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: Image.asset(
              'assets/back.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
          ),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isWide ? Alignment.centerLeft : Alignment.topCenter,
                end: isWide ? Alignment.centerRight : Alignment.bottomCenter,
                colors: [
                  scaffoldBg.withValues(alpha: isWide ? 0.95 : 0.85),
                  scaffoldBg.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        // Foreground UI
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Custom Top Bar
                Container(
                  color: widget.themeColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Back',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        '${widget.roleName} Login',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isWide)
                        const Text(
                          'SirfBill Bill Karo, Befikar Raho',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        )
                      else
                        const SizedBox(width: 60), // Balance the row
                    ],
                  ),
                ),

                // Main Content (Scrollable & Responsive, Vertically Centered)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPadding(context),
                          vertical: 16.0,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 32.0, // Account for vertical padding
                          ),
                          child: Center(
                            child: isWide ? _buildWebLayout(isTablet) : _buildMobileLayout(),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 24,
                    vertical: 12,
                  ),
                  child: isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '© 2026 SirfBill Bill Karo, Befikar Raho. All rights reserved.',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Together for a Healthier Tomorrow',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.eco, size: 14, color: widget.themeColor),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Text(
                                      '© 2026 SirfBill Bill Karo, Befikar Raho. All rights reserved.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Together for a Healthier Tomorrow',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
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
          ),
        ), // Closes Scaffold
      ],
    ); // Closes Stack
  }

  Widget _buildWelcomeInfo({bool isCompact = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final titleFontSize = isCompact ? 30.0 : 40.0;
    final welcomeFontSize = isCompact ? 18.0 : 22.0;
    final descFontSize = isCompact ? 14.0 : 15.0;
    final logoHeight = isCompact ? 60.0 : 75.0;
    final vSpacing = isCompact ? 14.0 : 20.0;

    return Column(
      crossAxisAlignment: isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
          height: logoHeight,
          cacheHeight: 250,
        ),
        SizedBox(height: vSpacing),
        Text(
          'Welcome to',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: welcomeFontSize,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
          ),
        ),
        Text(
          '${widget.roleName} Module',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w900,
            color: widget.themeColor,
            height: 1.15,
          ),
        ),
        SizedBox(height: vSpacing * 0.7),
        Text(
          widget.roleName == 'Counter'
              ? 'Manage your pharmacy, billing, inventory\nand daily operations with ease.'
              : widget.roleName == 'Lab Test'
              ? 'Manage your lab test bookings, reports\nand patient records effortlessly.'
              : 'Manage patients, follow-ups and\ncustomer relationships efficiently.',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: descFontSize,
            color: subtitleColor,
            height: 1.5,
          ),
        ),
        SizedBox(height: vSpacing),
        if (widget.roleName == 'Counter') ...[
          _buildFeatureItem(
            Icons.medication,
            'Faster Billing',
            'Serve customers quickly',
          ),
          _buildFeatureItem(
            Icons.inventory,
            'Inventory Management',
            'Keep stock in control',
          ),
          _buildFeatureItem(
            Icons.security,
            'Reliable & Secure',
            'Your data is always safe',
          ),
        ] else if (widget.roleName == 'Lab Test') ...[
          _buildFeatureItem(
            Icons.science,
            'Easy Booking',
            'Schedule lab tests quickly',
          ),
          _buildFeatureItem(
            Icons.assignment,
            'Report Management',
            'Access and manage reports',
          ),
          _buildFeatureItem(
            Icons.people,
            'Patient Support',
            'Keep records organized',
          ),
        ] else ...[
          _buildFeatureItem(
            Icons.folder_shared,
            'Patient Management',
            'Keep patient records organized',
          ),
          _buildFeatureItem(
            Icons.notifications_active,
            'Smart Follow-ups',
            'Never miss an important follow-up',
          ),
          _buildFeatureItem(
            Icons.handshake,
            'Better Relationships',
            'Build stronger customer connections',
          ),
        ],
      ],
    );
  }

  Widget _buildWebLayout(bool isTablet) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final isCompactWeb = availableWidth < 960;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactWeb ? 20.0 : (isTablet ? 32.0 : 48.0),
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Content
                  Expanded(
                    flex: isCompactWeb ? 5 : 6,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: _buildWelcomeInfo(isCompact: isCompactWeb),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompactWeb ? 32 : 56),
                  // Right Login Card
                  SizedBox(
                    width: isCompactWeb ? 370 : 420,
                    child: _buildLoginCard(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: _buildLoginCard(),
        ),
      ),
    );
  }
  Widget _buildLoginCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Access ${widget.roleName} Module',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _userIdController,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'User ID',
                hintStyle: TextStyle(color: subtitleColor),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter User ID' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: textColor),
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: subtitleColor),
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
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
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
                Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Secure Access. Authorized Personnel Only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
