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

    return Container(
      width: 800,
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
                const Text('New Booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, )),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Details Section
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Patient Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Patient Name', border: OutlineInputBorder(), isDense: true),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        onSaved: (value) => _patientName = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), isDense: true),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        onSaved: (value) => _patientPhone = value!,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder(), isDense: true),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              onSaved: (value) => _patientAge = value!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _patientGender,
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), isDense: true),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => _patientGender = val!),
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
                      const Text('Select Tests / Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                        child: ListView(
                          children: [
                            if (_availablePackages.isNotEmpty) ...[
                              const Padding(padding: EdgeInsets.all(8.0), child: Text('Packages', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)))),
                              ..._availablePackages.map((p) => CheckboxListTile(
                                activeColor: const Color(0xFFEA580C),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('₹${p.discountedPrice.toStringAsFixed(2)}'),
                                value: _selectedPackageIds.contains(p.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) _selectedPackageIds.add(p.id);
                                    else _selectedPackageIds.remove(p.id);
                                  });
                                },
                              )),
                              const Divider(height: 1),
                            ],
                            if (_availableTests.isNotEmpty) ...[
                              const Padding(padding: EdgeInsets.all(8.0), child: Text('Individual Tests', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)))),
                              ..._availableTests.map((t) => CheckboxListTile(
                                activeColor: const Color(0xFFEA580C),
                                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('₹${t.price.toStringAsFixed(2)}'),
                                value: _selectedTestIds.contains(t.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) _selectedTestIds.add(t.id);
                                    else _selectedTestIds.remove(t.id);
                                  });
                                },
                              )),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
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
                ),
                child: const Text('Create Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
