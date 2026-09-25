import 'package:flutter/material.dart';

class CrmPlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const CrmPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF8B5CF6), size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CRM Module • SirfBill Bill Karo, Befikar Raho',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),
                    Text(
                      '$title Module',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This screen is currently under construction.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 1. Dashboard (will be replaced by real dashboard, but keep for fallback)
class CrmDashboardFallback extends StatelessWidget {
  const CrmDashboardFallback({super.key});
  @override
  Widget build(BuildContext context) =>
      const CrmPlaceholderScreen(title: 'Dashboard', icon: Icons.dashboard);
}

// 2. Patient Management
// Implemented in crm_patients_screen.dart

// 3. Appointment Management
// Implemented in crm_appointments_screen.dart

// 4. Prescription Generation
// Implemented in crm_prescriptions_screen.dart

// 5. Doctor Inventory
// Implemented in crm_doctors_screen.dart

// 6. Payment Receipt
// Implemented in crm_payment_receipt_screen.dart

// 7. Payment History
class CrmPaymentHistoryScreen extends StatelessWidget {
  const CrmPaymentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const CrmPlaceholderScreen(title: 'Payment History', icon: Icons.history);
}

// 8. Lab Test Billing
class CrmLabBillingScreen extends StatelessWidget {
  const CrmLabBillingScreen({super.key});
  @override
  Widget build(BuildContext context) => const CrmPlaceholderScreen(
    title: 'Lab Test Billing',
    icon: Icons.science,
  );
}

// 9. Send to Lab
// Implemented in crm_send_to_lab_screen.dart

// 10. Order Management
// Implemented in crm_orders_screen.dart
