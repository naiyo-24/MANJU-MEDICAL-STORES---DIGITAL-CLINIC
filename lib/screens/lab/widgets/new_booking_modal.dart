import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/lab_models.dart';
import '../../../services/lab_data_service.dart';

class NewBookingModal extends StatefulWidget {
  final VoidCallback onBookingCreated;

  const NewBookingModal({super.key, required this.onBookingCreated});

  @override
  State<NewBookingModal> createState() => _NewBookingModalState();
}

class _NewBookingModalState extends State<NewBookingModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Patient details
  String _patientName = '';
  String _patientPhone = '';
  String _patientAge = '';
  String _patientGender = 'Male';

  // Selection
  List<LabTest> _availableTests = [];
  List<LabPackage> _availablePackages = [];
  
  final Set<String> _selectedTestIds = {};
  final Set<String> _selectedPackageIds = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tests = await LabDataService.getTests();
    final packages = await LabDataService.getPackages();
    setState(() {
      _availableTests = tests;
      _availablePackages = packages;
      _isLoading = false;
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (final id in _selectedTestIds) {
      total += _availableTests.firstWhere((t) => t.id == id).price;
    }
    for (final id in _selectedPackageIds) {
      total += _availablePackages.firstWhere((p) => p.id == id).discountedPrice;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTestIds.isEmpty && _selectedPackageIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one test or package.')));
      return;
    }

    _formKey.currentState!.save();

    final newBooking = LabBooking(
      id: const Uuid().v4(),
      patientName: _patientName,
      patientPhone: _patientPhone,
      patientAge: _patientAge,
      patientGender: _patientGender,
      bookingDate: DateTime.now(),
      testIds: _selectedTestIds.toList(),
      packageIds: _selectedPackageIds.toList(),
      totalAmount: _calculateTotal(),
      status: 'Pending',
    );

    await LabDataService.saveBooking(newBooking);
    widget.onBookingCreated();
    if (mounted) Navigator.pop(context, );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFFEA580C))));
    }

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFE5E7E2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );

    return Container(
      width: 800,
      decoration: BoxDecoration(
        color: const Color(0xFFEBECE7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close, color: Color(0xFF64748B)), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Details Section
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Patient Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: inputDecoration.copyWith(hintText: 'Patient Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        onSaved: (value) => _patientName = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: inputDecoration.copyWith(hintText: 'Phone Number'),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        onSaved: (value) => _patientPhone = value!,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: inputDecoration.copyWith(hintText: 'Age'),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              onSaved: (value) => _patientAge = value!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _patientGender,
                                  decoration: inputDecoration.copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                  onChanged: (val) => setState(() => _patientGender = val!),
                                ),
                                Positioned(
                                  top: -8,
                                  left: 12,
                                  child: Container(
                                    color: const Color(0xFFEBECE7),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: const Text('Gender', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                const SizedBox(width: 32),
                // Tests & Packages Section
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Tests / Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_availablePackages.isNotEmpty) ...[
                              const Text('Packages', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEA580C), fontSize: 14)),
                              const SizedBox(height: 12),
                              ..._availablePackages.map((p) => _buildSelectionItem(
                                title: p.name,
                                price: p.discountedPrice,
                                isSelected: _selectedPackageIds.contains(p.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedPackageIds.add(p.id);
                                    } else {
                                      _selectedPackageIds.remove(p.id);
                                    }
                                  });
                                },
                              )),
                              const SizedBox(height: 16),
                            ],
                            if (_availableTests.isNotEmpty) ...[
                              const Text('Individual Tests', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEA580C), fontSize: 14)),
                              const SizedBox(height: 12),
                              ..._availableTests.map((t) => _buildSelectionItem(
                                title: t.name,
                                price: t.price,
                                isSelected: _selectedTestIds.contains(t.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedTestIds.add(t.id);
                                    } else {
                                      _selectedTestIds.remove(t.id);
                                    }
                                  });
                                },
                              )),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                            Text('₹${_calculateTotal().toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Create Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionItem({required String title, required double price, required bool isSelected, required Function(bool?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: onChanged,
              activeColor: Colors.transparent,
              checkColor: const Color(0xFF1E293B),
              side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }
}
