import re

file_path = 'lib/screens/counter/accounts_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

pattern_to_remove = r'    final _transactions = accountsState\.transactions;\n    final _categories = accountsState\.categories;\n    final _totalIncome = accountsState\.totalIncome;\n    final _totalExpenses = accountsState\.totalExpenses;\n    final _netProfit = accountsState\.netProfit;\n    final _cashInHand = accountsState\.cashInHand;\n    final _bankBalance = accountsState\.bankBalance;\n    final _outstandingReceivables = accountsState\.outstandingReceivables;\n    final _isLoading = accountsAsync\.isLoading;\n'

content = re.sub(pattern_to_remove, '', content)

with open(file_path, 'w') as f:
    f.write(content)
