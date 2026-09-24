import re

file_path = 'lib/screens/counter/bill_customization_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Add import
import_str = "import '../../models/settings_models.dart';\n"
if "settings_models.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{import_str}")

# Replace Map for settings
content = re.sub(
    r"final settings = \{.*?\};", 
    "final settings = ShopSettings(\n        shopName: _shopNameCtrl.text,\n        tagline: _taglineCtrl.text,\n        address: _addressCtrl.text,\n        phone: _phoneCtrl.text,\n        landline: _landlineCtrl.text,\n        email: _emailCtrl.text,\n        gstNumber: _gstCtrl.text,\n        bankName: _bankNameCtrl.text,\n        branchName: _branchNameCtrl.text,\n        acHolderName: _acHolderCtrl.text,\n        acNumber: _acNumberCtrl.text,\n        ifscCode: _ifscCtrl.text,\n        terms1: _terms1Ctrl.text,\n        terms2: _terms2Ctrl.text,\n        terms3: _terms3Ctrl.text,\n      );", 
    content, flags=re.DOTALL
)

# Fix generatePdf call to use settings.toMap() temporarily to avoid changing pdf_generator.dart right now
content = content.replace("settings: settings,", "settings: settings.toMap(),")

# Replace dummyItems with BillItem
dummy_items_str = """final dummyItems = [
        BillItem(id: '1', name: 'Paracetamol 500mg', batch: 'B123', expiry: '12/25', hsn: '3004', qty: 2, mrp: 25.0, price: 25.0, cgst: 6, sgst: 6, total: 50.0),
        BillItem(id: '2', name: 'Amoxicillin 250mg', batch: 'B456', expiry: '10/24', hsn: '3004', qty: 1, mrp: 120.0, price: 120.0, cgst: 6, sgst: 6, total: 120.0),
        BillItem(id: '3', name: 'Cough Syrup 100ml', batch: 'C789', expiry: '05/26', hsn: '3004', qty: 1, mrp: 85.0, price: 85.0, cgst: 6, sgst: 6, total: 85.0),
      ].map((e) => e.toMap()).toList();"""
      
content = re.sub(
    r"final dummyItems = \[.*?\];", 
    dummy_items_str, 
    content, flags=re.DOTALL
)

with open(file_path, 'w') as f:
    f.write(content)
