import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/theme_provider.dart';
import 'widgets/subscription_pricing_widgets.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _selectedPlanId;

  void _handleSubscribe(SubscriptionPlan plan) {
    setState(() {
      _selectedPlanId = plan.id;
    });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Subscription Plans',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 32,
              vertical: isCompact ? 20 : 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  children: [
                    SubscriptionHeaderSection(
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                    const SizedBox(height: 28),
                    SubscriptionPricingGrid(
                      isDark: isDark,
                      selectedPlanId: _selectedPlanId,
                      onSubscribe: _handleSubscribe,
                    ),
                    const SizedBox(height: 24),
                    SubscriptionSummaryBar(isDark: isDark),
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
