import re

with open('right_side_raw.dart', 'r') as f:
    content = f.read()

# Make it a ConsumerWidget
widget_code = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/billing_provider.dart';
import '../../../../models/doctor.dart';

class BillingRightPanel extends ConsumerWidget {
  final bool hasEnoughHeight;
  final TextEditingController discountController;
  final TextEditingController gstController;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController customerLocationController;
  final TextEditingController newDoctorController;
  final List<Doctor> doctorsList;
  
  final VoidCallback onClearCart;
  final Function(int) onDecreaseQty;
  final Function(int) onIncreaseQty;
  final Function(int) onRemoveItem;
  final VoidCallback onSaveCustomerToDb;
  final VoidCallback onSaveDraft;
  final VoidCallback onShowDraftsDialog;
  final VoidCallback onShowBillPreview;
  final VoidCallback onGenerateBill;
  final Widget customerSearchField;

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
  }) : super(key: key);

  Widget _buildCompactField(String label, TextEditingController controller, {bool isNumber = false, String? hint, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionalExpanded(bool condition, Widget child) {
    if (condition) {
      return Expanded(child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);
    final notifier = ref.read(billingProvider.notifier);
    
"""

# Now transform the raw code
content = content.replace("Widget rightSide = Container(", "return Container(")
# State variables -> billingState.x
content = content.replace("_currentBill", "billingState.currentBill")
content = content.replace("_totalItems", "billingState.currentBill.length")
content = content.replace("_subtotal", "billingState.subtotal")
content = content.replace("_discountAmount", "billingState.discountAmount")
content = content.replace("_gstAmount", "billingState.gstAmount")
content = content.replace("_grandTotal", "billingState.grandTotal")

content = content.replace("_isDiscountPercentage", "billingState.isDiscountPercentage")
content = content.replace("_isGstPercentage", "billingState.isGstPercentage")
content = content.replace("_paymentMethod", "billingState.paymentMethod")
content = content.replace("_selectedDoctorId", "billingState.selectedDoctorId")
content = content.replace("_selectedDoctorName", "billingState.selectedDoctorName")
content = content.replace("_selectedFormat", "billingState.selectedFormat")
content = content.replace("_isGeneratingBill", "billingState.isGeneratingBill") # Wait, isGeneratingBill is not in state. It's local. I will leave it local to the screen, so I'll add it to the state or pass it.
# Wait, I didn't add isGeneratingBill to BillingState. Let me add it to the BillingRightPanel constructor.
# I'll just manually fix it if it's missing. Or I'll add `final bool isGeneratingBill;`

# Controllers
content = content.replace("_discountController", "discountController")
content = content.replace("_gstController", "gstController")
content = content.replace("_customerNameController", "customerNameController")
content = content.replace("_customerPhoneController", "customerPhoneController")
content = content.replace("_customerLocationController", "customerLocationController")
content = content.replace("_newDoctorController", "newDoctorController")
content = content.replace("_doctorsList", "doctorsList")
content = content.replace("_buildCustomerSearchField()", "customerSearchField")

# Methods
content = content.replace("_clearCart", "onClearCart")
content = content.replace("_decreaseQty", "onDecreaseQty")
content = content.replace("_increaseQty", "onIncreaseQty")
content = content.replace("_removeItem", "onRemoveItem")
content = content.replace("_saveCustomerToDb", "onSaveCustomerToDb")
content = content.replace("_saveDraft", "onSaveDraft")
content = content.replace("_showDraftsDialog", "onShowDraftsDialog")
content = content.replace("_showBillPreview", "onShowBillPreview")
content = content.replace("_generateAndSaveBill", "onGenerateBill")

# setState replacements for things like changing payment method or doctor
content = re.sub(r'setState\(\(\)\s*\{\s*_paymentMethod\s*=\s*(.*?);\s*\}\);', r'notifier.updatePaymentMethod(\1);', content)
content = re.sub(r'setState\(\(\)\s*\{\s*_isDiscountPercentage\s*=\s*(.*?);\s*\}\);', r'notifier.updateDiscount(billingState.discountValue, \1);', content)
content = re.sub(r'setState\(\(\)\s*\{\s*_isGstPercentage\s*=\s*(.*?);\s*\}\);', r'notifier.updateGst(billingState.gstValue, \1);', content)

# Some setStates are more complex (e.g. DropdownButton for doctor)
content = re.sub(r'setState\(\(\)\s*\{\s*_selectedDoctorId\s*=\s*val;\s*if\s*\(val\s*!=\s*\'new\'\)\s*\{\s*_selectedDoctorName\s*=\s*doctorsList\.firstWhere\(\(d\)\s*=>\s*d\.id\s*==\s*val\)\.name;\s*\}\s*\}\);',
                 r"notifier.updateDoctor(val, val != 'new' ? doctorsList.firstWhere((d) => d.id == val).name : 'Walk-in');", content)

widget_code += content + "\n}\n"

with open('lib/screens/counter/widgets/billing/billing_right_panel.dart', 'w') as f:
    f.write(widget_code)

print("BillingRightPanel created.")
