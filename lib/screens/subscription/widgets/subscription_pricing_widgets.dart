import 'package:flutter/material.dart';

class SubscriptionPlan {
  final String id;
  final String durationLabel;
  final String priceLabel;
  final String gstNote;
  final String? badgeText;
  final bool isHighlighted;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.durationLabel,
    required this.priceLabel,
    this.gstNote = 'Incl. 18% GST',
    this.badgeText,
    this.isHighlighted = false,
    required this.features,
  });
}

const List<SubscriptionPlan> kSubscriptionPlans = [
  SubscriptionPlan(
    id: 'plan_1m',
    durationLabel: '1 Month',
    priceLabel: '₹353',
    features: [
      'Full Billing Counter Access',
      'Lab Test & CRM Modules',
      'GST-Ready Invoices & Reports',
      'Standard Support',
    ],
  ),
  SubscriptionPlan(
    id: 'plan_3m',
    durationLabel: '3 Months',
    priceLabel: '₹1,058',
    features: [
      'Full Billing Counter Access',
      'Lab Test & CRM Modules',
      'GST-Ready Invoices & Reports',
      'Priority Support',
    ],
  ),
  SubscriptionPlan(
    id: 'plan_6m',
    durationLabel: '6 Months',
    priceLabel: '₹1,905',
    badgeText: '10% OFF',
    features: [
      'Full Billing Counter Access',
      'Lab Test & CRM Modules',
      'Cloud Sync Across Devices',
      'Priority Support',
    ],
  ),
  SubscriptionPlan(
    id: 'plan_12m',
    durationLabel: '12 Months',
    priceLabel: '₹3,599',
    badgeText: '15% OFF • BEST VALUE',
    isHighlighted: true,
    features: [
      'Full Billing Counter Access',
      'Lab Test & CRM Modules',
      'Cloud Sync Across Devices',
      'Dedicated Priority Support',
    ],
  ),
];

class SubscriptionHeaderSection extends StatelessWidget {
  final bool isDark;
  final bool isCompact;

  const SubscriptionHeaderSection({
    super.key,
    required this.isDark,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final accentColor =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                : const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF059669).withValues(alpha: 0.5)
                  : const Color(0xFF86EFAC),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'SirfBill Pharma',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'All-in-One Pharmacy Suite',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 24 : 32,
            fontWeight: FontWeight.w900,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'One Plan. Complete Access to Billing Counter, Lab Test & CRM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 13 : 15,
            color: subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SubscriptionPricingGrid extends StatelessWidget {
  final bool isDark;
  final String? selectedPlanId;
  final ValueChanged<SubscriptionPlan> onSubscribe;

  const SubscriptionPricingGrid({
    super.key,
    required this.isDark,
    required this.selectedPlanId,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns = width >= 1040 ? 4 : (width >= 600 ? 2 : 1);
        const double spacing = 18;
        final double cardWidth =
            (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: kSubscriptionPlans.map((plan) {
            return SizedBox(
              width: cardWidth,
              child: SubscriptionPlanCard(
                plan: plan,
                isDark: isDark,
                isSelected: selectedPlanId == plan.id,
                onSubscribe: () => onSubscribe(plan),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onSubscribe;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.isDark,
    required this.isSelected,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
    final borderColor = plan.isHighlighted || isSelected
        ? (isDark ? const Color(0xFF22C55E) : const Color(0xFF166534))
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: plan.isHighlighted || isSelected ? 2 : 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: (plan.isHighlighted
                      ? const Color(0xFF166534)
                      : Colors.black)
                  .withValues(alpha: plan.isHighlighted ? 0.10 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: plan.badgeText != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: plan.isHighlighted
                          ? const Color(0xFF166534)
                          : (isDark
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.badgeText!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: plan.isHighlighted
                            ? Colors.white
                            : accentColor,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Text(
            plan.durationLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.priceLabel,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: accentColor,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.gstNote,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 16),
          ...plan.features.map(
            (feat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feat,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isHighlighted
                    ? const Color(0xFF166534)
                    : (isDark
                        ? const Color(0xFF059669)
                        : const Color(0xFF22C55E)),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionSummaryBar extends StatelessWidget {
  final bool isDark;

  const SubscriptionSummaryBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF0FDF4);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFBBF7D0);
    final textColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF166534);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 8,
        children: [
          _SummaryItem(
            icon: Icons.point_of_sale_rounded,
            label: 'Billing Counter',
            color: textColor,
          ),
          _SummaryItem(
            icon: Icons.science_rounded,
            label: 'Lab Test',
            color: textColor,
          ),
          _SummaryItem(
            icon: Icons.groups_rounded,
            label: 'CRM',
            color: textColor,
          ),
          _SummaryItem(
            icon: Icons.support_agent_rounded,
            label: 'Priority Support',
            color: textColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class SubscriptionEnquiryDesk extends StatelessWidget {
  final bool isDark;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onCallTap;

  const SubscriptionEnquiryDesk({
    super.key,
    required this.isDark,
    required this.onWhatsAppTap,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 14,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Need Help? Subscription Enquiry Desk',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reach out to our team for plan guidance, GST invoices, or renewals.',
                style: TextStyle(fontSize: 12.5, color: subColor),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onWhatsAppTap,
                icon: const Icon(Icons.chat_rounded, size: 17),
                label: const Text(
                  'WhatsApp: 9836723590',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCallTap,
                icon: Icon(
                  Icons.call_rounded,
                  size: 17,
                  color: isDark
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF166534),
                ),
                label: Text(
                  'Call: 9836723590',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF166534),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF166534),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
