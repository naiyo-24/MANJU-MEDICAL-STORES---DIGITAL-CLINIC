import re

file_path = 'lib/screens/counter/inventory_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Replace the table body block
pattern = r'child:\s*_isLoading\s*\?\s*const Center\(child:\s*CircularProgressIndicator\(color:\s*Color\(0xFF22C55E\)\)\)\s*:\s*_errorMessage\.isNotEmpty\s*\?\s*Center\(child:\s*Text\(_errorMessage,\s*style:\s*const TextStyle\(color:\s*Colors\.red\)\)\)\s*:\s*_medicines\.isEmpty\s*\?\s*const Center\(child:\s*Text\(\'No inventory items found\.\'\)\)\s*:\s*ListView\.separated\('
replacement = r'''child: inventoryAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
                                error: (err, stack) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
                                data: (medicines) {
                                  if (medicines.isEmpty) {
                                    return const Center(child: Text('No inventory items found.'));
                                  }
                                  return ListView.separated('''
content = re.sub(pattern, replacement, content)

# Change _medicines[index] to medicines[index]
content = re.sub(r'final medicine = _medicines\[index\];', r'final medicine = medicines[index];', content)
content = re.sub(r'itemCount: _medicines\.length,', r'itemCount: medicines.length,', content)

# Close the inventoryAsync.when bracket at line 602
content = content.replace('''                                        },
                                      ),
                      ),
                    ],
                  );''', '''                                        },
                                      );
                                }),
                      ),
                    ],
                  );''')

with open(file_path, 'w') as f:
    f.write(content)
