import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/custom_date_range_picker.dart';
import '../../widgets/custom_pagination.dart';
import '../../services/billing_history_service.dart';
import '../../utils/pdf_generator.dart';
import '../../services/export_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _activeDateRange = 'Today';
  String _selectedType = 'All';
  String _selectedPaymentMode = 'All';
  String _searchQuery = '';
  int _currentPage = 1;
  DateTimeRange? _customDateRange;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).reloadHistory();
    });
    BillingHistoryService.historyUpdated.addListener(_onHistoryUpdated);
  }

  void _onHistoryUpdated() {
    ref.read(historyProvider.notifier).reloadHistory();
  }

  @override
  void dispose() {
    BillingHistoryService.historyUpdated.removeListener(_onHistoryUpdated);
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredTransactions(
    List<Map<String, dynamic>> allTransactions, {
    String? overrideDateRange,
  }) {
    final now = DateTime.now();
    final targetRange = overrideDateRange ?? _activeDateRange;
    
    return allTransactions.where((tx) {
      DateTime date = tx['createdAtDate'] ?? now;

      bool matchesDate = false;
      switch (targetRange) {
        case 'Today':
          matchesDate =
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          matchesDate = date.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          );
          break;
        case 'This Month':
          matchesDate = date.year == now.year && date.month == now.month;
          break;
        case 'This Year':
          matchesDate = date.year == now.year;
          break;
        case 'Custom Range':
          if (_customDateRange != null) {
            final start = _customDateRange!.start;
            final end = _customDateRange!.end.add(const Duration(days: 1));
            matchesDate = date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end);
          } else {
            matchesDate = true;
          }
          break;
        default:
          matchesDate = true;
      }

      final matchesSearch =
          tx['refNo'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          tx['customerName'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          tx['customerPhone'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesType = _selectedType == 'All' || tx['type'] == _selectedType;
      final matchesMode =
          _selectedPaymentMode == 'All' ||
          tx['paymentMode'] == _selectedPaymentMode;

      return matchesDate && matchesSearch && matchesType && matchesMode;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _activeDateRange = 'Today';
      _selectedType = 'All';
      _selectedPaymentMode = 'All';
      _searchQuery = '';
      _currentPage = 1;
      _customDateRange = null;
    });
  }

    Future<void> _exportToExcel(
      List<Map<String, dynamic>> allTransactions, {
      bool exportFiltered = true,
      String? overrideDateRange,
    }) async {
      final targetData = exportFiltered ? _filteredTransactions(allTransactions, overrideDateRange: overrideDateRange) : allTransactions;
  
      if (targetData.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data available to export for the selected filter!')));
        }
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating Excel Report...')));
  
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['History'];
      excel.setDefaultSheet('History');
  
      sheetObject.appendRow([
        TextCellValue('Date'),
        TextCellValue('Time'),
        TextCellValue('Bill No / Ref No'),
        TextCellValue('Customer Name'),
        TextCellValue('Type'),
        TextCellValue('Items'),
        TextCellValue('Amount'),
        TextCellValue('Payment Mode'),
        TextCellValue('Status'),
      ]);
  
      for (var tx in targetData) {
      sheetObject.appendRow([
        TextCellValue(tx['date'].toString()),
        TextCellValue(tx['time'].toString()),
        TextCellValue(tx['refNo'].toString()),
        TextCellValue(tx['customerName'].toString()),
        TextCellValue(tx['type'].toString()),
        IntCellValue(tx['items'] as int),
        DoubleCellValue(double.tryParse(tx['amount'].toString()) ?? 0.0),
        TextCellValue(tx['paymentMode'].toString()),
        TextCellValue(tx['status'].toString()),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      try {
        final path = await FileSaver.instance.saveAs(
          name: 'History_Report_${DateTime.now().millisecondsSinceEpoch}',
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel report saved successfully to your device!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  Future<void> _exportToPdf(
      List<Map<String, dynamic>> allTransactions, {
      bool exportFiltered = true,
      String? overrideDateRange,
    }) async {
      final targetData = exportFiltered ? _filteredTransactions(allTransactions, overrideDateRange: overrideDateRange) : allTransactions;

      if (targetData.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data available to export for the selected filter!')));
        }
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
  
      final dataToExport = targetData.map((tx) => {
        'Date': tx['date'].toString(),
        'Bill No': tx['refNo'].toString(),
        'Customer Name': tx['customerName'].toString(),
        'Type': tx['type'].toString(),
        'Amount': tx['amount'].toString(),
        'Mode': tx['paymentMode'].toString(),
        'Status': tx['status'].toString(),
      }).toList();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await ExportService.exportToPDF(dataToExport, 'History_Report_$timestamp');
  }

  void _viewBill(SavedBill bill) async {
    // Ensure settings are loaded BEFORE opening dialog
    Map<String, dynamic> shopSettings = {};
    final settingsAsync = ref.read(settingsProvider);
    if (settingsAsync.value != null) {
      shopSettings = settingsAsync.value!;
    } else {
      // Force load settings if not yet loaded
      try {
        shopSettings = await ref.read(settingsProvider.future);
      } catch (_) {
        shopSettings = {};
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bill View - ${bill.invoiceNo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) async {
                      return await PdfGenerator.generateBill(
                        items: bill.items,
                        subtotal: bill.subtotal,
                        discount: bill.discount,
                        tax: bill.tax,
                        grandTotal: bill.grandTotal,
                        invoiceNumber: bill.invoiceNo,
                        customerName: bill.customerName,
                        customerPhone: bill.customerPhone,
                        customerLocation: bill.customerLocation,
                        gstNumber: bill.customerGstin,
                        doctorName: bill.doctorName,
                        paymentMethod: bill.paymentMode,
                        shopSettings: shopSettings,
                        format: bill.format,
                        billingDate: bill.createdAt,
                      );
                    },
                    allowSharing: false,
                    allowPrinting: true,
                    canDebug: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    initialPageFormat: bill.format == 'Thermal'
                        ? const PdfPageFormat(
                            80 * PdfPageFormat.mm,
                            300 * PdfPageFormat.mm,
                          )
                        : bill.format == 'A5'
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

  Widget _buildStatCard(
    String value,
    String label,
    Color bgColor,
    Color iconColor,
    IconData icon,
    String percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (percentage.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      percentage.startsWith('+')
                          ? Icons.arrow_upward
                          : (percentage == '0%'
                                ? Icons.horizontal_rule
                                : Icons.arrow_downward),
                      color: percentage.startsWith('+')
                          ? const Color(0xFF22C55E)
                          : (percentage == '0%'
                                ? const Color(0xFF94A3B8)
                                : Colors.red),
                      size: 12,
                    ),
                    Text(
                      percentage,
                      style: TextStyle(
                        color: percentage.startsWith('+')
                            ? const Color(0xFF22C55E)
                            : (percentage == '0%'
                                  ? const Color(0xFF94A3B8)
                                  : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'vs last month',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBtn(String title, bool isCustom) {
    final isActive = _activeDateRange == title;
    return InkWell(
      onTap: () async {
        if (isCustom) {
          final DateTimeRange? picked = await showDialog<DateTimeRange>(
            context: context,
            builder: (context) => const CustomDateRangePicker(),
          );
          if (picked != null) {
            setState(() {
              _activeDateRange = title;
              _customDateRange = picked;
              _currentPage = 1;
            });
          }
        } else {
          setState(() {
            _activeDateRange = title;
            _currentPage = 1;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF22C55E) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (isCustom) ...[
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF1E293B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : const Color(0xFF1E293B)),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                size: 18,
              ),
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 13),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypePill(String type) {
    Color bgColor, textColor;
    IconData icon;
    switch (type) {
      case 'Sale':
        bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
        textColor = const Color(0xFF22C55E);
        icon = Icons.shopping_cart_outlined;
        break;
      case 'Return':
        bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
        textColor = Colors.red;
        icon = Icons.keyboard_return;
        break;
      case 'Adjustment':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFF97316);
        icon = Icons.inventory_2_outlined;
        break;
      case 'Purchase':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        icon = Icons.local_shipping_outlined;
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.help_outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModePill(String mode) {
    if (mode == '-') {
      return Text('-', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B)));
    }
    Color bgColor, textColor;
    switch (mode) {
      case 'Cash':
        bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
        textColor = const Color(0xFF22C55E);
        break;
      case 'UPI':
        bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF);
        textColor = const Color(0xFFA855F7);
        break;
      case 'Card':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'Bank Transfer':
        bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF);
        textColor = const Color(0xFFA855F7);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (historyState) {
        final filtered = _filteredTransactions(historyState.transactions);
        final int itemsPerPage = 10;
        final int totalRecords = filtered.length;
        final int totalPages = (totalRecords / itemsPerPage).ceil() == 0
            ? 1
            : (totalRecords / itemsPerPage).ceil();

        final int startIdx = (_currentPage - 1) * itemsPerPage;
        final int endIdx = (startIdx + itemsPerPage > totalRecords)
            ? totalRecords
            : startIdx + itemsPerPage;
        final pagedTransactions = filtered.isNotEmpty
            ? filtered.sublist(startIdx, endIdx)
            : <Map<String, dynamic>>[];

        return Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history,
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View all transactions, activities and records',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => ref
                              .read(historyProvider.notifier)
                              .reloadHistory(),
                          icon: Icon(
                            Icons.refresh,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          tooltip: 'Refresh',
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            final parts = value.split('_');
                            final format = parts[0];
                            final action = parts[1];

                            if (action == 'All') {
                              if (format == 'Excel') {
                                _exportToExcel(historyState.transactions, exportFiltered: false);
                              } else {
                                _exportToPdf(historyState.transactions, exportFiltered: false);
                              }
                            } else if (action == 'Filtered') {
                              if (format == 'Excel') {
                                _exportToExcel(historyState.transactions, exportFiltered: true);
                              } else {
                                _exportToPdf(historyState.transactions, exportFiltered: true);
                              }
                            } else {
                              // specific date ranges
                              final dateRangeMap = {
                                'Today': 'Today',
                                'Week': 'This Week',
                                'Month': 'This Month',
                                'Year': 'This Year',
                              };
                              final dateRange = dateRangeMap[action];
                              if (format == 'Excel') {
                                _exportToExcel(historyState.transactions, exportFiltered: true, overrideDateRange: dateRange);
                              } else {
                                _exportToPdf(historyState.transactions, exportFiltered: true, overrideDateRange: dateRange);
                              }
                            }
                          },
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF22C55E),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 16,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.green[400]! : Color(0xFF166534),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.green[400]! : const Color(0xFF166534),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.green[400]! : Color(0xFF166534),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Excel_Filtered',
                              child: Text('Export Current Filtered List (Excel)'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'Excel_Today',
                              child: Text('Export Today (Excel)'),
                            ),
                            const PopupMenuItem(
                              value: 'Excel_Week',
                              child: Text('Export This Week (Excel)'),
                            ),
                            const PopupMenuItem(
                              value: 'Excel_Month',
                              child: Text('Export This Month (Excel)'),
                            ),
                            const PopupMenuItem(
                              value: 'Excel_Year',
                              child: Text('Export This Year (Excel)'),
                            ),
                            const PopupMenuItem(
                              value: 'Excel_All',
                              child: Text('Export All Time (Excel)'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'PDF_Filtered',
                              child: Text('Export Current Filtered List (PDF)'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'PDF_Today',
                              child: Text('Export Today (PDF)'),
                            ),
                            const PopupMenuItem(
                              value: 'PDF_Week',
                              child: Text('Export This Week (PDF)'),
                            ),
                            const PopupMenuItem(
                              value: 'PDF_Month',
                              child: Text('Export This Month (PDF)'),
                            ),
                            const PopupMenuItem(
                              value: 'PDF_Year',
                              child: Text('Export This Year (PDF)'),
                            ),
                            const PopupMenuItem(
                              value: 'PDF_All',
                              child: Text('Export All Time (PDF)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 800;

                  double totalRevenue = 0;
                  int totalInvoices = 0;
                  double totalReturns = 0;
                  double cashInHand = 0;

                  for (var tx in filtered) {
                    double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                    if (tx['type'] == 'Return') {
                      totalReturns += amount;
                    } else {
                      totalRevenue += amount;
                      totalInvoices += 1;
                      if (tx['paymentMode'] == 'Cash') {
                        cashInHand += amount;
                      }
                    }
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: _buildStatCard(
                            '₹${totalRevenue.toStringAsFixed(2)}',
                            'Total Revenue',
                            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                            Theme.of(context).brightness == Brightness.dark ? Colors.green[400]! : const Color(0xFF166534),
                            Icons.currency_rupee,
                            '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: _buildStatCard(
                            '$totalInvoices',
                            'Total Invoices',
                            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
                            Theme.of(context).brightness == Brightness.dark ? Colors.blue[400]! : const Color(0xFF0369A1),
                            Icons.receipt_long,
                            '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: _buildStatCard(
                            '₹${totalReturns.toStringAsFixed(2)}',
                            'Total Returns',
                            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                            Theme.of(context).brightness == Brightness.dark ? Colors.red[400]! : Colors.red,
                            Icons.keyboard_return,
                            '',
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: isDesktop
                              ? (constraints.maxWidth - 48) / 4
                              : 250,
                          child: _buildStatCard(
                            '₹${cashInHand.toStringAsFixed(2)}',
                            'Cash in Hand',
                            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF),
                            Theme.of(context).brightness == Brightness.dark ? Colors.purple[400]! : const Color(0xFF7E22CE),
                            Icons.account_balance_wallet,
                            '',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Filters Row
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 1000;
                  return isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date Range',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildDateRangeBtn('Today', false),
                                      _buildDateRangeBtn('This Week', false),
                                      _buildDateRangeBtn('This Month', false),
                                      _buildDateRangeBtn('This Year', false),
                                      VerticalDivider(
                                        width: 16,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      _buildDateRangeBtn('Custom Range', true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            _buildDropdownFilter(
                              'Transaction Type',
                              [
                                'All',
                                'Sale',
                                'Return',
                                'Adjustment',
                                'Purchase',
                              ],
                              _selectedType,
                              (v) => setState(() => _selectedType = v!),
                            ),
                            const SizedBox(width: 16),
                            _buildDropdownFilter(
                              'Payment Mode',
                              ['All', 'Cash', 'UPI', 'Card', 'Bank Transfer'],
                              _selectedPaymentMode,
                              (v) => setState(() => _selectedPaymentMode = v!),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: TextField(
                                      onChanged: (val) =>
                                          setState(() => _searchQuery = val),
                                      style: const TextStyle(fontSize: 13),
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Search by bill no, customer name, phone...',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: Color(0xFF94A3B8),
                                          size: 18,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('', style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _resetFilters,
                                  icon: Icon(
                                    Icons.clear,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Reset Filters',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date Range',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildDateRangeBtn('Today', false),
                                        _buildDateRangeBtn('This Week', false),
                                        _buildDateRangeBtn('This Month', false),
                                        _buildDateRangeBtn('This Year', false),
                                        VerticalDivider(
                                          width: 16,
                                          color: Theme.of(context).dividerColor,
                                        ),
                                        _buildDateRangeBtn(
                                          'Custom Range',
                                          true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              _buildDropdownFilter(
                                'Transaction Type',
                                [
                                  'All',
                                  'Sale',
                                  'Return',
                                  'Adjustment',
                                  'Purchase',
                                ],
                                _selectedType,
                                (v) => setState(() {
                                  _selectedType = v!;
                                  _currentPage = 1;
                                }),
                              ),
                              const SizedBox(width: 16),
                              _buildDropdownFilter(
                                'Payment Mode',
                                ['All', 'Cash', 'UPI', 'Card', 'Bank Transfer'],
                                _selectedPaymentMode,
                                (v) => setState(() {
                                  _selectedPaymentMode = v!;
                                  _currentPage = 1;
                                }),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 300,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: TextField(
                                        onChanged: (val) =>
                                            setState(() => _searchQuery = val),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search by bill no, customer name, phone...',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Color(0xFF94A3B8),
                                            size: 18,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: _resetFilters,
                                    icon: Icon(
                                      Icons.clear,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Reset Filters',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(0, 40),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                },
              ),
              const SizedBox(height: 16),

              // Data Table
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 1200,
                          maxWidth: constraints.maxWidth > 1200
                              ? constraints.maxWidth
                              : 1200,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '#',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Date & Time',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Bill No / Ref No',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Customer Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Type',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Items',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Amount (₹)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Payment Mode',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        'Action',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              // Table Body
                              filtered.isEmpty
                                  ? const Expanded(
                                      child: Center(
                                        child: Text('No history found'),
                                      ),
                                    )
                                  : Expanded(
                                      child: ListView.separated(
                                        itemCount: pagedTransactions.length,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                              height: 1,
                                              color: Theme.of(context).dividerColor,
                                            ),
                                        itemBuilder: (context, index) {
                                          final tx = pagedTransactions[index];
                                          final isNegative = tx['amount'] < 0;
                                          final amountStr = tx['amount'] == 0
                                              ? '-'
                                              : tx['amount'].toStringAsFixed(2);

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 30,
                                                  child: Text(
                                                    '${startIdx + index + 1}',
                                                    style: TextStyle(
                                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        tx['date'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        tx['time'],
                                                        style: TextStyle(
                                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    tx['refNo'],
                                                    style: TextStyle(
                                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        tx['customerName'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      if (tx['customerPhone']
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          tx['customerPhone'],
                                                          style:
                                                              TextStyle(
                                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: _buildTypePill(
                                                      tx['type'],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    '${tx['items']} ${tx['items'] == 1 ? 'item' : 'items'}',
                                                    style: TextStyle(
                                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    amountStr,
                                                    style: TextStyle(
                                                      color: isNegative
                                                          ? Colors.red
                                                          : const Color(
                                                              0xFF1E293B,
                                                            ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child:
                                                        _buildPaymentModePill(
                                                          tx['paymentMode'],
                                                        ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Color(
                                                                0xFF22C55E,
                                                              ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        tx['status'],
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF166534,
                                                          ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 200,
                                                  child: Row(
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () {
                                                          if (tx['originalBill'] !=
                                                              null) {
                                                            _viewBill(
                                                              tx['originalBill'],
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Detailed view not available for synced backend bills yet.',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        icon: Icon(
                                                          Icons.visibility,
                                                          size: 14,
                                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Color(0xFF1E293B),
                                                        ),
                                                        label: Text(
                                                          'View',
                                                          style: TextStyle(
                                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize:
                                                              const Size(0, 32),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                          side:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFFE2E8F0,
                                                                ),
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      OutlinedButton.icon(
                                                        onPressed: () {},
                                                        icon: Image.asset(
                                                          'assets/whatsapp.png',
                                                          height: 14,
                                                          errorBuilder:
                                                              (
                                                                c,
                                                                e,
                                                                s,
                                                              ) => const Icon(
                                                                Icons.chat,
                                                                size: 14,
                                                                color: Color(
                                                                  0xFF22C55E,
                                                                ),
                                                              ),
                                                        ),
                                                        label: const Text(
                                                          'Send',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFF166534,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize:
                                                              const Size(0, 32),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                          side:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFF22C55E,
                                                                ),
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFDCFCE7,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        height: 32,
                                                        width: 32,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFFE2E8F0,
                                                            ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons.more_vert,
                                                          size: 16,
                                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              // Pagination
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Theme.of(context).dividerColor),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Showing ${totalRecords == 0 ? 0 : startIdx + 1} to $endIdx of $totalRecords records',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                    CustomPagination(
                                      currentPage: _currentPage,
                                      totalPages: totalPages,
                                      onPageChanged: (page) {
                                        setState(() {
                                          _currentPage = page;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
