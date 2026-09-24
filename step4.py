with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    text = f.read()

import_str = "import 'widgets/billing/billing_left_panel.dart';\nimport 'widgets/billing/billing_right_panel.dart';\n"
text = text.replace("import '../../providers/billing_provider.dart';", "import '../../providers/billing_provider.dart';\n" + import_str)

with open('lib/screens/counter/billing_screen.dart', 'w') as f:
    f.write(text)
