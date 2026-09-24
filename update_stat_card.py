import sys

with open('lib/screens/counter/customers_screen.dart', 'r') as f:
    lines = f.readlines()

import_line = "import 'widgets/customers/customer_stat_card.dart';\n"
if import_line not in lines:
    lines.insert(10, import_line)

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor, {String? subtitle}) {" in line:
        start_idx = i
        brace_count = 0
        started = False
        for j in range(i, len(lines)):
            brace_count += lines[j].count('{') - lines[j].count('}')
            if '{' in lines[j]:
                started = True
            if started and brace_count == 0:
                end_idx = j
                break
        break

if start_idx != -1 and end_idx != -1:
    del lines[start_idx:end_idx+1]
    
    # replace calls
    for i in range(len(lines)):
        lines[i] = lines[i].replace("_buildStatCard(", "CustomerStatCard(title: ")
        
        # We need a regex or split approach because _buildStatCard used positional args, and CustomerStatCard uses named args.
        # Actually, it's easier to just do it via regex in python.
        
import re
for i in range(len(lines)):
    lines[i] = re.sub(r'_buildStatCard\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+)(.*?)\)', 
                      r'CustomerStatCard(title: \1, value: \2, icon: \3, bgColor: \4, iconColor: \5\6)', lines[i])

with open('lib/screens/counter/customers_screen.dart', 'w') as f:
    f.writelines(lines)
print("Successfully updated customers_screen.dart for stat_card")
