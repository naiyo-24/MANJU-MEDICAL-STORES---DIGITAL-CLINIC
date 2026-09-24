import re

file_path = 'lib/screens/counter/accounts_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# We can replace "_buildStatCard" with "AccountsWidgets.buildStatCard"
replacements = {
    "_buildStatCard": "AccountsWidgets.buildStatCard",
    "_buildDynamicDropdown": "AccountsWidgets.buildDynamicDropdown",
    "_buildRightCard": "AccountsWidgets.buildRightCard",
    "_buildSummaryRow": "AccountsWidgets.buildSummaryRow",
    "_buildActionBtn": "AccountsWidgets.buildActionBtn",
    "_buildDetailRow": "AccountsWidgets.buildDetailRow",
    "_buildActivityItem": "AccountsWidgets.buildActivityItem"
}

# The block from "  Widget _buildStatCard" to the end of the file is what we want to extract
# wait, there's `void _showAddTransactionDialog` and `void _showTransactionDetails` at the top, they are not widgets.
# Let's find the start of `Widget _buildStatCard`
idx = content.find("  Widget _buildStatCard")
if idx != -1:
    widgets_code = content[idx:]
    # Remove it from content
    content = content[:idx]
    
    # We need to make sure we close the `_AccountsScreenState` class which might have been closed inside widgets_code
    # Wait, the widgets are inside the class. So `idx` is inside the class. The class ends after them.
    # The last character of the file is a '}' closing the class.
    
    # Let's find the last '}' in widgets_code and remove it, putting it back to content.
    last_brace_idx = widgets_code.rfind('}')
    if last_brace_idx != -1:
        widgets_code = widgets_code[:last_brace_idx]
        content += "}\n"
    
    # Now create the accounts_common_widgets.dart
    accounts_widgets_path = 'lib/screens/counter/widgets/accounts/accounts_common_widgets.dart'
    
    widgets_content = """import 'package:flutter/material.dart';

class AccountsWidgets {
""" + widgets_code.replace("  Widget ", "  static Widget ").replace("  void ", "  static void ") + "\n}\n"
    
    # Fix the method calls in `widgets_content`
    for old, new in replacements.items():
        widgets_content = widgets_content.replace(old, new)
        
    with open(accounts_widgets_path, 'w') as f:
        f.write(widgets_content)

    # Fix the method calls in `content`
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    # Add import
    import_stmt = "import 'widgets/accounts/accounts_common_widgets.dart';\n"
    if "accounts_common_widgets.dart" not in content:
        content = content.replace(
            "import 'widgets/receivables_view.dart';", 
            "import 'widgets/receivables_view.dart';\nimport 'widgets/accounts/accounts_common_widgets.dart';"
        )
        
    with open(file_path, 'w') as f:
        f.write(content)

print("Done extracting accounts widgets.")
