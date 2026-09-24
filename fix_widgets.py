import re

file_path = 'lib/screens/counter/widgets/accounts/accounts_common_widgets.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Fix static method declarations
content = re.sub(r'static Widget AccountsWidgets\.([a-zA-Z0-9_]+)\(', r'static Widget \1(', content)

# Fix missing imports for TransactionModel
if "import '../../../../services/transaction_service.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../../../services/transaction_service.dart';")

# Fix missing _fmt. We can just add a static _fmt to AccountsWidgets
fmt_code = """
  static String _fmt(double val) {
    if (val == 0) return '0';
    return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
  }
"""
if "_fmt(double val)" not in content:
    content = content.replace("class AccountsWidgets {\n", "class AccountsWidgets {\n" + fmt_code)

# Ensure _showTransactionDetails is not in the common widgets class or is properly handled.
# _showTransactionDetails uses `context`, so it cannot be extracted as is if it doesn't take context.
# Let's remove _showTransactionDetails from accounts_common_widgets.dart if it's there.
content = re.sub(r'  void _showTransactionDetails.*?\}\s*\}\s*,\s*\);\s*\}\s*', '', content, flags=re.DOTALL)

with open(file_path, 'w') as f:
    f.write(content)
