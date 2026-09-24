import re

file_path = 'lib/screens/counter/customers_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Fix _showAddCustomerDialog tear-off
content = content.replace('onPressed: _showAddCustomerDialog,', 'onPressed: () => showAddCustomerDialog(context, _loadCustomers),')

# Fix CustomerStatCard usages
# Currently they look like:
# CustomerStatCard(title: 'Total Customers', '${_allCustomers.length}', Icons.people, AppColors.primaryLight, AppColors.primaryDark)
# I want to change it to:
# CustomerStatCard(title: 'Total Customers', value: '${_allCustomers.length}', icon: Icons.people, bgColor: AppColors.primaryLight, iconColor: AppColors.primaryDark)

def replacer(match):
    title = match.group(1)
    val = match.group(2)
    icon = match.group(3)
    bg = match.group(4)
    ic_col = match.group(5)
    return f"CustomerStatCard(title: {title}, value: {val}, icon: {icon}, bgColor: {bg}, iconColor: {ic_col}"

content = re.sub(r"CustomerStatCard\(title:\s*(.*?),\s*('[^']+'|\"[^\"]+\"|\d+),\s*([^,]+),\s*([^,]+),\s*([^,\)]+)", replacer, content)

with open(file_path, 'w') as f:
    f.write(content)

print("Fixed customers_screen.dart")
