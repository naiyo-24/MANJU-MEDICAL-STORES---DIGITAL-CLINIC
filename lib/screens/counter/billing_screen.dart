import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:async';
import '../../services/inventory_service.dart';
import '../../services/customer_service.dart';
import '../../services/billing_service.dart';
import '../../services/doctor_service.dart';
import '../../services/draft_service.dart';
import '../../services/billing_history_service.dart';
import '../../utils/pdf_generator.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];

  // Modifiable Data for Current Bill
  List<Map<String, dynamic>> _currentBill = [];

  final List<String> _categories = ['All', 'Tablets', 'Capsules', 'Syrups', 'Injections', 'Ointments', 'Others'];
  int _selectedCategoryIndex = 0;

  bool _isDiscountPercentage = true;
  double _discountValue = 0.0;
  final TextEditingController _discountController = TextEditingController();
  
  bool _isGstPercentage = true;
  double _gstValue = 0.0;
  final TextEditingController _gstController = TextEditingController();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerAgeController = TextEditingController();
  final TextEditingController _newDoctorController = TextEditingController();
  
  List<Doctor> _doctorsList = [];
  String? _selectedDoctorId;
  String _selectedDoctorName = 'Walk-in';
  
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  String _selectedFormat = 'A4'; // Default format
  String? _savedCustomerId;
  
  bool _isGeneratingBill = false;

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchMedicines();
    _fetchDoctors();
    _discountController.addListener(() {
      setState(() {
        _discountValue = double.tryParse(_discountController.text) ?? 0.0;
      });
    });
    _gstController.addListener(() {
      setState(() {
        _gstValue = double.tryParse(_gstController.text) ?? 0.0;
      });
    });
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAgeController.dispose();
    _newDoctorController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }



  Future<void> _saveDraft() async {
    if (_currentBill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot save empty draft')));
      return;
    }
    
    final draft = DraftBill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerAge: _customerAgeController.text,
      doctorName: _selectedDoctorId == 'new' ? _newDoctorController.text : _selectedDoctorName,
      format: _selectedFormat,
      items: List.from(_currentBill),
      discountValue: _discountValue,
      isDiscountPercentage: _isDiscountPercentage,
      createdAt: DateTime.now(),
    );

    await DraftService.saveDraft(draft);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill saved as draft!')));
      _currentBill.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerAgeController.clear();
      _newDoctorController.clear();
      _discountValue = 0.0;
      _discountController.clear();
      setState(() {});
    }
  }

  Future<void> _saveCustomerToDb() async {
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a customer name to save.')));
      return;
    }
    
    final customer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _customerNameController.text,
      phone: _customerPhoneController.text,
    );

    try {
      final savedCustomer = await CustomerService.saveCustomer(customer);
      if (mounted) {
        setState(() {
          _savedCustomerId = savedCustomer.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer saved to database successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving customer: $e'), backgroundColor: Colors.red));
      }
    }
  }

  double get _subtotal {
    return _currentBill.fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  int get _totalItems => _currentBill.length;

  double get _discountAmount {
    if (_isDiscountPercentage) {
      return _subtotal * (_discountValue / 100);
    }
    return _discountValue;
  }
  
  double get _gstAmount {
    final amountAfterDiscount = _subtotal - _discountAmount;
    if (_isGstPercentage) {
      return amountAfterDiscount * (_gstValue / 100);
    }
    return _gstValue;
  }

  double get _grandTotal {
    return _subtotal - _discountAmount + _gstAmount;
  }

  Future<void> _fetchMedicines() async {
    try {
      final fetchedMedicines = await InventoryService.fetchInventory();
      if (mounted) {
        setState(() {
          _medicines = fetchedMedicines.map((item) => {
            'inventory_item_id': item.id,
            'name': item.name,
            'brand': item.manufacturer,
            'pack': item.sku,
            'mrp': item.unitPrice,
            'stock': item.stockQuantity,
          }).toList();
          _filteredMedicines = _medicines;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading inventory: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await DoctorService.fetchDoctors();
      if (mounted) {
        setState(() {
          _doctorsList = doctors;
        });
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    }
  }

  Future<void> _showDraftsDialog() async {
    final drafts = await DraftService.getDrafts();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.folder_open, color: Color(0xFF1E293B)),
                  SizedBox(width: 8),
                  Text('Saved Drafts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: drafts.isEmpty 
                  ? const Center(child: Text('No drafts found.', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        final timeStr = "${draft.createdAt.day}/${draft.createdAt.month}/${draft.createdAt.year} ${draft.createdAt.hour}:${draft.createdAt.minute.toString().padLeft(2, '0')}";
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(draft.customerName.isEmpty ? 'Walk-in Customer' : draft.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Items: ${draft.items.length} • Format: ${draft.format} • $timeStr', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                await DraftService.deleteDraft(draft.id);
                                setDialogState(() {
                                  drafts.removeAt(index);
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _currentBill = List.from(draft.items);
                                _customerNameController.text = draft.customerName;
                                _customerPhoneController.text = draft.customerPhone;
                                _customerAgeController.text = draft.customerAge;
                                final matchedDoctor = _doctorsList.cast<Doctor?>().firstWhere(
                                  (d) => d?.name == draft.doctorName, 
                                  orElse: () => null
                                );
                                if (matchedDoctor != null) {
                                  _selectedDoctorId = matchedDoctor.id;
                                  _selectedDoctorName = matchedDoctor.name;
                                  _newDoctorController.clear();
                                } else if (draft.doctorName.isNotEmpty && draft.doctorName != 'Walk-in') {
                                  _selectedDoctorId = 'new';
                                  _selectedDoctorName = 'New Doctor';
                                  _newDoctorController.text = draft.doctorName;
                                } else {
                                  _selectedDoctorId = 'walk-in';
                                  _selectedDoctorName = 'Walk-in';
                                  _newDoctorController.clear();
                                }
                                _selectedFormat = draft.format.isNotEmpty ? draft.format : 'A4';
                                _discountValue = draft.discountValue;
                                _isDiscountPercentage = draft.isDiscountPercentage;
                                _discountController.text = _discountValue > 0 ? _discountValue.toString() : '';
                              });
                              Navigator.pop(context, );
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft loaded successfully!')));
                            },
                          ),
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    );
  }

  Future<void> _showBillPreview() async {
    if (_currentBill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add items to the bill first.')));
      return;
    }
    
    final String invoiceNo = 'INV${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(32),
          child: Container(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.8, // Added height constraint to fix layout freeze
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill Preview ($_selectedFormat)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    build: (format) => PdfGenerator.generateBill(
                      items: _currentBill,
                      subtotal: _subtotal,
                      discount: _discountAmount,
                      tax: _gstAmount,
                      grandTotal: _grandTotal,
                      invoiceNumber: invoiceNo,
                      customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Walk-in Customer',
                      customerPhone: _customerPhoneController.text,
                      customerAge: _customerAgeController.text,
                      doctorName: _selectedDoctorId == 'new' ? _newDoctorController.text : _selectedDoctorName,
                      format: _selectedFormat,
                    ),
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: 'Bill_$invoiceNo.pdf',
                    initialPageFormat: _selectedFormat == 'Thermal' 
                        ? const PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm)
                        : _selectedFormat == 'A5' 
                            ? PdfPageFormat.a5.landscape 
                            : PdfPageFormat.a4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndSaveBill() async {
    if (_currentBill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add items to the bill first.')));
      return;
    }

    setState(() {
      _isGeneratingBill = true;
    });

    try {
      // 1. Send to Backend POS API
      final checkoutItems = _currentBill.where((item) => item['inventory_item_id'] != null).toList();
      
      if (checkoutItems.isNotEmpty) {
        await BillingService.checkout(
          items: checkoutItems,
          customerId: _savedCustomerId,
          paymentMethod: 'CASH',
        );
      }

      // 2. Refresh Inventory to reflect new stock
      await _fetchMedicines();

      // 3. Generate PDF and Save/Print
      final String invoiceNo = 'INV${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final pdfBytes = await PdfGenerator.generateBill(
        items: _currentBill,
        subtotal: _subtotal,
        discount: _discountAmount,
        tax: _gstAmount,
        grandTotal: _grandTotal,
        invoiceNumber: invoiceNo,
        customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Walk-in Customer',
        customerPhone: _customerPhoneController.text,
        customerAge: _customerAgeController.text,
        doctorName: _selectedDoctorId == 'new' ? _newDoctorController.text : _selectedDoctorName,
        format: _selectedFormat,
      );

      await FileSaver.instance.saveFile(
        name: 'Bill_$invoiceNo',
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bill generated and saved successfully! Preparing to print...'),
          backgroundColor: Colors.green,
        ));
      }

      // Save to local billing history FIRST
      await BillingHistoryService.saveBill(
        SavedBill(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          invoiceNo: invoiceNo,
          customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Walk-in Customer',
          customerPhone: _customerPhoneController.text,
          doctorName: _selectedDoctorId == 'new' ? _newDoctorController.text : _selectedDoctorName,
          subtotal: _subtotal,
          discount: _discountAmount,
          tax: _gstAmount,
          grandTotal: _grandTotal,
          items: List.from(_currentBill),
          createdAt: DateTime.now(),
        ),
      );

      // Clear after successful checkout
      _clearCart();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Bill_$invoiceNo.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error generating bill: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingBill = false;
        });
      }
    }
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. John Doe',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Phone Number *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+91 00000 00000',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. 123 Main St',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  Navigator.pop(context, );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer ${nameController.text} added successfully!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Save Customer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  void _increaseQty(int index) {
    setState(() {
      _currentBill[index]['qty'] += 1;
      _currentBill[index]['total'] = _currentBill[index]['qty'] * _currentBill[index]['price'];
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (_currentBill[index]['qty'] > 1) {
        _currentBill[index]['qty'] -= 1;
        _currentBill[index]['total'] = _currentBill[index]['qty'] * _currentBill[index]['price'];
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _currentBill.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _currentBill.clear();
    });
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingIndex = _currentBill.indexWhere((element) => element['name'] == item['name']);
      if (existingIndex >= 0) {
        _currentBill[existingIndex]['qty'] += 1;
        _currentBill[existingIndex]['total'] = _currentBill[existingIndex]['qty'] * _currentBill[existingIndex]['price'];
      } else {
        _currentBill.add({
          'inventory_item_id': item['inventory_item_id'],
          'name': item['name'],
          'brand': item['brand'],
          'qty': 1,
          'price': item['mrp'],
          'total': item['mrp'],
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${item['name']} to cart'), duration: const Duration(seconds: 1)));
  }

  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final packController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final discountController = TextEditingController();
    final gstController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Custom Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                const Text('Item Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Bandage / Consultation',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Brand & Pack Size
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Brand', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: brandController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Johnson',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pack Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: packController,
                            decoration: InputDecoration(
                              hintText: 'e.g. 1 Box',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Qty & Price
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Discount & GST
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Discount (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GST (%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: gstController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 12',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final brand = brandController.text.trim().isEmpty ? 'Custom Item' : brandController.text.trim();
                final qty = int.tryParse(qtyController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0.0;
                // You can use discount/gst in total calculations later if needed

                if (name.isNotEmpty && price > 0) {
                  setState(() {
                    _currentBill.add({
                      'name': name,
                      'brand': brand,
                      'qty': qty,
                      'price': price,
                      'total': qty * price,
                    });
                  });
                  Navigator.pop(context, );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  Widget _buildCompactField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    bool isSelected = _selectedCategoryIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Bill', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        Text('Create a new invoice, search medicines and add to cart', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF166534), size: 16),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(_currentTime), style: const TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(_formatTime(_currentTime), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Split Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Available Medicines
                  Expanded(
                    flex: 13,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          // Search & Action Row
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: TextField(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Search medicine by name, brand, barcode...',
                                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.qr_code_scanner, color: Color(0xFF64748B), size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _showAddCustomItemDialog,
                                  icon: const Icon(Icons.add, color: Color(0xFF22C55E), size: 16),
                                  label: const Text('Add Custom Item', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF22C55E)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              ],
                            ),
                          ),
                          
                          // Filters
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Available Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                InkWell(
                                  onTap: () => context.go('/counter/inventory'),
                                  child: const Text('View Stock', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _categories.asMap().entries.map((entry) => _buildFilterChip(entry.value, entry.key)).toList(),
                              ),
                            ),
                          ),

                          // Medicines Table Header
                          Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 2, child: Text('Pack Size', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 2, child: Text('MRP (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                Expanded(flex: 1, child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                                SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                              ],
                            ),
                          ),

                          // Medicines Table Body
                          Expanded(
                            child: ListView.separated(
                              itemCount: _filteredMedicines.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final item = _filteredMedicines[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 3, child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                                      Expanded(flex: 2, child: Text(item['brand'], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12))),
                                      Expanded(flex: 2, child: Text(item['pack'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                      Expanded(flex: 2, child: Text(item['mrp'].toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12))),
                                      Expanded(flex: 1, child: Text(item['stock'].toString(), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12))),
                                      SizedBox(
                                        width: 80,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _addToCart(item),
                                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF22C55E),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            minimumSize: Size.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right Side: Current Bill
                  Expanded(
                    flex: 9,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Current Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                InkWell(
                                  onTap: _clearCart,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bill Table Header
                          Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              children: [
                                SizedBox(width: 20, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                Expanded(flex: 2, child: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                Expanded(flex: 2, child: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                SizedBox(width: 45, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                              ],
                            ),
                          ),

                          // Bill Table Body
                          Expanded(
                            child: _currentBill.isEmpty
                                ? const Center(child: Text('Cart is empty', style: TextStyle(color: Color(0xFF94A3B8))))
                                : ListView.separated(
                              itemCount: _currentBill.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final item = _currentBill[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 20, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 11)),
                                            Text(item['brand'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () => _decreaseQty(index),
                                                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Icon(Icons.remove, size: 14)),
                                                ),
                                                Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                InkWell(
                                                  onTap: () => _increaseQty(index),
                                                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Icon(Icons.add, size: 14)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(flex: 2, child: Text(item['price'].toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11))),
                                      Expanded(flex: 2, child: Text(item['total'].toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11))),
                                      SizedBox(
                                        width: 45,
                                        child: InkWell(
                                          onTap: () => _removeItem(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Customer Details
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.person, color: Color(0xFF166534), size: 16),
                                          SizedBox(width: 8),
                                          Text('Customer Details (Optional)', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                      const Icon(Icons.keyboard_arrow_up, color: Color(0xFF166534), size: 16),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _buildCompactField('Name', _customerNameController)),
                                          const SizedBox(width: 8),
                                          Expanded(child: _buildCompactField('Phone', _customerPhoneController, isNumber: true)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _buildCompactField('Age', _customerAgeController, isNumber: true)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Doctor Name', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Container(
                                                  height: 32,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      value: _selectedDoctorId,
                                                      isExpanded: true,
                                                      icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
                                                      onChanged: (String? newValue) {
                                                        if (newValue != null) {
                                                          setState(() {
                                                            _selectedDoctorId = newValue;
                                                            if (newValue == 'walk-in') {
                                                              _selectedDoctorName = 'Walk-in';
                                                            } else if (newValue == 'new') {
                                                              _selectedDoctorName = 'New Doctor';
                                                            } else {
                                                              final doc = _doctorsList.firstWhere((d) => d.id == newValue);
                                                              _selectedDoctorName = doc.name;
                                                            }
                                                          });
                                                        }
                                                      },
                                                      items: [
                                                        const DropdownMenuItem(value: 'walk-in', child: Text('Walk-in')),
                                                        ..._doctorsList.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.name))),
                                                        const DropdownMenuItem(value: 'new', child: Text('+ Add New Doctor')),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (_selectedDoctorId == 'new') ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    height: 32,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                                    child: TextField(
                                                      controller: _newDoctorController,
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
                                                      decoration: const InputDecoration(
                                                        hintText: 'Enter doctor name',
                                                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                                        border: InputBorder.none,
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: _saveCustomerToDb,
                                          icon: const Icon(Icons.person_add, size: 14, color: Color(0xFF22C55E)),
                                          label: const Text('Save to DB', style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                                            minimumSize: Size.zero,
                                            backgroundColor: const Color(0xFFDCFCE7),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bill Summary
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Items', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('$_totalItems', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('₹ ${_subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Discount', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(() => _isDiscountPercentage = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: _isDiscountPercentage ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                        child: Text('%', style: TextStyle(color: _isDiscountPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 60,
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                      child: TextField(
                                        controller: _discountController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          hintText: '0.00',
                                          hintStyle: TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(() => _isDiscountPercentage = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(color: !_isDiscountPercentage ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                        child: Text('₹', style: TextStyle(color: !_isDiscountPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text('- ₹ ${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Tax (GST)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Container(
                                          height: 24,
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () => setState(() => _isGstPercentage = true),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: _isGstPercentage ? const Color(0xFF22C55E) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                                                  child: Text('%', style: TextStyle(color: _isGstPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => setState(() => _isGstPercentage = false),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: !_isGstPercentage ? const Color(0xFF22C55E) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                                                  child: Text('₹', style: TextStyle(color: !_isGstPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 60,
                                          height: 24,
                                          child: TextField(
                                            controller: _gstController,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(fontSize: 12),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text('₹ ${_gstAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Grand Total', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('₹ ${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 16)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text('Format:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: ['A4', 'A5', 'Thermal'].map((format) {
                                            bool isSelected = _selectedFormat == format;
                                            return Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedFormat = format;
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: isSelected ? [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.05),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ] : null,
                                                  ),
                                                  child: Text(
                                                    format,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _showDraftsDialog,
                                        icon: const Icon(Icons.folder_open, color: Color(0xFF1E293B), size: 16),
                                        label: const Text('Drafts', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2E8F0)), padding: const EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _saveDraft,
                                        icon: const Icon(Icons.save, color: Color(0xFF1E293B), size: 16),
                                        label: const Text('Save Draft', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2E8F0)), padding: const EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _showBillPreview,
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: _isGeneratingBill ? null : _generateAndSaveBill,
                                        icon: _isGeneratingBill 
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.print, size: 16),
                                        label: Text(_isGeneratingBill ? 'Generating...' : 'Generate Bill', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
