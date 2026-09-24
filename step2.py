with open('lib/screens/counter/billing_screen.dart', 'r') as f:
    lines = f.readlines()

left_call = [
    "                Widget leftSide = BillingLeftPanel(\n",
    "                  isDesktopWidth: isDesktopWidth,\n",
    "                  hasEnoughHeight: hasEnoughHeight,\n",
    "                  filteredMedicines: _filteredMedicines,\n",
    "                  categories: _categories,\n",
    "                  selectedCategoryIndex: ref.watch(billingProvider).selectedCategoryIndex,\n",
    "                  onAddToCart: _addToCart,\n",
    "                  onCategorySelected: (index) {\n",
    "                    ref.read(billingProvider.notifier).updateCategory(index);\n",
    "                    setState(() {\n",
    "                      if (index == 0) {\n",
    "                        _filteredMedicines = _medicines;\n",
    "                      } else {\n",
    "                        String category = _categories[index];\n",
    "                        _filteredMedicines = _medicines.where((m) => m['category'] == category).toList();\n",
    "                      }\n",
    "                    });\n",
    "                  },\n",
    "                  onSearch: (q) {\n",
    "                    setState(() {\n",
    "                      if (q.isEmpty) {\n",
    "                        _filteredMedicines = _medicines;\n",
    "                      } else {\n",
    "                        _filteredMedicines = _medicines.where((m) => \n",
    "                          m['name'].toString().toLowerCase().contains(q.toLowerCase()) || \n",
    "                          m['brand'].toString().toLowerCase().contains(q.toLowerCase())\n",
    "                        ).toList();\n",
    "                      }\n",
    "                    });\n",
    "                  },\n",
    "                );\n"
]

r_start, r_end = -1, -1
for i, l in enumerate(lines):
    if 'Widget leftSide = Container(' in l:
        r_start = i
        break

if r_start != -1:
    open_brackets = 0
    in_block = False
    for i in range(r_start, len(lines)):
        for char in lines[i]:
            if char == '(':
                open_brackets += 1
                in_block = True
            elif char == ')':
                open_brackets -= 1
        
        if in_block and open_brackets == 0:
            if ';' in lines[i]:
                r_end = i
                break

    new_lines = lines[:r_start] + left_call + lines[r_end+1:]
    with open('lib/screens/counter/billing_screen.dart', 'w') as f:
        f.writelines(new_lines)
