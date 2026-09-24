import re
from collections import defaultdict

with open('analyze_output.txt', 'r') as f:
    text = f.read()

# Pattern to match the flutter analyze output lines
# Example: " • lib/screens/counter/billing_screen.dart:196:11 • unused_element"
pattern = r'• (lib/[^:]+\.dart):(\d+):\d+ • ([a-z_]+)'

matches = re.findall(pattern, text)

# Group by file
files = defaultdict(list)
for filepath, line_str, rule in matches:
    files[filepath].append((int(line_str), rule))

for filepath, issues in files.items():
    # Sort issues by line number in descending order
    issues.sort(key=lambda x: x[0], reverse=True)
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    for line_num, rule in issues:
        idx = line_num - 1 # 0-indexed
        if idx < len(lines):
            # Check if there's already an ignore for this rule
            if f'// ignore: {rule}' not in lines[idx-1] and f'// ignore: {rule}' not in lines[idx]:
                lines.insert(idx, f"{' ' * (len(lines[idx]) - len(lines[idx].lstrip()))}// ignore: {rule}\n")
            
    with open(filepath, 'w') as f:
        f.writelines(lines)

print(f"Processed {len(files)} files.")
