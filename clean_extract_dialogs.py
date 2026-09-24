import re
import sys

file_path = 'lib/screens/counter/billing_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

def extract_method(content, method_name):
    pattern = r"  void " + method_name + r"\("
    match = re.search(pattern, content)
    if not match:
        return content, ""
    
    start_idx = match.start()
    open_braces = 0
    in_method = False
    end_idx = -1
    
    for i in range(start_idx, len(content)):
        if content[i] == '{':
            open_braces += 1
            in_method = True
        elif content[i] == '}':
            open_braces -= 1
            
        if in_method and open_braces == 0:
            end_idx = i + 1
            break
            
    if end_idx != -1:
        method_body = content[start_idx:end_idx]
        return method_body
    return ""

customer_dialog = extract_method(content, '_showAddCustomerDialog')
item_dialog = extract_method(content, '_showAddCustomItemDialog')

dialogs_file_content = """import 'package:flutter/material.dart';
import '../../../../services/customer_service.dart';

class BillingDialogs {
"""

# Modify customer dialog
customer_dialog = customer_dialog.replace("void _showAddCustomerDialog()", "static void showAddCustomerDialog(BuildContext context, Function(String, String, String) onSuccess)")
# Replace the setState setting _savedCustomerId
customer_dialog = re.sub(r'setState\(\(\) \{\s*_savedCustomerId = customer\[\'id\'\];\s*\}\);', 'onSuccess(customer[\'name\'], customer[\'phone\'], customer[\'id\']);', customer_dialog)
dialogs_file_content += customer_dialog + "\n\n"

# Modify item dialog
item_dialog = item_dialog.replace("void _showAddCustomItemDialog()", "static void showAddCustomItemDialog(BuildContext context, Function(Map<String, dynamic>) onAdd)")
# Remove setState wrapper around _currentBill.add
item_dialog = re.sub(r'setState\(\(\) \{\s*_currentBill\.add\(\{', 'onAdd({', item_dialog)
# We also have to remove the closing brackets of setState.
# Let's just do it with a simple replacement of the whole setState block.
# Actually, the user already changed `_currentBill.add` to `ref.read(billingProvider.notifier).addItem({`
item_dialog = item_dialog.replace("ref.read(billingProvider.notifier).addItem({", "onAdd({")
item_dialog = re.sub(r'setState\(\(\) \{\s*onAdd\(\{', 'onAdd({', item_dialog)
item_dialog = item_dialog.replace("});\n                  Navigator.pop(context);", "\n                  Navigator.pop(context);")

dialogs_file_content += item_dialog + "\n}\n"

with open('lib/screens/counter/widgets/billing/billing_dialogs.dart', 'w') as f:
    f.write(dialogs_file_content)

print("Billing dialogs extracted correctly.")
