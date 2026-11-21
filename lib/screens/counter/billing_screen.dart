import 'package:flutter/foundation.dart';
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
import '../../utils/docx_generator.dart';
import '../../utils/excel_invoice_generator.dart';
import '../../utils/file_download_helper.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/billing_provider.dart';
import '../../providers/counter_providers.dart';
import '../../providers/stock_alert_provider.dart';
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

  Timer? _timer;
  Timer? _searchDebounce;
  // Format is now handled by billingProvider
  String? _savedCustomerId;
  Map<String, dynamic>? _shopSettings;

  bool _isGeneratingBill = false;
  int _mobileTabIndex = 0; // 0: Medicines catalog, 1: Cart & Checkout
  String? _rectifyingInvoiceNo;
  String? _rectifyingBillId;

  @override
  void initState() {
    super.initState();
    _startClock();
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

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
      });
    });
  }

  Future<void> _fetchShopSettings() async {
    try {
      final settings = await ref.read(settingsProvider.future);
      if (mounted) {
        setState(() {
          _shopSettings = settings;
        });
      }
      // Pre-warm the PDF logo, QR code, and fonts cache to speed up the first bill generation
      PdfGenerator.preloadFonts();
      
      if (_shopSettings?['logo_url'] != null) {
        String url = _shopSettings!['logo_url'].toString();
        PdfGenerator.preloadLogo(url);
      }
      if (_shopSettings?['qr_url'] != null) {
        String url = _shopSettings!['qr_url'].toString();
        PdfGenerator.preloadQr(url);
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
    _timer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Invoice draft saved! You can access it anytime from the 'Draft Invoices' (auto-retained for 30 days).",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      ref.read(billingProvider.notifier).clearBill();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerLocationController.clear();

      _newDoctorController.clear();
      _discountController.clear();
      _rectifyingInvoiceNo = null;
      _rectifyingBillId = null;
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Row(
                children: [
                  Icon(Icons.folder_open, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text(
                    'Draft Invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: drafts.isEmpty
                    ? Center(
                        child: Text(
                          'No draft invoices found (auto-retained for 30 days).',
                          style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: drafts.length,
                        itemBuilder: (context, index) {
                          final draft = drafts[index];
                          final timeStr =
                              "${draft.createdAt.day}/${draft.createdAt.month}/${draft.createdAt.year} ${draft.createdAt.hour}:${draft.createdAt.minute.toString().padLeft(2, '0')}";
                          return Card(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                draft.customerName.isEmpty
                                    ? 'Walk-in Customer'
                                    : draft.customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                'Items: ${draft.items.length} • Format: ${draft.format} • $timeStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
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
                                    _newDoctorController.clear();
                                  } else if (draft.doctorName.isNotEmpty &&
                                      draft.doctorName != 'Walk-in') {
                                    _newDoctorController.text =
                                        draft.doctorName;
                                  } else {
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
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Draft invoice loaded successfully!'),
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
                  child: Text('Close', style: TextStyle(color: isDark ? Colors.white : null)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showInvoicesDialog() async {
    List<SavedBill> backendBills = [];
    bool isLoadingBackend = true;
    bool hasInitiatedFetch = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void fetchLatestInvoices() {
              setDialogState(() {
                isLoadingBackend = true;
              });

              BillingService.getPosHistory(days: 30).then((res) {
                final historyList = res['history'] as List? ?? [];
                final mapped = historyList.map((item) {
                  String dateStr = item['date']?.toString() ?? '';
                  dateStr = dateStr.replaceAll(' ', 'T');
                  if (dateStr.endsWith('Z')) dateStr = dateStr.substring(0, dateStr.length - 1);
                  final dt = DateTime.tryParse(dateStr) ?? DateTime.now();

                  final rawItems = (item['items_detail'] as List?)
                          ?.map((i) => Map<String, dynamic>.from(i))
                          .toList() ??
                      [];

                  final itemsList = rawItems.map((i) {
                    final price = (i['mrp'] as num?)?.toDouble() ??
                        (i['price'] as num?)?.toDouble() ??
                        0.0;
                    final qty = (i['qty'] as num?)?.toInt() ?? 1;
                    return <String, dynamic>{
                      'name': i['name'] ?? 'Item',
                      'qty': qty,
                      'price': price,
                      'mrp': price,
                      'total': (i['total'] as num?)?.toDouble() ?? (price * qty),
                      'batch': i['batch']?.toString() ?? '-',
                      'expiry': i['expiry']?.toString() ?? '-',
                      'hsn': i['hsn']?.toString() ?? '-',
                      'inventory_item_id': i['inventory_item_id'],
                      'is_loose': i['is_loose'] ?? false,
                    };
                  }).toList();

                  final grandTotal = (item['amount'] as num?)?.toDouble() ?? 0.0;
                  return SavedBill(
                    id: item['id']?.toString() ?? '',
                    invoiceNo: item['bill_no']?.toString() ?? item['invoice_no']?.toString() ?? 'INV',
                    customerName: item['customer_name']?.isEmpty ?? true ? 'Walk-in Customer' : item['customer_name'],
                    customerPhone: item['customer_phone']?.toString() ?? '',
                    customerLocation: item['customer_location']?.toString() ?? '',
                    customerGstin: item['customer_gstin']?.toString() ?? '',
                    doctorName: item['doctor_name']?.toString() ?? '',
                    paymentMode: item['payment_mode']?.toString() ?? 'CASH',
                    subtotal: (item['subtotal'] as num?)?.toDouble() ?? grandTotal,
                    discount: (item['discount'] as num?)?.toDouble() ?? 0.0,
                    tax: (item['tax'] as num?)?.toDouble() ?? 0.0,
                    grandTotal: grandTotal,
                    items: itemsList,
                    createdAt: dt,
                    format: item['format']?.toString() ?? 'A5',
                  );
                }).toList();

                if (dialogCtx.mounted) {
                  setDialogState(() {
                    backendBills = mapped;
                    isLoadingBackend = false;
                  });
                }
              }).catchError((_) async {
                final localBills = await BillingHistoryService.getBillingHistory();
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    backendBills = localBills;
                    isLoadingBackend = false;
                  });
                }
              });
            }

            if (!hasInitiatedFetch) {
              hasInitiatedFetch = true;
              fetchLatestInvoices();
            }

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Invoices (Recent 30 Days)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                      size: 20,
                    ),
                    tooltip: 'Refresh latest invoices',
                    onPressed: isLoadingBackend ? null : fetchLatestInvoices,
                  ),
                ],
              ),
              content: SizedBox(
                width: 650,
                height: 480,
                child: isLoadingBackend
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Fetching recent invoices from backend...'),
                          ],
                        ),
                      )
                    : backendBills.isEmpty
                        ? Center(
                            child: Text(
                              'No generated invoices found for the last 30 days.',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: backendBills.length,
                            itemBuilder: (ctx, index) {
                              final bill = backendBills[index];
                              final timeStr =
                                  "${bill.createdAt.day}/${bill.createdAt.month}/${bill.createdAt.year} ${bill.createdAt.hour}:${bill.createdAt.minute.toString().padLeft(2, '0')}";
                              return Card(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  bill.invoiceNo,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: (isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534)).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    bill.paymentMode,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Customer: ${bill.customerName.isEmpty ? "Walk-in" : bill.customerName} • Items: ${bill.items.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$timeStr • Format: ${bill.format}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${bill.grandTotal.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // RE-PRINT BUTTON
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.pop(dialogCtx);
                                                  _reprintBill(bill);
                                                },
                                                icon: const Icon(Icons.print, size: 14),
                                                label: const Text('Re-Print', style: TextStyle(fontSize: 11)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF3B82F6),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // RECTIFY / EDIT BUTTON
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.pop(dialogCtx);
                                                  _rectifyBill(bill);
                                                },
                                                icon: const Icon(Icons.edit, size: 14, color: Color(0xFFD97706)),
                                                label: const Text('Rectify', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFFD97706)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Close', style: TextStyle(color: isDark ? Colors.white : null)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _rectifyBill(SavedBill bill) {
    setState(() {
      _rectifyingInvoiceNo = bill.invoiceNo;
      _rectifyingBillId = bill.id;
      ref.read(billingProvider.notifier).setBill(List.from(bill.items));
      _customerNameController.text = bill.customerName == 'Walk-in Customer' ? '' : bill.customerName;
      _customerPhoneController.text = bill.customerPhone;
      _customerLocationController.text = bill.customerLocation;

      final matchedDoctor = _doctorsList.cast<Doctor?>().firstWhere(
            (d) => d?.name == bill.doctorName,
            orElse: () => null,
          );
      if (matchedDoctor != null) {
        _newDoctorController.clear();
      } else if (bill.doctorName.isNotEmpty && bill.doctorName != 'Walk-in') {
        _newDoctorController.text = bill.doctorName;
      } else {
        _newDoctorController.clear();
      }

      ref.read(billingProvider.notifier).updateDiscount(bill.discount, false);
      _discountController.text = bill.discount > 0 ? bill.discount.toStringAsFixed(2) : '';
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Loaded '${bill.invoiceNo}' for rectification. Make your adjustments and click 'Generate Bill' to update.",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD97706),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _reprintBill(SavedBill bill) async {
    final currentSettings = _shopSettings;
    final pdfBytes = await PdfGenerator.generateBill(
      items: bill.items,
      subtotal: bill.subtotal,
      discount: bill.discount,
      tax: bill.tax,
      grandTotal: bill.grandTotal,
      invoiceNumber: bill.invoiceNo,
      customerName: bill.customerName,
      customerPhone: bill.customerPhone,
      customerLocation: bill.customerLocation,
      shopSettings: currentSettings ?? bill.shopSettings,
      doctorName: bill.doctorName,
      paymentMethod: bill.paymentMode,
      gstNumber: bill.customerGstin,
      format: bill.format,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(32),
          child: Container(
            width: 800,
            height: MediaQuery.of(dialogCtx).size.height * 0.8,
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
                      Row(
                        children: [
                          const Icon(Icons.print, color: Color(0xFF3B82F6), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Re-Printing Invoice — ${bill.invoiceNo}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PdfPreview(
                    key: ValueKey('reprint_${bill.invoiceNo}'),
                    build: (format) => pdfBytes,
                    allowPrinting: true,
                    allowSharing: true,
                    canDebug: false,
                    initialPageFormat: bill.format == 'A4'
                        ? PdfPageFormat.a4
                        : (bill.format == 'A5' ? PdfPageFormat.a5 : PdfPageFormat.roll80),
                  ),
                ),
              ],
            ),
          ),
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

    final currentSettings = ref.read(settingsProvider).value ?? _shopSettings;
    String baseInvoice =
        currentSettings?['shop_name']
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
      shopSettings: currentSettings,
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
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534),
                                  side: const BorderSide(color: Color(0xFF166534)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.description_outlined, size: 18),
                                label: const Text('Download Word (.docx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    final logoBytes = await PdfGenerator.resolveLogoBytes(currentSettings);
                                    final qrBytes = await PdfGenerator.resolveQrBytes(currentSettings);

                                    final docxBytes = DocxGenerator.generateInvoiceDocx(
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
                                      gstNumber: ref.read(billingProvider).gstNumber,
                                      doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
                                          ? _newDoctorController.text
                                          : ref.read(billingProvider).selectedDoctorName,
                                      paymentMethod: ref.read(billingProvider).paymentMethod,
                                      shopSettings: currentSettings,
                                      billingDate: DateTime.now(),
                                      logoBytes: logoBytes,
                                      qrBytes: qrBytes,
                                    );
                                    final result = await FileDownloadHelper.saveFile(
                                      name: 'Bill_$invoiceNo',
                                      bytes: docxBytes,
                                      fileExtension: 'docx',
                                      mimeType: MimeType.microsoftWord,
                                      dialogTitle: 'Save Word Invoice',
                                    );
                                    if (context.mounted) {
                                      if (result.success) {
                                        final locationMsg = result.savedPath != null
                                            ? ' Saved to: ${result.savedPath}'
                                            : '';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Word document downloaded successfully!$locationMsg'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to save Word document: ${result.errorMessage ?? "Unknown error"}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to download Word document: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF166534),
                                  side: const BorderSide(color: Color(0xFF166534)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.table_chart_outlined, size: 18),
                                label: const Text('Download Excel (.xlsx)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    final excelBytes = ExcelInvoiceGenerator.generateInvoiceExcel(
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
                                      gstNumber: ref.read(billingProvider).gstNumber,
                                      doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
                                          ? _newDoctorController.text
                                          : ref.read(billingProvider).selectedDoctorName,
                                      paymentMethod: ref.read(billingProvider).paymentMethod,
                                      shopSettings: currentSettings,
                                      billingDate: DateTime.now(),
                                    );
                                    final result = await FileDownloadHelper.saveFile(
                                      name: 'Bill_$invoiceNo',
                                      bytes: excelBytes,
                                      fileExtension: 'xlsx',
                                      mimeType: MimeType.microsoftExcel,
                                      dialogTitle: 'Save Excel Invoice',
                                    );
                                    if (context.mounted) {
                                      if (result.success) {
                                        final locationMsg = result.savedPath != null
                                            ? ' Saved to: ${result.savedPath}'
                                            : '';
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Excel spreadsheet downloaded successfully!$locationMsg'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to save Excel spreadsheet: ${result.errorMessage ?? "Unknown error"}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to download Excel spreadsheet: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: PdfPreview(
                        key: ValueKey('billing_pdf_preview_$invoiceNo'),
                        build: (format) => snapshot.data!,
                        allowPrinting: true,
                        allowSharing: false,
                        canDebug: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        pdfFileName: 'Bill_$invoiceNo.pdf',
                        initialPageFormat: ref.read(billingProvider).selectedFormat == 'Thermal'
                            ? PdfPageFormat.roll80
                            : ref.read(billingProvider).selectedFormat == 'A5'
                                ? PdfPageFormat.a5.landscape
                                : PdfPageFormat.a4,
                        pageFormats: {
                          'A5 Landscape': PdfPageFormat.a5.landscape,
                          'A4': PdfPageFormat.a4,
                          'Thermal': PdfPageFormat.roll80,
                        },
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

      final currentSettings = ref.read(settingsProvider).value ?? _shopSettings;
      String baseInvoice =
          currentSettings?['shop_name']
              ?.toString()
              .replaceAll(' ', '')
              .toUpperCase() ??
          'INV';
      if (baseInvoice.length > 5) baseInvoice = baseInvoice.substring(0, 5);
      final String invoiceNo = _rectifyingInvoiceNo ??
          '$baseInvoice${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      // 1. Send to Backend POS API (Checkout or Rectify)
      final checkoutItems = _currentBill
          .where((item) => item['inventory_item_id'] != null)
          .toList();

      if (checkoutItems.isNotEmpty) {
        if (_rectifyingInvoiceNo != null) {
          // Dedicated atomic rectification pipeline
          await BillingService.rectifyInvoice(
            invoiceNo: invoiceNo,
            items: checkoutItems,
            totalAmount: _grandTotal,
            subtotal: _subtotal,
            totalDiscount: _discountAmount,
            totalGst: _gstAmount,
            customerId: _savedCustomerId,
            customerName: _customerNameController.text.isNotEmpty
                ? _customerNameController.text
                : 'Walk-in Customer',
            customerPhone: _customerPhoneController.text,
            customerLocation: _customerLocationController.text,
            customerGstin: ref.read(billingProvider).gstNumber,
            paymentMethod: ref.read(billingProvider).paymentMethod,
          );
        } else {
          // Standard fresh checkout pipeline
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
      }

      // 2. Refresh Inventory, History, Accounts, Customers, and Stock Alerts
      ref.invalidate(inventoryProvider);
      ref.invalidate(billingInventoryProvider);
      ref.invalidate(historyProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(customerProvider);
      ref.invalidate(stockAlertProvider);

      // Check if any checked-out items became low or out of stock to alert the user
      final lowStockNames = <String>[];
      for (final item in checkoutItems) {
        final currentStock = (item['stock_quantity'] as num?)?.toInt() ?? 0;
        final billedQty = (item['quantity'] as num?)?.toInt() ?? 0;
        final remaining = currentStock - billedQty;
        final threshold = (item['low_stock_threshold'] as num?)?.toInt() ?? 10;
        if (remaining <= threshold) {
          final medName = item['medicine_name'] ?? item['name'] ?? 'Item';
          lowStockNames.add('$medName ($remaining left)');
        }
      }

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
        shopSettings: currentSettings,
        doctorName: ref.read(billingProvider).selectedDoctorId == 'new'
            ? _newDoctorController.text
            : ref.read(billingProvider).selectedDoctorName,
        paymentMethod: ref.read(billingProvider).paymentMethod,
        gstNumber: ref.read(billingProvider).gstNumber,
        format: ref.read(billingProvider).selectedFormat,
      );

      await FileDownloadHelper.saveFile(
        name: 'Bill_$invoiceNo',
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
        dialogTitle: 'Save Bill PDF',
      );

      if (mounted) {
        if (lowStockNames.isNotEmpty) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bill generated! ⚠️ Low stock alert: ${lowStockNames.join(", ")}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.deepOrange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Bill generated and saved successfully! Preparing to print...',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Save or Update local billing history
      final savedBillObj = SavedBill(
        id: _rectifyingBillId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
        shopSettings: currentSettings != null
            ? Map<String, dynamic>.from(currentSettings)
            : null,
      );

      if (_rectifyingBillId != null) {
        await BillingHistoryService.updateBill(savedBillObj);
      } else {
        await BillingHistoryService.saveBill(savedBillObj);
      }

      final isRectifiedRun = _rectifyingInvoiceNo != null;
      _rectifyingInvoiceNo = null;
      _rectifyingBillId = null;

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

        // App Toaster notifying the cashier that bill is saved to Invoices
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isRectifiedRun
                        ? "Invoice '$invoiceNo' rectified successfully! Saved to 'Invoices' page."
                        : "Bill '$invoiceNo' generated successfully! Saved to 'Invoices' page.",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF166534),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      // Wait a tiny bit to allow the pop animation to finish, preventing !_debugLocked crash
      await Future.delayed(const Duration(milliseconds: 200));

      // Show the print preview dialog for the final bill immediately!
      // This uses the exact same PdfPreview widget that successfully prints
      // the complete bill with zero cut-off on the Essae printer.
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) {
            return Dialog(
              insetPadding: const EdgeInsets.all(32),
              child: Container(
                width: 800,
                height: MediaQuery.of(dialogCtx).size.height * 0.8,
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
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF166534), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Bill Generated Successfully — $invoiceNo',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: PdfPreview(
                        key: ValueKey('generated_bill_preview_$invoiceNo'),
                        build: (format) => pdfBytes,
                        allowPrinting: true,
                        allowSharing: true,
                        canDebug: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        pdfFileName: 'Bill_$invoiceNo.pdf',
                        initialPageFormat: ref.read(billingProvider).selectedFormat == 'Thermal'
                            ? PdfPageFormat.roll80
                            : ref.read(billingProvider).selectedFormat == 'A5'
                                ? PdfPageFormat.a5.landscape
                                : PdfPageFormat.a4,
                        pageFormats: {
                          'A5 Landscape': PdfPageFormat.a5.landscape,
                          'A4': PdfPageFormat.a4,
                          'Thermal': PdfPageFormat.roll80,
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
    final item = _currentBill[index];
    final packStock = item['stock'] ?? 0;
    final looseStock = item['loose_stock'] ?? 0;
    final packSize = item['pack_size'] ?? 1;
    final isLoose = item['is_loose'] ?? false;
    final currentQty = item['qty'] ?? 0;
    final itemName = item['name'];

    final int availableLimit = isLoose ? (packStock * packSize) + looseStock : packStock;

    if (currentQty >= availableLimit) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Stock Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Cannot add more $itemName. Only $availableLimit ${isLoose ? "pieces" : "packs"} available in stock.',
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
        .updateItemQuantity(index, currentQty + 1);
  }

  void _decreaseQty(int index) {
    if (_currentBill[index]['qty'] > 1) {
      ref
          .read(billingProvider.notifier)
          .updateItemQuantity(index, _currentBill[index]['qty'] - 1);
    }
  }

  void _toggleLoose(int index) {
    final item = _currentBill[index];
    final packStock = item['stock'] ?? 0;
    final looseStock = item['loose_stock'] ?? 0;
    final packSize = item['pack_size'] ?? 1;
    final isLoose = item['is_loose'] ?? false;
    final currentQty = item['qty'] ?? 0;

    final bool newIsLoose = !isLoose;
    final int availableLimit = newIsLoose ? (packStock * packSize) + looseStock : packStock;

    if (currentQty > availableLimit) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Stock Limit Reached',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Cannot switch to ${newIsLoose ? "loose pieces" : "full packs"}. You have $currentQty in your cart, but only $availableLimit ${newIsLoose ? "pieces" : "packs"} available in stock.',
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

    ref.read(billingProvider.notifier).toggleItemLoose(index);
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

      if (isLoose && packSize > 1) {
        double effectivePrice = mrp / packSize;
        totalAfterDiscount = effectivePrice - (effectivePrice * (discount / 100));
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
      // ignore: use_build_context_synchronously
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
    ref.listen<AsyncValue<Map<String, dynamic>>>(settingsProvider, (previous, next) {
      next.whenData((settings) {
        if (mounted) {
          setState(() {
            _shopSettings = settings;
          });
        }
        if (settings['logo_url'] != null) {
          PdfGenerator.preloadLogo(settings['logo_url'].toString());
        }
        if (settings['qr_url'] != null) {
          PdfGenerator.preloadQr(settings['qr_url'].toString());
        }
      });
    });

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
              'low_stock_threshold': item.lowStockThreshold ?? 10,
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

    final query = _medicineSearchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> computedFilteredMedicines = allMedicines;
    if (query.isNotEmpty) {
      computedFilteredMedicines = allMedicines.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final brand = (item['brand'] ?? '').toString().toLowerCase();

        // When user types 1 single letter, filter by prefix of medicine name or brand
        if (query.length == 1) {
          final words = name.split(RegExp(r'\s+'));
          final matchesNamePrefix = words.any((w) => w.startsWith(query)) || name.startsWith(query);
          final matchesBrandPrefix = brand.startsWith(query);
          return matchesNamePrefix || matchesBrandPrefix;
        }

        // For >= 2 letters, match anywhere in name, brand, or barcode
        final barcode = (item['pack'] ?? '').toString().toLowerCase();
        final batch = (item['batch_number'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            brand.contains(query) ||
            barcode.contains(query) ||
            batch.contains(query);
      }).toList();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'New Bill',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Create a new invoice, search medicines and add to cart',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  ),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Main Split Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktopWidth = constraints.maxWidth > 1100;
                bool hasEnoughHeight =
                    constraints.maxHeight >
                    850; // Use the tested safe threshold

                  final currentItems = inventoryState.value ?? [];
                  final isInitialLoading = inventoryState.isLoading && currentItems.isEmpty;

                  Widget leftSide = isInitialLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                        )
                      : (inventoryState.hasError && currentItems.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    inventoryState.error.toString(),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => ref.read(billingInventoryProvider.notifier).loadInventory(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : BillingLeftPanel(
                              isDesktopWidth: isDesktopWidth,
                              hasEnoughHeight: true,
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
                                _searchDebounce?.cancel();
                                setState(() {}); // Immediately filter loaded medicines in UI for 0ms lag

                                final trimmed = _medicineSearchController.text.trim();

                                // 1. If empty, immediately reset to default inventory
                                if (trimmed.isEmpty) {
                                  ref.read(billingInventoryProvider.notifier).cancelPendingSearch();
                                  ref
                                      .read(billingInventoryProvider.notifier)
                                      .loadInventory(searchQuery: null);
                                  return;
                                }

                                // 2. Minimum 2-character guard: don't hammer API on 1 letter
                                if (trimmed.length < 2) {
                                  ref.read(billingInventoryProvider.notifier).cancelPendingSearch();
                                  return;
                                }

                                // 3. Debounce network call by 300ms
                                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                                  final currentQuery = _medicineSearchController.text.trim();
                                  if (currentQuery.length >= 2) {
                                    ref
                                        .read(billingInventoryProvider.notifier)
                                        .loadInventory(searchQuery: currentQuery);
                                  }
                                });
                              },
                            );

                  Widget rightSide = BillingRightPanel(
                    hasEnoughHeight: isDesktopWidth ? hasEnoughHeight : true,
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
                    onToggleLoose: _toggleLoose,
                    onSaveCustomerToDb: _saveCustomerToDb,
                    onSaveDraft: _saveDraft,
                    onShowDraftsDialog: _showDraftsDialog,
                    onShowInvoicesDialog: _showInvoicesDialog,
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
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 13, child: leftSide),
                          const SizedBox(width: 24),
                          Expanded(flex: 9, child: rightSide),
                        ],
                      ),
                    );
                  } else {
                    // Mobile View: Clean Segmented Tab Switcher + Sticky Cart Summary Pill
                    final totalCartItems = _currentBill.fold<int>(
                      0,
                      (sum, item) => sum + (item['quantity'] as int? ?? 1),
                    );
                    final grandTotal = ref.watch(billingProvider).grandTotal;
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Tab Switcher (Medicines vs Cart)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _mobileTabIndex = 0;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(9),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: _mobileTabIndex == 0
                                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _mobileTabIndex == 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medication_outlined,
                                          size: 16,
                                          color: _mobileTabIndex == 0
                                              ? const Color(0xFF166534)
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Medicines',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _mobileTabIndex == 0 ? FontWeight.bold : FontWeight.w600,
                                            color: _mobileTabIndex == 0
                                                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534))
                                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _mobileTabIndex = 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(9),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: _mobileTabIndex == 1
                                          ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _mobileTabIndex == 1
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 16,
                                          color: _mobileTabIndex == 1
                                              ? const Color(0xFF166534)
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cart',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _mobileTabIndex == 1 ? FontWeight.bold : FontWeight.w600,
                                            color: _mobileTabIndex == 1
                                                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534))
                                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          ),
                                        ),
                                        if (totalCartItems > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF166534),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$totalCartItems',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Active Tab Body (expanded cleanly from edge to edge with 6px margin)
                        Expanded(
                          child: IndexedStack(
                            index: _mobileTabIndex,
                            children: [
                              // Tab 0: Medicines Catalog
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: leftSide,
                              ),
                              // Tab 1: Cart & Checkout
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: rightSide,
                              ),
                            ],
                          ),
                        ),

                        // Sticky Bottom Cart Bar (Shown in Catalog view when cart has items)
                        if (_mobileTabIndex == 0 && _currentBill.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$totalCartItems item${totalCartItems > 1 ? 's' : ''} added',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '₹${grandTotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _mobileTabIndex = 1;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_forward, size: 16),
                                    label: const Text(
                                      'View Cart & Pay',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF166534),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

}
