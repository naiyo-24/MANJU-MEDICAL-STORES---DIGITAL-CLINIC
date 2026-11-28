import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import 'widgets/subscription_pricing_widgets.dart';
import 'widgets/subscription_status_widgets.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _selectedPlanId;
  bool _isRefreshing = false;

  final List<SubscriptionInvoiceRecord> _mockInvoices = const [
    SubscriptionInvoiceRecord(
      invoiceNo: 'INV-SUB-20261128-01',
      date: '2026-11-28',
      planCycle: 'SirfBill Pharma (1 Month)',
      amount: '₹353',
      paymentRef: 'pay_Phase2Mock001',
      status: 'ACTIVE',
    ),
  ];

  void _handleSubscribe(SubscriptionPlan plan) {
    setState(() => _selectedPlanId = plan.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected ${plan.durationLabel} (${plan.priceLabel} ${plan.gstNote})',
        ),
        backgroundColor: const Color(0xFF166534),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/919836723590?text=${Uri.encodeComponent('Hi SirfBill Pharma Team, I have an enquiry regarding the Subscription plans. Please assist.')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openDialer() async {
    await launchUrl(Uri.parse('tel:+919836723590'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4FBF7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 130,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Image.asset(
            isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'Subscription Plans',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (MediaQuery.of(context).size.width >= 600) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SubscriptionLiveClock(isDark: isDark),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : _handleRefresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
          ),
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 32,
              vertical: isCompact ? 20 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  children: [
                    SubscriptionLicenseBanner(
                      isDark: isDark,
                      planName: 'SirfBill Pharma Suite (1 Month)',
                      validUntil: '2026-12-28',
                      daysRemaining: 30,
                      latestInvoiceNo: _mockInvoices.first.invoiceNo,
                      onViewInvoice: () {},
                    ),
                    const SizedBox(height: 28),
                    SubscriptionHeaderSection(
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                    const SizedBox(height: 24),
                    SubscriptionPricingGrid(
                      isDark: isDark,
                      selectedPlanId: _selectedPlanId,
                      onSubscribe: _handleSubscribe,
                    ),
                    const SizedBox(height: 24),
                    SubscriptionSummaryBar(isDark: isDark),
                    const SizedBox(height: 20),
                    SubscriptionInvoicesTable(
                      isDark: isDark,
                      invoices: _mockInvoices,
                      onViewInvoice: (_) {},
                    ),
                    const SizedBox(height: 20),
                    SubscriptionEnquiryDesk(
                      isDark: isDark,
                      onWhatsAppTap: _openWhatsApp,
                      onCallTap: _openDialer,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
