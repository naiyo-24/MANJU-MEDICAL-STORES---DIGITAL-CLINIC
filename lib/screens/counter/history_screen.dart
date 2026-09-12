import 'package:flutter/material.dart';
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
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeDateRange = 'Today';
  String _selectedType = 'All';
  String _selectedPaymentMode = 'All';
  String _searchQuery = '';
  int _currentPage = 1;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    BillingHistoryService.historyUpdated.addListener(_loadHistory);
  }

  @override
  void dispose() {
    BillingHistoryService.historyUpdated.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final savedBills = await BillingHistoryService.getBillingHistory();
      
      if (mounted) {
        setState(() {
          _transactions = savedBills.map((bill) {
            return {
              'date': DateFormat('dd MMM yyyy').format(bill.createdAt),
              'time': DateFormat('hh:mm a').format(bill.createdAt),
              'refNo': bill.invoiceNo,
              'customerName': bill.customerName.isEmpty ? 'Walk-in' : bill.customerName,
              'customerPhone': bill.customerPhone,
              'type': 'Sale',
              'items': bill.items.length,
              'amount': bill.grandTotal,
              'paymentMode': 'Cash', // Default for now since we don't store it yet
              'status': 'Completed',
              'originalBill': bill,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Error loading history: $e');
      print(stack);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((tx) {
      final matchesSearch = tx['refNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['customerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx['customerPhone'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _selectedType == 'All' || tx['type'] == _selectedType;
      final matchesMode = _selectedPaymentMode == 'All' || tx['paymentMode'] == _selectedPaymentMode;
      
      return matchesSearch && matchesType && matchesMode;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _activeDateRange = 'Today';
      _selectedType = 'All';
      _selectedPaymentMode = 'All';
      _searchQuery = '';
    });
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Excel Report...')));
    
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['History'];
    excel.setDefaultSheet('History');
    
    sheetObject.appendRow([
      TextCellValue('Date'), TextCellValue('Time'), TextCellValue('Bill No / Ref No'),
      TextCellValue('Customer Name'), TextCellValue('Type'), TextCellValue('Items'),
      TextCellValue('Amount'), TextCellValue('Payment Mode'), TextCellValue('Status'),
    ]);

    for (var tx in _filteredTransactions) {
      sheetObject.appendRow([
        TextCellValue(tx['date'].toString()), TextCellValue(tx['time'].toString()),
        TextCellValue(tx['refNo'].toString()), TextCellValue(tx['customerName'].toString()),
        TextCellValue(tx['type'].toString()), IntCellValue(tx['items'] as int),
        DoubleCellValue(double.tryParse(tx['amount'].toString()) ?? 0.0),
        TextCellValue(tx['paymentMode'].toString()), TextCellValue(tx['status'].toString()),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: 'History_Report_${DateTime.now().millisecondsSinceEpoch}',
        bytes: Uint8List.fromList(fileBytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }
  }

  Future<void> _exportToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('History Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Date', 'Bill No', 'Customer Name', 'Type', 'Amount', 'Mode', 'Status'],
                data: _filteredTransactions.map((tx) => [
                  tx['date'].toString(),
                  tx['refNo'].toString(),
                  tx['customerName'].toString(),
                  tx['type'].toString(),
                  tx['amount'].toString(),
                  tx['paymentMode'].toString(),
                  tx['status'].toString(),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List fileBytes = await pdf.save();
    
    await FileSaver.instance.saveFile(
      name: 'History_Report_${DateTime.now().millisecondsSinceEpoch}',
      bytes: fileBytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  void _viewBill(SavedBill bill) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 800,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bill View - ${bill.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        doctorName: bill.doctorName,
                        format: 'A4',
                      );
                    },
                    allowSharing: true,
                    allowPrinting: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor, Color iconColor, IconData icon, String percentage) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Color(0xFF22C55E), size: 12),
                    Text(percentage, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const Text('vs last month', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
              ],
            ),
          ],
        ),
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
              // Can use picked.start and picked.end to filter the data here if real backend was hooked up
            });
          }
        } else {
          setState(() => _activeDateRange = title);
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
              Icon(Icons.calendar_today, size: 14, color: isActive ? Colors.white : const Color(0xFF1E293B)),
              const SizedBox(width: 6),
            ],
            Text(title, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Container(
          height: 40,
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
        bgColor = const Color(0xFFDCFCE7); textColor = const Color(0xFF22C55E); icon = Icons.shopping_cart_outlined; break;
      case 'Return':
        bgColor = const Color(0xFFFEE2E2); textColor = Colors.red; icon = Icons.keyboard_return; break;
      case 'Adjustment':
        bgColor = const Color(0xFFFFEDD5); textColor = const Color(0xFFF97316); icon = Icons.inventory_2_outlined; break;
      case 'Purchase':
        bgColor = const Color(0xFFDBEAFE); textColor = const Color(0xFF3B82F6); icon = Icons.local_shipping_outlined; break;
      default:
        bgColor = const Color(0xFFF1F5F9); textColor = const Color(0xFF64748B); icon = Icons.help_outline; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(type, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentModePill(String mode) {
    if (mode == '-') return const Text('-', style: TextStyle(color: Color(0xFF64748B)));
    Color bgColor, textColor;
    switch (mode) {
      case 'Cash': bgColor = const Color(0xFFDCFCE7); textColor = const Color(0xFF22C55E); break;
      case 'UPI': bgColor = const Color(0xFFF3E8FF); textColor = const Color(0xFFA855F7); break;
      case 'Card': bgColor = const Color(0xFFDBEAFE); textColor = const Color(0xFF3B82F6); break;
      case 'Bank Transfer': bgColor = const Color(0xFFF3E8FF); textColor = const Color(0xFFA855F7); break;
      default: bgColor = const Color(0xFFF1F5F9); textColor = const Color(0xFF64748B); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(mode, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text('View all transactions, activities and records', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Excel') _exportToExcel();
                  if (value == 'PDF') _exportToPdf();
                },
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF22C55E)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download, size: 16, color: Color(0xFF166534)),
                      const SizedBox(width: 8),
                      const Text('Export', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF166534)),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Excel', child: Row(children: [Icon(Icons.table_chart_outlined, color: Color(0xFF22C55E), size: 18), SizedBox(width: 8), Text('Export as Excel')])),
                  const PopupMenuItem(value: 'PDF', child: Row(children: [Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 18), SizedBox(width: 8), Text('Export as PDF')])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildStatCard('${_transactions.length}', 'Total Bills', const Color(0xFFE8F5E9), const Color(0xFF22C55E), Icons.shopping_cart, '+12%'),
              const SizedBox(width: 16),
              _buildStatCard('₹ ${_transactions.fold(0.0, (sum, tx) => sum + (tx['amount'] as double)).toStringAsFixed(2)}', 'Total Sales', const Color(0xFFE3F2FD), const Color(0xFF3B82F6), Icons.currency_rupee, '+18%'),
              const SizedBox(width: 16),
              _buildStatCard('${_transactions.where((t) => t['customerName'] != 'Walk-in').length}', 'Customers Served', const Color(0xFFFFF3E0), const Color(0xFFF97316), Icons.people, '+9%'),
              const SizedBox(width: 16),
              _buildStatCard('${_transactions.fold(0, (sum, tx) => sum + (tx['items'] as int))}', 'Items Sold', const Color(0xFFF3E8FF), const Color(0xFFA855F7), Icons.inventory_2, '+15%'),
            ],
          ),
          const SizedBox(height: 24),

          // Filters Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      children: [
                        _buildDateRangeBtn('Today', false),
                        _buildDateRangeBtn('This Week', false),
                        _buildDateRangeBtn('This Month', false),
                        _buildDateRangeBtn('This Year', false),
                        const VerticalDivider(width: 16, color: Color(0xFFE2E8F0)),
                        _buildDateRangeBtn('Custom Range', true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              _buildDropdownFilter('Transaction Type', ['All', 'Sale', 'Return', 'Adjustment', 'Purchase'], _selectedType, (v) => setState(() => _selectedType = v!)),
              const SizedBox(width: 16),
              _buildDropdownFilter('Payment Mode', ['All', 'Cash', 'UPI', 'Card', 'Bank Transfer'], _selectedPaymentMode, (v) => setState(() => _selectedPaymentMode = v!)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search by bill no, customer name, phone...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                    icon: const Icon(Icons.refresh, color: Color(0xFF1E293B), size: 16),
                    label: const Text('Reset', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                    child: Row(
                      children: [
                        const SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 2, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 2, child: Text('Bill No / Ref No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 3, child: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 1, child: Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 2, child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 2, child: Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                        const SizedBox(width: 200, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 12))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Table Body
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty 
                        ? const Center(child: Text('No history found'))
                        : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isNegative = tx['amount'] < 0;
                        final amountStr = tx['amount'] == 0 ? '-' : tx['amount'].toStringAsFixed(2);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx['date'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(tx['time'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Expanded(flex: 2, child: Text(tx['refNo'], style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12)),
                                    if (tx['customerPhone'].isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(tx['customerPhone'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                    ]
                                  ],
                                ),
                              ),
                              Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildTypePill(tx['type']))),
                              Expanded(flex: 1, child: Text('${tx['items']} ${tx['items'] == 1 ? 'item' : 'items'}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12))),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  amountStr,
                                  style: TextStyle(color: isNegative ? Colors.red : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildPaymentModePill(tx['paymentMode']))),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(tx['status'], style: const TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _viewBill(tx['originalBill']),
                                      icon: const Icon(Icons.visibility, size: 14, color: Color(0xFF1E293B)),
                                      label: const Text('View', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8), side: const BorderSide(color: Color(0xFFE2E8F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: Image.asset('assets/whatsapp.png', height: 14, errorBuilder: (c, e, s) => const Icon(Icons.chat, size: 14, color: Color(0xFF22C55E))),
                                      label: const Text('Send', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 8), side: const BorderSide(color: Color(0xFF22C55E)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), backgroundColor: const Color(0xFFDCFCE7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 32, width: 32,
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                                      child: const Icon(Icons.more_vert, size: 16, color: Color(0xFF64748B)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Showing 1 to ${filtered.length} of ${_transactions.length} records', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        CustomPagination(
                          currentPage: _currentPage,
                          totalPages: 1, // Only 1 page for now since it's local
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
        ],
      ),
    );
  }
}
