import 'package:flutter/material.dart';
import '../../models/crm_models.dart';

class CrmPaymentReceiptScreen extends StatefulWidget {
  const CrmPaymentReceiptScreen({super.key});

  @override
  State<CrmPaymentReceiptScreen> createState() => _CrmPaymentReceiptScreenState();
}

class _CrmPaymentReceiptScreenState extends State<CrmPaymentReceiptScreen> {
  final List<CrmReceiptItem> _items = [
    CrmReceiptItem(particulars: 'Doctor Consultation Fee', qty: 1, unitPrice: 500.00, amount: 500.00),
    CrmReceiptItem(particulars: 'Prescription Charge', qty: 1, unitPrice: 50.00, amount: 50.00),
    CrmReceiptItem(particulars: 'Select Service / Item', qty: 1, unitPrice: 0.00, amount: 0.00),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1000;
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: isDesktop 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildLeftPane()),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildRightPane()),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLeftPane(),
                          const SizedBox(height: 24),
                          _buildRightPane(),
                        ],
                      ),
                    ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Payment Receipt', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Create a new payment receipt for consultation, prescription, lab test or other services', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to List'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: const [
                    Text('A5 (148 x 210 mm)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLeftPane() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Patient Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Search Patient'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFFE9D5FF)),
                          backgroundColor: const Color(0xFFF3E8FF).withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildFormField('Patient Name *', 'Rahul Das', Icons.search)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('UHID / Patient ID', 'PT000123', null)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('Phone', '9830011223', null)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Age / Gender', '32 Years / Male')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdownField('Doctor', 'Dr. Sen')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('Appointment ID (Optional)', 'APPT000564', Icons.search)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 32),
                  
                  // Receipt Details
                  const Text('Receipt Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildFormField('Receipt No.', 'RCPT000286', Icons.refresh, iconColor: const Color(0xFF8B5CF6))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('Date & Time', '09 Sep 2026 10:15 AM', Icons.calendar_month, iconColor: const Color(0xFF8B5CF6))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdownField('Payment Mode', 'UPI')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 32),
                  
                  // Service / Item Details
                  const Text('Service / Item Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(8)), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          child: Row(
                            children: const [
                              SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                              Expanded(flex: 4, child: Text('Particulars', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Unit Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.right)),
                              SizedBox(width: 60, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        ..._items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _items.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                            child: Row(
                              children: [
                                SizedBox(width: 32, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.bold))),
                                Expanded(flex: 4, child: _buildTableDropdown(item.particulars)),
                                Expanded(flex: 1, child: _buildTableInput(item.qty.toString(), textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: _buildTableInput(item.unitPrice.toStringAsFixed(2), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: _buildTableInput(item.amount.toStringAsFixed(2), textAlign: TextAlign.right, readOnly: true)),
                                SizedBox(
                                  width: 60,
                                  child: Center(
                                    child: Icon(Icons.delete, size: 18, color: const Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Footer Area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Remarks (Optional)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              height: 80,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Thank you for choosing SirfBill Bill Karo, Befikar Raho.', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', '₹ 550.00'),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Discount', '₹ 0.00', isInput: true),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14)),
                                  Text('₹ 550.00', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 18)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Send Receipt', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildCheckbox('Print Receipt', true),
                        const SizedBox(width: 24),
                        _buildCheckbox('Send to Patient (SMS/WhatsApp)', true),
                        const SizedBox(width: 24),
                        _buildCheckbox('Send to Email', false),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B5CF6),
                            side: const BorderSide(color: Color(0xFFE9D5FF)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Generate & Preview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane() {
    return Column(
      children: [
        // Preview Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('A5 Receipt Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 16),
        
        // A5 Paper Area
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF8FAFC)),
                            child: const Center(
                              child: Text('SirfBill', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('SirfBill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                              Text('Bill Karo, Befikar Raho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                              SizedBox(height: 4),
                              Text('', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMiniIconText(Icons.location_on, '123, Main Road, Kolkata - 700016'),
                          const SizedBox(height: 4),
                          _buildMiniIconText(Icons.phone, '+91 9830011223'),
                          const SizedBox(height: 4),
                          _buildMiniIconText(Icons.email, 'info@manjumedical.in'),
                          const SizedBox(height: 4),
                          _buildMiniIconText(Icons.language, 'www.manjumedical.in'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  
                  // Receipt Title
                  const Center(
                    child: Text('PAYMENT RECEIPT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Patient Details Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildPreviewDetailRow('Receipt No.', ': RCPT000286'),
                            _buildPreviewDetailRow('Date & Time', ': 09 Sep 2026, 10:15 AM'),
                            _buildPreviewDetailRow('Patient Name', ': Rahul Das'),
                            _buildPreviewDetailRow('Patient ID', ': PT000123'),
                            _buildPreviewDetailRow('Age / Gender', ': 32 Years / Male'),
                            _buildPreviewDetailRow('Phone', ': 9830011223'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildPreviewDetailRow('Doctor', ': Dr. Sen'),
                            _buildPreviewDetailRow('Appointment ID', ': APPT000564'),
                            _buildPreviewDetailRow('Service Type', ': Consultation'),
                            _buildPreviewDetailRow('Payment Mode', ': UPI'),
                            _buildPreviewDetailRow('Transaction ID', ': UPI263456789'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 80, child: Text('Status', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold))),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(': ', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.circle, size: 4, color: Color(0xFF16A34A)),
                                              SizedBox(width: 4),
                                              Text('Paid', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Medicine Table
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          child: Row(
                            children: const [
                              SizedBox(width: 20, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                              Expanded(flex: 3, child: Text('Particulars', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)), textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('Unit Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)), textAlign: TextAlign.right)),
                              Expanded(flex: 1, child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                        _buildReceiptTableRow('1', 'Doctor Consultation Fee', '1', '500.00', '500.00'),
                        _buildReceiptTableRow('2', 'Prescription Charge', '1', '50.00', '50.00', isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Table
                  Row(
                    children: [
                      Expanded(flex: 5, child: const SizedBox()),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildPreviewSummaryRow('Subtotal', '₹ 550.00'),
                            const SizedBox(height: 8),
                            _buildPreviewSummaryRow('Discount', '₹ 0.00'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 11)),
                                  Text('₹ 550.00', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Amount in Words
                  const Text('Amount in Words :', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  const Text('Rupees Five Hundred Fifty Only', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                  const SizedBox(height: 32),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                            child: const Center(child: Icon(Icons.qr_code_2, size: 40)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Scan for digital receipt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              SizedBox(height: 8),
                              Text('Thank you for choosing', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                              Text('SirfBill Bill Karo, Befikar Raho.', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Signature', style: TextStyle(fontFamily: 'cursive', fontSize: 20, color: Color(0xFF475569))),
                          Container(width: 100, height: 1, color: Colors.black),
                          const SizedBox(height: 4),
                          const Text('Authorized Signature', style: TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Center(child: Text('Care Today   Healthier Tomorrow', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF16A34A)))),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom Toolbar
        Container(
          margin: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildToolbarBtn(Icons.chevron_left),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('1 / 1')),
                  _buildToolbarBtn(Icons.chevron_right),
                ],
              ),
              Row(
                children: [
                  _buildToolbarBtn(Icons.remove),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('100%')),
                  _buildToolbarBtn(Icons.add),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print A5'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: Size.zero,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildFormField(String label, String value, IconData? icon, {Color iconColor = const Color(0xFF94A3B8)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
              if (icon != null) Icon(icon, size: 18, color: iconColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildTableInput(String value, {TextAlign textAlign = TextAlign.left, bool readOnly = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
        textAlign: textAlign,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isInput = false}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
        if (isInput)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
            child: Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
          )
        else
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13)),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool isChecked) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFF8B5CF6) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isChecked ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1)),
          ),
          child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
      ],
    );
  }

  // Preview Helpers
  Widget _buildMiniIconText(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 10, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildPreviewDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }

  Widget _buildReceiptTableRow(String index, String particulars, String qty, String unitPrice, String amount, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text(index, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
          Expanded(flex: 3, child: Text(particulars, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
          Expanded(flex: 1, child: Text(qty, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(unitPrice, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text(amount, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPreviewSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildToolbarBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Icon(icon, size: 18, color: const Color(0xFF64748B))),
    );
  }
}
