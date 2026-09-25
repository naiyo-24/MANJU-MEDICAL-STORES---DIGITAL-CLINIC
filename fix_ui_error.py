import re

ui_file = '/Users/hypothticoder/MANJU-MEDICAL-STORES---DIGITAL-CLINIC/lib/screens/counter/upload_management_screen.dart'
content = open(ui_file).read()

old_snackbar = "Text('Failed to add medicine: $e'"
new_snackbar = "Text(e.toString().replaceAll('Exception: ', '')"

if old_snackbar in content:
    content = content.replace(old_snackbar, new_snackbar)
    open(ui_file, 'w').write(content)
    print("Updated upload_management_screen.dart successfully")
else:
    print("Could not find the snackbar in upload_management_screen.dart")
