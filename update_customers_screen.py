import sys

with open('lib/screens/counter/customers_screen.dart', 'r') as f:
    lines = f.readlines()

import_line = "import 'widgets/customers/customer_dialogs.dart';\n"
if import_line not in lines:
    lines.insert(10, import_line)

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "void _showAddCustomerDialog()" in line:
        start_idx = i
    
    # We want to find the end of _buildModernTextField
    if "Widget _buildModernTextField" in line:
        # Search forward for the closing brace
        brace_count = 0
        started = False
        for j in range(i, len(lines)):
            brace_count += lines[j].count('{') - lines[j].count('}')
            if '{' in lines[j]:
                started = True
            if started and brace_count == 0:
                end_idx = j
                break

if start_idx != -1 and end_idx != -1:
    del lines[start_idx:end_idx+1]
    
    # Also replace method calls
    for i in range(len(lines)):
        lines[i] = lines[i].replace("_showAddCustomerDialog()", "showAddCustomerDialog(context, _loadCustomers)")
        lines[i] = lines[i].replace("_showEditCustomerDialog(customer)", "showEditCustomerDialog(context, customer, _loadCustomers)")
        # _showEditCustomerDialog might be called differently, let's check exact call
        lines[i] = lines[i].replace("_showEditCustomerDialog(", "showEditCustomerDialog(context, ")

    with open('lib/screens/counter/customers_screen.dart', 'w') as f:
        f.writelines(lines)
    print("Successfully updated customers_screen.dart")
else:
    print(f"Could not find bounds: {start_idx}, {end_idx}")

