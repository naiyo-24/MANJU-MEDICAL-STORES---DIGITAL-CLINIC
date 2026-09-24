import re

with open('lib/screens/counter/widgets/billing/billing_right_panel.dart', 'r') as f:
    content = f.read()

# Fix imports
content = content.replace("import '../../../../models/doctor.dart';", "import '../../../../services/doctor_service.dart';")

# Replace setStates
# setState(() { billingState.selectedDoctorId = newValue; if (newValue == 'walk-in') { billingState.selectedDoctorName = 'Walk-in'; } else if (newValue != 'new') { billingState.selectedDoctorName = doctorsList.firstWhere((d) => d.id == newValue).name; } });
# Actually we can just do a multi-line replacement using regex or just rewrite that dropdown logic completely:
doc_dropdown_pattern = r"setState\(\(\)\s*\{\s*billingState\.selectedDoctorId\s*=\s*newValue;\s*if\s*\(newValue\s*==\s*'walk-in'\)\s*\{\s*billingState\.selectedDoctorName\s*=\s*'Walk-in';\s*\}\s*else\s*if\s*\(newValue\s*!=\s*'new'\)\s*\{\s*billingState\.selectedDoctorName\s*=\s*doctorsList\.firstWhere\(\(d\)\s*=>\s*d\.id\s*==\s*newValue\)\.name;\s*\}\s*\}\);"
replacement = """if (newValue == 'walk-in') {
                                                            notifier.updateDoctor('walk-in', 'Walk-in');
                                                          } else if (newValue == 'new') {
                                                            notifier.updateDoctor('new', 'New Doctor');
                                                          } else {
                                                            notifier.updateDoctor(newValue, doctorsList.firstWhere((d) => d.id == newValue).name);
                                                          }"""
content = re.sub(doc_dropdown_pattern, replacement, content, flags=re.DOTALL)

# setState(() => billingState.isDiscountPercentage = true)
content = content.replace("setState(() => billingState.isDiscountPercentage = true)", "notifier.updateDiscount(billingState.discountValue, true)")
content = content.replace("setState(() => billingState.isDiscountPercentage = false)", "notifier.updateDiscount(billingState.discountValue, false)")

# setState(() => billingState.isGstPercentage = true)
content = content.replace("setState(() => billingState.isGstPercentage = true)", "notifier.updateGst(billingState.gstValue, true)")
content = content.replace("setState(() => billingState.isGstPercentage = false)", "notifier.updateGst(billingState.gstValue, false)")

with open('lib/screens/counter/widgets/billing/billing_right_panel.dart', 'w') as f:
    f.write(content)
