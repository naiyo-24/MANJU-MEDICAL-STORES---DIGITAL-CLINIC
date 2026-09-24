import 'package:flutter/material.dart';
import '../../widgets/custom_pagination.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/counter_providers.dart';
import '../../notifiers/accounts_notifier.dart';
import '../../services/account_service.dart';

import 'widgets/accounts/receivables_view.dart';
import 'widgets/accounts/payables_view.dart';
import 'widgets/accounts/ledger_view.dart';
import 'widgets/accounts/reports_view.dart';
import 'widgets/accounts/accounts_common_widgets.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  int _activeTab = 0;
  final List<String> _tabs = ['Transactions', 'Receivables (Credit)', 'Payables', 'Ledger', 'Reports'];

  AccountsState get _state => ref.watch(accountsProvider).value ?? AccountsState();
  List<TransactionModel> get _transactions => _state.transactions;
  List<String> get _categories => _state.categories;
  double get _totalIncome => _state.totalIncome;
  double get _totalExpenses => _state.totalExpenses;
  double get _netProfit => _state.netProfit;
  double get _cashInHand => _state.cashInHand;
  double get _bankBalance => _state.bankBalance;
  double get _outstandingReceivables => _state.outstandingReceivables;
  bool get _isLoading => ref.watch(accountsProvider).isLoading;

  String _selectedPeriod = 'All Time';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year', 'All Time'];

  String _selectedType = 'All Types';
  final List<String> _types = ['All Types', 'Income', 'Expense'];

  String _selectedCategory = 'All Categories';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    ref.read(accountsProvider.notifier).loadTransactions(
      selectedPeriod: _selectedPeriod,
      selectedType: _selectedType,
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  void _showAddTransactionDialog({String defaultType = 'Income'}) {
    final typeCtrl = TextEditingController(text: defaultType);
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final paymentModeCtrl = TextEditingController(text: 'Cash');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF0369A1), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 24),
                
                DropdownButtonFormField<String>(
                  value: typeCtrl.text,
                  decoration: const InputDecoration(labelText: 'Transaction Type', border: OutlineInputBorder()),
                  items: ['Income', 'Expense'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setStateDialog(() => typeCtrl.text = val!),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category (e.g. Sales, Rent)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: paymentModeCtrl.text,
                  decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                  items: ['Cash', 'Bank Transfer', 'UPI', 'Card'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setStateDialog(() => paymentModeCtrl.text = val!),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context, ), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (amountCtrl.text.isEmpty || categoryCtrl.text.isEmpty) return;
                        
                        final now = DateTime.now();
                        final payload = {
                          "date": now.toUtc().toIso8601String(),
                          "amount": double.tryParse(amountCtrl.text) ?? 0.0,
                          "transaction_type": typeCtrl.text.toUpperCase(),
                          "description": descriptionCtrl.text,
                        };

                        await TransactionService.saveTransaction(payload);
                        if (context.mounted) {
                          Navigator.pop(context, );
                          _loadTransactions();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF166534), foregroundColor: Colors.white),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(double val) => NumberFormat.currency(symbol: '₹ ', decimalDigits: 2).format(val);

  @override
  Widget build(BuildContext context) {
    final totalRecords = _transactions.length;
    final totalPages = (totalRecords / _itemsPerPage).ceil() == 0 ? 1 : (totalRecords / _itemsPerPage).ceil();
    final startIdx = (_currentPage - 1) * _itemsPerPage;
    final endIdx = (startIdx + _itemsPerPage > totalRecords) ? totalRecords : startIdx + _itemsPerPage;
    final pagedTxns = _transactions.isNotEmpty ? _transactions.sublist(startIdx, endIdx) : <TransactionModel>[];

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 1000;
        
        Widget leftColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text('Manage income, expenses, payments and financial reports', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _loadTransactions(),
                          icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                          tooltip: 'Refresh',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTransactionDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Transaction'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 250, child: AccountsWidgets.buildStatCard('Total Income', _fmt(_totalIncome), Icons.currency_rupee, const Color(0xFFDCFCE7), const Color(0xFF166534))),
                      const SizedBox(width: 16),
                      SizedBox(width: 250, child: AccountsWidgets.buildStatCard('Total Expenses', _fmt(_totalExpenses), Icons.credit_card, const Color(0xFFFEE2E2), const Color(0xFFB91C1C))),
                      const SizedBox(width: 16),
                      SizedBox(width: 250, child: AccountsWidgets.buildStatCard('Net Profit', _fmt(_netProfit), Icons.bar_chart, const Color(0xFFE0F2FE), const Color(0xFF0369A1))),
                      const SizedBox(width: 16),
                      SizedBox(width: 250, child: AccountsWidgets.buildStatCard('Outstanding Receivables', _fmt(_outstandingReceivables), Icons.people_alt, const Color(0xFFF3E8FF), const Color(0xFF7E22CE))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Content Area
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tabs
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                              _tabs.length,
                              (index) => InkWell(
                                onTap: () => setState(() => _activeTab = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _activeTab == index ? const Color(0xFF22C55E) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      color: _activeTab == index ? const Color(0xFF166534) : const Color(0xFF64748B),
                                      fontWeight: _activeTab == index ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                        
                        if (_activeTab == 0) ...[
                          // Filters
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AccountsWidgets.buildDynamicDropdown(_selectedPeriod, _periods, (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedPeriod = newValue);
                                    _loadTransactions();
                                  }
                                }),
                                AccountsWidgets.buildDynamicDropdown(_selectedType, _types, (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedType = newValue);
                                    _loadTransactions();
                                  }
                                }),
                                AccountsWidgets.buildDynamicDropdown(_selectedCategory, _categories, (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedCategory = newValue);
                                    _loadTransactions();
                                  }
                                }),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 350, minWidth: 200),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        icon: Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                                        hintText: 'Search by description, customer, invoice no...',
                                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        _searchQuery = value;
                                        _loadTransactions();
                                      },
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPeriod = 'All Time';
                                      _selectedType = 'All Types';
                                      _selectedCategory = 'All Categories';
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                    _loadTransactions();
                                  },
                                  icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF1E293B)),
                                  label: const Text('Reset', style: TextStyle(color: Color(0xFF1E293B))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                        ),
                        
                        LayoutBuilder(builder: (context, constraints) {
                          final tableWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 800.0;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: tableWidth,
                              child: Column(
                                  children: [
                                    // Table Headers
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      color: const Color(0xFFF8FAFC),
                                      child: Row(
                                        children: const [
                                          SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 2, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          Expanded(flex: 1, child: Text('Debit (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                                          Expanded(flex: 1, child: Text('Credit (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                                          Expanded(flex: 1, child: Text('Balance (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                                          SizedBox(width: 100, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                        ],
                                      ),
                                    ),
                                    
                                    // Table Body
                                    _isLoading 
                              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                              : pagedTxns.isEmpty
                                ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No transactions found. Add one to get started!', style: TextStyle(color: Color(0xFF64748B)))))
                                : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pagedTxns.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, index) {
                              final txn = pagedTxns[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(txn.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                          Text(txn.time, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: txn.type == 'Income' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(txn.type == 'Income' ? Icons.arrow_outward : Icons.arrow_downward, 
                                                size: 12, color: txn.type == 'Income' ? const Color(0xFF166534) : const Color(0xFFB91C1C)),
                                              const SizedBox(width: 4),
                                              Text(txn.type, style: TextStyle(fontSize: 11, color: txn.type == 'Income' ? const Color(0xFF166534) : const Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(flex: 1, child: Text(txn.category, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 3, child: Text(txn.description, style: const TextStyle(fontSize: 12))),
                                    Expanded(flex: 1, child: Text(txn.type == 'Expense' ? _fmt(txn.amount) : '-', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                                    Expanded(flex: 1, child: Text(txn.type == 'Income' ? _fmt(txn.amount) : '-', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                                    Expanded(flex: 1, child: Text(_fmt(txn.runningBalance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF64748B)), onPressed: () {
                                            AccountsWidgets.showTransactionDetails(context, txn);
                                          }, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                                          const SizedBox(width: 8),
                                          IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)), onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Transaction'),
                                                content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    onPressed: () async {
                                                      Navigator.pop(context);
                                                      await TransactionService.deleteTransaction(txn.id);
                                                      _loadTransactions();
                                                    },
                                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        // Pagination
                        if (totalRecords > 0) Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              Text('Showing ${startIdx + 1} to $endIdx of $totalRecords records', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              CustomPagination(
                                currentPage: _currentPage,
                                totalPages: totalPages,
                                onPageChanged: (page) {
                                  setState(() => _currentPage = page);
                                },
                              ),
                            ],
                          ),
                        ),
                        ] else if (_activeTab == 1) ...[
                          const ReceivablesView(),
                        ] else if (_activeTab == 2) ...[
                          const PayablesView(),
                        ] else if (_activeTab == 3) ...[
                          const LedgerView(),
                        ] else if (_activeTab == 4) ...[
                          const ReportsView(),
                        ],
                      ],
                    ),
                  ),
              ],
            );

        Widget rightSidebar = Column(
              children: [
                AccountsWidgets.buildRightCard(
                  title: 'Account Summary',
                  child: Column(
                    children: [
                      AccountsWidgets.buildSummaryRow(Icons.money, 'Cash in Hand', _fmt(_cashInHand), const Color(0xFF22C55E)),
                      AccountsWidgets.buildSummaryRow(Icons.account_balance, 'Bank Balance', _fmt(_bankBalance), const Color(0xFF3B82F6)),
                      AccountsWidgets.buildSummaryRow(Icons.credit_card, 'Total Income', _fmt(_totalIncome), const Color(0xFF64748B)),
                      AccountsWidgets.buildSummaryRow(Icons.credit_score, 'Total Expenses', _fmt(_totalExpenses), const Color(0xFFEF4444)),
                      AccountsWidgets.buildSummaryRow(Icons.bar_chart, 'Net Profit', _fmt(_netProfit), const Color(0xFF3B82F6)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AccountsWidgets.buildRightCard(
                  title: 'Quick Actions',
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AccountsWidgets.buildActionBtn('Receive Payment', Icons.download, const Color(0xFFDCFCE7), const Color(0xFF166534), () => _showAddTransactionDialog(defaultType: 'Income')),
                          AccountsWidgets.buildActionBtn('Make Payment', Icons.upload, const Color(0xFFFEE2E2), const Color(0xFFB91C1C), () => _showAddTransactionDialog(defaultType: 'Expense')),
                          AccountsWidgets.buildActionBtn('Add Expense', Icons.receipt_long, const Color(0xFFF3E8FF), const Color(0xFF7E22CE), () => _showAddTransactionDialog(defaultType: 'Expense')),
                          AccountsWidgets.buildActionBtn('Bank Transfer', Icons.account_balance, const Color(0xFFE0F2FE), const Color(0xFF0369A1), () => _showAddTransactionDialog(defaultType: 'Expense')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AccountsWidgets.buildRightCard(
                  title: 'Recent Activities',
                  actionText: 'View All',
                  expandChild: false,
                  child: _transactions.isEmpty ? const Center(child: Text('No recent activities', style: TextStyle(color: Color(0xFF94A3B8)))) : ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _transactions.take(5).map((txn) => AccountsWidgets.buildActivityItem(
                        '${txn.type == 'Income' ? 'Payment received' : 'Payment sent'}: ${txn.category}', 
                        _fmt(txn.amount), 
                        '${txn.date} ${txn.time}', 
                        txn.type == 'Income' ? Colors.green : Colors.red,
                      )).toList(),
                    ),
                  ),
              ],
            );

        if (isDesktop) {
          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: leftColumn),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: rightSidebar),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                leftColumn,
                const SizedBox(height: 24),
                rightSidebar,
              ],
            ),
          );
        }
      }),
    );
  }

}
