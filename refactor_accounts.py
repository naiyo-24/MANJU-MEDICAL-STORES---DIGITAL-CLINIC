import re

file_path = 'lib/screens/counter/accounts_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# 1. Imports
if 'import \'../../providers/counter_providers.dart\';' not in content:
    content = content.replace(
        "import '../../services/transaction_service.dart';", 
        "import '../../services/transaction_service.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../providers/counter_providers.dart';"
    )

# 2. Change StatefulWidget to ConsumerStatefulWidget
content = content.replace("class AccountsScreen extends StatefulWidget", "class AccountsScreen extends ConsumerStatefulWidget")
content = content.replace("State<AccountsScreen> createState() => _AccountsScreenState();", "ConsumerState<AccountsScreen> createState() => _AccountsScreenState();")
content = content.replace("class _AccountsScreenState extends State<AccountsScreen>", "class _AccountsScreenState extends ConsumerState<AccountsScreen>")

# 3. Modify state variables
# Remove _transactions, _isLoading, totals, categories list (except the active search states which we keep as local states for UI inputs)
# Wait, actually, _selectedPeriod, _selectedType, _selectedCategory, _searchQuery can be kept locally to feed into the notifier OR they can trigger notifier fetches when they change.
content = re.sub(r'  List<TransactionModel> _transactions = \[\];\n  bool _isLoading = true;\n\n', '', content)
content = re.sub(r'  List<String> _categories = \[\'All Categories\'\];\n\n', '', content)
content = re.sub(r'  double _totalIncome = 0;\n  double _totalExpenses = 0;\n  double _netProfit = 0;\n  double _cashInHand = 0;\n  double _bankBalance = 0;\n  double _outstandingReceivables = 0;\n\n', '', content)

# 4. Rewrite initState
init_state_pattern = r'  @override\n  void initState\(\) \{\n    super\.initState\(\);\n    _loadTransactions\(\);\n  \}'
init_state_fix = '''  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }'''
content = re.sub(init_state_pattern, init_state_fix, content, flags=re.DOTALL)

# 5. Rewrite _loadTransactions
load_txns_pattern = r'  Future<void> _loadTransactions\(\) async \{.*?\n  \}\n\n  void _showAddTransactionDialog'
load_txns_fix = '''  Future<void> _loadTransactions() async {
    ref.read(accountsProvider.notifier).loadTransactions(
      selectedPeriod: _selectedPeriod,
      selectedType: _selectedType,
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  void _showAddTransactionDialog'''
content = re.sub(load_txns_pattern, load_txns_fix, content, flags=re.DOTALL)

# 6. Inside _showAddTransactionDialog, change _loadTransactions to await notifier.addTransaction
# Or we can just keep _loadTransactions() since it triggers the notifier anyway!
# Wait, let's keep _loadTransactions() calls as they are, they just trigger the notifier now.

# 7. Modify build method to get data from accountsProvider
build_pattern = r'  @override\n  Widget build\(BuildContext context\) \{\n    final totalPages = \(_transactions\.length / _itemsPerPage\)\.ceil\(\);'
build_fix = '''  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final AccountsState accountsState = accountsAsync.value ?? AccountsState();
    
    final _transactions = accountsState.transactions;
    final _categories = accountsState.categories;
    final _totalIncome = accountsState.totalIncome;
    final _totalExpenses = accountsState.totalExpenses;
    final _netProfit = accountsState.netProfit;
    final _cashInHand = accountsState.cashInHand;
    final _bankBalance = accountsState.bankBalance;
    final _outstandingReceivables = accountsState.outstandingReceivables;
    final _isLoading = accountsAsync.isLoading;
    
    final totalPages = (_transactions.length / _itemsPerPage).ceil();'''
content = content.replace("  @override\n  Widget build(BuildContext context) {\n    final totalPages = (_transactions.length / _itemsPerPage).ceil();", build_fix)


# 8. Fix transaction deletion to use loadTransactions
delete_pattern = r'await TransactionService\.deleteTransaction\(txn\.id\);\n                                                      _loadTransactions\(\);'
delete_fix = r'await TransactionService.deleteTransaction(txn.id);\n                                                      _loadTransactions();'
# no change needed for delete because _loadTransactions works.

with open(file_path, 'w') as f:
    f.write(content)

print("Accounts screen refactored.")
