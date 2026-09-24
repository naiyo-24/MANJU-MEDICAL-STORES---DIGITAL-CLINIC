import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';

class LabCreateTemplateScreen extends StatefulWidget {
  final LabTemplate? existingTemplate;
  const LabCreateTemplateScreen({super.key, this.existingTemplate});

  @override
  State<LabCreateTemplateScreen> createState() => _LabCreateTemplateScreenState();
}

class _LabCreateTemplateScreenState extends State<LabCreateTemplateScreen> {
  int _selectedTab = 0;
  
  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _testNameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _remarksCtrl;

  late TextEditingController _clinicNameCtrl;
  late TextEditingController _clinicAddressCtrl;
  late TextEditingController _clinicPhoneCtrl;
  late TextEditingController _clinicEmailCtrl;
  late TextEditingController _footerColorCtrl;
  late TextEditingController _qrCodeCtrl;
  late TextEditingController _playStoreCtrl;
  
  late ReportLayoutConfig _layoutConfig;
  
  String _selectedType = 'Tabular';
  String _selectedFormat = 'A4 Portrait';
  bool _isActive = true;
  
  bool _showPatientDetails = true;
  bool _showReferrals = true;
  bool _showLabLogo = true;
  bool _showRemarksSection = false;

  List<TemplateField> _fields = [];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTemplate;
    _nameCtrl = TextEditingController(text: t?.name);
    _testNameCtrl = TextEditingController(text: t?.testName);
    _categoryCtrl = TextEditingController(text: t?.category ?? 'Hematology');
    _descCtrl = TextEditingController(text: t?.description);
    _remarksCtrl = TextEditingController(text: t?.defaultRemarks);
    
    _layoutConfig = t?.layoutConfig ?? ReportLayoutConfig();
    _clinicNameCtrl = TextEditingController(text: _layoutConfig.clinicName);
    _clinicAddressCtrl = TextEditingController(text: _layoutConfig.clinicAddress);
    _clinicPhoneCtrl = TextEditingController(text: _layoutConfig.clinicPhone);
    _clinicEmailCtrl = TextEditingController(text: _layoutConfig.clinicEmail);
    _footerColorCtrl = TextEditingController(text: _layoutConfig.footerColorHex);
    _qrCodeCtrl = TextEditingController(text: _layoutConfig.qrCodeUrl);
    _playStoreCtrl = TextEditingController(text: _layoutConfig.playStoreUrl);

    
    if (t != null) {
      _selectedType = t.type;
      _selectedFormat = t.reportFormat;
      _isActive = t.isActive;
      _showPatientDetails = t.showPatientDetails;
      _showReferrals = t.showReferrals;
      _showLabLogo = t.showLabLogo;
      _showRemarksSection = t.showRemarksSection;
      _fields = List.from(t.fields);
    } else {
      _fields = [TemplateField(name: '', unit: '', normalRange: '')];
    }
  }

  Future<void> _saveTemplate() async {
    _layoutConfig.clinicName = _clinicNameCtrl.text;
    _layoutConfig.clinicAddress = _clinicAddressCtrl.text;
    _layoutConfig.clinicPhone = _clinicPhoneCtrl.text;
    _layoutConfig.clinicEmail = _clinicEmailCtrl.text;
    _layoutConfig.footerColorHex = _footerColorCtrl.text;
    _layoutConfig.qrCodeUrl = _qrCodeCtrl.text;
    _layoutConfig.playStoreUrl = _playStoreCtrl.text;

    final template = LabTemplate(
      id: widget.existingTemplate?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      testName: _testNameCtrl.text,
      category: _categoryCtrl.text,
      type: _selectedType,
      reportFormat: _selectedFormat,
      isActive: _isActive,
      description: _descCtrl.text,
      showPatientDetails: _showPatientDetails,
      showReferrals: _showReferrals,
      showLabLogo: _showLabLogo,
      showRemarksSection: _showRemarksSection,
      defaultRemarks: _remarksCtrl.text,
      fields: _fields.where((f) => f.name.isNotEmpty).toList(),
      layoutConfig: _layoutConfig,
    );
    await LabDataService.saveTemplate(template);
    if (mounted) Navigator.pop(context, );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context, ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFFEA580C), size: 20),
                ),
                const SizedBox(width: 8),
                const Text('Templates', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 16),
                const Text('Create Template', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.description, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create / Edit Template', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text('Design custom report template for your lab test', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.visibility, color: Color(0xFF1E293B)),
                            label: const Text('Preview', style: TextStyle(color: Color(0xFF1E293B))),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), side: const BorderSide(color: Color(0xFFE2E8F0)), backgroundColor: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _saveTemplate,
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save Template'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Main Body
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 900;
                        
                        Widget leftColumn = Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                            child: Column(
                              children: [
                                // Tabs
                                Row(
                                  children: [
                                    _buildTab('Basic Information', 0),
                                    _buildTab('Add Parameters', 1),
                                    _buildTab('Layout & Design', 2),
                                    _buildTab('Footer & Notes', 3),
                                  ],
                                ),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_selectedTab == 0 || _selectedTab == 1) ...[
                                          // Form Row 1
                                          Row(
                                            children: [
                                              Expanded(child: _buildTextField('Template Name *', _nameCtrl)),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildTextField('Test Name *', _testNameCtrl)),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildDropdown('Category *', _categoryCtrl.text, ['Hematology', 'Biochemistry', 'Hormones'], (v) => setState(() => _categoryCtrl.text = v))),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Form Row 2
                                        Row(
                                          children: [
                                            Expanded(child: _buildDropdown('Template Type', _selectedType, ['Tabular', 'Descriptive'], (v) => setState(() => _selectedType = v))),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildDropdown('Report Format', _selectedFormat, ['A4 Portrait', 'A4 Landscape'], (v) => setState(() => _selectedFormat = v))),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    height: 40,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                                    child: Row(
                                                      children: [
                                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
                                                        const SizedBox(width: 8),
                                                        Expanded(child: DropdownButtonHideUnderline(
                                                          child: DropdownButton<bool>(
                                                            value: _isActive,
                                                            isExpanded: true,
                                                            items: const [
                                                              DropdownMenuItem(value: true, child: Text('Active', style: TextStyle(fontSize: 13, color: Colors.green))),
                                                              DropdownMenuItem(value: false, child: Text('Inactive', style: TextStyle(fontSize: 13, color: Colors.grey))),
                                                            ],
                                                            onChanged: (v) => setState(() => _isActive = v!),
                                                          ),
                                                        )),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField('Description (Optional)', _descCtrl, maxLines: 2),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Parameters Table
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Test Parameters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                            Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () => setState(() => _fields.add(TemplateField(name: '', unit: '', normalRange: ''))),
                                                  icon: const Icon(Icons.add, size: 16),
                                                  label: const Text('Add Parameter'),
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {},
                                                  icon: const Icon(Icons.download, size: 16),
                                                  label: const Text('Import Parameters'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Data Table Header
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          color: const Color(0xFFF8FAFC),
                                          child: Row(
                                            children: [
                                              SizedBox(width: 30, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 3, child: Text('Parameter Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Short Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Reference Range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 2, child: Text('Result Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              Expanded(flex: 1, child: Text('Decimals', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                              SizedBox(width: 80, child: Text('Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                            ],
                                          ),
                                        ),
                                        
                                        // Data Table Rows
                                        ..._fields.asMap().entries.map((entry) {
                                          final i = entry.key;
                                          final f = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 30, child: Row(children: [const Icon(Icons.drag_indicator, size: 14, color: Color(0xFF94A3B8)), const SizedBox(width: 4), Text('${i + 1}', style: const TextStyle(fontSize: 11))])),
                                                Expanded(flex: 3, child: _tableInput(f.name, (v) => _updateField(i, f, name: v))),
                                                Expanded(flex: 2, child: _tableInput(f.shortCode, (v) => _updateField(i, f, shortCode: v))),
                                                Expanded(flex: 2, child: _tableInput(f.unit, (v) => _updateField(i, f, unit: v))),
                                                Expanded(flex: 2, child: _tableInput(f.normalRange, (v) => _updateField(i, f, normalRange: v))),
                                                Expanded(flex: 2, child: Container(margin: const EdgeInsets.only(right: 8), height: 32, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: f.resultType, isExpanded: true, items: ['Numeric', 'Text'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(), onChanged: (v) => _updateField(i, f, resultType: v!))))),
                                                Expanded(flex: 1, child: _tableInput(f.decimals.toString(), (v) => _updateField(i, f, decimals: int.tryParse(v) ?? 1))),
                                                SizedBox(width: 80, child: Row(children: [
                                                  InkWell(onTap: (){}, child: const Icon(Icons.edit, size: 16, color: Color(0xFF64748B))),
                                                  const SizedBox(width: 8),
                                                  InkWell(onTap: () => setState(() => _fields.removeAt(i)), child: const Icon(Icons.delete, size: 16, color: Colors.red)),
                                                ])),
                                              ],
                                            ),
                                          );
                                        }),
                                        
                                        const SizedBox(height: 32),
                                        
                                        ],
                                        if (_selectedTab == 0 || _selectedTab == 2) ...[
                                          const SizedBox(height: 32),
                                          const Text('Clinic Details (Header)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 16),
                                          _buildTextField('Clinic Name', _clinicNameCtrl, onChanged: (v) => setState((){})),
                                          const SizedBox(height: 12),
                                          _buildTextField('Clinic Address', _clinicAddressCtrl, onChanged: (v) => setState((){})),
                                          const SizedBox(height: 12),
                                          _buildTextField('Clinic Phone', _clinicPhoneCtrl, onChanged: (v) => setState((){})),
                                          const SizedBox(height: 12),
                                          _buildTextField('Clinic Email', _clinicEmailCtrl, onChanged: (v) => setState((){})),
                                          const SizedBox(height: 24),
                                          const Text('Styling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 16),
                                          _buildTextField('Footer Color (Hex)', _footerColorCtrl, onChanged: (v) => setState((){})),
                                        ],
                                        if (_selectedTab == 0 || _selectedTab == 3) ...[
                                          const SizedBox(height: 32),
                                          const Text('Footer Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                          const SizedBox(height: 16),
                                          _buildTextField('QR Code Value', _qrCodeCtrl, onChanged: (v) => setState((){})),
                                          const SizedBox(height: 12),
                                          _buildTextField('Play Store URL', _playStoreCtrl, onChanged: (v) => setState((){})),
                                        ],
                                        
                                        const SizedBox(height: 32),
                                        if (_selectedTab == 0 || _selectedTab == 2)
                                        // Additional Options
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Additional Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                                  const SizedBox(height: 16),
                                                  _buildToggle('Show Patient Details', _showPatientDetails, (v) => setState(() => _showPatientDetails = v)),
                                                  _buildToggle('Show Referring Doctor', _showReferrals, (v) => setState(() => _showReferrals = v)),
                                                  _buildToggle('Show Lab Logo', _showLabLogo, (v) => setState(() => _showLabLogo = v)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 34),
                                                  _buildToggle('Show Referrals', _showReferrals, (v) => setState(() => _showReferrals = v)),
                                                  _buildToggle('Show Remarks Section', _showRemarksSection, (v) => setState(() => _showRemarksSection = v)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Default Remarks', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: _remarksCtrl,
                                                    maxLines: 4,
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                                      hintText: 'Enter default remarks...',
                                                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
                              ],
                            ),
                          );
                        
                        Widget rightColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Live Preview (A4 Print Layout)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4), color: Colors.white),
                                    child: Row(
                                      children: const [
                                        Text('Change Template Style', style: TextStyle(fontSize: 12)),
                                        Icon(Icons.arrow_drop_down, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white, 
                                    border: Border.all(color: const Color(0xFFE2E8F0)), 
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Mock Letterhead
                                      if (_showLabLogo) Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.1), shape: BoxShape.circle),
                                            child: const Icon(Icons.local_hospital, color: Color(0xFFEA580C), size: 32),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_clinicNameCtrl.text.isNotEmpty ? _clinicNameCtrl.text : 'SirfBill Bill Karo, Befikar Raho', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                                              Text(_clinicAddressCtrl.text.isNotEmpty ? _clinicAddressCtrl.text : '123, Main Road, Kolkata - 700001', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                              Text('Phone: ${_clinicPhoneCtrl.text}  |  Email: ${_clinicEmailCtrl.text}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(color: Color(0xFF1E293B)),
                                      const SizedBox(height: 12),
                                      const Center(child: Text('LABORATORY TEST REPORT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                                      const SizedBox(height: 16),
                                      
                                      // Patient Details Block
                                      if (_showPatientDetails) Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _DocVarRow(label: 'Patient Name', val: ': Rahul Das'),
                                              _DocVarRow(label: 'Age / Gender', val: ': 32 Years / Male'),
                                              _DocVarRow(label: 'Patient ID', val: ': P2025090901'),
                                              if (_showReferrals) _DocVarRow(label: 'Referred By', val: ': Dr. Anirban Sen'),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _DocVarRow(label: 'Sample ID', val: ': S2025099901'),
                                              _DocVarRow(label: 'Sample Type', val: ': Whole Blood'),
                                              _DocVarRow(label: 'Collection Date', val: ': 09 Sep 2026 09:30 AM'),
                                              _DocVarRow(label: 'Reporting Date', val: ': 09 Sep 2026 04:15 PM'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      Text(_testNameCtrl.text.isEmpty ? 'TEST NAME' : _testNameCtrl.text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                      const SizedBox(height: 8),
                                      
                                      // Table Title
                                      const SizedBox(height: 16),
                                      Text(_testNameCtrl.text.isNotEmpty ? _testNameCtrl.text.toUpperCase() : 'TEST NAME', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                      const SizedBox(height: 8),

                                      // Result Table
                                      Container(
                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              color: const Color(0xFFF8FAFC),
                                              child: Row(
                                                children: const [
                                                  Expanded(flex: 3, child: Text('Parameter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Result', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                  Expanded(flex: 2, child: Text('Reference Range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                                              child: Row(
                                                children: const [
                                                  Expanded(flex: 3, child: Text('Parameter', style: TextStyle(fontSize: 11))),
                                                  Expanded(flex: 2, child: Text('...', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                                                  Expanded(flex: 2, child: Text('', style: TextStyle(fontSize: 11))),
                                                  Expanded(flex: 2, child: Text('', style: TextStyle(fontSize: 11))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 48),
                                      
                                      // Signatures and QR Code
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Icon(Icons.qr_code_2, size: 40, color: Colors.black),
                                              SizedBox(height: 4),
                                              Text('Scan to verify report', style: TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                                              SizedBox(height: 2),
                                              Text('This is a computer generated report and does not require a signature.', style: TextStyle(fontSize: 6, color: Color(0xFF94A3B8))),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.draw, size: 32, color: Color(0xFF1E293B)), // Mock signature
                                              SizedBox(height: 4),
                                              SizedBox(width: 120, child: Divider(color: Color(0xFF94A3B8))),
                                              Text('Dr. Anirban Sen', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              Text('MD (Pathology)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                              Text('Reg. No.: 12345', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(color: Color(0xFFEA580C)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [Icon(Icons.phone, size: 10, color: Color(0xFFEA580C)), SizedBox(width: 4), Text('+91 98765 43210', style: TextStyle(fontSize: 8))]),
                                          Row(children: [Icon(Icons.email, size: 10, color: Color(0xFFEA580C)), SizedBox(width: 4), Text('lab@manjumedical.com', style: TextStyle(fontSize: 8))]),
                                          Row(children: [Icon(Icons.language, size: 10, color: Color(0xFFEA580C)), SizedBox(width: 4), Text('www.manjudiagnostic.com', style: TextStyle(fontSize: 8))]),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Better Care', style: TextStyle(fontSize: 10, color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                                              Text('Brighter Tomorrows', style: TextStyle(fontSize: 10, color: Color(0xFFEA580C))),
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        
                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: leftColumn),
                              const SizedBox(width: 24),
                              Expanded(flex: 4, child: rightColumn),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 600, child: leftColumn), // Fixed height to allow inner scroll
                                const SizedBox(height: 24),
                                rightColumn,
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateField(int index, TemplateField f, {String? name, String? shortCode, String? unit, String? normalRange, String? resultType, int? decimals}) {
    setState(() {
      _fields[index] = TemplateField(
        name: name ?? f.name,
        shortCode: shortCode ?? f.shortCode,
        unit: unit ?? f.unit,
        normalRange: normalRange ?? f.normalRange,
        resultType: resultType ?? f.resultType,
        decimals: decimals ?? f.decimals,
      );
    });
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFFEA580C) : Colors.transparent, width: 2))),
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(children: [TextSpan(text: label.replaceAll(' *', ''), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)), if (label.contains('*')) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontSize: 12))])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (val) {
            if (onChanged != null) onChanged(val);
            setState(() {});
          },
          maxLines: maxLines,
          decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0)))),
        ),
      ],
    );
  }
  
  // ignore: unused_element
  Widget _buildTableInput(String value, Function(String) onChanged) {
    return _tableInput(value, onChanged);
  }

  Widget _tableInput(String value, Function(String) onChanged) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 32,
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 11),
        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFE2E8F0)))),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(children: [TextSpan(text: label.replaceAll(' *', ''), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)), if (label.contains('*')) const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontSize: 12))])),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
      ],
    );
  }


  // ignore: unused_element
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor";
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return const Color(0xFFEA580C);
    }
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFEA580C),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _DocVarRow extends StatelessWidget {
  final String label;
  final String val;

  const _DocVarRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Text(val, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
