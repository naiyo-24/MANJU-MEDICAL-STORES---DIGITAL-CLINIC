with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    lines = f.readlines()

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

r_start, r_end = -1, -1
for i, l in enumerate(lines):
    if 'Widget rightSide = Container(' in l:
        r_start = i
        break

if r_start != -1:
    open_brackets = 0
    in_block = False
    for i in range(r_start, len(lines)):
        for char in lines[i]:
            if char == '(':
                open_brackets += 1
                in_block = True
            elif char == ')':
                open_brackets -= 1
        
        if in_block and open_brackets == 0:
            if ';' in lines[i]:
                r_end = i
                break

    new_lines = lines[:r_start] + right_call + lines[r_end+1:]
    with open('lib/screens/counter/billing_screen.dart', 'w') as f:
        f.writelines(new_lines)
