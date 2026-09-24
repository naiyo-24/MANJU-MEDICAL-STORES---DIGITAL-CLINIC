import re

file_path = 'lib/screens/counter/billing_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

def extract_method(content, method_name):
    # Find the start of the method
    pattern = r"  void " + method_name + r"\("
    match = re.search(pattern, content)
    if not match:
        return content, ""
    
    start_idx = match.start()
    
    # Track braces to find the end
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
        new_content = content[:start_idx] + content[end_idx:]
        return new_content, method_body
    return content, ""

content, customer_dialog = extract_method(content, '_showAddCustomerDialog')
content, item_dialog = extract_method(content, '_showAddCustomItemDialog')

# Make them static methods of BillingDialogs, taking context and other necessary params
# We will do this manually in dart later, so for now just dump them.
# Wait, it's easier to just pass the whole state or ref, or define them as functions taking BuildContext, WidgetRef, and callbacks.

dialogs_file_content = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/customer_service.dart';

class BillingDialogs {
"""

# Process customer dialog
customer_dialog = customer_dialog.replace("void _showAddCustomerDialog()", "static void showAddCustomerDialog(BuildContext context)")
customer_dialog = customer_dialog.replace("setState(", "// setState(") 
dialogs_file_content += customer_dialog + "\n\n"

# Process item dialog
item_dialog = item_dialog.replace("void _showAddCustomItemDialog()", "static void showAddCustomItemDialog(BuildContext context, Function(Map<String, dynamic>) onAdd)")
item_dialog = item_dialog.replace("setState(() {", "")
item_dialog = item_dialog.replace("_currentBill.add({", "onAdd({")
# Wait, there's a closing brace for setState that we need to handle. 
# It's better to just leave it as is and fix manually if it's too complex.

dialogs_file_content += item_dialog + "\n}\n"

with open('lib/screens/counter/widgets/billing/billing_dialogs.dart', 'w') as f:
    f.write(dialogs_file_content)

# We won't modify billing_screen.dart just yet because we might break it.
# We will just write the extracted text to a new file and manually fix it up.
