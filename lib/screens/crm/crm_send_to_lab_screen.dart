import 'package:flutter/material.dart';
import '../../models/crm_models.dart';

class CrmSendToLabScreen extends StatefulWidget {
  const CrmSendToLabScreen({super.key});

  @override
  State<CrmSendToLabScreen> createState() => _CrmSendToLabScreenState();
}

class _CrmSendToLabScreenState extends State<CrmSendToLabScreen> {
  String _activeTab = 'Popular Tests';

  final List<CrmLabTest> _catalog = [
    CrmLabTest(name: 'Complete Blood Count (CBC)', code: 'CBC', sampleType: 'Whole Blood (EDTA)', price: 400.00),
    CrmLabTest(name: 'Blood Sugar (Fasting)', code: 'BSF', sampleType: 'Serum (Fasting)', price: 120.00),
    CrmLabTest(name: 'Blood Sugar (Post Prandial)', code: 'BSPP', sampleType: 'Serum (PP)', price: 120.00),
    CrmLabTest(name: 'HbA1c (Glycated Hemoglobin)', code: 'HBA1C', sampleType: 'Whole Blood (EDTA)', price: 450.00),
    CrmLabTest(name: 'Lipid Profile', code: 'LIPID', sampleType: 'Serum', price: 700.00),
  ];

  final List<CrmLabTest> _selectedTests = [
    CrmLabTest(name: 'Complete Blood Count (CBC)', code: 'CBC', sampleType: 'Whole Blood (EDTA)', price: 400.00),
    CrmLabTest(name: 'Blood Sugar (Fasting)', code: 'BSF', sampleType: 'Serum (Fasting)', price: 120.00),
    CrmLabTest(name: 'HbA1c (Glycated Hemoglobin)', code: 'HBA1C', sampleType: 'Whole Blood (EDTA)', price: 450.00),
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
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Send to Lab', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Create and send lab test requests to partner laboratories', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Accurate Diagnostics', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              Row(
                children: const [
                  Text('Healthier Tomorrow ', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  Icon(Icons.eco, size: 16, color: Color(0xFF22C55E)),
                ],
              ),
            ],
          ),
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
                  const Text('Patient Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
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
                      Expanded(child: _buildDropdownField('Doctor (Referred By)', 'Dr. Sen')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('Appointment ID (Optional)', 'APPT000564', Icons.search)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 32),
                  
                  // Select Tests
                  const Text('Select Tests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search test by name or code (e.g. CBC, LFT, HbA1c...)',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Test'),
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
                  const SizedBox(height: 16),
                  
                  // Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab('Popular Tests'),
                        _buildTab('Hematology'),
                        _buildTab('Biochemistry'),
                        _buildTab('Serology'),
                        _buildTab('Hormone'),
                        _buildTab('Others'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Catalog Table
                  LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 800,
                          maxWidth: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                        ),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(8)), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 32),
                                    SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 3, child: Text('Test Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 1, child: Text('Test Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 1, child: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.right)),
                                    SizedBox(width: 60, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),
                              ..._catalog.asMap().entries.map((entry) {
                                final i = entry.key;
                                final test = entry.value;
                                final isSelected = _selectedTests.any((t) => t.code == test.code);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _catalog.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Icon(
                                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1),
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 32, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
                                      Expanded(flex: 3, child: Text(test.name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                      Expanded(flex: 1, child: Text(test.code, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                      Expanded(flex: 1, child: Text(test.price.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13), textAlign: TextAlign.right)),
                                      SizedBox(
                                        width: 60,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                            child: const Icon(Icons.add, size: 14, color: Color(0xFF8B5CF6)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  
                  // Selected Tests
                  const Text('Selected Tests (3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 800,
                          maxWidth: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                        ),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(8)), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 3, child: Text('Test Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 1, child: Text('Test Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 2, child: Text('Sample Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13))),
                                    Expanded(flex: 1, child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.right)),
                                    SizedBox(width: 60, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13), textAlign: TextAlign.center)),
                                  ],
                                ),
                              ),
                              ..._selectedTests.asMap().entries.map((entry) {
                                final i = entry.key;
                                final test = entry.value;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _selectedTests.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 32, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
                                      Expanded(flex: 3, child: Text(test.name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                      Expanded(flex: 1, child: Text(test.code, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                      Expanded(flex: 2, child: Text(test.sampleType, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                      Expanded(flex: 1, child: Text(test.price.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13), textAlign: TextAlign.right)),
                                      SizedBox(
                                        width: 60,
                                        child: Center(
                                          child: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 32),
                  
                  // Sample Collection Details
                  const Text('Sample Collection Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Sample Collection', 'At Clinic')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('Collection Date', '09 Sep 2026', Icons.calendar_month, iconColor: const Color(0xFF8B5CF6))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildFormField('Collection Time', '10:30 AM', null)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Notes (Optional)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Please collect the sample and process urgently. Patient is fasting.', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save as Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send to Lab'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
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
          children: [
            const Text('Lab Request Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
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
                                    Text('', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF16A34A))),
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
                        
                        // Title & Barcode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('LAB TEST REQUEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 1.2)),
                            // Mock Barcode
                            Column(
                              children: [
                                Row(
                                  children: List.generate(30, (index) => Container(
                                    width: index % 3 == 0 ? 3 : (index % 2 == 0 ? 1 : 2),
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 2),
                                    color: Colors.black,
                                  )),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Metadata Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildPreviewDetailRow('Request No.', ': LABREQ000286'),
                                  _buildPreviewDetailRow('Date', ': 09 Sep 2026, 10:24 AM'),
                                  _buildPreviewDetailRow('Patient Name', ': Rahul Das'),
                                  _buildPreviewDetailRow('Patient ID', ': PT000123'),
                                  _buildPreviewDetailRow('Age / Gender', ': 32 Years / Male'),
                                  _buildPreviewDetailRow('Phone', ': 9830011223'),
                                  _buildPreviewDetailRow('Referred By', ': Dr. Sen'),
                                  _buildPreviewDetailRow('Appointment ID', ': APPT000564'),
                                  _buildPreviewDetailRow('Sample Collection', ': At Clinic'),
                                  _buildPreviewDetailRow('Notes', ': Please collect the sample and\n  process urgently. Patient is fasting.', isMultiLine: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('To,', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  const Text('City Diagnostics Lab', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const Text('45, Park Street', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                  const Text('Kolkata - 700016', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                  const Text('+91 9876543210', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                  const Text('reports@citydiagnostics.in', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Sample Collection', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                        SizedBox(height: 4),
                                        Text('09 Sep 2026, 10:30 AM', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Test Table
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
                                    Expanded(flex: 3, child: Text('Test Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                                    Expanded(flex: 1, child: Text('Test Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                                    Expanded(flex: 2, child: Text('Sample Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E3A8A)))),
                                  ],
                                ),
                              ),
                              ..._selectedTests.asMap().entries.map((entry) {
                                final i = entry.key;
                                final test = entry.value;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _selectedTests.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 20, child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 3, child: Text(test.name, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 1, child: Text(test.code, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
                                      Expanded(flex: 2, child: Text(test.sampleType, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        const Text('Kindly share the report via email or our online portal. For any queries, please contact us.', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B))),
                        const SizedBox(height: 64),
                        
                        // Signatures
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Care Together', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF8B5CF6))),
                                Row(
                                  children: [
                                    Text('For A Healthier Tomorrow ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF8B5CF6))),
                                    Icon(Icons.eco, size: 14, color: Color(0xFF22C55E)),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Signature', style: TextStyle(fontFamily: 'cursive', fontSize: 20, color: Color(0xFF475569))),
                                Container(width: 120, height: 1, color: Colors.black),
                                const SizedBox(height: 4),
                                const Text('Authorized Signature', style: TextStyle(fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // Purple Footer Strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: const Color(0xFFF3E8FF),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Thank you for your support in delivering better healthcare.', style: TextStyle(fontSize: 10, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w500)),
                        SizedBox(width: 8),
                        Icon(Icons.favorite, size: 12, color: Color(0xFF8B5CF6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildTab(String title) {
    final isSelected = _activeTab == title;
    return InkWell(
      onTap: () => setState(() => _activeTab = title),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

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

  Widget _buildPreviewDetailRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }
}
