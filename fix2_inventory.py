import re

file_path = 'lib/screens/counter/inventory_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Remove unused _onSearchChanged
content = re.sub(r'  void _onSearchChanged\(String value\) \{\n    _fetchData\(value\);\n  \}\n', '', content)

# Fix valueOrNull to .value
content = content.replace("final data = currentState.valueOrNull?.map((m) => m.toMap()).toList() ?? [];", "final data = currentState.value?.map((m) => m.toMap()).toList() ?? [];")

# Add inventoryAsync as parameter to _buildMedicineTable
content = content.replace("Widget _buildMedicineTable(BoxConstraints tableConstraints) {", "Widget _buildMedicineTable(BoxConstraints tableConstraints, AsyncValue<List<InventoryItem>> inventoryAsync) {")

# Pass it from build method
content = content.replace("_buildMedicineTable(tableConstraints)", "_buildMedicineTable(tableConstraints, inventoryAsync)")

with open(file_path, 'w') as f:
    f.write(content)
