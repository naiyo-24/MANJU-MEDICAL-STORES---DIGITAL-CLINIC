import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:async';
import '../../services/customer_service.dart';
import '../../services/billing_service.dart';
import '../../services/doctor_service.dart';
import '../../services/draft_service.dart';
import '../../services/billing_history_service.dart';
import '../../utils/pdf_generator.dart';
import '../../services/shop_settings_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/billing_provider.dart';
import '../../providers/counter_providers.dart';
import 'widgets/billing/billing_left_panel.dart';
import 'widgets/billing/billing_right_panel.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  List<Map<String, dynamic>> get _currentBill =>
      ref.watch(billingProvider).currentBill;

  List<Customer> _allCustomers = [];


  // Modifiable Data for Current Bill

  final List<String> _categories = [
    'All',
    'Tablets',
    'Capsules',
    'Syrups',
    'Injections',
    'Ointments',
    'Others',
  ];
  int _selectedCategoryIndex = 0;

  final TextEditingController _discountController = TextEditingController();

  final TextEditingController _customerNameController = TextEditingController();
  final FocusNode _customerNameFocusNode = FocusNode();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerLocationController =
      TextEditingController();

  final String _paymentMethod = 'CASH'; // CASH, UPI, CARD

  final TextEditingController _newDoctorController = TextEditingController();

  List<Doctor> _doctorsList = [];
  String? _selectedDoctorId;
  String _selectedDoctorName = 'Walk-in';

  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  // Format is now handled by billingProvider
  String? _savedCustomerId;

  bool _isGeneratingBill = false;

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchDoctors();
    _fetchCustomers();
    _discountController.addListener(() {
      final val = double.tryParse(_discountController.text) ?? 0.0;
      final isPerc = ref.read(billingProvider).isDiscountPercentage;
      if (ref.read(billingProvider).discountValue != val) {
        ref.read(billingProvider.notifier).updateDiscount(val, isPerc);
      }
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
    _customerNameFocusNode.dispose();
    _customerPhoneController.dispose();
    _customerLocationController.dispose();

    _newDoctorController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot save empty draft')));
      return;
    }

    final draft = DraftBill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerAge: '',

      doctorName: _selectedDoctorId == 'new'
          ? _newDoctorController.text
          : _selectedDoctorName,
      format: ref.read(billingProvider).selectedFormat,
      items: List.from(_currentBill),
      discountValue: ref.read(billingProvider).discountValue,
      isDiscountPercentage: ref.read(billingProvider).isDiscountPercentage,
      createdAt: DateTime.now(),
    );

    await DraftService.saveDraft(draft);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bill saved as draft!')));
      ref.read(billingProvider.notifier).clearBill();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerLocationController.clear();

      _newDoctorController.clear();
      _discountController.clear();
      setState(() {});
    }
  }

  Future<void> _saveCustomerToDb() async {
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a customer name to save.')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer saved to database successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _subtotal => ref.read(billingProvider).subtotal;
  double get _discountAmount => ref.read(billingProvider).discountAmount;
  double get _gstAmount => ref.read(billingProvider).gstAmount;
  double get _grandTotal => ref.read(billingProvider).grandTotal;

  Future<void> _fetchCustomers() async {
    try {
      final customers = await CustomerService.getCustomers();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching customers: $e');
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
                  Text(
                    'Saved Drafts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: drafts.isEmpty
                    ? const Center(
                        child: Text(
                          'No drafts found.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: drafts.length,
                        itemBuilder: (context, index) {
                          final draft = drafts[index];
                          final timeStr =
                              "${draft.createdAt.day}/${draft.createdAt.month}/${draft.createdAt.year} ${draft.createdAt.hour}:${draft.createdAt.minute.toString().padLeft(2, '0')}";
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                draft.customerName.isEmpty
                                    ? 'Walk-in Customer'
                                    : draft.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Items: ${draft.items.length} • Format: ${draft.format} • $timeStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await DraftService.deleteDraft(draft.id);
                                  setDialogState(() {
                                    drafts.removeAt(index);
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  ref
                                      .read(billingProvider.notifier)
                                      .setBill(List.from(draft.items));
                                  _customerNameController.text =
                                      draft.customerName;
                                  _customerPhoneController.text =
                                      draft.customerPhone;

                                  final matchedDoctor = _doctorsList
                                      .cast<Doctor?>()
                                      .firstWhere(
                                        (d) => d?.name == draft.doctorName,
                                        orElse: () => null,
                                      );
                                  if (matchedDoctor != null) {
                                    _selectedDoctorId = matchedDoctor.id;
                                    _selectedDoctorName = matchedDoctor.name;
                                    _newDoctorController.clear();
                                  } else if (draft.doctorName.isNotEmpty &&
                                      draft.doctorName != 'Walk-in') {
                                    _selectedDoctorId = 'new';
                                    _selectedDoctorName = 'New Doctor';
                                    _newDoctorController.text =
                                        draft.doctorName;
                                  } else {
                                    _selectedDoctorId = 'walk-in';
                                    _selectedDoctorName = 'Walk-in';
                                    _newDoctorController.clear();
                                  }
                                  ref
                                      .read(billingProvider.notifier)
                                      .updateSelectedFormat(
                                        draft.format.isNotEmpty
                                            ? draft.format
                                            : 'A4',
                                      );
                                  ref
                                      .read(billingProvider.notifier)
                                      .updateDiscount(
                                        draft.discountValue,
                                        draft.isDiscountPercentage,
                                      );
                                  _discountController.text =
                                      draft.discountValue > 0
                                      ? draft.discountValue.toString()
                                      : '';
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Draft loaded successfully!'),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBillPreview() async {
    if (_currentBill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the bill first.')),
      );
      return;
    }

    Map<String, dynamic>? shopSettings;
    try {
      shopSettings = await ShopSettingsService.getSettings();
    } catch (e) {
      debugPrint('Error fetching shop settings: $e');
    }

    if (!mounted) return;

    String baseInvoice =
        shopSettings?['shop_name']
            ?.toString()
            .replaceAll(' ', '')
            .toUpperCase() ??
        'INV';
    if (baseInvoice.length > 5) baseInvoice = baseInvoice.substring(0, 5);
    final String invoiceNo =
        '$baseInvoice${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(32),
          child: Container(
            width: 800,
            height:
                MediaQuery.of(context).size.height *
                0.8, // Added height constraint to fix layout freeze
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill Preview (${ref.read(billingProvider).selectedFormat})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
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
                      customerName: _customerNameController.text.isNotEmpty
                          ? _customerNameController.text
                          : 'Walk-in Customer',
                      customerPhone: _customerPhoneController.text,
                      customerLocation: _customerLocationController.text,
                      shopSettings: shopSettings,

                      doctorName: _selectedDoctorId == 'new'
                          ? _newDoctorController.text
                          : _selectedDoctorName,
                      format: ref.read(billingProvider).selectedFormat,
                    ),
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName: 'Bill_$invoiceNo.pdf',
                    initialPageFormat:
                        ref.read(billingProvider).selectedFormat == 'Thermal'
                        ? const PdfPageFormat(
                            80 * PdfPageFormat.mm,
                            300 * PdfPageFormat.mm,
                          )
                        : ref.read(billingProvider).selectedFormat == 'A5'
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
    if (_isGeneratingBill) return; // Prevent double clicks

    if (_currentBill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the bill first.')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isGeneratingBill = true;
    });

    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx;
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Generating bill..."),
              ],
            ),
          ),
        );
      },
    );

    // Yield to the event loop so the dialog can render and start spinning
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // 0. Save Customer if new
      if (_customerNameController.text.isNotEmpty) {
        final existingCust = _allCustomers
            .where(
              (c) =>
                  c.name.toLowerCase() ==
                  _customerNameController.text.toLowerCase(),
            )
            .toList();
        if (existingCust.isNotEmpty) {
          _savedCustomerId = existingCust.first.id;
        } else {
          final newCust = await CustomerService.saveCustomer(
            Customer(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _customerNameController.text,
              phone: _customerPhoneController.text,
            ),
          );
          _savedCustomerId = newCust.id;
          _allCustomers.add(newCust); // Keep local list updated
        }
      }

      // Get shop settings for invoice number generation
      Map<String, dynamic>? shopSettings;
      try {
        shopSettings = await ShopSettingsService.getSettings();
      } catch (e) {
        debugPrint('Error fetching shop settings: $e');
      }

      String baseInvoice =
          shopSettings?['shop_name']
              ?.toString()
              .replaceAll(' ', '')
              .toUpperCase() ??
          'INV';
      if (baseInvoice.length > 5) baseInvoice = baseInvoice.substring(0, 5);
      final String invoiceNo =
          '$baseInvoice${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // 1. Send to Backend POS API
      final checkoutItems = _currentBill
          .where((item) => item['inventory_item_id'] != null)
          .toList();

      if (checkoutItems.isNotEmpty) {
        await BillingService.checkout(
          items: checkoutItems,
          totalAmount: _grandTotal,
          customerId: _savedCustomerId,
          customerName: _customerNameController.text.isNotEmpty
              ? _customerNameController.text
              : 'Walk-in Customer',
          customerPhone: _customerPhoneController.text,
          customerLocation: _customerLocationController.text,
          customerGstin: ref.read(billingProvider).gstNumber,
          invoiceNo: invoiceNo,
          paymentMethod: _paymentMethod,
        );
      }

      // 2. Refresh Inventory, History, Accounts, and Customers to reflect new stock and transactions
      ref.invalidate(inventoryProvider);
      ref.invalidate(historyProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(customerProvider);

      // 3. Generate PDF and Save/Print

      final pdfBytes = await PdfGenerator.generateBill(
        items: _currentBill,
        subtotal: _subtotal,
        discount: _discountAmount,
        tax: _gstAmount,
        grandTotal: _grandTotal,
        invoiceNumber: invoiceNo,
        customerName: _customerNameController.text.isNotEmpty
            ? _customerNameController.text
            : 'Walk-in Customer',
        customerPhone: _customerPhoneController.text,
        customerLocation: _customerLocationController.text,
        shopSettings: shopSettings,
        doctorName: _selectedDoctorId == 'new'
            ? _newDoctorController.text
            : _selectedDoctorName,
        paymentMethod: _paymentMethod,
        gstNumber: ref.read(billingProvider).gstNumber,
        format: ref.read(billingProvider).selectedFormat,
      );

      await FileSaver.instance.saveFile(
        name: 'Bill_$invoiceNo',
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Bill generated and saved successfully! Preparing to print...',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Save to local billing history FIRST
      await BillingHistoryService.saveBill(
        SavedBill(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          invoiceNo: invoiceNo,
          customerName: _customerNameController.text.isNotEmpty
              ? _customerNameController.text
              : 'Walk-in Customer',
          customerPhone: _customerPhoneController.text,
          doctorName: _selectedDoctorId == 'new'
              ? _newDoctorController.text
              : _selectedDoctorName,
          subtotal: _subtotal,
          discount: _discountAmount,
          tax: _gstAmount,
          grandTotal: _grandTotal,
          items: List.from(_currentBill),
          createdAt: DateTime.now(),
          format: ref.read(billingProvider).selectedFormat,
        ),
      );

      // Clear after successful checkout
      _clearCart();

      // Dismiss the loading dialog BEFORE printing to prevent it from getting stuck behind the print dialog
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
        dialogContext = null;
      }
      if (mounted) {
        setState(() {
          _isGeneratingBill = false;
        });
      }

      // Do NOT await this, so execution doesn't block if the print preview stays open
      Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Bill_$invoiceNo.pdf',
      );

      return; // Exit here since we already cleaned up
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error generating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Fallback cleanup in case of errors
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        setState(() {
          _isGeneratingBill = false;
        });
      }
    }
  }

  // ignore: unused_element
  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'New Customer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Name *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. John Doe',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Phone Number *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+91 00000 00000',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. 123 Main St',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Customer ${nameController.text} added successfully!',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Customer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  void _increaseQty(int index) {
    final stock = _currentBill[index]['stock'];
    final currentQty = _currentBill[index]['qty'];
    final itemName = _currentBill[index]['name'];

    if (stock != null && currentQty >= stock) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Stock Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Cannot add more $itemName. Only $stock available in stock.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ref
        .read(billingProvider.notifier)
        .updateItemQuantity(index, _currentBill[index]['qty'] + 1);
  }

  void _decreaseQty(int index) {
    if (_currentBill[index]['qty'] > 1) {
      ref
          .read(billingProvider.notifier)
          .updateItemQuantity(index, _currentBill[index]['qty'] - 1);
    }
  }

  void _removeItem(int index) {
    ref.read(billingProvider.notifier).removeItem(index);
  }

  void _clearCart() {
    ref.read(billingProvider.notifier).clearBill();
    setState(() {
      _customerNameController.clear();
      _customerPhoneController.clear();
      _savedCustomerId = null;
    });
  }

  void _addToCart(Map<String, dynamic> item) {
    final stock = item['stock'] ?? 0;

    final existingIndex = _currentBill.indexWhere(
      (element) => element['name'] == item['name'],
    );

    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['name']} is already in the cart!'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    } else {
      if (stock <= 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Out of Stock',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: Text(
              '${item['name']} is currently out of stock and cannot be added to the bill.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      ref.read(billingProvider.notifier).addItem({
        'inventory_item_id': item['inventory_item_id'],
        'name': item['name'],
        'brand': item['brand'],
        'qty': 1,
        'price': item['mrp'],
        'mrp': item['mrp'],
        'total': item['mrp'],
        'batch': item['batch'] ?? '-',
        'expiry': item['expiry'] ?? '-',
        'hsn': item['hsn'] ?? '-',
        'cgst': item['cgst'] ?? 0,
        'sgst': item['sgst'] ?? 0,
        'stock': stock,
        'id': item['inventory_item_id'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${item['name']} to cart'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ignore: unused_element
  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final packController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final discountController = TextEditingController();
    final gstController = TextEditingController();
    final hsnController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Custom Item',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                const Text(
                  'Item Name *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Bandage / Consultation',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Brand & SKU / Barcode
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Brand',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: brandController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Johnson',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                          const Text(
                            'SKU / Barcode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: packController,
                            decoration: InputDecoration(
                              hintText: 'e.g. 1 Box',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // HSN Code
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HSN Code',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: hsnController,
                            decoration: InputDecoration(
                              hintText: 'e.g. 3004',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Container()), // Empty space for alignment
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
                          const Text(
                            'Quantity *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                          const Text(
                            'Price (₹) *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                          const Text(
                            'Discount (%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                          const Text(
                            'GST (%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: gstController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 12',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final brand = brandController.text.trim().isEmpty
                    ? 'Custom Item'
                    : brandController.text.trim();
                final qty = int.tryParse(qtyController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0.0;
                // You can use discount/gst in total calculations later if needed

                if (name.isNotEmpty && price > 0) {
                  final existingIndex = ref
                      .read(billingProvider)
                      .currentBill
                      .indexWhere((element) => element['name'] == name);
                  if (existingIndex >= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name is already in the cart!'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  ref.read(billingProvider.notifier).addItem({
                    'name': name,
                    'brand': brand,
                    'qty': qty,
                    'price': price,
                    'mrp': price,
                    'total': qty * price,
                    'batch': '-',
                    'expiry': '-',
                    'hsn': hsnController.text.isNotEmpty
                        ? hsnController.text
                        : '-',
                    'cgst': 0.0,
                    'sgst': 0.0,
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildCompactField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
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
            color: isSelected
                ? const Color(0xFF22C55E)
                : const Color(0xFFF1F5F9),
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

  // ignore: unused_element
  Widget _buildConditionalExpanded(bool isDesktop, Widget child) {
    return isDesktop
        ? Expanded(child: child)
        : SizedBox(height: 400, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final allMedicines = inventoryState.when(
      data: (items) => items
          .map(
            (item) => {
              'inventory_item_id': item.id,
              'name': item.name,
              'brand': item.manufacturer,
              'pack': item.sku,
              'mrp': item.unitPrice,
              'stock': item.stockQuantity,
              'batch': item.batchNumber,
              'hsn': item.hsnCode ?? '-',
              'expiry': item.expiryDate,
              'cgst': (item.gst ?? 0.0) / 2,
              'sgst': (item.gst ?? 0.0) / 2,
            },
          )
          .toList(),
      loading: () => <Map<String, dynamic>>[],
      error: (err, stack) => <Map<String, dynamic>>[],
    );

    List<Map<String, dynamic>> computedFilteredMedicines = allMedicines;

    int currentCatIndex = ref.watch(billingProvider).selectedCategoryIndex;
    if (currentCatIndex != 0) {
      String category = _categories[currentCatIndex];
      computedFilteredMedicines = computedFilteredMedicines
          .where((m) => m['category'] == category)
          .toList();
    }

    // Removed local search filtering since we will fetch from backend
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Bill',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Text(
                            'Create a new invoice, search medicines and add to cart',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF166534),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(_currentTime),
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTime(_currentTime),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
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

          // Main Split Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktopWidth = constraints.maxWidth > 1100;
                  bool hasEnoughHeight =
                      constraints.maxHeight >
                      400; // Lowered to ensure internal scrolling on standard laptops

                  Widget leftSide = BillingLeftPanel(
                    isDesktopWidth: isDesktopWidth,
                    hasEnoughHeight: hasEnoughHeight,
                    filteredMedicines: computedFilteredMedicines,
                    categories: _categories,
                    selectedCategoryIndex: ref
                        .watch(billingProvider)
                        .selectedCategoryIndex,
                    onAddToCart: _addToCart,
                    onCategorySelected: (index) {
                      ref.read(billingProvider.notifier).updateCategory(index);
                    },
                    hasMore: ref.read(inventoryProvider.notifier).hasMore,
                    onLoadMore: () {
                      ref.read(inventoryProvider.notifier).loadMore();
                    },
                    onSearch: (q) {

                      // Trigger backend search for pagination to work
                      ref
                          .read(inventoryProvider.notifier)
                          .loadInventory(searchQuery: q);
                    },
                  );

                  Widget rightSide = BillingRightPanel(
                    hasEnoughHeight: hasEnoughHeight,
                    discountController: _discountController,
                    customerNameController: _customerNameController,
                    customerPhoneController: _customerPhoneController,
                    customerLocationController: _customerLocationController,
                    newDoctorController: _newDoctorController,
                    doctorsList: _doctorsList,
                    onClearCart: _clearCart,
                    onDecreaseQty: _decreaseQty,
                    onIncreaseQty: _increaseQty,
                    onRemoveItem: _removeItem,
                    onSaveCustomerToDb: _saveCustomerToDb,
                    onSaveDraft: _saveDraft,
                    onShowDraftsDialog: _showDraftsDialog,
                    onShowBillPreview: _showBillPreview,
                    onGenerateBill: _generateAndSaveBill,
                    customerSearchField: _buildCustomerSearchField(),
                    isGeneratingBill: _isGeneratingBill,
                  );

                  if (isDesktopWidth) {
                    Widget content = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 13, child: leftSide),
                        const SizedBox(width: 24),
                        Expanded(flex: 9, child: rightSide),
                      ],
                    );
                    return hasEnoughHeight
                        ? content
                        : SingleChildScrollView(child: content);
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftSide,
                          const SizedBox(height: 24),
                          rightSide,
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Customer',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: RawAutocomplete<Customer>(
            textEditingController: _customerNameController,
            focusNode: _customerNameFocusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Customer>.empty();
              }
              final matches = _allCustomers.where((Customer customer) {
                return customer.name.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ) ||
                    customer.phone.contains(textEditingValue.text);
              });

              if (matches.isEmpty) {
                return [
                  Customer(
                    id: 'NO_DATA',
                    name: 'No data found',
                    phone: '',
                    location: '',
                    createdAt: DateTime.now().toIso8601String(),
                  ),
                ];
              }

              return matches;
            },
            displayStringForOption: (Customer option) => option.id == 'NO_DATA'
                ? _customerNameController.text
                : option.name,
            onSelected: (Customer selection) {
              if (selection.id == 'NO_DATA') return;
              _customerNameController.text = selection.name;
              _customerPhoneController.text = selection.phone;
              _customerLocationController.text = selection.location;
              setState(() {
                _savedCustomerId = selection.id;
              });
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      isDense: true,
                      hintText: 'Type name or phone number...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);

                        if (option.id == 'NO_DATA') {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No data found',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(option);
                            // Hide options after selection
                            FocusScope.of(context).unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  option.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  option.phone,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
