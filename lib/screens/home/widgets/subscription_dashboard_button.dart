import 'package:flutter/material.dart';

class SubscriptionDashboardButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const SubscriptionDashboardButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                : const Color(0xFF166534),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF059669).withValues(alpha: 0.6)
                  : const Color(0xFF166534),
              width: 1.2,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF166534).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: isDark ? const Color(0xFF4ADE80) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF4ADE80) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
