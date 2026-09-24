import re

with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    content = f.read()

# Add imports for left and right panels
imports = """import 'widgets/billing/billing_left_panel.dart';
import 'widgets/billing/billing_right_panel.dart';
"""
content = content.replace("import 'widgets/billing/billing_dialogs.dart';", imports + "import 'widgets/billing/billing_dialogs.dart';")

# Find where leftSide and rightSide are defined and replace them
def find_block(content, prefix, start_char='(', end_char=')'):
    start_idx = content.find(prefix)
    if start_idx == -1: return None, None
    open_brackets = 0
    in_block = False
    for i in range(start_idx, len(content)):
        if content[i] == start_char:
            open_brackets += 1
            in_block = True
        elif content[i] == end_char:
            open_brackets -= 1
        if in_block and open_brackets == 0:
            return start_idx, i + 1
    return None, None

left_start, left_end = find_block(content, "Widget leftSide = Container", '{', '}')
if left_start:
    # Just need to make sure we find the semicolon at the end
    while content[left_end] != ';':
        left_end += 1
    left_end += 1

right_start, right_end = find_block(content, "Widget rightSide = Container", '{', '}')
if right_start:
    while content[right_end] != ';':
        right_end += 1
    right_end += 1

left_call = """Widget leftSide = BillingLeftPanel(
                  isDesktopWidth: isDesktopWidth,
                  hasEnoughHeight: hasEnoughHeight,
                  filteredMedicines: _filteredMedicines,
                  categories: _categories,
                  selectedCategoryIndex: ref.watch(billingProvider).selectedCategoryIndex,
                  onAddToCart: _addToCart,
                  onCategorySelected: (index) {
                    ref.read(billingProvider.notifier).updateCategory(index);
                    setState(() {
                      if (index == 0) {
                        _filteredMedicines = _medicines;
                      } else {
                        String category = _categories[index];
                        _filteredMedicines = _medicines.where((m) => m['category'] == category).toList();
                      }
                    });
                  },
                  onSearch: _filterMedicines,
                );"""

right_call = """Widget rightSide = BillingRightPanel(
                  hasEnoughHeight: hasEnoughHeight,
                  discountController: _discountController,
                  gstController: _gstController,
                  customerNameController: _customerNameController,
                  customerPhoneController: _customerPhoneController,
                  customerLocationController: _customerLocationController,
                  newDoctorController: _newDoctorController,
                  doctorsList: _doctorsList,
                  onClearCart: _clearCart,
                  onDecreaseQty: _decreaseQty,
                  onIncreaseQty: _increaseQty,
                  onRemoveItem: _removeItem,
                  onSaveCustomerToDb: _saveCustomerToDb,
                  onSaveDraft: _saveDraft,
                  onShowDraftsDialog: _showDraftsDialog,
                  onShowBillPreview: _showBillPreview,
                  onGenerateBill: _generateAndSaveBill,
                  customerSearchField: _buildCustomerSearchField(),
                  isGeneratingBill: _isGeneratingBill,
                );"""

if left_start and left_end:
    content = content[:left_start] + left_call + content[left_end:]

# Recalculate right_start because content changed
right_start, right_end = find_block(content, "Widget rightSide = Container", '{', '}')
if right_start and right_end:
    while content[right_end] != ';':
        right_end += 1
    right_end += 1
    content = content[:right_start] + right_call + content[right_end:]


# We can safely remove the unused getters at the bottom since they are in BillingState now
# Remove _subtotal, _totalItems, _discountAmount, _gstAmount, _grandTotal
def remove_getter(content, name):
    pattern = r'(double|int)\s+get\s+' + name + r'\s*\{.*?\}'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
    
    # Also if they are arrow functions
    pattern_arrow = r'(double|int)\s+get\s+' + name + r'\s*=>.*?;'
    content = re.sub(pattern_arrow, '', content, flags=re.DOTALL)
    
    return content

for getter in ['_subtotal', '_totalItems', '_discountAmount', '_gstAmount', '_grandTotal']:
    content = remove_getter(content, getter)

# Fix where the unused getters are called in _generateAndSaveBill or other methods
# Actually, those methods are inside billing_screen.dart, so we need to update them to use ref.watch(billingProvider).grandTotal, etc.
content = content.replace("this._subtotal", "ref.read(billingProvider).subtotal")
content = content.replace("this._discountAmount", "ref.read(billingProvider).discountAmount")
content = content.replace("this._gstAmount", "ref.read(billingProvider).gstAmount")
content = content.replace("this._grandTotal", "ref.read(billingProvider).grandTotal")
content = content.replace("_subtotal", "ref.read(billingProvider).subtotal")
content = content.replace("_discountAmount", "ref.read(billingProvider).discountAmount")
content = content.replace("_gstAmount", "ref.read(billingProvider).gstAmount")
content = content.replace("_grandTotal", "ref.read(billingProvider).grandTotal")
content = content.replace("_totalItems", "ref.read(billingProvider).currentBill.length")

# Remove unused local variables that we moved to BillingState
# _isDiscountPercentage, _discountValue, _isGstPercentage, _gstValue, _paymentMethod, _selectedDoctorId, _selectedDoctorName, _selectedFormat
# Be careful removing them if they are still used in initState etc.
# I'll just leave them for now to avoid breaking the logic. 
# But wait, we need to make sure the app compiles. Let's see.

with open('lib/screens/counter/billing_screen.dart', 'w') as f:
    f.write(content)
