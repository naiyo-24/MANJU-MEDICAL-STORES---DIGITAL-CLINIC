import sys

with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    lines = f.readlines()

def get_block_end(start_line):
    # Find matching brace and semicolon
    open_count = 0
    in_block = False
    for i in range(start_line, len(lines)):
        line = lines[i]
        for char in line:
            if char == '(':
                open_count += 1
                in_block = True
            elif char == ')':
                open_count -= 1
        if in_block and open_count == 0:
            if ';' in line:
                return i
    return -1

left_start = -1
for i, line in enumerate(lines):
    if 'Widget leftSide = Container(' in line:
        left_start = i
        break

left_end = get_block_end(left_start)

right_start = -1
for i, line in enumerate(lines):
    if 'Widget rightSide = Container(' in line:
        right_start = i
        break

right_end = get_block_end(right_start)

# Now we replace the block lines
# First right side, so it doesn't mess up left side's index
right_call = [
    "                Widget rightSide = BillingRightPanel(\n",
    "                  hasEnoughHeight: hasEnoughHeight,\n",
    "                  discountController: _discountController,\n",
    "                  gstController: _gstController,\n",
    "                  customerNameController: _customerNameController,\n",
    "                  customerPhoneController: _customerPhoneController,\n",
    "                  customerLocationController: _customerLocationController,\n",
    "                  newDoctorController: _newDoctorController,\n",
    "                  doctorsList: _doctorsList,\n",
    "                  onClearCart: _clearCart,\n",
    "                  onDecreaseQty: _decreaseQty,\n",
    "                  onIncreaseQty: _increaseQty,\n",
    "                  onRemoveItem: _removeItem,\n",
    "                  onSaveCustomerToDb: _saveCustomerToDb,\n",
    "                  onSaveDraft: _saveDraft,\n",
    "                  onShowDraftsDialog: _showDraftsDialog,\n",
    "                  onShowBillPreview: _showBillPreview,\n",
    "                  onGenerateBill: _generateAndSaveBill,\n",
    "                  customerSearchField: _buildCustomerSearchField(),\n",
    "                  isGeneratingBill: _isGeneratingBill,\n",
    "                );\n"
]

left_call = [
    "                Widget leftSide = BillingLeftPanel(\n",
    "                  isDesktopWidth: isDesktopWidth,\n",
    "                  hasEnoughHeight: hasEnoughHeight,\n",
    "                  filteredMedicines: _filteredMedicines,\n",
    "                  categories: _categories,\n",
    "                  selectedCategoryIndex: ref.watch(billingProvider).selectedCategoryIndex,\n",
    "                  onAddToCart: _addToCart,\n",
    "                  onCategorySelected: (index) {\n",
    "                    ref.read(billingProvider.notifier).updateCategory(index);\n",
    "                    setState(() {\n",
    "                      if (index == 0) {\n",
    "                        _filteredMedicines = _medicines;\n",
    "                      } else {\n",
    "                        String category = _categories[index];\n",
    "                        _filteredMedicines = _medicines.where((m) => m['category'] == category).toList();\n",
    "                      }\n",
    "                    });\n",
    "                  },\n",
    "                  onSearch: _filterMedicines,\n",
    "                );\n"
]

new_lines = lines[:left_start] + left_call + lines[left_end+1:right_start] + right_call + lines[right_end+1:]

# We also need to add the imports at the top
import_str = "import 'widgets/billing/billing_left_panel.dart';\nimport 'widgets/billing/billing_right_panel.dart';\n"
for i, line in enumerate(new_lines):
    if "import 'widgets/billing/billing_dialogs.dart';" in line:
        new_lines.insert(i, import_str)
        break

# Now for the subtotal/discount used in _generateAndSaveBill and _printBill
new_text = "".join(new_lines)

# Instead of removing the getters, let's just replace their uses and then remove them if flutter analyze complains.
new_text = new_text.replace("_subtotal", "ref.read(billingProvider).subtotal")
new_text = new_text.replace("_discountAmount", "ref.read(billingProvider).discountAmount")
new_text = new_text.replace("_gstAmount", "ref.read(billingProvider).gstAmount")
new_text = new_text.replace("_grandTotal", "ref.read(billingProvider).grandTotal")
new_text = new_text.replace("_totalItems", "ref.read(billingProvider).currentBill.length")
new_text = new_text.replace("_isDiscountPercentage", "ref.read(billingProvider).isDiscountPercentage")
new_text = new_text.replace("_isGstPercentage", "ref.read(billingProvider).isGstPercentage")
new_text = new_text.replace("_paymentMethod", "ref.read(billingProvider).paymentMethod")
new_text = new_text.replace("_selectedDoctorId", "ref.read(billingProvider).selectedDoctorId")
new_text = new_text.replace("_selectedDoctorName", "ref.read(billingProvider).selectedDoctorName")
new_text = new_text.replace("_selectedFormat", "ref.read(billingProvider).selectedFormat")

with open('lib/screens/counter/billing_screen.dart', 'w') as f:
    f.write(new_text)

