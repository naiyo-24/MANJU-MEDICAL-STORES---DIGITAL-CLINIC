import os
import re

files_to_update = [
    'lib/screens/counter/customers_screen.dart',
    'lib/screens/counter/widgets/customers/customer_dialogs.dart',
    'lib/screens/counter/widgets/customers/customer_stat_card.dart',
    'lib/screens/counter/widgets/customers/view_bill_dialog.dart',
]

color_map = {
    '0xFF1E293B': 'AppColors.textPrimary',
    '0xFF64748B': 'AppColors.textSecondary',
    '0xFF94A3B8': 'AppColors.textHint',
    '0xFF166534': 'AppColors.primaryDark',
    '0xFF22C55E': 'AppColors.primary',
    '0xFFDCFCE7': 'AppColors.primaryLight',
    '0xFFF8FAFC': 'AppColors.background',
    '0xFFE2E8F0': 'AppColors.border',
    '0xFFF1F5F9': 'AppColors.divider',
    '0xFF334155': 'AppColors.textPrimary', # Close match
    '0xFF0369A1': 'AppColors.info', 
    '0xFFE0F2FE': 'AppColors.infoLight',
    '0xFFFEE2E2': 'AppColors.errorLight',
    '0xFF991B1B': 'AppColors.error',
    '0xFFF3E8FF': 'AppColors.secondaryLight',
    '0xFF7E22CE': 'AppColors.secondary',
    '0xFFFFEDD5': 'AppColors.warningLight',
    '0xFFC2410C': 'AppColors.warning',
    '0xFFF0FDF4': 'AppColors.primaryLight', # Close match
}

import_line = "import '../../../../themes/app_colors.dart';\n"
import_line_base = "import '../../themes/app_colors.dart';\n"

for file_path in files_to_update:
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Do replacements
    for hex_code, app_color in color_map.items():
        # Handle 'const Color(0xFF...)' -> 'AppColors...' (removing const since AppColors fields are const)
        content = re.sub(r'const\s+Color\(' + hex_code + r'\)', app_color, content)
        # Handle 'Color(0xFF...)' -> 'AppColors...'
        content = re.sub(r'Color\(' + hex_code + r'\)', app_color, content)
        
    # Ensure import is present
    if 'AppColors' in content and 'app_colors.dart' not in content:
        lines = content.split('\n')
        if 'widgets/customers' in file_path:
            lines.insert(1, import_line)
        else:
            lines.insert(1, import_line_base)
        content = '\n'.join(lines)
        
    with open(file_path, 'w') as f:
        f.write(content)

print("Color replacements complete.")
