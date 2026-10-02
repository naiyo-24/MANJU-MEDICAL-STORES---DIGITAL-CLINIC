import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/category_service.dart';
import '../providers/counter_providers.dart';

class CategoryDropdown extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  ConsumerState<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends ConsumerState<CategoryDropdown> {
  @override
  void initState() {
    super.initState();
    // Riverpod handles fetching automatically upon watching
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final newCategory = await ref.read(categoryProvider.notifier).createCategory(
                  nameCtrl.text,
                  descriptionCtrl.text.isEmpty ? null : descriptionCtrl.text,
                );
                if (mounted) {
                  widget.onChanged(newCategory?.id);
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add category: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryProvider);

    return categoryAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const Text('Error loading categories'),
      data: (categories) {
        final isValidValue = widget.selectedCategoryId == null || categories.any((c) => c.id == widget.selectedCategoryId);
        final safeValue = isValidValue ? widget.selectedCategoryId : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            return DropdownButtonFormField<String>(
              isExpanded: true,
              value: safeValue,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: [
                ...categories.map((cat) {
                  final displayText = cat.description != null && cat.description!.isNotEmpty
                      ? '${cat.name} (${cat.description})'
                      : cat.name;
                  return DropdownMenuItem(
                    value: cat.id,
                    child: SizedBox(
                      width: constraints.maxWidth - 32, // account for inner padding
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(displayText, overflow: TextOverflow.ellipsis)),
                          IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Close the dropdown first
                    Navigator.pop(context);
                    
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Category'),
                        content: Text('Are you sure you want to delete "$displayText"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref.read(categoryProvider.notifier).deleteCategory(cat.id);
                                if (widget.selectedCategoryId == cat.id) {
                                  widget.onChanged(null);
                                }
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete category: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
        DropdownMenuItem(
          value: 'add_new',
          child: SizedBox(
            width: constraints.maxWidth - 32,
            child: Row(
              children: const [
                Icon(Icons.add, color: Color(0xFF22C55E)),
                SizedBox(width: 8),
                Expanded(child: Text('Add New Category', overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ],
      selectedItemBuilder: (BuildContext context) {
        return [
          ...categories.map((cat) {
            final displayText = cat.description != null && cat.description!.isNotEmpty
                ? '${cat.name} (${cat.description})'
                : cat.name;
            return Text(displayText, overflow: TextOverflow.ellipsis);
          }),
          const Text('Add New Category'),
        ];
      },
      onChanged: (value) {
        if (value == 'add_new') {
          _showAddCategoryDialog();
        } else {
          widget.onChanged(value);
        }
      },
    );
          },
        );
      },
    );
  }
}
