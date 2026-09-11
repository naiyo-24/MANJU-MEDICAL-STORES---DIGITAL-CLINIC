import 'package:flutter/material.dart';
import '../../widgets/custom_pagination.dart';

import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';

import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';

import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int _activeTab = 0;
  final List<String> _tabs = ['Transactions', 'Receivables (Credit)', 'Payables', 'Ledger', 'Reports'];

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  String _selectedPeriod = 'All Time';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year', 'All Time'];

  String _selectedType = 'All Types';
  final List<String> _types = ['All Types', 'Income', 'Expense'];

  String _selectedCategory = 'All Categories';
  List<String> _categories = ['All Categories'];

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  double _cashInHand = 0;
  double _bankBalance = 0;

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1; // Reset to page 1 on reload
    });
    final allTxns = await TransactionService.getTransactions();
    
    // Dynamically build category list from all transactions
    final Set<String> catSet = {};
    for (var t in allTxns) {
      if (t.category.isNotEmpty) catSet.add(t.category);
    }
    final List<String> loadedCategories = ['All Categories', ...catSet.toList()..sort()];
    // If the currently selected category is not in the new list, reset it
    if (!loadedCategories.contains(_selectedCategory)) {
      _selectedCategory = 'All Categories';
    }
    
    final now = DateTime.now();
    final DateFormat format = DateFormat('dd MMM yyyy');
    
    List<TransactionModel> filteredTxns = [];
    
    for (var txn in allTxns) {
      try {
        final txnDate = format.parse(txn.date);
        bool include = false;
        
        // 1. Period Filter
        switch (_selectedPeriod) {
          case 'Today':
            include = txnDate.year == now.year && txnDate.month == now.month && txnDate.day == now.day;
            break;
          case 'This Week':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            include = txnDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
            break;
          case 'This Month':
            include = txnDate.year == now.year && txnDate.month == now.month;
            break;
          case 'This Year':
            include = txnDate.year == now.year;
            break;
          case 'All Time':
          default:
            include = true;
            break;
        }
        
        // 2. Type Filter
        if (include && _selectedType != 'All Types' && txn.type != _selectedType) {
          include = false;
        }

        // 3. Category Filter
        if (include && _selectedCategory != 'All Categories' && txn.category != _selectedCategory) {
          include = false;
        }

        // 4. Search Filter
        if (include && _searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!txn.description.toLowerCase().contains(query) &&
              !txn.category.toLowerCase().contains(query)) {
            include = false;
          }
        }
        
        if (include) {
          filteredTxns.add(txn);
        }
      } catch (e) {
        // Fallback for parsing errors, just include but still apply other filters if possible
        if (_selectedType != 'All Types' && txn.type != _selectedType) continue;
        if (_selectedCategory != 'All Categories' && txn.category != _selectedCategory) continue;
        filteredTxns.add(txn);
      }
    }
    
    double income = 0;
    double expenses = 0;
    double cash = 28450.0; // Base cash
    double bank = 112300.0; // Base bank

    for (var t in filteredTxns) {
      if (t.type == 'Income') {
        income += t.amount;
        if (t.paymentMode == 'Cash') cash += t.amount;
        else bank += t.amount;
      } else {
        expenses += t.amount;
        if (t.paymentMode == 'Cash') cash -= t.amount;
        else bank -= t.amount;
      }
    }

    if (mounted) {
      setState(() {
        _categories = loadedCategories;
        _transactions = filteredTxns;
        _totalIncome = income;
        _totalExpenses = expenses;
        _netProfit = income - expenses;
        _cashInHand = cash;
        _bankBalance = bank;
        _isLoading = false;
      });
    }
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
                        final newTxn = TransactionModel(
                          id: now.millisecondsSinceEpoch.toString(),
                          date: DateFormat('dd MMM yyyy').format(now),
                          time: DateFormat('hh:mm a').format(now),
                          type: typeCtrl.text,
                          category: categoryCtrl.text,
                          description: descriptionCtrl.text,
                          amount: double.tryParse(amountCtrl.text) ?? 0.0,
                          paymentMode: paymentModeCtrl.text,
                        );

                        await TransactionService.saveTransaction(newTxn);
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Left Column
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Income', _fmt(_totalIncome), Icons.currency_rupee, const Color(0xFFDCFCE7), const Color(0xFF166534))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Total Expenses', _fmt(_totalExpenses), Icons.credit_card, const Color(0xFFFEE2E2), const Color(0xFFB91C1C))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Net Profit', _fmt(_netProfit), Icons.bar_chart, const Color(0xFFE0F2FE), const Color(0xFF0369A1))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Outstanding Receivables', _fmt(138500.0), Icons.people_alt, const Color(0xFFF3E8FF), const Color(0xFF7E22CE))),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Content Area
                Expanded(
                  child: Container(
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
                        
                        // Filters
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _buildDynamicDropdown(_selectedPeriod, _periods, (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedPeriod = newValue);
                                  _loadTransactions();
                                }
                              }),
                              const SizedBox(width: 12),
                              _buildDynamicDropdown(_selectedType, _types, (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedType = newValue);
                                  _loadTransactions();
                                }
                              }),
                              const SizedBox(width: 12),
                              _buildDynamicDropdown(_selectedCategory, _categories, (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedCategory = newValue);
                                  _loadTransactions();
                                }
                              }),
                              const SizedBox(width: 12),
                              Expanded(
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
                              const SizedBox(width: 12),
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
                        Expanded(
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : pagedTxns.isEmpty
                              ? const Center(child: Text('No transactions found. Add one to get started!', style: TextStyle(color: Color(0xFF64748B))))
                              : ListView.separated(
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
                                    Expanded(flex: 1, child: Text('-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF64748B)), onPressed: () {}, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                                          const SizedBox(width: 8),
                                          IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)), onPressed: () {}, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                                          const SizedBox(width: 8),
                                          IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)), onPressed: () async {
                                            await TransactionService.deleteTransaction(txn.id);
                                            _loadTransactions();
                                          }, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
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
                        if (totalRecords > 0) Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          
          // Right Sidebar
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildRightCard(
                  title: 'Account Summary',
                  child: Column(
                    children: [
                      _buildSummaryRow(Icons.money, 'Cash in Hand', _fmt(_cashInHand), const Color(0xFF22C55E)),
                      _buildSummaryRow(Icons.account_balance, 'Bank Balance', _fmt(_bankBalance), const Color(0xFF3B82F6)),
                      _buildSummaryRow(Icons.credit_card, 'Total Income', _fmt(_totalIncome), const Color(0xFF64748B)),
                      _buildSummaryRow(Icons.credit_score, 'Total Expenses', _fmt(_totalExpenses), const Color(0xFFEF4444)),
                      _buildSummaryRow(Icons.bar_chart, 'Net Profit', _fmt(_netProfit), const Color(0xFF3B82F6)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildRightCard(
                  title: 'Quick Actions',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildActionBtn('Receive Payment', Icons.download, const Color(0xFFDCFCE7), const Color(0xFF166534), () => _showAddTransactionDialog(defaultType: 'Income'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildActionBtn('Make Payment', Icons.upload, const Color(0xFFFEE2E2), const Color(0xFFB91C1C), () => _showAddTransactionDialog(defaultType: 'Expense'))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildActionBtn('Add Expense', Icons.receipt_long, const Color(0xFFF3E8FF), const Color(0xFF7E22CE), () => _showAddTransactionDialog(defaultType: 'Expense'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildActionBtn('Bank Transfer', Icons.account_balance, const Color(0xFFE0F2FE), const Color(0xFF0369A1), () => _showAddTransactionDialog(defaultType: 'Expense'))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildRightCard(
                    title: 'Recent Activities',
                    actionText: 'View All',
                    expandChild: true,
                    child: _transactions.isEmpty ? const Center(child: Text('No recent activities', style: TextStyle(color: Color(0xFF94A3B8)))) : ListView(
                      children: _transactions.take(5).map((txn) => _buildActivityItem(
                        '${txn.type == 'Income' ? 'Payment received' : 'Payment sent'}: ${txn.category}', 
                        _fmt(txn.amount), 
                        '${txn.date} ${txn.time}', 
                        txn.type == 'Income' ? Colors.green : Colors.red,
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBgColor, Color iconColor, [String? trend]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (trend != null) ...[
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 12, color: iconColor),
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildDynamicDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRightCard({required String title, required Widget child, String? actionText, bool expandChild = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              if (actionText != null)
                Text(actionText, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color bgColor, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String amount, String time, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
