import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UploadManagementScreen extends StatelessWidget {
  const UploadManagementScreen({super.key});

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

  Widget _buildTextField(String label, String hint, {bool isRequired = false, IconData? suffixIcon}) {
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
                          children: [
                            Expanded(child: _buildTextField('Medicine Name', 'e.g. Paracetamol 500mg', isRequired: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Brand Name', 'e.g. Crocin')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Generic Name', 'e.g. Paracetamol')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildDropdown('Category', 'Select category', isRequired: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildDropdown('Sub Category', 'Select sub category')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Manufacturer', 'e.g. Sun Pharma')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Composition', 'e.g. Paracetamol 500mg')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Pack Size', 'e.g. 10 Tablets')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildDropdown('Dosage Form', 'Select dosage form')),
                          ],
                        ),
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
                            Expanded(child: _buildTextField('Purchase Price (₹)', '0.00', isRequired: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Selling Price (₹)', '0.00', isRequired: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('MRP (₹)', '0.00')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Current Stock', '0', isRequired: true)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Minimum Stock Alert', '0')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Batch Number', 'e.g. B202401')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('Expiry Date', 'dd/mm/yyyy', isRequired: true, suffixIcon: Icons.calendar_today)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('HSN Code', 'e.g. 3004')),
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
                              child: _buildTextField('Barcode / SKU', 'Scan or enter barcode', suffixIcon: Icons.qr_code_scanner),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildTextField('Storage Instructions', 'e.g. Keep in a cool, dry place'),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 8),
                                  TextField(
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Additional notes (optional)',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
                  onPressed: () {},
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
