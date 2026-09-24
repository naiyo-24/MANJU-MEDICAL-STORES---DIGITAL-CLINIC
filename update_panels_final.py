import re

with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    lines = f.readlines()

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
    "                  onSearch: (q) {\n",
    "                    setState(() {\n",
    "                      if (q.isEmpty) {\n",
    "                        _filteredMedicines = _medicines;\n",
    "                      } else {\n",
    "                        _filteredMedicines = _medicines.where((m) => \n",
    "                          m['name'].toString().toLowerCase().contains(q.toLowerCase()) || \n",
    "                          m['brand'].toString().toLowerCase().contains(q.toLowerCase())\n",
    "                        ).toList();\n",
    "                      }\n",
    "                    });\n",
    "                  },\n",
    "                );\n"
]

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

new_lines = lines[:1205] + left_call + ['\n'] + right_call + ['\n'] + lines[1876:]

import_str = "import 'widgets/billing/billing_left_panel.dart';\nimport 'widgets/billing/billing_right_panel.dart';\n"
for i, line in enumerate(new_lines):
    if "import 'widgets/billing/billing_dialogs.dart';" in line:
        new_lines.insert(i, import_str)
        break

new_text = "".join(new_lines)

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
new_text = new_text.replace("_savedCustomerId", "ref.read(billingProvider).savedCustomerId")

new_text = new_text.replace("double get ref.read(billingProvider).subtotal", "double get _subtotal")
new_text = new_text.replace("double get ref.read(billingProvider).discountAmount", "double get _discountAmount")
new_text = new_text.replace("double get ref.read(billingProvider).gstAmount", "double get _gstAmount")
new_text = new_text.replace("double get ref.read(billingProvider).grandTotal", "double get _grandTotal")
new_text = new_text.replace("int get ref.read(billingProvider).currentBill.length", "int get _totalItems")

with open('lib/screens/counter/billing_screen.dart', 'w') as f:
    f.write(new_text)
