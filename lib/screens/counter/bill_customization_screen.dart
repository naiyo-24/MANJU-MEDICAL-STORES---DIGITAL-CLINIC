import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/settings_models.dart';

import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../services/shop_settings_service.dart';
import '../../utils/responsive.dart';
import '../../utils/pdf_generator.dart';
import '../../config/api_constants.dart';
import 'package:dio/dio.dart';
import '../../config/api_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';

class BillCustomizationScreen extends ConsumerStatefulWidget {
  const BillCustomizationScreen({super.key});

  @override
  ConsumerState<BillCustomizationScreen> createState() => _BillCustomizationScreenState();
}

class _BillCustomizationScreenState extends ConsumerState<BillCustomizationScreen> {
  bool _isSaving = false;
  bool _isGenerating = false;

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

  String _previewFormat = 'A4';
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final settings = await ref.read(settingsProvider.future);
        _populateFields(settings);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading settings: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  void _populateFields(Map<String, dynamic> settings) {
    if (!mounted) return;
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

      _terms1Ctrl.text = settings['terms_1'] ?? '';
      _terms2Ctrl.text = settings['terms_2'] ?? '';
      _terms3Ctrl.text = settings['terms_3'] ?? '';

      _logoUrl = settings['logo_url'];
      _qrUrl = settings['qr_url'];
    });
  }

  Future<void> _saveSettings() async {
    final gst = _gstCtrl.text.trim();
    if (gst.isNotEmpty && !RegExp(r'^[A-Za-z0-9]{15}$').hasMatch(gst)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GST Number must be exactly 15 alphanumeric characters'), backgroundColor: Colors.red),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone Number must be exactly 10 digits'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
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
      };

      await ref.read(settingsProvider.notifier).updateSettings(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      try {
        final bytes = result.files.single.bytes!;
        final filename = result.files.single.name;
        String url;
        if (isLogo) {
          url = await ShopSettingsService.uploadLogo(bytes, filename);
          setState(() => _logoUrl = url);
        } else {
          url = await ShopSettingsService.uploadQr(bytes, filename);
          setState(() => _qrUrl = url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Local cache for images
  static Uint8List? _cachedDefaultLogo;
  static Uint8List? _cachedLogoBytes;
  static String? _cachedLogoUrl;
  static Uint8List? _cachedQrBytes;
  static String? _cachedQrUrl;

  Future<void> _generatePreviewPdf() async {
    setState(() {
      _isGenerating = true;
    });

    // Show loading dialog with spinning animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating Preview...'),
          ],
        ),
      ),
    );

    // Fetch images asynchronously without blocking UI thread
    Uint8List? finalLogoBytes;
    Uint8List? finalQrBytes;

    try {
      if (_logoUrl != null && _logoUrl!.isNotEmpty) {
        if (_cachedLogoUrl == _logoUrl && _cachedLogoBytes != null) {
          finalLogoBytes = _cachedLogoBytes;
        } else {
          final res = await ApiClient().dio.get(
            _logoUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.statusCode == 200) {
            _cachedLogoBytes = res.data;
            _cachedLogoUrl = _logoUrl;
            finalLogoBytes = _cachedLogoBytes;
          }
        }
      } else {
        if (_cachedDefaultLogo == null) {
          final ByteData bytes = await rootBundle.load('assets/LOGO.png');
          _cachedDefaultLogo = bytes.buffer.asUint8List();
        }
        finalLogoBytes = _cachedDefaultLogo;
      }

      if (_qrUrl != null && _qrUrl!.isNotEmpty) {
        if (_cachedQrUrl == _qrUrl && _cachedQrBytes != null) {
          finalQrBytes = _cachedQrBytes;
        } else {
          final res = await ApiClient().dio.get(
            _qrUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          if (res.statusCode == 200) {
            _cachedQrBytes = res.data;
            _cachedQrUrl = _qrUrl;
            finalQrBytes = _cachedQrBytes;
          }
        }
      }

      final settings = ShopSettings(
        shopName: _shopNameCtrl.text,
        tagline: _taglineCtrl.text,
        address: _addressCtrl.text,
        phone: _phoneCtrl.text,
        landline: _landlineCtrl.text,
        email: _emailCtrl.text,
        gstNumber: _gstCtrl.text,
        bankName: _bankNameCtrl.text,
        branchName: _branchNameCtrl.text,
        acHolderName: _acHolderCtrl.text,
        acNumber: _acNumberCtrl.text,
        ifscCode: _ifscCtrl.text,
        terms1: _terms1Ctrl.text,
        terms2: _terms2Ctrl.text,
        terms3: _terms3Ctrl.text,
      );

      final dummyItems = [
        BillItem(id: '1', name: 'Paracetamol 500mg', batch: 'B123', expiry: '12/25', hsn: '3004', qty: 2, mrp: 25.0, price: 25.0, cgst: 6, sgst: 6, total: 50.0),
        BillItem(id: '2', name: 'Amoxicillin 250mg', batch: 'B456', expiry: '10/24', hsn: '3004', qty: 1, mrp: 120.0, price: 120.0, cgst: 6, sgst: 6, total: 120.0),
        BillItem(id: '3', name: 'Cough Syrup 100ml', batch: 'C789', expiry: '05/26', hsn: '3004', qty: 1, mrp: 85.0, price: 85.0, cgst: 6, sgst: 6, total: 85.0),
      ].map((e) => e.toMap()).toList();

      final args = {
        'items': dummyItems,
        'subtotal': 170.0,
        'discount': 0.0,
        'tax': 20.4,
        'grandTotal': 190.4,
        'invoiceNumber': 'PREVIEW-001',
        'customerName': 'John Doe',
        'customerPhone': '9876543210',
        'customerLocation': 'Mumbai',
        'doctorName': 'Dr. Smith',
        'format': _previewFormat,
        'shopSettings': settings,
        'logoBytes': finalLogoBytes,
        'qrBytes': finalQrBytes,
      };

      final bytes = await PdfGenerator.generateBill(
        items: args['items'] as List<Map<String, dynamic>>,
        subtotal: args['subtotal'] as double,
        discount: args['discount'] as double,
        tax: args['tax'] as double,
        grandTotal: args['grandTotal'] as double,
        invoiceNumber: args['invoiceNumber'] as String,
        customerName: args['customerName'] as String,
        customerPhone: args['customerPhone'] as String,
        customerLocation: args['customerLocation'] as String,
        doctorName: args['doctorName'] as String,
        format: args['format'] as String,
        shopSettings: args['shopSettings'] as Map<String, dynamic>,
        logoBytes: args['logoBytes'] as Uint8List?,
        qrBytes: args['qrBytes'] as Uint8List?,
      );

      if (mounted) {
        setState(() {
          _previewBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating preview: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, int? maxLength, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    if (settingsAsync.isLoading) {
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ResponsiveSplitView(
                leftPane: SingleChildScrollView(
                  child: Column(
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
                                  Expanded(child: _buildTextField('Phone', _phoneCtrl, maxLength: 10, keyboardType: TextInputType.phone)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField('Landline', _landlineCtrl)),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField('Email', _emailCtrl)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField('GST Number', _gstCtrl, maxLength: 15)),
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
                              const Text('Terms & Conditions (Footer)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 16),
                              _buildTextField('Term 1', _terms1Ctrl),
                              _buildTextField('Term 2', _terms2Ctrl),
                              _buildTextField('Term 3', _terms3Ctrl),
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
                                          ? Image.network('${ApiConstants.baseUrl}$_logoUrl', fit: BoxFit.contain)
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
                                          ? Image.network('${ApiConstants.baseUrl}$_qrUrl', fit: BoxFit.contain)
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
                rightPane: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 16,
                          spacing: 16,
                          children: [
                            const Text('Live Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ToggleButtons(
                                  isSelected: [_previewFormat == 'Thermal', _previewFormat == 'A4', _previewFormat == 'A5'],
                                  onPressed: (index) {
                                    setState(() {
                                      _previewFormat = index == 0 ? 'Thermal' : (index == 1 ? 'A4' : 'A5');
                                      _previewBytes = null; // Clear old preview on format change
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF64748B),
                                  selectedColor: const Color(0xFF22C55E),
                                  fillColor: const Color(0xFFF1F8F5),
                                  children: const [
                                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Thermal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('A4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('A5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isGenerating ? null : _generatePreviewPdf,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Generate Preview'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _previewBytes == null
                              ? const Center(
                                  child: Text(
                                    'Click "Generate Preview" to see the bill format',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                )
                              : PdfPreview(
                                  build: (format) async => _previewBytes!,
                                  canChangePageFormat: false,
                                  canChangeOrientation: false,
                                  canDebug: false,
                                  allowPrinting: false,
                                  allowSharing: false,
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
