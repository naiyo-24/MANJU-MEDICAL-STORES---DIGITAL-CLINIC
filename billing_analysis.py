import re

with open("lib/screens/counter/billing_screen.dart", "r") as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")

methods = []
current_method = None
start_line = 0
open_braces = 0

for i, line in enumerate(lines):
    if " Widget build(BuildContext context)" in line or re.search(r'^\s*Widget _build', line) or re.search(r'^\s*void _show', line):
        current_method = line.strip().split('(')[0].split()[-1]
        start_line = i
        open_braces = line.count('{') - line.count('}')
    elif current_method:
        open_braces += line.count('{') - line.count('}')
        if open_braces == 0:
            methods.append((current_method, start_line, i))
            current_method = None

for m in methods:
    print(f"{m[0]}: {m[1]} - {m[2]} ({m[2]-m[1]} lines)")
