import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubscriptionLiveClock extends StatefulWidget {
  final bool isDark;

  const SubscriptionLiveClock({super.key, required this.isDark});

  @override
  State<SubscriptionLiveClock> createState() => _SubscriptionLiveClockState();
}

class _SubscriptionLiveClockState extends State<SubscriptionLiveClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
        : const Color(0xFFF0FDF4);
    final borderColor = widget.isDark
        ? const Color(0xFF059669).withValues(alpha: 0.5)
        : const Color(0xFFBBF7D0);
    final textColor =
        widget.isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: textColor),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE, dd MMM yyyy').format(_now),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.1,
                ),
              ),
              Text(
                DateFormat('hh:mm:ss a').format(_now),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SubscriptionLicenseBanner extends StatelessWidget {
  final bool isDark;
  final String planName;
  final String validUntil;
  final int daysRemaining;
  final String latestInvoiceNo;
  final VoidCallback onViewInvoice;

  const SubscriptionLicenseBanner({
    super.key,
    required this.isDark,
    required this.planName,
    required this.validUntil,
    required this.daysRemaining,
    required this.latestInvoiceNo,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC);
    final accentColor =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF166534).withValues(alpha: 0.06),
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
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ACTIVE PHARMA LICENSE ($daysRemaining DAYS REMAINING)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      latestInvoiceNo,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                planName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Valid until $validUntil • Full Billing Counter, Lab Test & CRM Access',
                style: TextStyle(fontSize: 12.5, color: subColor),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      'Current Plan Active (${daysRemaining}d)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onViewInvoice,
                icon: Icon(Icons.receipt_long_rounded,
                    size: 16, color: titleColor),
                label: Text(
                  'Latest Tax Invoice',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
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

class SubscriptionInvoiceRecord {
  final String invoiceNo;
  final String date;
  final String planCycle;
  final String amount;
  final String paymentRef;
  final String status;

  const SubscriptionInvoiceRecord({
    required this.invoiceNo,
    required this.date,
    required this.planCycle,
    required this.amount,
    required this.paymentRef,
    required this.status,
  });
}

class SubscriptionInvoicesTable extends StatelessWidget {
  final bool isDark;
  final List<SubscriptionInvoiceRecord> invoices;
  final ValueChanged<SubscriptionInvoiceRecord> onViewInvoice;

  const SubscriptionInvoicesTable({
    super.key,
    required this.isDark,
    required this.invoices,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 18, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'Subscription & Tax Invoices',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '18% GST Compliant',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 52,
              columnSpacing: 28,
              headingTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: subColor,
              ),
              dataTextStyle: TextStyle(
                fontSize: 12.5,
                color: titleColor,
              ),
              columns: const [
                DataColumn(label: Text('Invoice #')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Plan & Cycle')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Payment Ref')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Tax Invoice')),
              ],
              rows: invoices.map((inv) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      inv.invoiceNo,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    )),
                    DataCell(Text(inv.date)),
                    DataCell(Text(inv.planCycle)),
                    DataCell(Text(
                      inv.amount,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )),
                    DataCell(Text(inv.paymentRef,
                        style: TextStyle(color: subColor))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inv.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      OutlinedButton.icon(
                        onPressed: () => onViewInvoice(inv),
                        icon: Icon(Icons.visibility_outlined,
                            size: 14, color: accentColor),
                        label: Text(
                          'View',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
