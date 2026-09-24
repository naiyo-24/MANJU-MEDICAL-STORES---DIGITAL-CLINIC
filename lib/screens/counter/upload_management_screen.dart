import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/inventory_service.dart';
import '../../providers/counter_providers.dart';

class UploadManagementScreen extends ConsumerStatefulWidget {
  const UploadManagementScreen({super.key});

  @override
  ConsumerState<UploadManagementScreen> createState() => _UploadManagementScreenState();
}

class _UploadManagementScreenState extends ConsumerState<UploadManagementScreen> {
  bool _isUploading = false;
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(); // MRP/Selling Price
  final _buyingPriceCtrl = TextEditingController(); // Buying Price
  final _hsnCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _gstCtrl = TextEditingController(text: '0');
  PlatformFile? _selectedImage;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedImage = result.files.first;
      });
    }
  }

  Future<void> _uploadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
        });

        final message = await InventoryService.uploadInventory(result.files.single.path!);
        
        if (mounted) {
          ref.invalidate(inventoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF22C55E), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool isRequired = false, IconData? suffixIcon, TextEditingController? controller, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            readOnly: onTap != null,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 18) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF22C55E)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDropdown(String label, String hint, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hint, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context, ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 18),
                          SizedBox(width: 8),
                          Text('Back', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                      child: const Icon(Icons.medication, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Medicine', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        Text('Add a new medicine to your inventory (Master DB)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(width: 32),
                    if (_isUploading) 
                       const CircularProgressIndicator(color: Color(0xFF22C55E))
                    else
                       ElevatedButton.icon(
                         onPressed: _uploadExcel,
                         icon: const Icon(Icons.upload_file, size: 18),
                         label: const Text('Bulk Upload (Excel)'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF1E293B),
                           foregroundColor: Colors.white,
                           elevation: 0,
                         ),
                       ),
                  ],
                ),
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Better Care', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14, fontStyle: FontStyle.italic)),
                        Text('Brighter Tomorrow', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.eco, color: const Color(0xFF22C55E), size: 24),
                  ],
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Basic Information Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.medication_liquid, 'Basic Information', 'General details about the medicine'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField('Medicine Name', 'e.g. Paracetamol 500mg', isRequired: true, controller: _nameCtrl)),
                                      const SizedBox(width: 24),
                                      Expanded(child: _buildTextField('Manufacturer', 'e.g. Sun Pharma', controller: _manufacturerCtrl)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Medicine Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: _selectedImage != null
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(_selectedImage!.bytes!, fit: BoxFit.cover),
                                                ),
                                                Positioned(
                                                  right: 4,
                                                  top: 4,
                                                  child: InkWell(
                                                    onTap: () => setState(() => _selectedImage = null),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_photo_alternate, color: Color(0xFF94A3B8), size: 32),
                                                SizedBox(height: 8),
                                                Text('Upload Image', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 24),
                        // Row(
                        //   children: [
                        //     Expanded(child: _buildDropdown('Category', 'Select category', isRequired: true)),
                        //     const SizedBox(width: 24),
                        //     Expanded(child: _buildDropdown('Sub Category', 'Select sub category')),
                        //     const SizedBox(width: 24),
                        //     Expanded(child: _buildTextField('Manufacturer', 'e.g. Sun Pharma', controller: _manufacturerCtrl)),
                        //   ],
                        // ),
                        // const SizedBox(height: 24),
                        // Row(
                        //   children: [
                        //     Expanded(child: _buildTextField('Composition', 'e.g. Paracetamol 500mg')),
                        //     const SizedBox(width: 24),
                        //     Expanded(child: _buildTextField('Pack Size', 'e.g. 10 Tablets')),
                        //     const SizedBox(width: 24),
                        //     Expanded(child: _buildDropdown('Dosage Form', 'Select dosage form')),
                        //   ],
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pricing & Stock Details Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.currency_rupee, 'Pricing & Stock Details', 'Set pricing and stock information'),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Buying Price (₹)', '0.00', isRequired: true, controller: _buyingPriceCtrl)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Selling Price/MRP (₹)', '0.00', isRequired: true, controller: _priceCtrl)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Initial Stock', '0', isRequired: true, controller: _stockCtrl)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('GST (%)', '0', controller: _gstCtrl)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            // Expanded(child: _buildTextField('Minimum Stock Alert', '0')),
                            // const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Batch Number', 'e.g. B202401', controller: _batchCtrl)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                'Expiry Date',
                                'yyyy-mm-dd',
                                isRequired: true,
                                suffixIcon: Icons.calendar_today,
                                controller: _expiryCtrl,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _expiryCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                    });
                                  }
                                },
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('HSN Code', 'e.g. 3004', controller: _hsnCtrl)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Information Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.description, 'Additional Information', 'Optional details'),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildTextField('Barcode / SKU', 'Scan or enter barcode', suffixIcon: Icons.qr_code_scanner, controller: _skuCtrl),
                            ),
                            const Spacer(),
                            // const SizedBox(width: 24),
                            // Expanded(
                            //   flex: 1,
                            //   child: _buildTextField('Storage Instructions', 'e.g. Keep in a cool, dry place'),
                            // ),
                            // const SizedBox(width: 24),
                            // Expanded(
                            //   flex: 1,
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            //       const SizedBox(height: 8),
                            //       TextField(
                            //         maxLines: 3,
                            //         decoration: InputDecoration(
                            //           hintText: 'Additional notes (optional)',
                            //           hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            //           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _stockCtrl.text.isEmpty || _expiryCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                      return;
                    }
                    try {
                      setState(() => _isUploading = true);
                      
                      String? uploadedImageUrl;
                      if (_selectedImage != null && _selectedImage!.bytes != null) {
                        try {
                          uploadedImageUrl = await InventoryService.uploadMedicineImage(_selectedImage!.bytes!, _selectedImage!.name);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                            setState(() => _isUploading = false);
                          }
                          return;
                        }
                      }

                      await InventoryService.addMedicine({
                        'name': _nameCtrl.text,
                        'sku': _skuCtrl.text.isNotEmpty ? _skuCtrl.text : DateTime.now().millisecondsSinceEpoch.toString(),
                        'manufacturer': _manufacturerCtrl.text,
                        'batch_number': _batchCtrl.text.isNotEmpty ? _batchCtrl.text : 'BATCH-01',
                        'hsn_code': _hsnCtrl.text.isNotEmpty ? _hsnCtrl.text : '3004',
                        'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
                        'buying_price': double.tryParse(_buyingPriceCtrl.text) ?? 0.0,
                        'unit_price': double.tryParse(_priceCtrl.text) ?? 0.0,
                        'expiry_date': _expiryCtrl.text.isNotEmpty ? _expiryCtrl.text : '2026-12-31',
                        'gst': double.tryParse(_gstCtrl.text) ?? 0.0,
                        'image_url': ?uploadedImageUrl,
                      });
                      if (context.mounted) {
                        ref.invalidate(inventoryProvider);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine added successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add medicine: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => _isUploading = false);
                      }
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
