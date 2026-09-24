import re

file_path = 'lib/screens/counter/billing_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Find the start of rightSide
start_str = "Widget rightSide = Container("
start_idx = content.find(start_str)

# Find the end by counting braces/parentheses. 
# We need to trace until the closing parenthesis/semicolon of rightSide.
open_parens = 0
open_braces = 0
end_idx = -1

for i in range(start_idx, len(content)):
    if content[i] == '(':
        open_parens += 1
    elif content[i] == ')':
        open_parens -= 1
    elif content[i] == '{':
        open_braces += 1
    elif content[i] == '}':
        open_braces -= 1
        
    if open_parens == 0 and open_braces == 0 and content[i] == ';':
        if i > start_idx + len(start_str):
            end_idx = i + 1
            break

right_side_code = content[start_idx:end_idx]

with open('right_side_raw.dart', 'w') as f:
    f.write(right_side_code)

print("Right side extracted to right_side_raw.dart")
