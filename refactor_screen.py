import re

file_path = 'lib/screens/counter/customers_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# 1. Add imports
if 'flutter_riverpod.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", 
        "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../providers/counter_providers.dart';")

# 2. Change class signatures
content = content.replace('class CustomersScreen extends StatefulWidget', 'class CustomersScreen extends ConsumerStatefulWidget')
content = content.replace('State<CustomersScreen> createState() => _CustomersScreenState();', 'ConsumerState<CustomersScreen> createState() => _CustomersScreenState();')
content = content.replace('class _CustomersScreenState extends State<CustomersScreen>', 'class _CustomersScreenState extends ConsumerState<CustomersScreen>')

# 3. Remove _allCustomers and _loadCustomers
content = re.sub(r'List<Map<String,\s*dynamic>>\s*_allCustomers\s*=\s*\[\];', '', content)

load_cust_pattern = r'Future<void> _loadCustomers\(\) async \{.*?\n  \}\n'
content = re.sub(load_cust_pattern, '', content, flags=re.DOTALL)

# In initState, replace _loadCustomers() with ref.read
init_state_pattern = r'void initState\(\) \{\s*super\.initState\(\);\s*_loadCustomers\(\);\s*\}'
content = re.sub(init_state_pattern, '''void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
    });
  }''', content)

# 4. In build, fetch _allCustomers from ref.watch
build_start = '  Widget build(BuildContext context) {'
build_replacement = '''  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerProvider);
    
    return customerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (_allCustomers) {
        if (_selectedCustomer != null) {
          final updatedCust = _allCustomers.where((c) => c['full_id'] == _selectedCustomer!['full_id']).firstOrNull;
          if (updatedCust != null && updatedCust != _selectedCustomer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCustomer = updatedCust);
            });
          }
        }
'''

content = content.replace(build_start, build_replacement)

# We need to add the closing bracket for customerAsync.when at the very end of build method
# Since we know `return Container(` is used for the main widget, and it ends right before `_buildCustomerRow`.
# Let's find `Widget _buildCustomerRow` and insert the closing brackets right before it.
# Wait, the build method ends at `  }` before `  Widget _buildCustomerRow`.
# We need to find `  Widget _buildCustomerRow` and insert `    );\n  }\n` before it. But we also need to remove the original `  }` of build.

# Let's just find `    );\n  }\n\n  Widget _buildCustomerRow` and replace it with `    );\n      },\n    );\n  }\n\n  Widget _buildCustomerRow`.
# A safer way: Find the `return Container(` inside build, it returns the main widget.
# Let's use regex to find the end of build method.
content = re.sub(r'    \);\n  \}\n\n  Widget _buildCustomerRow', 
                 '    );\n      },\n    );\n  }\n\n  Widget _buildCustomerRow', 
                 content)

# 5. Fix _loadCustomers callbacks
content = content.replace('showAddCustomerDialog(context, _loadCustomers)', 'showAddCustomerDialog(context, () => ref.read(customerProvider.notifier).loadCustomers())')
content = content.replace('showEditCustomerDialog(context, customer, _loadCustomers)', 'showEditCustomerDialog(context, customer, () => ref.read(customerProvider.notifier).loadCustomers())')

with open(file_path, 'w') as f:
    f.write(content)

print("Updated customers_screen.dart")
