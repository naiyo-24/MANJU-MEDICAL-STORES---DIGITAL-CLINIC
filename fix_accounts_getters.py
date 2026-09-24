import re

file_path = 'lib/screens/counter/accounts_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Insert the getters
getters = '''  AccountsState get _state => ref.watch(accountsProvider).value ?? AccountsState();
  List<TransactionModel> get _transactions => _state.transactions;
  List<String> get _categories => _state.categories;
  double get _totalIncome => _state.totalIncome;
  double get _totalExpenses => _state.totalExpenses;
  double get _netProfit => _state.netProfit;
  double get _cashInHand => _state.cashInHand;
  double get _bankBalance => _state.bankBalance;
  double get _outstandingReceivables => _state.outstandingReceivables;
  bool get _isLoading => ref.watch(accountsProvider).isLoading;
'''

pattern = r'(class _AccountsScreenState extends ConsumerState<AccountsScreen> \{\n  int _activeTab = 0;\n  final List<String> _tabs = \[\'Transactions\', \'Receivables \(Credit\)\', \'Payables\', \'Ledger\', \'Reports\'\];\n)'
content = re.sub(pattern, r'\1\n' + getters, content)

with open(file_path, 'w') as f:
    f.write(content)
