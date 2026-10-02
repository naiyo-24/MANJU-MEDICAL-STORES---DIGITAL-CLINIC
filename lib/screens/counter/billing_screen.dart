import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:async';
import 'dart:typed_data';
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
import 'widgets/billing/customer_search_field.dart';

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

  int _selectedCategoryIndex = 0;

  final TextEditingController _discountController = TextEditingController();

  final TextEditingController _customerNameController = TextEditingController();
  final FocusNode _customerNameFocusNode = FocusNode();
  final TextEditingController _customerSearchController =
      TextEditingController();
  final FocusNode _customerSearchFocusNode = FocusNode();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerLocationController =
      TextEditingController();

  final TextEditingController _medicineSearchController = TextEditingController();

  final TextEditingController _newDoctorController = TextEditingController();

  List<Doctor> _doctorsList = [];
  String? _selectedDoctorId;
  String _selectedDoctorName = 'Walk-in';
  
  Timer? _searchDebounce;
  // Format is now handled by billingProvider
  String? _savedCustomerId;
  Map<String, dynamic>? _shopSettings;

  bool _isGeneratingBill = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _fetchCustomers();
    _fetchShopSettings();
    _discountController.addListener(() {
      final val = double.tryParse(_discountController.text) ?? 0.0;
      final isPerc = ref.read(billingProvider).isDiscountPercentage;
      if (ref.read(billingProvider).discountValue != val) {
        ref.read(billingProvider.notifier).updateDiscount(val, isPerc);
      }
    });
  }

  Future<void> _fetchShopSettings() async {
    try {
      _shopSettings = await ShopSettingsService.getSettings();
      // Pre-warm the PDF logo, QR code, and fonts cache to speed up the first bill generation
      PdfGenerator.preloadFonts();
      
      if (_shopSettings?['logo_url'] != null) {
        String url = _shopSettings!['logo_url'];
        if (PdfGenerator.getCachedLogoUrl() != url) {
           PdfGenerator.preloadLogo(url);
        }
      }
      if (_shopSettings?['qr_url'] != null) {
        String url = _shopSettings!['qr_url'];
        if (PdfGenerator.getCachedQrUrl() != url) {
           PdfGenerator.preloadQr(url);
        }
      }
    } catch (e) {
      debugPrint('Error fetching shop settings: $e');
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _customerNameController.dispose();
    _customerNameFocusNode.dispose();
    _customerSearchController.dispose();
    _customerSearchFocusNode.dispose();
    _customerPhoneController.dispose();
    _customerLocationController.dispose();
    _medicineSearchController.dispose();

    _newDoctorController.dispose();
    _searchDebounce?.cancel();
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

      doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
          ? _newDoctorController.text
          : ref.read(billingProvider).selectedDoctorName,
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
      location: _customerLocationController.text,
    );

    try {
      final savedCustomer = await CustomerService.saveCustomer(customer);
      if (mounted) {
        setState(() {
          _savedCustomerId = savedCustomer.id;
        });
        
        // Update both local and global customer lists
        ref.invalidate(customerProvider);
        _fetchCustomers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer saved to database successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error Saving Customer', style: TextStyle(color: Colors.red)),
                ],
              ),
              content: Text(errorMessage),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Color(0xFF166534))),
                ),
              ],
            );
          },
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

    String baseInvoice =
        _shopSettings?['shop_name']
            ?.toString()
            .replaceAll(' ', '')
            .toUpperCase() ??
        'INV';
    if (baseInvoice.length > 5) baseInvoice = baseInvoice.substring(0, 5);
    final String invoiceNo =
        '$baseInvoice${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // We wrap this in a small delay so that the FutureBuilder inside the dialog
    // has a chance to render the loading spinner FIRST before the heavy synchronous
    // PDF generation blocks the main thread.
    final futurePdfBytes = Future.delayed(const Duration(milliseconds: 50), () => PdfGenerator.generateBill(
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
      shopSettings: _shopSettings,
      doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
          ? _newDoctorController.text
          : ref.read(billingProvider).selectedDoctorName,
      paymentMethod: ref.read(billingProvider).paymentMethod,
      gstNumber: ref.read(billingProvider).gstNumber,
      format: ref.read(billingProvider).selectedFormat,
    ));

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(32),
          child: Container(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<Uint8List>(
              future: futurePdfBytes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating preview...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        key: UniqueKey(), // Force fresh render to fix Flutter Web iframe bug
                        build: (format) => snapshot.data!,
                        allowPrinting: true,
                        allowSharing: false,
                        canDebug: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        pdfFileName: 'Bill_$invoiceNo.pdf',
                        initialPageFormat: ref.read(billingProvider).selectedFormat == 'Thermal'
                            ? const PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm)
                            : ref.read(billingProvider).selectedFormat == 'A5'
                                ? PdfPageFormat.a5.landscape
                                : PdfPageFormat.a4,
                      ),
                    ),
                  ],
                );
              },
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

      String baseInvoice =
          _shopSettings?['shop_name']
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
          paymentMethod: ref.read(billingProvider).paymentMethod,
        );
      }

      // 2. Refresh Inventory, History, Accounts, and Customers to reflect new stock and transactions
      ref.invalidate(inventoryProvider);
      ref.invalidate(billingInventoryProvider);
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
        shopSettings: _shopSettings,
        doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
            ? _newDoctorController.text
            : ref.read(billingProvider).selectedDoctorName,
        paymentMethod: ref.read(billingProvider).paymentMethod,
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
          customerLocation: _customerLocationController.text,
          customerGstin: ref.read(billingProvider).gstNumber,
          doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
              ? _newDoctorController.text
              : ref.read(billingProvider).selectedDoctorName,
          paymentMode: ref.read(billingProvider).paymentMethod,
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

      // Dismiss the loading dialog
      if (dialogContext != null && dialogContext!.mounted) {
        final ctx = dialogContext!;
        dialogContext = null;
        Navigator.pop(ctx);
      }
      
      if (mounted) {
        setState(() {
          _isGeneratingBill = false;
        });
      }

      // Wait a tiny bit to allow the pop animation to finish, preventing !_debugLocked crash
      await Future.delayed(const Duration(milliseconds: 200));

      // Show the native print dialog for the user to print the final bill immediately!
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Bill_$invoiceNo.pdf',
        );
      }

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
        final ctx = dialogContext!;
        dialogContext = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctx.mounted) {
            Navigator.pop(ctx);
          }
        });
      }
      if (mounted) {
        setState(() {
          _isGeneratingBill = false;
        });
      }
    }
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
      _customerLocationController.clear();
      _customerSearchController.clear();
      _discountController.clear();
      _newDoctorController.clear();
      _savedCustomerId = null;
      _selectedDoctorId = null;
      _selectedDoctorName = 'Walk-in';
      _selectedCategoryIndex = 0;
    });
    ref.read(billingProvider.notifier).updateDiscount(0.0, false);
    
    // Refresh inventory, doctors, and customers
    ref.read(billingInventoryProvider.notifier).loadInventory();
    _fetchDoctors();
    _fetchCustomers();
  }

  void _addToCart(Map<String, dynamic> item) async {
    final stock = item['stock'] ?? 0;

    final existingIndex = _currentBill.indexWhere(
      (element) => element['name'] == item['name'],
    );

    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['name'].toString().split(' - Item')[0]} is already in the cart!'),
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
              '${item['name'].toString().split(' - Item')[0]} is currently out of stock and cannot be added to the bill.',
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

      double mrp = (item['mrp'] as num?)?.toDouble() ?? 0.0;
      double discount = (item['discount'] as num?)?.toDouble() ?? 0.0;
      double totalAfterDiscount = mrp - (mrp * (discount / 100));

      int packSize = (item['pack_size'] as num?)?.toInt() ?? 1;
      bool isLoose = false;

      if (packSize > 1) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Quantity Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            content: Text('Do you want to add ${item['name'].toString().split(' - Item')[0]} as a Full Strip or Loose Pieces?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Loose Pieces', style: TextStyle(color: Color(0xFF166534))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534)),
                child: const Text('Full Strip', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (result == null) return;
        isLoose = result;
      }

      ref.read(billingProvider.notifier).addItem({
        'inventory_item_id': item['inventory_item_id'],
        'name': item['name'],
        'brand': item['brand'],
        'qty': 1,
        'price': mrp,
        'mrp': mrp,
        'total': totalAfterDiscount,
        'batch': (item['batch_number'] != null && item['batch_number'].toString().isNotEmpty) 
            ? item['batch_number'] 
            : (item['batch'] ?? '-'),
        'expiry': (item['expiry_date'] != null && item['expiry_date'].toString().isNotEmpty) 
            ? item['expiry_date'] 
            : (item['expiry'] ?? '-'),
        'hsn': (item['hsn_code'] != null && item['hsn_code'].toString().isNotEmpty) 
            ? item['hsn_code'] 
            : (item['hsn'] ?? '-'),
        'discount': item['discount'] ?? 0.0,
        'cgst': item['cgst'] ?? 0,
        'sgst': item['sgst'] ?? 0,
        'stock': stock,
        'pack_size': item['pack_size'] ?? 1,
        'loose_stock': item['loose_stock'] ?? 0,
        'is_loose': isLoose,
        'id': item['inventory_item_id'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${item['name'].toString().split(' - Item')[0]} to cart'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryState = ref.watch(billingInventoryProvider);
    final allMedicines = inventoryState.when(
      data: (items) {
        final mapped = items
          .map(
            (item) => {
              'inventory_item_id': item.id,
              'name': item.name,
              'brand': item.manufacturer,
              'pack': item.sku,
              'mrp': item.unitPrice,
              'stock': item.stockQuantity,
              'batch_number': item.batchNumber,
              'hsn_code': (item.hsnCode != null && item.hsnCode!.isNotEmpty) ? item.hsnCode : '-',
              'expiry_date': item.expiryDate.isNotEmpty ? item.expiryDate : '-',
              'cgst': (item.gst ?? 0.0) / 2,
              'sgst': (item.gst ?? 0.0) / 2,
              'discount': item.discount ?? 0.0,
              'category_id': item.categoryId,
              'rack_id': item.rackId,
              'pack_size': item.packSize ?? 1,
              'loose_stock': item.looseStock,
            },
          )
          .toList();

        // Sort by Expiry Date (Ascending) - FIFO principle
        mapped.sort((a, b) {
          final expA = a['expiry_date'] as String;
          final expB = b['expiry_date'] as String;
          
          if (expA == '-' && expB == '-') return 0;
          if (expA == '-') return 1; // Put missing dates at the bottom
          if (expB == '-') return -1;
          
          return expA.compareTo(expB); // YYYY-MM-DD naturally sorts correctly
        });

        return mapped;
      },
      loading: () => <Map<String, dynamic>>[],
      error: (err, stack) => <Map<String, dynamic>>[],
    );

    final categoryAsync = ref.watch(categoryProvider);
    final backendCategories = categoryAsync.value ?? [];
    final dynamicCategories = ['All', ...backendCategories.map((c) => c.name)];

    List<Map<String, dynamic>> computedFilteredMedicines = allMedicines;

    // Removed local search filtering since we will fetch from backend
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Bill',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
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
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        final selectedIndex = ref.read(billingProvider).selectedCategoryIndex;
                        String? categoryId;
                        if (selectedIndex != 0 && selectedIndex <= backendCategories.length) {
                          categoryId = backendCategories[selectedIndex - 1].id;
                        }
                        
                        ref.read(billingInventoryProvider.notifier).loadInventory(
                          searchQuery: _medicineSearchController.text.isNotEmpty
                              ? _medicineSearchController.text
                              : null,
                          categoryId: categoryId,
                        );
                        _fetchDoctors();
                        _fetchCustomers();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refreshed inventory and data.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF64748B),
                      ),
                      tooltip: 'Refresh',
                    ),
                  ],
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
                      850; // Use the tested safe threshold

                  Widget leftSide = inventoryState.when(
                    data: (items) => BillingLeftPanel(
                      isDesktopWidth: isDesktopWidth,
                      hasEnoughHeight: hasEnoughHeight,
                      filteredMedicines: computedFilteredMedicines,
                      categories: dynamicCategories,
                      selectedCategoryIndex: ref
                          .watch(billingProvider)
                          .selectedCategoryIndex,
                      onAddToCart: _addToCart,
                      onCategorySelected: (index) {
                        ref.read(billingProvider.notifier).updateCategory(index);
                        
                        String? categoryId;
                        if (index != 0 && index <= backendCategories.length) {
                          categoryId = backendCategories[index - 1].id;
                        }
                        
                        ref.read(billingInventoryProvider.notifier).loadInventory(
                          searchQuery: _medicineSearchController.text,
                          categoryId: categoryId,
                        );
                      },
                      hasMore: ref.read(billingInventoryProvider.notifier).hasMore,
                      onLoadMore: () {
                        ref.read(billingInventoryProvider.notifier).loadMore();
                      },
                      searchController: _medicineSearchController,
                      onSearch: (q) {
                        ref
                            .read(billingInventoryProvider.notifier)
                            .loadInventory(searchQuery: q);
                      },
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            err.toString(),
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(billingInventoryProvider.notifier).loadInventory(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
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
                    onUpdateItemDiscount: (index, disc) {
                      ref.read(billingProvider.notifier).updateItemDiscount(index, disc);
                    },
                    onToggleLoose: (index) {
                      ref.read(billingProvider.notifier).toggleItemLoose(index);
                    },
                    onSaveCustomerToDb: _saveCustomerToDb,
                    onSaveDraft: _saveDraft,
                    onShowDraftsDialog: _showDraftsDialog,
                    onShowBillPreview: _showBillPreview,
                    onGenerateBill: _generateAndSaveBill,
                                        customerSearchField: CustomerSearchField(
                      searchController: _customerSearchController,
                      searchFocusNode: _customerSearchFocusNode,
                      allCustomers: _allCustomers,
                      onCustomerSelected: (selection) {
                        if (selection.id == 'NO_DATA') return;
                        _customerNameController.text = selection.name;
                        _customerPhoneController.text = selection.phone;
                        _customerLocationController.text = selection.location;
                        _customerSearchController.clear();
                        setState(() {
                          _savedCustomerId = selection.id;
                        });
                      },
                    ),
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

}
