import re

file_path = 'lib/screens/counter/billing_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Replace _currentBill.clear()
content = content.replace('_currentBill.clear()', 'ref.read(billingProvider.notifier).clearBill()')

# Replace _currentBill.removeAt(index)
content = re.sub(r'_currentBill\.removeAt\(([^)]+)\)', r'ref.read(billingProvider.notifier).removeItem(\1)', content)

# Fix _addToCart mutation
add_to_cart_mutation = r"_currentBill\[existingIndex\]\['qty'\] \+= 1;\s*_currentBill\[existingIndex\]\['total'\] = _currentBill\[existingIndex\]\['qty'\] \* _currentBill\[existingIndex\]\['price'\];"
add_to_cart_fix = r"ref.read(billingProvider.notifier).updateItemQuantity(existingIndex, currentQty + 1);"
content = re.sub(add_to_cart_mutation, add_to_cart_fix, content)

# Fix manual _currentBill.add(...) in _showCustomItemDialog
custom_item_pattern = r"_currentBill\.add\(\{\s*'name': name,\s*'brand': brand,\s*'qty': 1,\s*'price': price,\s*'total': price,\s*\}\);"
custom_item_fix = r"ref.read(billingProvider.notifier).addItem({'name': name, 'brand': brand, 'qty': 1, 'price': price, 'total': price});"
content = re.sub(custom_item_pattern, custom_item_fix, content)

# Replace any other _currentBill.add(...) with ref.read(billingProvider.notifier).addItem(...)
content = re.sub(r'_currentBill\.add\(', r'ref.read(billingProvider.notifier).addItem(', content)

# There is a quantity decrement/increment via icon buttons in the table
# Look for _currentBill[index]['qty']++ or similar. Let's find it.
# Actually, the python regex might be too complex for unknown patterns. Let's just run it for the known ones and check `flutter analyze`.

with open(file_path, 'w') as f:
    f.write(content)

print("Fixed _currentBill mutations in billing_screen.dart")
