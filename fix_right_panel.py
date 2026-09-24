import re

with open('lib/screens/counter/widgets/billing/billing_right_panel.dart', 'r') as f:
    content = f.read()

# Fix `notifier.updateDoctor(val, val != 'new' ? doctorsList.firstWhere((d) => d.id == val).name : 'Walk-in');` 
# where `val` is nullable inside `onChanged: (val) { ... }`
content = content.replace("d.id == val", "d.id == val!")
content = content.replace("notifier.updateDoctor(val, val != 'new' ? doctorsList.firstWhere((d) => d.id == val!).name : 'Walk-in');",
                          "if (val != null) notifier.updateDoctor(val, val != 'new' ? doctorsList.firstWhere((d) => d.id == val).name : 'Walk-in');")

# Fix missing isGeneratingBill which was added to constructor implicitly but not added correctly by regex
# I'll just add `final bool isGeneratingBill;` to the class
class_def = """  final VoidCallback onShowBillPreview;
  final VoidCallback onGenerateBill;
  final Widget customerSearchField;
  final bool isGeneratingBill;

  const BillingRightPanel({
    Key? key,
    required this.hasEnoughHeight,
    required this.discountController,
    required this.gstController,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.customerLocationController,
    required this.newDoctorController,
    required this.doctorsList,
    required this.onClearCart,
    required this.onDecreaseQty,
    required this.onIncreaseQty,
    required this.onRemoveItem,
    required this.onSaveCustomerToDb,
    required this.onSaveDraft,
    required this.onShowDraftsDialog,
    required this.onShowBillPreview,
    required this.onGenerateBill,
    required this.customerSearchField,
    required this.isGeneratingBill,
  }) : super(key: key);"""
content = re.sub(r'  final VoidCallback onShowBillPreview;.*?\) : super\(key: key\);', class_def, content, flags=re.DOTALL)

# Fix `setState` that failed to replace properly
# The ones that failed were inside InkWell for discount and gst:
# `setState(() { _isDiscountPercentage = true; });`
content = re.sub(r'setState\(\(\)\s*\{\s*billingState\.isDiscountPercentage\s*=\s*(.*?);\s*\}\);', r'notifier.updateDiscount(billingState.discountValue, \1);', content)
content = re.sub(r'setState\(\(\)\s*\{\s*billingState\.isGstPercentage\s*=\s*(.*?);\s*\}\);', r'notifier.updateGst(billingState.gstValue, \1);', content)
content = re.sub(r'setState\(\(\)\s*\{\s*billingState\.paymentMethod\s*=\s*(.*?);\s*\}\);', r'notifier.updatePaymentMethod(\1);', content)
content = re.sub(r'setState\(\(\)\s*\{\s*billingState\.selectedFormat\s*=\s*(.*?);\s*\}\);', r'notifier.updateSelectedFormat(\1);', content)

# Fix `billingState.isGeneratingBill` to `isGeneratingBill`
content = content.replace("billingState.isGeneratingBill", "isGeneratingBill")

# Fix `color: const Color(0xFF22C55E).withOpacity(0.1)` -> `.withValues(alpha: 0.1)`
content = content.replace("withOpacity(", "withValues(alpha: ")

# Fix missing closing brace
if not content.strip().endswith('}'):
    content = content + "\n}\n"

with open('lib/screens/counter/widgets/billing/billing_right_panel.dart', 'w') as f:
    f.write(content)
