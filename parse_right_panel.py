import re

with open('right_side_raw.dart', 'r') as f:
    content = f.read()

# Dependencies to look for
deps = re.findall(r'_[a-zA-Z0-9_]+', content)
deps = set(deps)
print("Local state/methods used:", sorted(list(deps)))
