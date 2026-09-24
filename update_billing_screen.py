import re

file_path = 'lib/screens/counter/billing_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Remove _showAddCustomerDialog
pattern_customer = r"  void _showAddCustomerDialog\(\).*?\}\s*\}\s*,\s*\);\s*\}\s*"
content = re.sub(pattern_customer, '', content, flags=re.DOTALL)

# Remove _showAddCustomItemDialog
pattern_item = r"  void _showAddCustomItemDialog\(\).*?\}\s*\}\s*,\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(16\)\),\s*\);\s*\}\s*,\s*\);\s*\}\s*"
content = re.sub(pattern_item, '', content, flags=re.DOTALL)

# Let's do a more robust removal since regex over 250 lines might fail or timeout.
# We will just use the same extractor logic to find start and end indices and slice the string.

def remove_method(content, method_name):
    pattern = r"  void " + method_name + r"\("
    match = re.search(pattern, content)
    if not match:
        return content
    
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
        # Also remove trailing newlines
        while end_idx < len(content) and content[end_idx] in ['\n', '\r']:
            end_idx += 1
        return content[:start_idx] + content[end_idx:]
    return content

# Reload fresh content
with open(file_path, 'r') as f:
    content = f.read()

content = remove_method(content, '_showAddCustomerDialog')
content = remove_method(content, '_showAddCustomItemDialog')

# Add import if missing
if "import 'widgets/billing/billing_dialogs.dart';" not in content:
    content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", 
                              "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'widgets/billing/billing_dialogs.dart';")

# Update calls to _showAddCustomerDialog() -> BillingDialogs.showAddCustomerDialog(context, ...)
call_customer_replace = """BillingDialogs.showAddCustomerDialog(context, (name, phone, id) {
                                              setState(() {
                                                _customerNameController.text = name;
                                                _customerPhoneController.text = phone;
                                                _savedCustomerId = id;
                                              });
                                            })"""
content = content.replace("_showAddCustomerDialog()", call_customer_replace)

# Update calls to _showAddCustomItemDialog() -> BillingDialogs.showAddCustomItemDialog(context, ...)
call_item_replace = """BillingDialogs.showAddCustomItemDialog(context, (item) {
                                            ref.read(billingProvider.notifier).addItem(item);
                                          })"""
content = content.replace("_showAddCustomItemDialog()", call_item_replace)

with open(file_path, 'w') as f:
    f.write(content)

print("Billing screen updated successfully.")
