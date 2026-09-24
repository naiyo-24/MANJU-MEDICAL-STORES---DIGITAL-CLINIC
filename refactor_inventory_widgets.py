import re

file_path = 'lib/screens/counter/inventory_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Add import
import_stmt = "import 'widgets/inventory/inventory_row.dart';\n"
if "inventory_row.dart" not in content:
    content = content.replace("import '../../services/export_service.dart';", "import '../../services/export_service.dart';\nimport 'widgets/inventory/inventory_row.dart';")

# Remove _buildStatusBadge
status_badge_pattern = r'  Widget _buildStatusBadge\(String status, \[String\? text\]\) \{.*?\n  \}\n\n'
content = re.sub(status_badge_pattern, '', content, flags=re.DOTALL)

# Replace the builder block with the new widget
row_pattern = r'                                          return Padding\(.*?width: 40,\s*child: PopupMenuButton<String>\([\s\S]*?itemBuilder: \(context\) => \[.*?\]\s*,\s*\)\s*,\s*\)\s*,\s*\]\s*,\s*\)\s*,\s*\);\s*'
replacement = r'''                                          return InventoryRowWidget(
                                            medicine: medicine,
                                            onEdit: () => _showEditMedicineDialog(medicine),
                                            onDelete: () => _confirmDeleteMedicine(medicine.id),
                                          );
'''
content = re.sub(row_pattern, replacement, content, flags=re.DOTALL)

# Remove final status = medicine.stockQuantity ...
status_calc = r'                                          final status = medicine\.stockQuantity <= 0.*?OK\'\)\);\s*'
content = re.sub(status_calc, '', content, flags=re.DOTALL)

with open(file_path, 'w') as f:
    f.write(content)
