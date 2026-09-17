import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/shop_settings_service.dart';
import '../../utils/responsive.dart';

class BillCustomizationScreen extends StatefulWidget {
  const BillCustomizationScreen({super.key});

  @override
  State<BillCustomizationScreen> createState() => _BillCustomizationScreenState();
}

class _BillCustomizationScreenState extends State<BillCustomizationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _shopNameCtrl = TextEditingController();
  final TextEditingController _taglineCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _landlineCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _gstCtrl = TextEditingController();

  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _branchNameCtrl = TextEditingController();
  final TextEditingController _acHolderCtrl = TextEditingController();
  final TextEditingController _acNumberCtrl = TextEditingController();
  final TextEditingController _ifscCtrl = TextEditingController();

  final TextEditingController _terms1Ctrl = TextEditingController();
  final TextEditingController _terms2Ctrl = TextEditingController();
  final TextEditingController _terms3Ctrl = TextEditingController();

  String? _logoUrl;
  String? _qrUrl;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final settings = await ShopSettingsService.getSettings();
      setState(() {
        _shopNameCtrl.text = settings['shop_name'] ?? '';
        _taglineCtrl.text = settings['tagline'] ?? '';
        _addressCtrl.text = settings['address'] ?? '';
        _phoneCtrl.text = settings['phone'] ?? '';
        _landlineCtrl.text = settings['landline'] ?? '';
        _emailCtrl.text = settings['email'] ?? '';
        _gstCtrl.text = settings['gst_number'] ?? '';

        _bankNameCtrl.text = settings['bank_name'] ?? '';
        _branchNameCtrl.text = settings['branch_name'] ?? '';
        _acHolderCtrl.text = settings['ac_holder_name'] ?? '';
        _acNumberCtrl.text = settings['ac_number'] ?? '';
        _ifscCtrl.text = settings['ifsc_code'] ?? '';

        _terms1Ctrl.text = settings['terms_1'] ?? 'Medicines once sold will not be taken back.';
        _terms2Ctrl.text = settings['terms_2'] ?? 'Store in cool and dry place.';
        _terms3Ctrl.text = settings['terms_3'] ?? '';

        _logoUrl = settings['logo_url'];
        _qrUrl = settings['qr_url'];
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading settings: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ShopSettingsService.updateSettings({
        'shop_name': _shopNameCtrl.text,
        'tagline': _taglineCtrl.text,
        'address': _addressCtrl.text,
        'phone': _phoneCtrl.text,
        'landline': _landlineCtrl.text,
        'email': _emailCtrl.text,
        'gst_number': _gstCtrl.text,
        'bank_name': _bankNameCtrl.text,
        'branch_name': _branchNameCtrl.text,
        'ac_holder_name': _acHolderCtrl.text,
        'ac_number': _acNumberCtrl.text,
        'ifsc_code': _ifscCtrl.text,
        'terms_1': _terms1Ctrl.text,
        'terms_2': _terms2Ctrl.text,
        'terms_3': _terms3Ctrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop settings saved successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _isSaving = true);
      try {
        final url = isLogo 
            ? await ShopSettingsService.uploadLogo(result.files.single.bytes!, result.files.single.name)
            : await ShopSettingsService.uploadQr(result.files.single.bytes!, result.files.single.name);
        setState(() {
          if (isLogo) _logoUrl = url;
          else _qrUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bill Customization', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: ResponsiveSplitView(
                  leftPane: Column(
                    children: [
                      Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Shop Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 16),
                                  _buildTextField('Shop Name', _shopNameCtrl),
                                  _buildTextField('Tagline', _taglineCtrl),
                                  _buildTextField('Address', _addressCtrl, maxLines: 2),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField('Phone', _phoneCtrl)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField('Landline', _landlineCtrl)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField('Email', _emailCtrl)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField('GST Number', _gstCtrl)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Terms & Conditions (Footer)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 16),
                                  _buildTextField('Term 1', _terms1Ctrl),
                                  _buildTextField('Term 2', _terms2Ctrl),
                                  _buildTextField('Term 3', _terms3Ctrl),
                                ],
                              ),
                            ),
                          ),
                  ),
                  rightPane: Column(
                    children: [
                      Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 16),
                                  _buildTextField('Bank Name', _bankNameCtrl),
                                  _buildTextField('Branch Name', _branchNameCtrl),
                                  _buildTextField('A/C Holder Name', _acHolderCtrl),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField('Account Number', _acNumberCtrl)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField('IFSC Code', _ifscCtrl)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Media (Logo & UPI QR)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text('Shop Logo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 120, height: 120,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: _logoUrl != null 
                                              ? Image.network('http://127.0.0.1:8000$_logoUrl', fit: BoxFit.contain)
                                              : const Icon(Icons.image, size: 40, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(onPressed: () => _pickImage(true), icon: const Icon(Icons.upload), label: const Text('Upload'))
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text('UPI QR Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 120, height: 120,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: _qrUrl != null 
                                              ? Image.network('http://127.0.0.1:8000$_qrUrl', fit: BoxFit.contain)
                                              : const Icon(Icons.qr_code, size: 40, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(onPressed: () => _pickImage(false), icon: const Icon(Icons.upload), label: const Text('Upload'))
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
