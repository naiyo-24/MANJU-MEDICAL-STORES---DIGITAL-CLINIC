import re

file_path = 'lib/screens/counter/inventory_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Add riverpod import and provider
if 'import \'package:flutter_riverpod/flutter_riverpod.dart\';' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../providers/counter_providers.dart';")

# Change StatefulWidget to ConsumerStatefulWidget
content = content.replace("class InventoryScreen extends StatefulWidget", "class InventoryScreen extends ConsumerStatefulWidget")
content = content.replace("State<InventoryScreen> createState() => _InventoryScreenState();", "ConsumerState<InventoryScreen> createState() => _InventoryScreenState();")
content = content.replace("class _InventoryScreenState extends State<InventoryScreen>", "class _InventoryScreenState extends ConsumerState<InventoryScreen>")

# Remove local state variables
content = re.sub(r'  List<InventoryItem> _medicines = \[\];\n  bool _isLoading = true;\n  String _errorMessage = \'\';\n', '', content)

# Modify initState to use ref.read
init_state_pattern = r'  @override\n  void initState\(\) \{\n    super.initState\(\);\n    _fetchData\(\);\n  \}'
init_state_fix = '''  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }'''
content = content.replace("    super.initState();\n    _fetchData();", "    super.initState();\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      _fetchData();\n    });")


# Rewrite _fetchData
fetch_data_pattern = r'  Future<void> _fetchData\(\[String\? query\]\) async \{.*?\n  \}'
fetch_data_fix = '''  Future<void> _fetchData([String? query]) async {
    ref.read(inventoryProvider.notifier).loadInventory(
      searchQuery: query ?? _searchController.text,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
  }'''
content = re.sub(fetch_data_pattern, fetch_data_fix, content, flags=re.DOTALL)

# Refactor the build method to use AsyncValue
# Need to replace the body of the build method
build_pattern = r'  @override\n  Widget build\(BuildContext context\) \{\n    return Scaffold\('
build_fix = '''  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    
    return Scaffold('''
content = content.replace("  @override\n  Widget build(BuildContext context) {\n    return Scaffold(", build_fix)

# Refactor the table body which probably uses _isLoading and _errorMessage
# We need to find _isLoading ? ... : _errorMessage.isNotEmpty ? ... :
table_body_pattern = r'                              _isLoading\n                                \? const.*?\}\),\n'
table_body_fix = '''                              inventoryAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                                data: (items) {
                                  if (items.isEmpty) {
                                    return const Center(child: Text('No inventory items found', style: TextStyle(color: Color(0xFF94A3B8))));
                                  }
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return _buildInventoryRow(item, index);
                                    },
                                  );
                                },
                              ),
'''
# I'll just use a more targeted replacement for the _isLoading block
is_loading_block = r'_isLoading\s*\?\s*const Center\(child: CircularProgressIndicator\(\)\)\s*:\s*_errorMessage\.isNotEmpty\s*\?\s*Center\(child: Text\(_errorMessage.*?\)\)\s*:\s*_medicines\.isEmpty\s*\?\s*const Center\(child: Text\(\'No inventory items found\'.*?\)\)\s*:\s*ListView\.builder\([\s\S]*?itemBuilder:\s*\(context,\s*index\)\s*\{[\s\S]*?final\s*item\s*=\s*_medicines\[index\];\s*return\s*_buildInventoryRow\(item,\s*index\);\s*\},\s*\)'
content = re.sub(is_loading_block, table_body_fix.strip(), content)

# _exportData uses _medicines
export_pattern = r'final data = _medicines\.map\(\(m\) => m\.toMap\(\)\)\.toList\(\);'
export_fix = '''final currentState = ref.read(inventoryProvider);
    final data = currentState.valueOrNull?.map((m) => m.toMap()).toList() ?? [];'''
content = re.sub(export_pattern, export_fix, content)

with open(file_path, 'w') as f:
    f.write(content)

print("Inventory screen refactored.")
